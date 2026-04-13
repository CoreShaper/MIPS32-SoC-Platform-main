# core/mips/start.S - MIPS 架构启动代码
# 职责：设置栈、清零 BSS、跳转 main，不包含任何外设初始化
# 说明：此文件与 CPU 架构强绑定，切换 RISC-V 时需整体替换

.section .text.start
.globl _start
.type _start, @function

_start:
    # 1. 设置栈指针（链接脚本中定义 _stack_top）
    la    $sp, _stack_top
    li $at, -8
    la    $sp, _stack_top
    li    $t0, 0xFFFFFFE0
    sw    $sp, 0($t0)  # 将初始 sp 存储在一个固定位置，供异常处理程序使用

    # 2. 设置全局指针（如果未来使用 PIC 或需要访问 small data 段）
    # 这里暂不设置，预留指令位置
    # la    $gp, _gp

    # 3. 清零 .bss 段（C 语言要求未初始化全局变量为 0）
    la    $t0, __bss_start
    la    $t1, __bss_end
    beq   $t0, $t1, 2f       # 若 bss 段为空则跳过
    nop
1:
    sw    $zero, 0($t0)
    addiu $t0, $t0, 4
    bne   $t0, $t1, 1b
    nop
2:

    # 4. 跳转到 C 语言主函数 main()
    # 注意：裸机环境下 main 不应返回，若返回则进入死循环
    jal   main
    nop

    # 5. 如果 main 意外返回，死循环捕获
3:
    j     3b
    nop

# 为 C++ 全局构造/析构预留空函数（如果不使用 C++ 可忽略）
.globl _init
.type _init, @function
_init:
    jr    $ra
    nop

.globl _fini
.type _fini, @function
_fini:
    jr    $ra
    nop