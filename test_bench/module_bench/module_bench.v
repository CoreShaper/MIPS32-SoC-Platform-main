`timescale 1ns/1ps

module module_bench();

    // ---------- 时钟与复位 ----------
    reg clk;
    reg rst_n_sync;

    // ---------- CPU ----------
    reg        cpu_ce;
    reg [31:0] cpu_addr;
    wire [31:0] cpu_data;
    wire        cpu_stall;

    // ---------- RAM ----------
    wire        ram_ce;
    wire [31:0] ram_addr;
    wire [31:0] ram_rdata;

    // ---------- Cache 控制 ----------
    reg icache_en;

    // ---------- 仿真辅助 ----------
    integer error_cnt;
    integer stall_cnt;
    reg [31:0] expected_data;

    // ---------- RAM 模型（组合逻辑，4KB） ----------
    reg [31:0] mem [0:1023];
    integer i;

    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = {4{i[7:0]}};
        end
    end

    assign ram_rdata = ram_ce ? mem[ram_addr[11:2]] : 32'h0;

    // ---------- DUT ----------
    icache_top #(
        .LINE_NUM(16),
        .WORD_PER_LINE(8),
        .INDEX_BITS(4),
        .OFFSET_BITS(3),
        .TAG_BITS(23)
    ) u_icache (
        .clk(clk),
        .rst_sync(!rst_n_sync),
        .cpu_inst_ce(cpu_ce),
        .cpu_inst_addr(cpu_addr),
        .cpu_inst_data(cpu_data),
        .cpu_inst_stall(cpu_stall),
        .ram_inst_ce(ram_ce),
        .ram_inst_addr(ram_addr),
        .ram_inst_rdata(ram_rdata),
        .icache_en(icache_en)
    );

    // ---------- 时钟 ----------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ---------- 复位 ----------
    initial begin
        rst_n_sync = 0;
        #100;
        @(posedge clk);
        rst_n_sync = 1;
    end

    // ============================================================
    // golden model
    // ============================================================
    function [31:0] golden_mem;
        input [31:0] addr;
        begin
            golden_mem = mem[addr[11:2]];
        end
    endfunction

    // ============================================================
    // 主测试
    // ============================================================
    initial begin
        cpu_ce   = 0;
        cpu_addr = 32'h0;
        icache_en = 1'b0;
        error_cnt = 0;

        @(posedge rst_n_sync);
        repeat (2) @(posedge clk);

        // --- Test1: 旁路 ---
        $display("[%0t] Test1: bypass", $time);
        icache_en = 0;
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h0;
        @(negedge clk);
        expected_data = golden_mem(32'h0);
        check_data(32'h0, expected_data);
        @(posedge clk);
        cpu_ce   = 0;

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h14;
        @(negedge clk);
        expected_data = golden_mem(32'h14);
        check_data(32'h14, expected_data);
        @(posedge clk);
        cpu_ce   = 0;

        // --- Test2: miss + hit ---
        $display("[%0t] Test2: miss + hit", $time);
        icache_en = 1;
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h100;
        @(posedge clk);
        wait_stall_release();
        expected_data = golden_mem(32'h100);
        check_data_now(32'h100, expected_data);
        cpu_ce = 0;

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h100;
        @(negedge clk);
        check_data(32'h100, expected_data);
        @(posedge clk);
        cpu_ce   = 0;

        // --- Test3: conflict ---
        $display("[%0t] Test3: conflict", $time);
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h20;
        @(posedge clk);
        wait_stall_release();
        check_data_now(32'h20, golden_mem(32'h20));
        cpu_ce = 0;

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h0001_0020;
        @(posedge clk);
        wait_stall_release();
        check_data_now(32'h0001_0020, golden_mem(32'h0001_0020));
        cpu_ce = 0;

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h20;
        @(posedge clk);
        wait_stall_release();
        check_data_now(32'h20, golden_mem(32'h20));
        cpu_ce = 0;

        // --- Test4: reset ---
        $display("[%0t] Test4: reset", $time);
        rst_n_sync = 0;
        repeat (3) @(posedge clk);
        rst_n_sync = 1;
        @(posedge clk);

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h100;
        @(posedge clk);
        wait_stall_release();
        check_data_now(32'h100, golden_mem(32'h100));
        cpu_ce = 0;

             // ============================================================
        // Test5a: Miss 填充后立即再次访问同一地址（验证命中）
        // ============================================================
        $display("[%0t] Test5a: immediate re-fetch after fill", $time);
        icache_en = 1;

        // 1. Miss 0xF80，整行填充
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF80;
        @(posedge clk);
        wait_stall_release();                // 填充完成，数据已在 cpu_data 上
        expected_data = golden_mem(32'hF80);
        check_data_now(32'hF80, expected_data);


        // 2. 立即再次访问 0xF80（应命中，0 stall）
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF80;
        @(posedge clk);
        if (cpu_stall) begin
            $display("ERROR: stall on immediate re-hit 0xF80");
            error_cnt = error_cnt + 1;
        end else begin
            check_data_now(32'hF80, golden_mem(32'hF80));
        end


        // 3. 再验证同行另一个偏移（0xF84）
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF84;
        @(posedge clk);
        if (cpu_stall) begin
            $display("ERROR: stall on 0xF84 (should hit)");
            error_cnt = error_cnt + 1;
        end else begin
            check_data_now(32'hF84, golden_mem(32'hF84));
        end


        // ============================================================
        // Test5a: Miss 填充后立即再次访问同一地址（验证命中）
        // ============================================================
        $display("[%0t] Test5a: immediate re-fetch after fill", $time);
        icache_en = 1;

        // 1. Miss 0xF80，整行填充
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF80;
        @(posedge clk);
        wait_stall_release();                // 填充完成，数据已在 cpu_data 上
        expected_data = golden_mem(32'hF80);
        check_data_now(32'hF80, expected_data);
        

        // 2. 立即再次访问 0xF80（应命中，0 stall）
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF80;
        @(posedge clk);
        if (cpu_stall) begin
            $display("ERROR: stall on immediate re-hit 0xF80");
            error_cnt = error_cnt + 1;
        end else begin
            check_data_now(32'hF80, golden_mem(32'hF80));
        end
   

        // 3. 再验证同行另一个偏移（0xF84）
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF84;
        @(posedge clk);
        if (cpu_stall) begin
            $display("ERROR: stall on 0xF84 (should hit)");
            error_cnt = error_cnt + 1;
        end else begin
            check_data_now(32'hF84, golden_mem(32'hF84));
        end


        // ============================================================
        // Test5b: 填充另一行（Index 11）后，检查原行（Index 12）是否被破坏
        // ============================================================
        $display("[%0t] Test5b: fill other line (0xF60) and check corruption", $time);

        // 4. 填充 0xF60（Index 11）
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF60;
        @(posedge clk);
        wait_stall_release();
        check_data_now(32'hF60, golden_mem(32'hF60));
  

        // 5. 立即回读 0xF80（Index 12），观察是否损坏
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF80;
        @(posedge clk);
        if (cpu_stall) begin
            $display("ERROR: stall on 0xF80 after other fill (should hit)");
            error_cnt = error_cnt + 1;
        end else begin
            expected_data = golden_mem(32'hF80);
            if (cpu_data !== expected_data) begin
                $display("ERROR: 0xF80 corrupted after other fill! got=%h exp=%h",
                         cpu_data, expected_data);
                error_cnt = error_cnt + 1;
                $display("DEBUG: valid=%b tag=%h hit=%b",
                         u_icache.valid_array[u_icache.req_index],
                         u_icache.tag_array[u_icache.req_index],
                         u_icache.hit);
            end else begin
                $display("OK: 0xF80 still correct after other fill");
            end
        end
  

        // ============================================================
        // Test5c: 重新填充 0xF80 行，检查能否恢复正常并命中
        // ============================================================
        $display("[%0t] Test5c: re-fill 0xF80 line and check", $time);

        // 6. 再次请求 0xF80，此时应 miss（因为数据已损坏，valid/tag 可能还在但数据错？
        //    或者 valid 仍为 1 则不会 miss，这里只是为了观察）
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF80;
        @(posedge clk);
        if (!cpu_stall) begin
            // 如果没有 stall，说明 valid 仍为 1 且 tag 匹配（hit），但数据可能是错的那个 0
            $display("INFO: 0xF80 hit after corruption, data=%h", cpu_data);
        end else begin
            // 如果 stall 了，说明 miss，会重新填充
            wait_stall_release();
            check_data_now(32'hF80, golden_mem(32'hF80));
        end


        // 7. 再次命中验证
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF80;
        @(posedge clk);
        if (cpu_stall) begin
            $display("ERROR: stall on re-hit after re-fill");
            error_cnt = error_cnt + 1;
        end else begin
            check_data_now(32'hF80, golden_mem(32'hF80));
        end


        // ============================================================
        // 额外：填充另一个不冲突的行（0xF90，Index 12 吗？实际上 F90 与 F80 同一行）
        // 这里只是为了多观察一个 refill，可以保留但非必需
        // ============================================================

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF84;
        @(posedge clk);
        wait_stall_release();
        check_data_now(32'hF84, golden_mem(32'hF84));
  

        // 最后再读 0xF80，应为正常
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'hF80;
        @(posedge clk);
        if (cpu_stall) begin
            $display("ERROR: stall on 0xF80 after 0xF90 fill");
            error_cnt = error_cnt + 1;
        end else begin
            check_data_now(32'hF80, golden_mem(32'hF80));
        end
        cpu_ce = 0;

                // ============================================================
        // Test6: 验证 miss 时 stall 是否在同一周期拉高
        // ============================================================
        $display("[%0t] Test6: check stall timing on miss", $time);
        icache_en = 1;

        // 先填充 0x100 行，确保后续命中
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h100;
        @(posedge clk);
        wait_stall_release();
        check_data_now(32'h100, golden_mem(32'h100));
   
        // 准备连续取指：设置起始地址为 0x100，使能 ce
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h100;        // 命中，无 stall
        @(posedge clk);
        // 此时地址自动递增到 0x104（命中）
        @(posedge clk);
        // 地址 0x108（命中）
        // ... 我们直接跳到即将 miss 的地址之前：
        // 手动设置地址为 0x1FC，然后下一拍它会自动变成 0x200（miss）
                      // 暂停自动递增
        @(posedge clk);
        cpu_addr = 32'h1FC;        // 命中（如果在同一行）
        @(posedge clk);
        cpu_ce   = 1;              // 重新使能
        // 此时 cpu_addr 会从 0x1FC 自动变为 0x200（miss！）
        // 我们等待这个时钟沿
        @(posedge clk);            // 这一拍的上升沿，地址变为 0x200
        // 现在 stall 应该已经为 1，地址应该保持 0x200，不应加 4
        // 在下降沿检查
        @(negedge clk);
        if (cpu_stall !== 1'b1) begin
            $display("ERROR: stall not asserted at miss cycle! stall=%b", cpu_stall);
            error_cnt = error_cnt + 1;
        end
        if (cpu_addr !== 32'h200) begin
            $display("ERROR: address incremented during miss! addr=%h", cpu_addr);
            error_cnt = error_cnt + 1;
        end
        // 现在恢复正常：等待 refill 完成
        @(posedge clk);
        wait_stall_release();
        // 数据应为 golden_mem(0x200)
        check_data_now(32'h200, golden_mem(32'h200));
        cpu_ce = 0;
        // ====================
        // finish
        // ====================
        @(posedge clk);
        if (error_cnt == 0)
            $display("ALL PASS");
        else
            $display("FAIL: %0d errors", error_cnt);

        $finish;
    end

    // ============================================================
    // timeout
    // ============================================================
    initial begin
        #100000;
        $display("TIMEOUT");
        $finish;
    end
    // ============================================================
    // 调试监视器：每次 Refill 完成后打印整行数据
    // ============================================================
    always @(posedge clk) begin
        if (u_icache.state == 1'b1 && u_icache.wr_cnt == 4'd8 && u_icache.ram_ce_d1) begin
            $display("[%0t] Refill done: line=%0d", $time, u_icache.refill_index);
            for (int j = 0; j < 9; j++)
                $display("   word[%0d] = %h", j, u_icache.data_array[u_icache.refill_index][j]);
        end
    end
    // ============================================================
    // waveform
    // ============================================================
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, module_bench);
    end

    // ============================================================
    // 辅助任务
    // ============================================================
    task wait_stall_release;
    begin : WAIT_BLOCK
        stall_cnt = 0;
        while (cpu_stall) begin
            @(posedge clk);
            stall_cnt = stall_cnt + 1;
            if (stall_cnt > 20) begin
                $display("STALL TIMEOUT");
                error_cnt = error_cnt + 1;
                disable WAIT_BLOCK;
            end
        end
        $display("STALL cycles = %0d", stall_cnt);
    end
    endtask

    task check_data;
        input [31:0] addr;
        input [31:0] exp;
    begin
        if (cpu_data !== exp) begin
            $display("ERROR addr=%h got=%h exp=%h", addr, cpu_data, exp);
            error_cnt = error_cnt + 1;
        end else begin
            $display("OK addr=%h data=%h", addr, cpu_data);
        end
    end
    endtask

    task check_data_now;
        input [31:0] addr;
        input [31:0] exp;
    begin
        if (cpu_data !== exp) begin
            $display("ERROR addr=%h got=%h exp=%h", addr, cpu_data, exp);
            error_cnt = error_cnt + 1;
        end else begin
            $display("OK addr=%h data=%h", addr, cpu_data);
        end
    end
    endtask

endmodule