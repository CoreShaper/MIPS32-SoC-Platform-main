`include "defines.v"

module axi_bus_if(
  input  wire         clk,
  input  wire         rst,

  // stall control
  input  wire [5:0]   stall_i,
  input  wire         flush_i,

  // CPU侧接口（保持不变）
  input  wire         cpu_ce_i,
  input  wire [`RegBus] cpu_data_i,
  input  wire [`RegBus] cpu_addr_i,
  input  wire         cpu_we_i,
  input  wire [3:0]   cpu_sel_i,
  output reg  [`RegBus] cpu_data_o,

// AXI-Lite 主机接口信号定义
// 写地址通道 (Write Address Channel)
// M_AXI_AWADDR  : 写地址信号，表示主机发出的写操作地址。
// M_AXI_AWVALID : 写地址有效信号，表示写地址有效。
// M_AXI_AWREADY : 写地址准备信号，表示从机已准备好接收写地址。
// M_AXI_AWPROT  : 写地址保护信号，表示写操作的保护级别。
  output reg  [31:0]  M_AXI_AWADDR,
  output reg          M_AXI_AWVALID,
  input  wire         M_AXI_AWREADY,
 // output wire [2:0]    M_AXI_AWPROT,
// 写数据通道 (Write Data Channel)
// M_AXI_WDATA   : 写数据信号，表示主机发出的写操作数据。
// M_AXI_WSTRB   : 写数据字节选通信号，表示哪些字节有效。
// M_AXI_WVALID  : 写数据有效信号，表示写数据有效。
// M_AXI_WREADY  : 写数据准备信号，表示从机已准备好接收写数据。
  output reg  [31:0]  M_AXI_WDATA,
  output reg  [3:0]   M_AXI_WSTRB,
  output reg          M_AXI_WVALID,
  input  wire         M_AXI_WREADY,
// 读地址通道 (Read Address Channel)
// M_AXI_ARADDR  : 读地址信号，表示主机发出的读操作地址。
// M_AXI_ARVALID : 读地址有效信号，表示读地址有效。
// M_AXI_ARREADY : 读地址准备信号，表示从机已准备好接收读地址。
//M_AXI_ARPROT:  : 读地址保护信号，表示读操作的保护级别。
  output reg  [31:0]  M_AXI_ARADDR,
  output reg          M_AXI_ARVALID,
  input  wire         M_AXI_ARREADY,
 // output wire [2:0]   M_AXI_ARPROT,
// 读数据通道 (Read Data Channel)
// M_AXI_RDATA   : 读数据信号，表示从机返回的读操作数据。
// M_AXI_RVALID  : 读数据有效信号，表示读数据有效。
// M_AXI_RREADY  : 读数据准备信号，表示主机已准备好接收读数据。
// M_AXI_RRESP   : 读数据响应信号，表示读操作的响应状态。
  input  wire [31:0]  M_AXI_RDATA,
  input  wire         M_AXI_RVALID,
  output reg          M_AXI_RREADY,
 // input wire [1:0]    M_AXI_RRESP,
