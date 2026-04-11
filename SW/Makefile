# 工具链前缀
CROSS = mips-linux-gnu-
CC    = $(CROSS)gcc
LD    = $(CROSS)ld
OBJCOPY = $(CROSS)objcopy
OBJDUMP = $(CROSS)objdump

# 编译选项 (大端模式)
CFLAGS  = -mips32r2 -EB -O2 -Wall -nostdlib -ffreestanding -I. -fno-pic -mno-abicalls
LDFLAGS = -EB -T linker.ld

# 输出目录
OBJDIR = obj

# # 源文件
# SRCS   = start.S main.c
# OBJS   = $(addprefix $(OBJDIR)/, $(SRCS:.c=.o))
# OBJS  := $(OBJS:.S=.o)
# 源文件
SRCS   = cpu_selftest.S
OBJS   = $(addprefix $(OBJDIR)/, $(SRCS:.S=.o))


# 最终目标文件名 (放在 obj 目录下)
TARGET = $(OBJDIR)/program

# 默认目标
all: $(TARGET).elf $(TARGET).hex $(TARGET).mem $(TARGET).dis

# 创建 obj 目录
$(OBJDIR):
	mkdir -p $(OBJDIR)

# 编译汇编文件
$(OBJDIR)/%.o: %.S | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# 编译 C 文件
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# 链接生成 ELF
$(TARGET).elf: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

# 生成反汇编文件 (同时保存到 obj 目录)
$(TARGET).dis: $(TARGET).elf
	$(OBJDUMP) -D $< > $@

# 生成二进制文件
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# 生成 Verilog $readmemh 格式的 hex 文件（保持原始字节顺序）
$(TARGET).hex: $(TARGET).bin
	perl -e 'while(read(STDIN,$$buf,4)){print unpack("H8",$$buf)."\n"}' < $< > $@

# 生成 Verilog $readmemb 格式的 mem 文件 (使用 perl 解决二进制输出)
$(TARGET).mem: $(TARGET).bin
	perl -ne 'print unpack("B32", pack("N", unpack("N", $$_))) . "\n"' $< > $@

# 清理
clean:
	rm -rf $(OBJDIR)
	mkdir -p $(OBJDIR)

.PHONY: all clean
