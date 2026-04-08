`timescale 1ns/1ps
`include "mydefines.v"

module myopenmips_min_sopc_tb();

    reg     CLOCK_50;
    reg     rst;
    wire    gpio;
    
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

    // 仿真自动结束检测
    always @(posedge CLOCK_50) begin
        if (sim_ctrl == 32'h00000001) begin
            $display("\n========================================");
            $display("         TEST PASSED!");
            $display("========================================\n");
            $finish;
        end else if (sim_ctrl == 32'h00000002) begin
            $display("\n========================================");
            $display("         TEST FAILED!");
            $display("========================================\n");
            $finish;
        end
    end

    // 超时保护（可选，建议保留以防程序跑飞）
    initial begin
        #100000;
        $display("\n========================================");
        $display("     SIMULATION TIMEOUT (FAIL)");
        $display("========================================\n");
        $stop;
    end

    // VCD 波形记录
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, myopenmips_min_sopc_tb);
    end

    // 实例化 SoC
    mysoc myopenmips_min_sopc0 (
        .clk    (CLOCK_50),
        .rst    (rst),
        .cpu_test (),          // 若 mysoc 未输出此端口，可删除该连接
        .GPIO01  (gpio)
    );

endmodule