// 写响应通道 (Write Response Channel)
// M_AXI_BVALID  : 写响应有效信号，表示写响应有效。
// M_AXI_BREADY  : 写响应准备信号，表示主机已准备好接收写响应。
// M_AXI_BRESP   : 写响应信号，表示写操作的响应状态。
  input  wire         M_AXI_BVALID,
  output reg          M_AXI_BREADY,
 // input wire [1:0]    M_AXI_BRESP,

  output reg          stallreq
);

  reg [1:0] axi_state;
  reg [`RegBus] rd_buf;

  localparam AXI_IDLE            = 2'b00,
             AXI_WRITE_ADDR      = 2'b01,
             AXI_READ_ADDR       = 2'b10,
             AXI_WAIT_FOR_STALL  = 2'b11;

  always @(posedge clk) begin
    if (rst == `RstEnable) begin
      axi_state <= AXI_IDLE;
      {M_AXI_AWVALID, M_AXI_WVALID, M_AXI_ARVALID, M_AXI_RREADY, M_AXI_BREADY} <= 0;
      {M_AXI_AWADDR, M_AXI_WDATA, M_AXI_WSTRB, M_AXI_ARADDR} <= 0;
      rd_buf <= 0;
    end else begin
      case (axi_state)
        AXI_IDLE: begin
          if (cpu_ce_i && !flush_i) begin
            if (cpu_we_i) begin // write
              M_AXI_AWADDR <= {cpu_addr_i[31:2], 2'b00};    // 地址对齐为 word（32bit）
              M_AXI_AWVALID <= 1;
              M_AXI_WDATA <= cpu_data_i;
              M_AXI_WSTRB <= cpu_sel_i;
              M_AXI_WVALID <= 1;
              axi_state <= AXI_WRITE_ADDR;
            end else begin // read
              M_AXI_ARADDR <= {cpu_addr_i[31:2], 2'b00};
              M_AXI_ARVALID <= 1;
              axi_state <= AXI_READ_ADDR;
            end
          end
        end

        AXI_WRITE_ADDR: begin
          if (M_AXI_AWREADY && M_AXI_WREADY) begin
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_BREADY <= 1;
          end
          if (M_AXI_BVALID) begin
            M_AXI_BREADY <= 0;
            axi_state <= (stall_i != 6'b0) ? AXI_WAIT_FOR_STALL : AXI_IDLE;
          end
        end

        AXI_READ_ADDR: begin
          if (M_AXI_ARREADY) begin
            M_AXI_ARVALID <= 0;
            M_AXI_RREADY <= 1;
          end
          if (M_AXI_RVALID) begin
            M_AXI_RREADY <= 0;
            rd_buf <= M_AXI_RDATA;
            axi_state <= (stall_i != 6'b0) ? AXI_WAIT_FOR_STALL : AXI_IDLE;
          end
        end

        AXI_WAIT_FOR_STALL: begin
          if (stall_i == 6'b0) begin
            axi_state <= AXI_IDLE;
          end
        end

        default: axi_state <= AXI_IDLE;
      endcase
    end
  end

  // output control logic
  always @(*) begin
    if (rst == `RstEnable) begin
      stallreq = `NoStop;
      cpu_data_o = `ZeroWord;
    end else begin
        stallreq = `NoStop;
      case (axi_state)
        AXI_IDLE: begin
          if (cpu_ce_i && !flush_i)
            stallreq = `Stop;
        end
        AXI_WRITE_ADDR, AXI_READ_ADDR: begin
          stallreq = `Stop;
        end
        AXI_WAIT_FOR_STALL: begin
          cpu_data_o = rd_buf;

        end
      endcase
    end
  end

// assign M_AXI_AWPROT = 3'b000;
// assign M_AXI_ARPROT = 3'b000;

// reg write_error_flag;
// reg read_error_flag;

// always @(posedge clk) begin
// if (rst == `RstEnable) begin 
//     // 初始化错误标志寄存器
//     write_error_flag <= 1'b0;
//     read_error_flag <= 1'b0;
// end else begin
//     // 检测写响应错误
//     if (M_AXI_BVALID && M_AXI_BREADY) begin
//         if (M_AXI_BRESP != 2'b00) begin
//             write_error_flag <= 1'b1; // 设置写错误标志
//         end else begin
//             write_error_flag <= 1'b0; // 清除写错误标志
//         end
//     end

//     // 检测读响应错误
//     if (M_AXI_RVALID && M_AXI_RREADY) begin
//         if (M_AXI_RRESP != 2'b00) begin
//             read_error_flag <= 1'b1; // 设置读错误标志
//         end else begin
//             read_error_flag <= 1'b0; // 清除读错误标志
//         end
//     end
// end
// end


endmodule
