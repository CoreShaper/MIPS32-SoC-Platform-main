`timescale 1ns/1ps
module dual_port_ram #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 65536,               // 2**16 字深度
    parameter I_LATENCY  = 0           // 指令端口读延迟（0：组合输出；>0：延迟周期数）
) (
    input  wire                         clk,
    input  wire                         rst_n,
    
    // ---- 指令端口（只读，组合逻辑输出） ----
    input  wire                         i_ce,
    input  wire [ADDR_WIDTH-1:0]        i_addr,
    output wire [DATA_WIDTH-1:0]        i_rdata,
    output wire                         i_ready, // 新增指令端口就绪信号
    
    // ---- 数据端口（读写，时序逻辑） ----
    input  wire                         d_ce,
    input  wire                         d_we,
    input  wire [3:0]                   d_sel,
    input  wire [ADDR_WIDTH-1:0]        d_addr,
    input  wire [DATA_WIDTH-1:0]        d_wdata,
    output reg  [DATA_WIDTH-1:0]        d_rdata
);

    // 自动计算所需地址位宽
    localparam BYTE_OFFSET     = $clog2(DATA_WIDTH/8);         // 2 (4字节)
    localparam WORD_ADDR_WIDTH = $clog2(MEM_DEPTH);            // 16

    // 从字节地址中提取字地址（只取所需的低位，高位由外部译码）
    wire [WORD_ADDR_WIDTH-1:0] i_word_addr = i_addr[WORD_ADDR_WIDTH + BYTE_OFFSET - 1 : BYTE_OFFSET];
    wire [WORD_ADDR_WIDTH-1:0] d_word_addr = d_addr[WORD_ADDR_WIDTH + BYTE_OFFSET - 1 : BYTE_OFFSET];

    // 存储器数组
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    
    // 初始化（仅用于仿真，综合工具会忽略 initial 块）
    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
        //$readmemh("SW/obj/program.hex", mem);
        $readmemh("SW/obj/selftest.hex", mem);
        $display("RAM initialization check:");
        for (i = 0; i < 8; i = i + 1) begin
            $display("mem[%0d] = %08h", i, mem[i]);
        end
    end

    // 指令端口：组合逻辑读，数据与就绪信号均在当拍有效
    // assign i_rdata = i_ce ? mem[i_word_addr] : {DATA_WIDTH{1'b0}};
    // assign i_ready = i_ce;              // 组合输出，表示数据有效

// ============================================================
// Instruction Port Delay Model
// 固定延迟同步存储器模型
// ============================================================

generate
if (I_LATENCY == 0) begin : i_nodelay

    assign i_rdata = i_ce ? mem[i_word_addr] : 0;
    assign i_ready = i_ce;

end
else begin : i_delay

    reg [DATA_WIDTH-1:0] rdata_r;

    reg [31:0] wait_cnt;

    reg busy;

    //----------------------------------------------------------
    // 时序逻辑
    //----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin

            rdata_r <= 0;

            wait_cnt <= 0;

            busy <= 1;

        end
        else begin

            //--------------------------------------------------
            // IDLE
            //--------------------------------------------------
            if (!busy) begin

                if (i_ce) begin

                    //--------------------------------------------------
                    // 开始一次memory access
                    //--------------------------------------------------
                    wait_cnt <= I_LATENCY - 1;

                    busy <= 1'b1;
                end
            end

            //--------------------------------------------------
            // BUSY
            //--------------------------------------------------
            else begin

                if (wait_cnt != 0) begin

                    wait_cnt <= wait_cnt - 1;

                end
                else begin

                    //--------------------------------------------------
                    // latency结束
                    // 此时PC仍被stall住
                    // 直接读取当前PC对应数据
                    //--------------------------------------------------
                    rdata_r <= mem[i_word_addr];

                    busy <= 1'b0;
                end
            end
        end
    end

    //----------------------------------------------------------
    // 输出
    //----------------------------------------------------------

    // busy期间表示memory未ready
    assign i_ready = !busy;

    // 数据始终保持
    assign i_rdata = rdata_r;

end
endgenerate


    // 数据端口写操作（时序）
    always @(posedge clk) begin
        if (d_ce && d_we) begin
            if (d_sel[3]) mem[d_word_addr][31:24] <= d_wdata[31:24];
            if (d_sel[2]) mem[d_word_addr][23:16] <= d_wdata[23:16];
            if (d_sel[1]) mem[d_word_addr][15: 8] <= d_wdata[15: 8];
            if (d_sel[0]) mem[d_word_addr][ 7: 0] <= d_wdata[ 7: 0];
        end
    end

    // 数据端口读操作（组合逻辑，带写后读转发）
    always @(*) begin
        if (d_ce) begin
            if (d_we) begin
                d_rdata = { (d_sel[3] ? d_wdata[31:24] : mem[d_word_addr][31:24]),
                            (d_sel[2] ? d_wdata[23:16] : mem[d_word_addr][23:16]),
                            (d_sel[1] ? d_wdata[15: 8] : mem[d_word_addr][15: 8]),
                            (d_sel[0] ? d_wdata[ 7: 0] : mem[d_word_addr][ 7: 0]) };
            end else begin
                d_rdata = mem[d_word_addr];
            end
        end else begin
            d_rdata = 32'b0;
        end
    end

endmodule

