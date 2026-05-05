# SW/Makefile
CROSS = mips-linux-gnu-
CC    = $(CROSS)gcc
LD    = $(CROSS)ld
OBJCOPY = $(CROSS)objcopy
OBJDUMP = $(CROSS)objdump

CFLAGS = -march=mips32 -EB -O2 -Wall -nostdlib -ffreestanding -I. -fno-pic -mno-abicalls -G0
LDFLAGS = -EB -T linker.ld

OBJDIR = obj
TARGET = $(OBJDIR)/program

# 自动收集所有 .c 和 .S 文件，并去掉开头的 ./
C_SRCS   := $(shell find . -name "*.c" -not -path "./$(OBJDIR)/*" | sed 's|^\./||')
ASM_SRCS := $(shell find . -name "*.S" -not -path "./$(OBJDIR)/*" -not -name "*cpu_selftest*" | sed 's|^\./||')

# 转换为 obj 目录下的 .o 文件
C_OBJS   := $(patsubst %.c, $(OBJDIR)/%.o, $(C_SRCS))
ASM_OBJS := $(patsubst %.S, $(OBJDIR)/%.o, $(ASM_SRCS))
OBJS     := $(C_OBJS) $(ASM_OBJS)

# 默认目标
all: $(TARGET).elf $(TARGET).hex $(TARGET).dis selftest

# 创建 obj 目录
$(OBJDIR):
	mkdir -p $(OBJDIR)

# 编译 C 文件
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# 编译汇编文件
$(OBJDIR)/%.o: %.S | $(OBJDIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# 链接
$(TARGET).elf: $(OBJS) linker.ld
	$(LD) $(LDFLAGS) $(OBJS) -o $@
	$(OBJDUMP) -D $@ > $(TARGET).dis

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# 生成 hex
$(TARGET).hex: $(TARGET).bin
	perl -e 'while(read(STDIN,$$buf,4)){print unpack("H8",$$buf)."\n"}' < $< > $@

# 单独编译 cpu_selftest.S
SELFTEST_SRC = core/mips/cpu_selftest.S
SELFTEST_OBJ = $(OBJDIR)/$(SELFTEST_SRC:.S=.o)
SELFTEST_ELF = $(OBJDIR)/selftest.elf
SELFTEST_HEX = $(OBJDIR)/selftest.hex
SELFTEST_DIS = $(OBJDIR)/selftest.dis

selftest: $(SELFTEST_ELF) $(SELFTEST_HEX) $(SELFTEST_DIS)

$(SELFTEST_OBJ): $(SELFTEST_SRC) | $(OBJDIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# 链接时只用 .o 文件，不要传 linker.ld
$(SELFTEST_ELF): $(SELFTEST_OBJ) linker.ld
	$(LD) $(LDFLAGS) $(SELFTEST_OBJ) -o $@
	$(OBJDUMP) -D $@ > $(SELFTEST_DIS)

$(SELFTEST_HEX): $(SELFTEST_ELF)
	$(OBJCOPY) -O binary $< $(OBJDIR)/selftest.bin
	perl -e 'while(read(STDIN,$$buf,4)){print unpack("H8",$$buf)."\n"}' < $(OBJDIR)/selftest.bin > $@

clean:
	rm -rf $(OBJDIR)

.PHONY: all clean selftest