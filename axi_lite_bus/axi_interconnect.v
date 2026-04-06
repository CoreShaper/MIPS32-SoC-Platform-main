`include "defines.v"

module axi_interconnect (
    input wire          clk,
    input wire          rst,

    // 从 axi_bus_if 模块接收信号
    // 写地址通道 (Write Address Channel)
    input wire [31:0]    M_AXI_AWADDR,
    input wire           M_AXI_AWVALID,
    output wire          M_AXI_AWREADY,
    // 写数据通道 (Write Data Channel)
    input wire [31:0]    M_AXI_WDATA,
    input wire [3:0]     M_AXI_WSTRB,
    input wire           M_AXI_WVALID,
    output wire          M_AXI_WREADY,
    // 读地址通道 (Read Address Channel)
    input wire [31:0]    M_AXI_ARADDR,
    input wire           M_AXI_ARVALID,
    output wire          M_AXI_ARREADY,
    // 读数据通道 (Read Data Channel)
    output wire [31:0]   M_AXI_RDATA,
    output wire          M_AXI_RVALID,
    input wire           M_AXI_RREADY,
    // 写响应通道 (Write Response Channel)
    output wire          M_AXI_BVALID,
    input wire           M_AXI_BREADY,

    // 从机接口（3个从机）
    // 第一个从机的信号
    output reg [31:0]    M_AXI_AWADDR_0,
    output reg           M_AXI_AWVALID_0,
    input wire           M_AXI_AWREADY_0,
    output wire [2:0]    M_AXI_AWPROT_0,

    output reg [31:0]    M_AXI_WDATA_0,
    output reg [3:0]     M_AXI_WSTRB_0,
    output reg           M_AXI_WVALID_0,
    input wire           M_AXI_WREADY_0,

    output reg [31:0]    M_AXI_ARADDR_0,
    output reg           M_AXI_ARVALID_0,
    input wire           M_AXI_ARREADY_0,
    output wire [2:0]    M_AXI_ARPROT_0,
    
    input wire [31:0]    M_AXI_RDATA_0,
    input wire           M_AXI_RVALID_0,
    output reg           M_AXI_RREADY_0,
    input wire [1:0]     M_AXI_RRESP_0,

    input wire           M_AXI_BVALID_0,
    output reg           M_AXI_BREADY_0,
    input wire [1:0]     M_AXI_BRESP_0,

    // 第二个从机的信号
    output reg [31:0]    M_AXI_AWADDR_1,
    output reg           M_AXI_AWVALID_1,
    input wire           M_AXI_AWREADY_1,
    output wire [2:0]    M_AXI_AWPROT_1,

    output reg [31:0]    M_AXI_WDATA_1,
    output reg [3:0]     M_AXI_WSTRB_1,
    output reg           M_AXI_WVALID_1,
    input wire           M_AXI_WREADY_1,

    output reg [31:0]    M_AXI_ARADDR_1,
    output reg           M_AXI_ARVALID_1,
    input wire           M_AXI_ARREADY_1,
    output wire [2:0]    M_AXI_ARPROT_1,

    input wire [31:0]    M_AXI_RDATA_1,
    input wire           M_AXI_RVALID_1,
    output reg           M_AXI_RREADY_1,
    input wire [1:0]     M_AXI_RRESP_1,

    input wire           M_AXI_BVALID_1,
    output reg           M_AXI_BREADY_1,
    input wire [1:0]     M_AXI_BRESP_1,


    // 第三个从机的信号
    output reg [31:0]    M_AXI_AWADDR_2,
    output reg           M_AXI_AWVALID_2,
    input wire           M_AXI_AWREADY_2,
    output wire [2:0]    M_AXI_AWPROT_2,

    output reg [31:0]    M_AXI_WDATA_2,
    output reg [3:0]     M_AXI_WSTRB_2,
    output reg           M_AXI_WVALID_2,
    input wire           M_AXI_WREADY_2,

    output reg [31:0]    M_AXI_ARADDR_2,
    output reg           M_AXI_ARVALID_2,
    input wire           M_AXI_ARREADY_2,
    output wire [2:0]    M_AXI_ARPROT_2,

    input wire [31:0]    M_AXI_RDATA_2,
    input wire           M_AXI_RVALID_2,
    output reg           M_AXI_RREADY_2,
    input wire [1:0]     M_AXI_RRESP_2,

    input wire           M_AXI_BVALID_2,
    output reg           M_AXI_BREADY_2,
    input wire [1:0]     M_AXI_BRESP_2
);

    // 地址范围选择（假设每个从机有不同的地址范围）
    localparam SLAVE0_ADDR_BASE = 32'h00000000;
    localparam SLAVE1_ADDR_BASE = 32'h10000000;
    localparam SLAVE2_ADDR_BASE = 32'h20000000;

    // 根据地址选择从机
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            // Reset all signals
            {M_AXI_AWADDR_0, M_AXI_WDATA_0, M_AXI_WSTRB_0, M_AXI_AWVALID_0, M_AXI_WVALID_0, 
             M_AXI_ARADDR_0, M_AXI_ARVALID_0, M_AXI_RREADY_0, M_AXI_BREADY_0} <= 0;
            {M_AXI_AWADDR_1, M_AXI_WDATA_1, M_AXI_WSTRB_1, M_AXI_AWVALID_1, M_AXI_WVALID_1, 
             M_AXI_ARADDR_1, M_AXI_ARVALID_1, M_AXI_RREADY_1, M_AXI_BREADY_1} <= 0;
            {M_AXI_AWADDR_2, M_AXI_WDATA_2, M_AXI_WSTRB_2, M_AXI_AWVALID_2, M_AXI_WVALID_2, 
             M_AXI_ARADDR_2, M_AXI_ARVALID_2, M_AXI_RREADY_2, M_AXI_BREADY_2} <= 0;
        end else begin
            // 根据传入地址选择从机
            if (M_AXI_AWVALID || M_AXI_ARVALID) begin
                if (M_AXI_AWADDR >= SLAVE0_ADDR_BASE && M_AXI_AWADDR < SLAVE1_ADDR_BASE) begin
                    // 从机 0
                    M_AXI_AWADDR_0 <= M_AXI_AWADDR;
                    M_AXI_AWVALID_0 <= M_AXI_AWVALID;
                    M_AXI_WDATA_0 <= M_AXI_WDATA;
                    M_AXI_WSTRB_0 <= M_AXI_WSTRB;
                    M_AXI_WVALID_0 <= M_AXI_WVALID;
                    M_AXI_ARADDR_0 <= M_AXI_ARADDR;
                    M_AXI_ARVALID_0 <= M_AXI_ARVALID;
                    M_AXI_RREADY_0 <= M_AXI_RREADY;
                    M_AXI_BREADY_0 <= M_AXI_BREADY;
                end else if (M_AXI_AWADDR >= SLAVE1_ADDR_BASE && M_AXI_AWADDR < SLAVE2_ADDR_BASE) begin
                    // 从机 1
                    M_AXI_AWADDR_1 <= M_AXI_AWADDR;
                    M_AXI_AWVALID_1 <= M_AXI_AWVALID;
                    M_AXI_WDATA_1 <= M_AXI_WDATA;
                    M_AXI_WSTRB_1 <= M_AXI_WSTRB;
                    M_AXI_WVALID_1 <= M_AXI_WVALID;
                    M_AXI_ARADDR_1 <= M_AXI_ARADDR;
                    M_AXI_ARVALID_1 <= M_AXI_ARVALID;
                    M_AXI_RREADY_1 <= M_AXI_RREADY;
                    M_AXI_BREADY_1 <= M_AXI_BREADY;
                end else if (M_AXI_AWADDR >= SLAVE2_ADDR_BASE) begin
                    // 从机 2
                    M_AXI_AWADDR_2 <= M_AXI_AWADDR;
                    M_AXI_AWVALID_2 <= M_AXI_AWVALID;
                    M_AXI_WDATA_2 <= M_AXI_WDATA;
                    M_AXI_WSTRB_2 <= M_AXI_WSTRB;
                    M_AXI_WVALID_2 <= M_AXI_WVALID;
                    M_AXI_ARADDR_2 <= M_AXI_ARADDR;
                    M_AXI_ARVALID_2 <= M_AXI_ARVALID;
                    M_AXI_RREADY_2 <= M_AXI_RREADY;
                    M_AXI_BREADY_2 <= M_AXI_BREADY;
                end
            end
        end
    end

    // 总线互连的 AXI 响应信号处理
    assign M_AXI_AWREADY = (M_AXI_AWADDR >= SLAVE0_ADDR_BASE && M_AXI_AWADDR < SLAVE1_ADDR_BASE) ? M_AXI_AWREADY_0 :
                           (M_AXI_AWADDR >= SLAVE1_ADDR_BASE && M_AXI_AWADDR < SLAVE2_ADDR_BASE) ? M_AXI_AWREADY_1 : M_AXI_AWREADY_2;

    assign M_AXI_WREADY = (M_AXI_AWADDR >= SLAVE0_ADDR_BASE && M_AXI_AWADDR < SLAVE1_ADDR_BASE) ? M_AXI_WREADY_0 :
                           (M_AXI_AWADDR >= SLAVE1_ADDR_BASE && M_AXI_AWADDR < SLAVE2_ADDR_BASE) ? M_AXI_WREADY_1 : M_AXI_WREADY_2;

    assign M_AXI_RDATA = (M_AXI_ARADDR >= SLAVE0_ADDR_BASE && M_AXI_ARADDR < SLAVE1_ADDR_BASE) ? M_AXI_RDATA_0 :
                         (M_AXI_ARADDR >= SLAVE1_ADDR_BASE && M_AXI_ARADDR < SLAVE2_ADDR_BASE) ? M_AXI_RDATA_1 : M_AXI_RDATA_2;

    assign M_AXI_RVALID = (M_AXI_ARADDR >= SLAVE0_ADDR_BASE && M_AXI_ARADDR < SLAVE1_ADDR_BASE) ? M_AXI_RVALID_0 :
                          (M_AXI_ARADDR >= SLAVE1_ADDR_BASE && M_AXI_ARADDR < SLAVE2_ADDR_BASE) ? M_AXI_RVALID_1 : M_AXI_RVALID_2;

    assign M_AXI_BVALID = (M_AXI_AWADDR >= SLAVE0_ADDR_BASE && M_AXI_AWADDR < SLAVE1_ADDR_BASE) ? M_AXI_BVALID_0 :
                          (M_AXI_AWADDR >= SLAVE1_ADDR_BASE && M_AXI_AWADDR < SLAVE2_ADDR_BASE) ? M_AXI_BVALID_1 : M_AXI_BVALID_2;


wire [2:0] M_AXI_AWPROT;
wire [2:0] M_AXI_ARPROT;
wire [1:0] M_AXI_RRESP;
wire [1:0] M_AXI_BRESP;


assign M_AXI_AWPROT = 3'b000;
assign M_AXI_ARPROT = 3'b000;

assign M_AXI_AWPROT_0 = M_AXI_AWPROT;
assign M_AXI_AWPROT_1 = M_AXI_AWPROT;
assign M_AXI_AWPROT_2 = M_AXI_AWPROT;
assign M_AXI_ARPROT_0 = M_AXI_ARPROT;
assign M_AXI_ARPROT_1 = M_AXI_ARPROT;
assign M_AXI_ARPROT_2 = M_AXI_ARPROT;
assign M_AXI_RRESP = (M_AXI_RRESP_0 | M_AXI_RRESP_1 | M_AXI_RRESP_2);
assign M_AXI_BRESP = (M_AXI_BRESP_0 | M_AXI_BRESP_1 | M_AXI_BRESP_2);

reg write_error_flag;
reg read_error_flag;

always @(posedge clk) begin
if (rst == `RstEnable) begin 
    // 初始化错误标志寄存器
    write_error_flag <= 1'b0;
    read_error_flag <= 1'b0;
end else begin
    // 检测写响应错误
    if (M_AXI_BVALID && M_AXI_BREADY) begin
        if (M_AXI_BRESP != 2'b00) begin
            write_error_flag <= 1'b1; // 设置写错误标志
        end else begin
            write_error_flag <= 1'b0; // 清除写错误标志
        end
    end

    // 检测读响应错误
    if (M_AXI_RVALID && M_AXI_RREADY) begin
        if (M_AXI_RRESP != 2'b00) begin
            read_error_flag <= 1'b1; // 设置读错误标志
        end else begin
            read_error_flag <= 1'b0; // 清除读错误标志
        end
    end
end
end

endmodule
