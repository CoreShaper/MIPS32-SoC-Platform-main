// ===================================================================
// 模块名 : icache_top
// 描述   : openmips 指令 Cache (512B, 直接映射, 整行 refill, 无 AXI)
//          修正旁路延迟问题：旁路时 RAM 接口直通，无寄存器打拍
// 版本   : v1.1
// 日期   : 2026-05-02
// ===================================================================
`timescale 1ns / 1ps

module icache_top #(
    parameter LINE_NUM      = 16,
    parameter WORD_PER_LINE = 8,
    parameter INDEX_BITS    = 4,
    parameter OFFSET_BITS   = 3,
    parameter TAG_BITS      = 32 - INDEX_BITS - OFFSET_BITS - 2
) (
    input  wire        clk,
    input  wire        rst_sync,

    // CPU 侧
    input  wire        cpu_inst_ce,
    input  wire [31:0] cpu_inst_addr,
    output wire [31:0] cpu_inst_data,
    output wire        cpu_inst_stall,

    // RAM 侧
    output wire        ram_inst_ce,
    output wire [31:0] ram_inst_addr,
    input  wire [31:0] ram_inst_rdata,

    input  wire        icache_en
);

    // ---- 地址拆分 ----
    wire [INDEX_BITS-1:0]   req_index       = cpu_inst_addr[OFFSET_BITS+INDEX_BITS+1 : OFFSET_BITS+2];
    wire [TAG_BITS-1:0]     req_tag         = cpu_inst_addr[31 : OFFSET_BITS+INDEX_BITS+2];
    wire [OFFSET_BITS-1:0]  req_word_offset = cpu_inst_addr[OFFSET_BITS+1 : 2];

    // ---- 存储体 ----
    reg [TAG_BITS-1:0] tag_array   [0:LINE_NUM-1];
    reg [31:0]         data_array  [0:LINE_NUM-1][0:WORD_PER_LINE-1];
    reg [LINE_NUM-1:0] valid_array;

    integer i, j;
    always @(posedge clk) begin
        if (rst_sync) begin
            for (i = 0; i < LINE_NUM; i = i + 1) begin
                valid_array[i] <= 1'b0;
                tag_array[i]   <= {TAG_BITS{1'b0}};
                for (j = 0; j < WORD_PER_LINE; j = j + 1) begin
                    data_array[i][j] <= 32'b0;
                end
            end
        end
    end

    // ---- 命中判断 ----
    wire line_valid = valid_array[req_index];
    wire tag_match  = (tag_array[req_index] == req_tag);
    wire hit        = line_valid && tag_match && icache_en;

    // ---- 状态机 ----
    localparam IDLE   = 1'b0;
    localparam REFILL = 1'b1;
    reg state, next_state;

    reg [3:0] send_cnt;
    reg [3:0] wr_cnt;
    reg [31:0] refill_base_addr;
    reg [TAG_BITS-1:0] refill_tag;
    reg [INDEX_BITS-1:0] refill_index;

    wire miss_req = cpu_inst_ce && icache_en && !hit && (state == IDLE);

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (miss_req) next_state = REFILL;
            REFILL: if (wr_cnt == 4'd8 && ram_ce_d1) next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst_sync) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 计数器与锁存
    always @(posedge clk) begin
        if (rst_sync) begin
            send_cnt         <= 4'd0;
            wr_cnt           <= 4'd0;
            refill_base_addr <= 32'd0;
            refill_tag       <= {TAG_BITS{1'b0}};
            refill_index     <= {INDEX_BITS{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    if (miss_req) begin
                        send_cnt         <= 4'd0;
                        wr_cnt           <= 4'd0;
                        refill_base_addr <= {req_tag, req_index, {OFFSET_BITS+2{1'b0}}};
                        refill_tag       <= req_tag;
                        refill_index     <= req_index;
                    end
                end

                REFILL: begin
                    if (ram_inst_ce && send_cnt != 4'd8)
                        send_cnt <= send_cnt + 1'b1;

                    if (ram_ce_d1)
                        wr_cnt <= wr_cnt + 1'b1;

                    if (wr_cnt == 4'd8 && ram_ce_d1) begin
                        send_cnt <= 4'd0;
                        wr_cnt   <= 4'd0;
                    end
                end
            endcase
        end
    end

    // ---- RAM 接口（关键修正） ----
    // 旁路模式：直接组合输出，不经过寄存器，消除额外延迟
    // 缓存模式：使用寄存器输出，保证时序干净
    wire ram_ce_req_cache;
    assign ram_ce_req_cache = (state == REFILL && send_cnt < 4'd8);

    reg ram_ce_reg;
    reg [31:0] ram_addr_reg;
    always @(posedge clk) begin
        if (rst_sync) begin
            ram_ce_reg   <= 1'b0;
            ram_addr_reg <= 32'd0;
        end else begin
            if (ram_ce_req_cache) begin
                ram_ce_reg <= 1'b1;
                // 使用拼接代替移位，避免宽度警告
                ram_addr_reg <= refill_base_addr + { {27{1'b0}}, send_cnt, 2'b00 };
            end else begin
                ram_ce_reg <= 1'b0;
            end
        end
    end

    // 最终输出：根据模式选择直通或寄存器
    assign ram_inst_ce   = (!icache_en) ? cpu_inst_ce   : ram_ce_reg;
    assign ram_inst_addr = (!icache_en) ? cpu_inst_addr : ram_addr_reg;

    // 流水线延迟标记（仅用于缓存填写的写回操作，旁路时置 0 避免误触发）
    reg ram_ce_d1;
    always @(posedge clk) begin
        if (rst_sync)
            ram_ce_d1 <= 1'b0;
        else
            ram_ce_d1 <= icache_en ? ram_inst_ce : 1'b0;
    end

    // ---- 写 Data 阵列与更新 Tag / Valid ----
    always @(posedge clk) begin
        if (ram_ce_d1 && state == REFILL) begin
            data_array[refill_index][wr_cnt] <= ram_inst_rdata;
        end
    end

    always @(posedge clk) begin
        if (rst_sync) begin
        end else if (ram_ce_d1 && state == REFILL && wr_cnt == 4'd8) begin
            valid_array[refill_index] <= 1'b1;
            tag_array[refill_index]   <= refill_tag;
        end
    end

    // ---- 数据输出 ----
    wire [31:0] hit_data = hit ? data_array[req_index][req_word_offset] : 32'd0;
    wire        refill_last_word = (state == REFILL) && ram_ce_d1 && (wr_cnt == 4'd8);

    assign cpu_inst_data = refill_last_word ? ram_inst_rdata :
                           (!icache_en)       ? ram_inst_rdata :
                                                hit_data;

    // ---- Stall ----
    assign cpu_inst_stall = (!icache_en) ? 1'b0 :
                            (hit && state == IDLE) ? 1'b0 :
                            1'b1;

endmodule