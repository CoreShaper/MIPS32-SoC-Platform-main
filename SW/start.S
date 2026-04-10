// .section .text.start
// .globl _start
// // _start:
// //     la    $sp, _stack_top       # 设置栈指针

// //     /* 清零 .bss 段 */
// //     la    $t0, __bss_start
// //     la    $t1, __bss_end
// // 1:
// //     sw    $zero, 0($t0)
// //     addiu $t0, $t0, 4
// //     bne   $t0, $t1, 1b
// //     nop

// //     jal   main                  # 跳转 C 入口
// //     nop

// //     /* main 返回后死循环 */
// // 2:
// //     j     2b
// //     nop
// _start:
//     la    $sp, _stack_top
//     # 跳过 bss 清零
//     jal   main
//     nop
# SW/start.S - 重现 bss 清零循环中的数据冒险
.section .text.start
.globl _start

_start:
    # 初始化栈指针（占位，无实际用途）
    li    $sp, 0x1000             # $sp = r29

    # ------------------------------------------------------------
    # 模拟 .bss 清零循环，使用固定值触发 RAW 冒险
    # t0 = 0x80 (起始地址), t1 = 0x80 (结束地址)
    # ------------------------------------------------------------
    li    $t0, 0x80               # $t0 = r8
    li    $t1, 0x80               # $t1 = r9

loop:
    sw    $zero, 0($t0)           # $zero = r0, 写入地址 [r8]
    addiu $t0, $t0, 4             # r8 = r8 + 4
    bne   $t0, $t1, loop          # 若 r8 != r9 则跳转 loop
    nop

    # 若循环正常退出，则写 PASS
pass:
    li    $t2, 0xFFFFFFF0         # $t2 = r10
    li    $t3, 1                  # $t3 = r11
    sw    $t3, 0($t2)             # 向 0xFFFFFFF0 写入 1 (PASS)
    j     end
    nop

fail:
    li    $t2, 0xFFFFFFF0         # $t2 = r10
    li    $t3, 2                  # $t3 = r11
    sw    $t3, 0($t2)             # 向 0xFFFFFFF0 写入 2 (FAIL)

end:
    j     end
    nop