OUTPUT_FORMAT("elf32-tradbigmips")
OUTPUT_ARCH(mips)
ENTRY(_start)

MEMORY
{
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
    /* 启动代码段：必须放在 0x0 */
    .text.start 0x00000000 : {
        *(.text.start)
    } > ram

    /* 异常向量段：固定在 0x180 */
    .exception 0x00000180 : {
        *(.exception*)
    } > ram

    /* 其余普通代码段：紧接着异常向量之后（例如从 0x200 开始） */
    .text 0x00000200 : {
        *(.text)
    } > ram

    .rodata : {
        *(.rodata*)
    } > ram

    .data : {
        *(.data*)
    } > ram

    .bss : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } > ram

    _stack_top = ORIGIN(ram) + LENGTH(ram);
}


