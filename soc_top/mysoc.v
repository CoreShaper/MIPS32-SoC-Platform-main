`include "mydefines.v"
`timescale 1ns/1ps
module mysoc (
    input  wire         clk,
    input  wire         rst,
    output wire         cpu_test,
    inout  wire         GPIO01,
    output wire [31:0] perf_hit_cnt,
    output wire [31:0] perf_miss_cnt,
    output wire [31:0] perf_stall_cnt,
    output wire [31:0] perf_cycle_cnt
);

    // ============================================================
    // 中断信号（仅连接定时器中断）
    // ============================================================
    wire [5:0] Inter;
    wire       timer_int_o;
    assign Inter = {5'b0, timer_int_o};

    // ============================================================
    // CPU 与存储器的连接信号
    // ============================================================
    wire                  inst_ce;
    wire [`InstAddrBus]   inst_addr;
    wire [`InstBus]       inst_data;
    wire                  inst_stallreq;      // 固定为 0

    wire                  data_ce;
    wire [`DataAddrBus]   data_addr;
    wire                  data_we;
    wire [3:0]            data_sel;
    wire [`DataBus]       data_wdata;
    wire [`DataBus]       data_rdata;
    wire                  data_stallreq;      // 固定为 0
    wire rst_n_sync; // 同步复位信号

    //assign inst_stallreq = 1'b0;
    assign data_stallreq = 1'b0;
reset_sync reset_sync1(
    .clk(clk),             // 时钟
    .rst_n_async(!rst),    // 外部异步复位，低有效
    .rst_n_sync(rst_n_sync)      // 同步释放后的复位信号，低有效
);
    // ============================================================
    // 实例化 openmips CPU
    // ============================================================
    openmips openmips0 (
        .clk              (clk),
        .rst              (!rst_n_sync),
        .int_i            (Inter),
        .timer_int_o      (timer_int_o),
        .cpu_test         (cpu_test),

        // 指令接口
        .inst_ce_o        (inst_ce),
        .inst_addr_o      (inst_addr),
        .inst_data_i      (inst_data),
        .inst_stallreq_i  (inst_stallreq),

        // 数据接口
        .data_ce_o        (data_ce),
        .data_addr_o      (data_addr),
        .data_we_o        (data_we),
        .data_sel_o       (data_sel),
        .data_wdata_o     (data_wdata),      // 注意信号名匹配
        .data_rdata_i     (data_rdata),
        .data_stallreq_i  (data_stallreq)
    );

    // ============================================================
    // 地址译码与仿真控制寄存器
    // ============================================================
    reg  [31:0] sim_ctrl_reg;
    reg  [31:0] sim_dbg_out; // 可选：第二个仿真控制寄存器
    wire        is_sim_ctrl_addr;

    assign is_sim_ctrl_addr = ((data_addr == 32'hFFFFFFF0) | (data_addr == 32'hFFFFFFE0)) && data_ce;

    // 写操作（异步复位，同步写）
    always @(posedge clk) begin
        if (!rst_n_sync == `RstEnable) begin
            sim_ctrl_reg <= 32'h0;
            sim_dbg_out <= 32'h0; // 可选：第二个仿真控制寄存器
        end else if (data_ce && data_we && is_sim_ctrl_addr) begin
                    if (data_addr == 32'hFFFFFFF0) begin
                        sim_ctrl_reg <= data_wdata;      // 使用 data_wdata 而非 data_data_o
                    end else if (data_addr == 32'hFFFFFFE0) begin
                        sim_dbg_out <= data_wdata;      // 可选：第二个仿真控制寄存器
                    end
        end
    end

    // 读操作：返回寄存器值（可根据需要改为返回 0）
     assign data_rdata = is_sim_ctrl_addr ? (data_addr == 32'hFFFFFFF0 ? sim_ctrl_reg : sim_dbg_out) : dbus_rdata; // 可选：返回寄存器值


wire ram_inst_ce;
wire [31:0] ram_inst_addr;
wire [31:0] ram_inst_rdata;
icache_top i_cache(
    .clk(clk),
    .rst_sync(!rst_n_sync),

    
    .cpu_inst_ce(inst_ce),
    .cpu_inst_addr(inst_addr),
    .cpu_inst_data(inst_data),
    .cpu_inst_stall(inst_stallreq),

    
    .ram_inst_ce(ram_inst_ce),
    .ram_inst_addr(ram_inst_addr),
    .ram_inst_rdata(ram_inst_rdata),

    .icache_en(1'b1),
    .perf_hit_cnt(perf_hit_cnt),
    .perf_miss_cnt(perf_miss_cnt),
    .perf_stall_cnt(perf_stall_cnt),
    .perf_cycle_cnt(perf_cycle_cnt)
);
    // ============================================================
    // 双口 RAM 接口信号（屏蔽仿真控制寄存器地址）
    // ============================================================
    wire        dbus_ce;
    wire        dbus_we;
    wire [3:0]  dbus_sel;
    wire [31:0] dbus_addr;
    wire [31:0] dbus_wdata;
    wire [31:0] dbus_rdata;

    assign dbus_ce    = data_ce && !is_sim_ctrl_addr;
    assign dbus_we    = data_we && !is_sim_ctrl_addr;
    assign dbus_sel   = data_sel;
    assign dbus_addr  = data_addr;
    assign dbus_wdata = data_wdata;           // 使用 data_wdata

    // ============================================================
    // 双口 RAM 实例化
    // ============================================================
    dual_port_ram #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .MEM_DEPTH(16384),
        .I_LATENCY(4) // 指令端口 1 周期读延迟
    ) u_ram (
        .clk      (clk),

        // 指令端口
        .i_ce     (ram_inst_ce),
        .i_addr   (ram_inst_addr),
        .i_rdata  (ram_inst_rdata),

        // 数据端口
        .d_ce     (dbus_ce),
        .d_we     (dbus_we),
        .d_sel    (dbus_sel),
        .d_addr   (dbus_addr),
        .d_wdata  (dbus_wdata),
        .d_rdata  (dbus_rdata)
    );

    // ============================================================
    // GPIO 示例
    // ============================================================
    assign GPIO01 = 1'b0;

endmodule

