`include "mydefines.v"

module mydata_ram (
    input  wire                   clk,
    input  wire                   rst,

    // AXI写地址通道
    input  wire[31:0]             M_AXI_AWADDR,
    input  wire                   M_AXI_AWVALID,
    output reg                    M_AXI_AWREADY,

    // AXI写数据通道
    input  wire[31:0]             M_AXI_WDATA,
    input  wire[3:0]              M_AXI_WSTRB,
    input  wire                   M_AXI_WVALID,
    output reg                    M_AXI_WREADY,

    // AXI写响应通道
    output reg                    M_AXI_BVALID,
    input  wire                   M_AXI_BREADY,

    // AXI读地址通道
    input  wire[31:0]             M_AXI_ARADDR,
    input  wire                   M_AXI_ARVALID,
    output reg                    M_AXI_ARREADY,

    // AXI读数据通道
    output reg[31:0]              M_AXI_RDATA,
    output reg                    M_AXI_RVALID,
    input  wire                   M_AXI_RREADY,

    // Stall 信号
    output reg                    stallreq
);

    reg[`ByteWidth] data_mem0[0:4096-1];
    reg[`ByteWidth] data_mem1[0:4096-1];
    reg[`ByteWidth] data_mem2[0:4096-1];
    reg[`ByteWidth] data_mem3[0:4096-1];

    wire [`DataMemNumLog2-1:0] addr_index;
    assign addr_index = M_AXI_AWVALID ? M_AXI_AWADDR[`DataMemNumLog2+1:2] : M_AXI_ARADDR[`DataMemNumLog2+1:2];

    reg [1:0] axi_state;
    localparam AXI_IDLE       = 2'b00,
               AXI_WRITE      = 2'b01,
               AXI_WRITE_RESP = 2'b10,
               AXI_READ       = 2'b11;

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            axi_state <= AXI_IDLE;
            {M_AXI_AWREADY, M_AXI_WREADY, M_AXI_BVALID,
             M_AXI_ARREADY, M_AXI_RVALID} <= 0;
            M_AXI_RDATA <= 32'b0;
            stallreq <= `NoStop;
        end else begin
            case (axi_state)
                AXI_IDLE: begin
                    stallreq <= `NoStop;

                    if (M_AXI_AWVALID && M_AXI_WVALID) begin
                        M_AXI_AWREADY <= 1;
                        M_AXI_WREADY  <= 1;
                        axi_state <= AXI_WRITE;
                        stallreq <= `Stop;  // 阻塞流水线直到完成写
                    end else if (M_AXI_ARVALID) begin
                        M_AXI_ARREADY <= 1;
                        axi_state <= AXI_READ;
                        stallreq <= `Stop;  // 阻塞流水线直到完成读
                    end
                end

                AXI_WRITE: begin
                    if (M_AXI_AWREADY && M_AXI_WREADY) begin
                        // 写数据
                        if (M_AXI_WSTRB[3]) data_mem3[addr_index] <= M_AXI_WDATA[31:24];
                        if (M_AXI_WSTRB[2]) data_mem2[addr_index] <= M_AXI_WDATA[23:16];
                        if (M_AXI_WSTRB[1]) data_mem1[addr_index] <= M_AXI_WDATA[15:8];
                        if (M_AXI_WSTRB[0]) data_mem0[addr_index] <= M_AXI_WDATA[7:0];

                        M_AXI_AWREADY <= 0;
                        M_AXI_WREADY  <= 0;
                        M_AXI_BVALID  <= 1;  // 响应写完成
                        axi_state <= AXI_WRITE_RESP;
                    end
                end

                AXI_WRITE_RESP: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        M_AXI_BVALID <= 0;
                        stallreq <= `NoStop;
                        axi_state <= AXI_IDLE;
                    end
                end

                AXI_READ: begin
                    if (M_AXI_ARREADY) begin
                        M_AXI_RDATA <= {
                            data_mem3[addr_index],
                            data_mem2[addr_index],
                            data_mem1[addr_index],
                            data_mem0[addr_index]
                        };
                        M_AXI_ARREADY <= 0;
                        M_AXI_RVALID  <= 1;
                    end

                    if (M_AXI_RVALID && M_AXI_RREADY) begin
                        M_AXI_RVALID <= 0;
                        stallreq <= `NoStop;
                        axi_state <= AXI_IDLE;
                    end
                end

                default: axi_state <= AXI_IDLE;
            endcase
        end
    end

endmodule
