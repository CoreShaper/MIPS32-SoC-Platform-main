
`include "mydefines.v"
`timescale 1ns/1ps
module myopenmips_min_sopc_tb();

    reg     CLOCK_50;
    reg     rst;
    wire    gpio;

wire [31:0] perf_hit, perf_miss, perf_stall, perf_cycle;
    // 监视仿真控制寄存器（来自 mysoc 内部）
    wire [31:0] sim_ctrl;
    assign sim_ctrl = myopenmips_min_sopc0.sim_ctrl_reg;

    // 时钟生成
    initial begin
        CLOCK_50 = 1'b0;
        forever #5 CLOCK_50 = ~CLOCK_50;
    end
      
    // 复位序列
    initial begin
        rst = `RstEnable;
        #195 rst = `RstDisable;
    end

always @(posedge CLOCK_50) begin
if (sim_ctrl == 32'h00000001) begin
        $display("\n========================================");
        $display("         TEST PASSED!");
        // 打印性能计数
        $display("--- I-Cache Performance ---");
        $display("  Cycles:  %0d", perf_cycle);
        $display("  Hits:    %0d", perf_hit);
        $display("  Misses:  %0d", perf_miss);
        $display("  Stalls:  %0d", perf_stall);
        if (perf_hit + perf_miss > 0)
            $display("  Hit rate: %.1f%%", 100.0 * perf_hit / (perf_hit + perf_miss));
        $display("========================================\n");
        $finish; 
    end else if ((sim_ctrl & 32'hFFFF0000) == 32'hDEAD0000) begin
        // 解析错误码
        $display("\n========================================");
        $display("         TEST FAILED!");
        $display("         Error code: %08h", sim_ctrl);
        // 模块号解析
        case (sim_ctrl[15:8])
            8'h11: $display("         Module: LOGIC");
            8'h12: $display("         Module: SHIFT");
            8'h13: $display("         Module: MOVE");
            8'h14: $display("         Module: ARITH");
            8'h15: $display("         Module: BRANCH");
            8'h16: $display("         Module: LOAD/STORE");
            8'h17: $display("         Module: HILO");
            8'h18: $display("         Module: CP0/EXCEPTION");
            default: $display("         Module: UNKNOWN");
        endcase
        $display("         Subcase: %02d", sim_ctrl[7:0]);
        $display("========================================\n");
        $finish;
    end
end

// 在 testbench 中
wire [31:0] sim_dbg_val = myopenmips_min_sopc0.sim_dbg_out;
reg  [31:0] prev_dbg_val = 0;

always @(posedge CLOCK_50) begin
    if (!rst &&
        myopenmips_min_sopc0.data_ce &&
        myopenmips_min_sopc0.data_we &&
        (myopenmips_min_sopc0.data_addr == 32'hFFFFFFE0)) begin
        $write("%c", myopenmips_min_sopc0.data_wdata[7:0]);
    end
end
    // 超时保护（可选，建议保留以防程序跑飞）
    initial begin
        #200000;
        $display("\n========================================");
        $display("     SIMULATION TIMEOUT (FAIL)");
        $display("========================================\n");
        $finish;
    end

    // VCD 波形记录
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, myopenmips_min_sopc_tb);
    end



mysoc myopenmips_min_sopc0 (
    .clk              (CLOCK_50),
    .rst              (rst),
    .cpu_test         (),
    .GPIO01           (gpio),
    // 新添加的四个性能端口
    .perf_hit_cnt     (perf_hit),
    .perf_miss_cnt    (perf_miss),
    .perf_stall_cnt   (perf_stall),
    .perf_cycle_cnt   (perf_cycle)
);
endmodule
