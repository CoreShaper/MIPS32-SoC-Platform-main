.section .text.start
.globl _start
_start:
    la    $sp, _stack_top       # 设置栈指针

    /* 清零 .bss 段 */
    la    $t0, __bss_start
    la    $t1, __bss_end
1:
    sw    $zero, 0($t0)
    addiu $t0, $t0, 4
    bne   $t0, $t1, 1b
    nop

    jal   main                  # 跳转 C 入口
    nop

    /* main 返回后死循环 */
2:
    j     2b
    nop
