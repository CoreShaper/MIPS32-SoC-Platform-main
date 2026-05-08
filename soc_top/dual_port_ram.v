`timescale 1ns/1ps
module dual_port_ram #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 65536,               // 2**16 字深度
    parameter I_LATENCY  = 0           // 指令端口读延迟（0：组合输出；>0：延迟周期数）
) (
    input  wire                         clk,
    
    // ---- 指令端口（只读，组合逻辑输出） ----
    input  wire                         i_ce,
    input  wire [ADDR_WIDTH-1:0]        i_addr,
    output wire [DATA_WIDTH-1:0]        i_rdata,
    
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

    // // 指令端口：组合逻辑读
    // assign i_rdata = i_ce ? mem[i_word_addr] : {DATA_WIDTH{1'b0}};
// 指令端口组合读数据（内部使用）
    wire [DATA_WIDTH-1:0] i_rdata_comb;
    assign i_rdata_comb = i_ce ? mem[i_word_addr] : {DATA_WIDTH{1'b0}};

    // 根据 I_LATENCY 生成最终输出
    generate
        if (I_LATENCY == 0) begin : i_nodelay
            assign i_rdata = i_rdata_comb;
        end else begin : i_delay
            // 移位寄存器链
            reg [DATA_WIDTH-1:0] i_rdata_sr [0:I_LATENCY-1];
            integer d;
            always @(posedge clk) begin
                i_rdata_sr[0] <= i_rdata_comb;
                for (d = 1; d < I_LATENCY; d = d + 1) begin
                    i_rdata_sr[d] <= i_rdata_sr[d-1];
                end
            end
            assign i_rdata = i_rdata_sr[I_LATENCY-1];
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