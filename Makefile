# 仿真 Makefile
# 使用方法：make -f Makefile.sim [compile|run|wave|clean]

IVL = iverilog
VVP = vvp
GTKWAVE = gtkwave

# 目录定义
RTL_DIR = soc_top
MIPS_DIR = soc_top/mips
TB_DIR = test_bench

# Include 路径
INC = -I $(MIPS_DIR) -I $(RTL_DIR)

# 顶层模块名
TOP_MODULE = myopenmips_min_sopc_tb

# 输出可执行文件名
SIM_EXE = simv

# 波形文件
WAVE = waveform.vcd

# 文件列表
FILELIST = filelist.f

# 所有源文件（从 filelist.f 读取 + testbench）
SRCS = $(shell cat $(FILELIST)) $(TB_DIR)/myopenmips_min_sopc_tb.v

# 默认目标：编译并运行
all: run

# 编译
compile: $(SIM_EXE)

$(SIM_EXE): $(SRCS)
	$(IVL) -o $@ -s $(TOP_MODULE) $(INC) $(SRCS)

# 运行仿真
run: $(SIM_EXE)
	$(VVP) $(SIM_EXE)

# 查看波形
wave: $(WAVE)
	$(GTKWAVE) $(WAVE) &

# 清理
clean:
	rm -f $(SIM_EXE) $(WAVE)

# 完全重新编译
rebuild: clean compile

# 显示源文件列表（调试用）
show_srcs:
	@echo "Source files:"
	@echo "$(SRCS)" | tr ' ' '\n'

.PHONY: all compile run wave clean rebuild show_srcs
