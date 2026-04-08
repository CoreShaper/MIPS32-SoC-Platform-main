module dual_port_ram #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 65536                // 2**ADDR_WIDTH 字深度
) (
    input  wire                         clk,
    
    // ---- 指令端口（只读，组合逻辑输出） ----
    input  wire                         i_ce,
    input  wire [ADDR_WIDTH-1:0]        i_addr,
    output wire [DATA_WIDTH-1:0]        i_rdata,   // 改为 wire 类型
    
    // ---- 数据端口（读写，时序逻辑） ----
    input  wire                         d_ce,
    input  wire                         d_we,
    input  wire [3:0]                   d_sel,
    input  wire [ADDR_WIDTH-1:0]        d_addr,
    input  wire [DATA_WIDTH-1:0]        d_wdata,
    output reg  [DATA_WIDTH-1:0]        d_rdata
);

    // 存储器数组
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    
    integer i;
    initial begin
        // 清零
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
        // 加载程序
        $readmemh("SW/obj/program.hex", mem);
        
        // 打印前 8 个地址的值，用于验证
        $display("RAM initialization check:");
        for (i = 0; i < 8; i = i + 1) begin
            $display("mem[%0d] = %08h", i, mem[i]);
        end
    end

    // 指令端口：组合逻辑读（无时钟）
    assign i_rdata = i_ce ? mem[i_addr[ADDR_WIDTH-1:2]] : {DATA_WIDTH{1'b0}};

    // 数据端口：时序逻辑读写（带字节使能）
    always @(posedge clk) begin
        if (d_ce) begin
            if (d_we) begin
                if (d_sel[3]) mem[d_addr[ADDR_WIDTH-1:2]][31:24] <= d_wdata[31:24];
                if (d_sel[2]) mem[d_addr[ADDR_WIDTH-1:2]][23:16] <= d_wdata[23:16];
                if (d_sel[1]) mem[d_addr[ADDR_WIDTH-1:2]][15: 8] <= d_wdata[15: 8];
                if (d_sel[0]) mem[d_addr[ADDR_WIDTH-1:2]][ 7: 0] <= d_wdata[ 7: 0];
            end
            d_rdata <= mem[d_addr[ADDR_WIDTH-1:2]];
        end
    end

endmodule