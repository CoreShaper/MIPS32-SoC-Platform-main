# exception.S - MIPS 异常/中断统一入口（汇编与 C 完全分离）
# 汇编保存现场 -> 调用 C 分发器 -> 恢复现场 -> eret

.section .exception, "ax"
.globl _exception_entry
.type _exception_entry, @function

_exception_entry:
    .set noat

    # 栈帧大小：
    # 31个寄存器槽（不含 zero） + 4个CP0槽 = 35 * 4 = 140字节
    # 这里按你的原布局实际使用 36 槽，分配 144 字节
    addiu   $sp, $sp, -144

    # 保存通用寄存器
    sw      $at,   0($sp)
    sw      $v0,   4($sp)
    sw      $v1,   8($sp)
    sw      $a0,  12($sp)
    sw      $a1,  16($sp)
    sw      $a2,  20($sp)
    sw      $a3,  24($sp)
    sw      $t0,  28($sp)
    sw      $t1,  32($sp)
    sw      $t2,  36($sp)
    sw      $t3,  40($sp)
    sw      $t4,  44($sp)
    sw      $t5,  48($sp)
    sw      $t6,  52($sp)
    sw      $t7,  56($sp)
    sw      $s0,  60($sp)
    sw      $s1,  64($sp)
    sw      $s2,  68($sp)
    sw      $s3,  72($sp)
    sw      $s4,  76($sp)
    sw      $s5,  80($sp)
    sw      $s6,  84($sp)
    sw      $s7,  88($sp)
    sw      $t8,  92($sp)
    sw      $t9,  96($sp)
    sw      $k0, 100($sp)
    sw      $k1, 104($sp)
    sw      $gp, 108($sp)

    # 保存“异常前的 sp”
    addiu   $k0, $sp, 144
    sw      $k0, 112($sp)

    sw      $fp, 116($sp)
    sw      $ra, 120($sp)

    # 保存 CP0 寄存器
    mfc0    $k0, $14          # EPC
    sw      $k0, 124($sp)
    mfc0    $k0, $12          # Status
    sw      $k0, 128($sp)
    mfc0    $k0, $13          # Cause
    sw      $k0, 132($sp)
    mfc0    $k0, $8           # BadVAddr
    sw      $k0, 136($sp)

    # 传递 trap_frame *tf
    move    $a0, $sp
    jal     mips_exception_dispatcher
    nop

    # 从 trap_frame 恢复 EPC / Status
    lw      $k0, 124($sp)
    mtc0    $k0, $14
    lw      $k0, 128($sp)
    mtc0    $k0, $12

    # 恢复通用寄存器（注意：sp 最后处理）
    lw      $at,   0($sp)
    lw      $v0,   4($sp)
    lw      $v1,   8($sp)
    lw      $a0,  12($sp)
    lw      $a1,  16($sp)
    lw      $a2,  20($sp)
    lw      $a3,  24($sp)
    lw      $t0,  28($sp)
    lw      $t1,  32($sp)
    lw      $t2,  36($sp)
    lw      $t3,  40($sp)
    lw      $t4,  44($sp)
    lw      $t5,  48($sp)
    lw      $t6,  52($sp)
    lw      $t7,  56($sp)
    lw      $s0,  60($sp)
    lw      $s1,  64($sp)
    lw      $s2,  68($sp)
    lw      $s3,  72($sp)
    lw      $s4,  76($sp)
    lw      $s5,  80($sp)
    lw      $s6,  84($sp)
    lw      $s7,  88($sp)
    lw      $t8,  92($sp)
    lw      $t9,  96($sp)
    lw      $k0, 100($sp)
    lw      $k1, 104($sp)
    lw      $gp, 108($sp)
    lw      $fp, 116($sp)
    lw      $ra, 120($sp)

    # 用 trap_frame 里保存的“异常前 sp”恢复栈指针
    lw      $sp, 112($sp)

    eret
    nop

    .set at
