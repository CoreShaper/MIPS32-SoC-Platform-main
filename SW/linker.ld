/* SW/linker.ld - MIPS 裸机链接脚本 */
OUTPUT_FORMAT("elf32-tradbigmips")
OUTPUT_ARCH(mips)
ENTRY(_start)

MEMORY
{
    /* 64KB 片上 RAM，从 0x00000000 开始 */
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
    /* 启动代码段：必须放在 0x00000000，CPU 上电复位入口 */
    .text.start 0x00000000 : {
        *(.text.start)
    } > ram

    /* 异常向量段：固定在 0x00000180，符合硬件异常入口地址 */
    .exception 0x00000180 : {
        *(.exception*)
    } > ram

    /* 普通代码段：从 0x00000200 开始，避免与异常向量重叠 */
    .text 0x00000300 : {
        *(.text*)
    } > ram

    /* 只读数据段 */
    .rodata : {
        *(.rodata*)
    } > ram

    /* 已初始化数据段 */
    .data : {
        *(.data*)
    } > ram

    /* 未初始化数据段（BSS），启动代码会清零 */
    .bss : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } > ram

    /* 堆段：为动态内存预留 4KB（可根据需要调整） */
    .heap : {
        __heap_start = .;
        . = . + 0x1000;
        __heap_end = .;
    } > ram

    /* 栈顶：RAM 末尾 */
    _stack_top = ORIGIN(ram) + LENGTH(ram);

    /* 全局指针（可选）*/
    _gp = ALIGN(16) + 0x7FF0;
}