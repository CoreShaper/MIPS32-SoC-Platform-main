# SW/cpu_selftest.S - MIPS CPU 自测试（纯汇编）
.section .text.start
.globl _start
.type _start, @function

# ============================================================
# 常量定义
# ============================================================
.equ SIM_CTRL,       0xFFFFFFF0
.equ PASS_CODE,      0x00000001

# 错误码：0xDEADMMCC
.equ FAIL_LOGIC,     0xDEAD1100
.equ FAIL_SHIFT,     0xDEAD1200
.equ FAIL_MOVE,      0xDEAD1300
.equ FAIL_ARITH,     0xDEAD1400
.equ FAIL_BRANCH,    0xDEAD1500
.equ FAIL_LOAD_STORE,0xDEAD1600
.equ FAIL_HILO,      0xDEAD1700
.equ FAIL_CP0_EXCEPT,0xDEAD1800

# ============================================================
# 启动入口
# ============================================================
_start:
    # 设置栈指针
    la    $sp, _stack_top

    # 清零 .bss（修正版）
    la    $t0, __bss_start
    la    $t1, __bss_end
    beq   $t0, $t1, 2f
    nop
1:
    sw    $zero, 0($t0)
    addiu $t0, $t0, 4
    bne   $t0, $t1, 1b
    nop
2:

    # ========== 依次调用各模块测试 ==========
    jal   test_logic
    nop
    # 后续模块测试调用暂时注释，待逐个添加
    # jal   test_shift
    # nop
    # jal   test_move
    # nop
    # jal   test_arith
    # nop
    # jal   test_branch
    # nop
    # jal   test_load_store
    # nop
    # jal   test_hilo
    # nop
    # jal   test_cp0_exception
    # nop

    # 全部通过
    li    $a0, PASS_CODE
    jal   report_result
    nop

pass_loop:
    j     pass_loop
    nop

# ============================================================
# 统一结果上报子程序
# 输入: $a0 = 结果代码
# ============================================================
report_result:
    sw    $a0, SIM_CTRL($zero)
    # 等待仿真结束
1:  j     1b
    nop

# ============================================================
# 模块测试：Logic（细化版）
# 错误码前缀：0xDEAD1100
# ============================================================
test_logic:
    # ------------------ 子用例1: and (寄存器与) ------------------
    # 错误码: 0xDEAD1101
    li    $t0, 0x5A5A5A5A      # 01011010...
    li    $t1, 0xA5A5A5A5      # 10100101...
    and   $t2, $t0, $t1
    li    $t3, 0x00000000
    bne   $t2, $t3, fail_logic_1
    nop

    # ------------------ 子用例2: or (寄存器或) ------------------
    # 错误码: 0xDEAD1102
    li    $t0, 0x5A5A5A5A
    li    $t1, 0xA5A5A5A5
    or    $t2, $t0, $t1
    li    $t3, 0xFFFFFFFF
    bne   $t2, $t3, fail_logic_2
    nop

    # ------------------ 子用例3: xor (寄存器异或) ------------------
    # 错误码: 0xDEAD1103
    li    $t0, 0x5A5A5A5A
    li    $t1, 0xA5A5A5A5
    xor   $t2, $t0, $t1
    li    $t3, 0xFFFFFFFF
    bne   $t2, $t3, fail_logic_3
    nop

    # ------------------ 子用例4: nor (寄存器或非) ------------------
    # 错误码: 0xDEAD1104
    li    $t0, 0x5A5A5A5A
    li    $t1, 0xA5A5A5A5
    nor   $t2, $t0, $t1
    li    $t3, 0x00000000
    bne   $t2, $t3, fail_logic_4
    nop

    # ------------------ 子用例5: andi (立即数与) ------------------
    # 错误码: 0xDEAD1105
    li    $t0, 0x12345678
    andi  $t1, $t0, 0xFF00
    li    $t2, 0x00005600
    bne   $t1, $t2, fail_logic_5
    nop

    # ------------------ 子用例6: ori (立即数或) ------------------
    # 错误码: 0xDEAD1106
    li    $t0, 0x12345678
    ori   $t1, $t0, 0x00FF
    li    $t2, 0x123456FF
    bne   $t1, $t2, fail_logic_6
    nop

    # ------------------ 子用例7: xori (立即数异或) ------------------
    # 错误码: 0xDEAD1107
    li    $t0, 0x12345678
    xori  $t1, $t0, 0xFFFF
    li    $t2, 0xEDCBA987
    bne   $t1, $t2, fail_logic_7
    nop

    # ------------------ 子用例8: lui (加载高位) ------------------
    # 错误码: 0xDEAD1108
    lui   $t1, 0xDEAD
    li    $t2, 0xDEAD0000
    bne   $t1, $t2, fail_logic_8
    nop

    # 全部通过，返回
    jr    $ra
    nop

# ----- 失败跳转点（带细粒度错误码）-----
fail_logic_1:
    li    $a0, 0xDEAD1101
    jal   report_result
    nop
fail_logic_2:
    li    $a0, 0xDEAD1102
    jal   report_result
    nop
fail_logic_3:
    li    $a0, 0xDEAD1103
    jal   report_result
    nop
fail_logic_4:
    li    $a0, 0xDEAD1104
    jal   report_result
    nop
fail_logic_5:
    li    $a0, 0xDEAD1105
    jal   report_result
    nop
fail_logic_6:
    li    $a0, 0xDEAD1106
    jal   report_result
    nop
fail_logic_7:
    li    $a0, 0xDEAD1107
    jal   report_result
    nop
fail_logic_8:
    li    $a0, 0xDEAD1108
    jal   report_result
    nop
