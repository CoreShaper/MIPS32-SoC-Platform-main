ifndef CROSS_COMPILE
CROSS_COMPILE = mips-sde-elf-
endif
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

OBJECTS = inst.o

export CROSS_COMPILE

# Rules of Compilation

all: inst.data  inst.asm post_clean
	@echo "Build successful!"

%.o: %.s
	$(CC) -mips32 $< -o $@

inst.om:inst.ld $(OBJECTS)
	$(LD) -T inst.ld $(OBJECTS) -o $@

inst.bin: inst.om
	$(OBJCOPY) -O binary $< $@

inst.data: inst.bin
	./Bin2Mem.exe -f $< -o $@
inst.asm: inst.om
	$(OBJDUMP) -D $< > $@
post_clean: 
	$(MAKE) clean
clean:
	rm -f *.o *.om *.bin
