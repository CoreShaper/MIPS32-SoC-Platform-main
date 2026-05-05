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
    reg  [31:0] ram_rdata;

    // ---------- Cache 控制 ----------
    reg icache_en;

    // ---------- 仿真辅助 ----------
    integer error_cnt;
    integer stall_cnt;
    reg [31:0] expected_data;

    // ---------- RAM 模型 ----------
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = {4{i[7:0]}};
        end
    end

    always @(posedge clk) begin
        if (ram_ce) begin
            ram_rdata <= mem[ram_addr[11:2]];
        end
    end

    // ---------- DUT ----------
    icache_top #(
        .LINE_NUM(16),
        .WORD_PER_LINE(8),
        .INDEX_BITS(4),
        .OFFSET_BITS(3),
        .TAG_BITS(23)
    ) u_icache (
        .clk(clk),
        .rst_n_sync(!rst_n_sync),
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
    // golden model（解决常量切片问题）
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
        cpu_addr = 0;
        icache_en = 0;
        error_cnt = 0;

        @(posedge rst_n_sync);
        repeat (2) @(posedge clk);

        // ====================
        // Test 1: bypass
        // ====================
        $display("[%0t] Test1: bypass", $time);
        icache_en = 0;

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h0;
        @(posedge clk);
        cpu_ce   = 0;
      #1;
        expected_data = golden_mem(32'h0);
        check_data(32'h0, expected_data);

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h14;
        @(posedge clk);
        cpu_ce   = 0;
      #1;
        expected_data = golden_mem(32'h14);
        check_data(32'h14, expected_data);

        // ====================
        // Test 2: miss + hit
        // ====================
        $display("[%0t] Test2: miss + hit", $time);
        icache_en = 1;

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h100;
        @(posedge clk);
        wait_stall_release();
        expected_data = golden_mem(32'h100);
        check_data(32'h100, expected_data);
        cpu_ce = 0;

        // hit
        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h100;
        @(posedge clk);
        cpu_ce   = 0;

        check_data(32'h100, expected_data);

        // ====================
        // Test 3: conflict
        // ====================
        $display("[%0t] Test3: conflict", $time);

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h20;
        @(posedge clk);
        wait_stall_release();
        check_data(32'h20, golden_mem(32'h20));
        cpu_ce = 0;

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h0001_0020;
        @(posedge clk);
        wait_stall_release();
        check_data(32'h0001_0020, golden_mem(32'h0001_0020));
        cpu_ce = 0;

        @(posedge clk);
        cpu_ce   = 1;
        cpu_addr = 32'h20;
        @(posedge clk);
        wait_stall_release();
        check_data(32'h20, golden_mem(32'h20));
        cpu_ce = 0;

        // ====================
        // Test 4: reset
        // ====================
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
        check_data(32'h100, golden_mem(32'h100));
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
    // waveform
    // ============================================================
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, module_bench);
    end

    // ============================================================
    // task
    // ============================================================
    task wait_stall_release();
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

endmodule