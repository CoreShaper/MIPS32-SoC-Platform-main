# ============================================================================
# module_bench/Makefile - I-Cache 模块级独立仿真
# 用法：
#   make          - 编译并运行仿真
#   make compile  - 仅编译
#   make run      - 仅运行
#   make wave     - 打开波形
#   make clean    - 清理生成文件
#   make lint     - Verilator lint 检查
#   make check    - Icarus 快速语法检查
# ============================================================================

IVL      = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

# ---------- 模块配置（根据实际模块修改） ----------
TOP_MODULE = module_bench          # Testbench 顶层模块名
LINT_TOP   = icache_top         # 纯 RTL 顶层（供 lint 用）

# RTL 源文件（相对于当前 Makefile 目录）
RTL_FILES = ../../soc_top/cache/icache_top.v

# Testbench 源文件（放在当前目录下）
TB_FILES  = module_bench.v

# ---------- 固定配置 ----------
SIM_EXE   = simv
WAVE      = wave.vcd
LINT_LOG  = lint.log

# 所有源文件
SRCS      = $(RTL_FILES) $(TB_FILES)

# Include 路径（如果 icache_top.v 有 `include 宏，按需添加）
# 这里暂时留空，因为该模块无外部包含需求
INC_ICARUS   =
INC_VERILATOR =

.PHONY: all compile run wave clean lint check

# 默认目标：编译 + 运行
all: run

# 编译
compile: $(SIM_EXE)

$(SIM_EXE): $(SRCS)
	@echo "[IVL] Compiling $(TOP_MODULE)..."
	$(IVL) -g2012 -Wall -o $@ -s $(TOP_MODULE) $(INC_ICARUS) $(SRCS)

# 运行仿真
run: $(SIM_EXE)
	@echo "[VVP] Running simulation..."
	$(VVP) $(SIM_EXE)

# 波形查看
wave:
	@if [ -f $(WAVE) ]; then \
		$(GTKWAVE) $(WAVE) & \
	else \
		echo "No waveform file $(WAVE) found. Run simulation first."; \
	fi

# 清理
clean:
	rm -f $(SIM_EXE) $(WAVE) $(LINT_LOG)

# Verilator lint 检查
lint:
	@echo "=== Verilator lint on $(LINT_TOP) ===" | tee $(LINT_LOG)
	verilator --lint-only -Wall --top-module $(LINT_TOP) \
	          $(INC_VERILATOR) $(SRCS) 2>&1 | tee -a $(LINT_LOG)
	@echo "=== Lint completed ===" | tee -a $(LINT_LOG)

# Icarus 轻量语法检查
check:
	@echo "=== Icarus syntax check ==="
	$(IVL) -g2012 -Wall -o /dev/null $(INC_ICARUS) $(SRCS)
	@echo "=== Syntax check passed ==="