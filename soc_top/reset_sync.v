`timescale 1ns / 1ps
module reset_sync (
    input  wire clk,             // 时钟
    input  wire rst_n_async,    // 外部异步复位，低有效
    output wire rst_n_sync      // 同步释放后的复位信号，低有效
);
    reg rst_n_s1;   // 第一级同步触发器
    reg rst_n_s2;   // 第二级同步触发器

    // 第一级：带异步复位，数据恒为 1’b1（无效电平）
    always @(posedge clk or negedge rst_n_async) begin
        if (!rst_n_async)
            rst_n_s1 <= 1'b0;         // 异步复位：立即清零
        else
            rst_n_s1 <= 1'b1;         // 释放后，接数据“1”
    end

    // 第二级：带异步复位，输入来自第一级
    always @(posedge clk or negedge rst_n_async) begin
        if (!rst_n_async)
            rst_n_s2 <= 1'b0;         // 异步复位：立即清零
        else
            rst_n_s2 <= rst_n_s1;     // 释放后，跟随 rst_n_s1
    end

    assign rst_n_sync = rst_n_s2;
endmodule

