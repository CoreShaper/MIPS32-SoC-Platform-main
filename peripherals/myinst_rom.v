`include "mydefines.v"

module myinst_rom (
    input  wire                   clk,
    input  wire                   rst,
        // AXI Lite 接口
    input  wire [`InstAddrBus]           araddr,
    input  wire                   arvalid,
    output reg                    arready,

    output reg  [`InstBus]             rdata,
    output reg                    rvalid,
    input  wire                   rready
);

    // ROM存储器
    //reg[`InstBus] inst_mem[0:`InstMemNum - 1];
   reg[`InstBus] inst_mem[0:4096 - 1];

    // 初始化 ROM
    //initial $readmemh("myinst_rom.data", inst_mem);

    always @(posedge clk) begin
             inst_mem[0]  = 32'h3c011000; 
             inst_mem[1]  = 32'h34030002; 
             inst_mem[2]  = 32'hac230040; 
             inst_mem[3]  = 32'h34030002; 
             inst_mem[4]  = 32'hac230044; 
             inst_mem[5]  = 32'h34020032; 
             inst_mem[6]  = 32'h00021400; 
             inst_mem[7]  = 32'h3442dcd5; 
             inst_mem[8]  = 32'h2042ffff; 
             inst_mem[9]  = 32'h1440fffe; 
             inst_mem[10] = 32'h00000000; 
             inst_mem[11] = 32'h34030000; 
             inst_mem[12] = 32'hac230044; 
             inst_mem[13] = 32'h34020032; 
             inst_mem[14] = 32'h00021400; 
             inst_mem[15] = 32'h3442dcd5; 
             inst_mem[16] = 32'h2042ffff; 
             inst_mem[17] = 32'h1440fffe; 
             inst_mem[18] = 32'h00000000;
             inst_mem[19] = 32'h08000003;
             inst_mem[20] = 32'h00000000;          
    end
 
    





// 状态机状态定义
localparam IDLE = 2'b00,
           ADDR = 2'b01,
           DATA = 2'b10;

reg [1:0] state;

always @(posedge clk) begin
    if (rst) begin
        arready <= 1'b0;
        rvalid  <= 1'b0;
        rdata   <= `ZeroWord;
        state   <= IDLE;
    end else begin
        case (state)
            IDLE: begin
                arready <= 1'b0;
                rvalid  <= 1'b0;
                if (arvalid) begin
                    arready <= 1'b1;
                    state   <= ADDR;
                end
            end
            ADDR: begin
                if (arvalid && arready) begin
                    arready <= 1'b0;
                    rdata   <= inst_mem[araddr[`InstMemNumLog2+1:2]]; // word对齐
                    rvalid  <= 1'b1;
                    state   <= DATA;
                end
            end
            DATA: begin
                if (rvalid && rready) begin
                    rvalid <= 1'b0;
                    state  <= IDLE;
                end
            end
        endcase
    end
end



endmodule


