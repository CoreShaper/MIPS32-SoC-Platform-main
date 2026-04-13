# SW/cpu_selftest.S - MIPS CPU 自测试（纯汇编）
# ============================================================
# 数据段：用于访存测试（放在文件最开头）
# ============================================================
.data
.align 4
test_data_base:
    .word 0x12345678
    .word 0x89ABCDEF
    .word 0x76543210
    .word 0x00000000
test_bytes:
    .byte 0x55, 0xAA, 0x33, 0xCC
test_halfs:
    .half 0x1122, 0x3344
.align 2
unalign_data:
    .word 0xAABBCCDD, 0x11223344
ll_sc_var:
    .word 0x00000000
.align 2
syscall_flag:   .word 0
trap_flag:      .word 0
ov_flag:        .word 0
timer_int_flag:   .word 0
int_count:        .word 0   # 可选，用于统计中断次数

# ============================================================
# 异常向量表
# ============================================================
.section .exception, "ax"
.globl exception_handler
exception_handler:
    # 统一异常处理入口，记录异常类型并上报
    j    _exception_entry
    nop


    
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
    
     jal   test_shift
     nop
     jal   test_move
     nop
     jal   test_arith
     nop
     jal   test_branch
     nop
     jal   test_load_store
     nop
     jal   test_hilo
     nop
     jal   test_cp0
     nop
     jal   test_exception
     nop
     jal   test_nop_sync
     nop
     jal   test_pipeline
     nop
     jal   test_timer_interrupt
     nop



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

.section .text
# ============================================================
# 模块测试：Logic（细化版）ba
# 错误码前缀：0xDEAD1100
# ============================================================
test_logic:
# =====================基本功能===========================
    # ------------------ 子用例1: and (寄存器与) ------------------
    # 错误码: 0xDEAD1101
    li    $t0, 0x5A5A5A5A      # 01011010...
    li    $t1, 0xA5A5A5A5     # 10100101...
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
    li    $t0, 0x12345678        # $t0 ($8) = 0x12345678
    xori  $t1, $t0, 0xFFFF       # $t1 ($9) = 0x1234A987
    li    $t2, 0x1234A987       # $t2 ($10) = 0x1234A987
    bne   $t1, $t2, fail_logic_7
    nop

# ------------------ 子用例8: lui (加载高位) ------------------
# 错误码: 0xDEAD1108
    lui   $t1, 0xDEAD            # $t1 ($9) = 0xDEAD0000
    li    $t2, 0xDEAD0000        # $t2 ($10) = 0xDEAD0000
    bne   $t1, $t2, fail_logic_8
    nop
# ================== 边界测试扩展 ==================
    # ----- 子用例9: ANDI 立即数为0 -----
    # 错误码: 0xDEAD1109
    li    $t0, 0xFFFFFFFF
    andi  $t1, $t0, 0x0000
    bne   $t1, $zero, fail_logic_9
    nop

    # ----- 子用例10: ORI 立即数为0xFFFF (低16位全1) -----
    # 错误码: 0xDEAD110A
    li    $t0, 0x12340000
    ori   $t1, $t0, 0xFFFF
    li    $t2, 0x1234FFFF
    bne   $t1, $t2, fail_logic_10
    nop

    # ----- 子用例11: XORI 立即数为0xFFFF (全1，测试位翻转) -----
    # 错误码: 0xDEAD110B
    li    $t0, 0xAAAAAAAA
    xori  $t1, $t0, 0xFFFF
    li    $t2, 0xAAAA5555
    bne   $t1, $t2, fail_logic_11
    nop

    # ----- 子用例12: LUI 结合 ORI 形成32位立即数（验证高位加载后低位OR）-----
    # 错误码: 0xDEAD110C
    lui   $t0, 0x1234
    ori   $t0, $t0, 0x5678
    li    $t1, 0x12345678
    bne   $t0, $t1, fail_logic_12
    nop

    # ----- 子用例13: 背靠背数据冒险 (AND -> OR) -----
    # 错误码: 0xDEAD110D
    li    $t0, 0x5A5A5A5A
    li    $t1, 0xA5A5A5A5
    and   $t2, $t0, $t1
    or    $t3, $t2, $t0          # t3 应等于 t0 (因为 t2=0)
    bne   $t3, $t0, fail_logic_13
    nop

    # ----- 子用例14: NOR 边界测试（全1输入产生全0）-----
    # 错误码: 0xDEAD110E
    li    $t0, -1                # 0xFFFFFFFF
    li    $t1, -1
    nor   $t2, $t0, $t1
    bne   $t2, $zero, fail_logic_14
    nop

    # ----- 子用例15: XOR 相同寄存器清零 -----
    # 错误码: 0xDEAD110F
    li    $t0, 0x12345678           
    xor   $t1, $t0, $t0
    bne   $t1, $zero, fail_logic_15
    nop

     # 全部通过，返回
     jr    $ra
    nop

// # ----- 失败跳转点（带细粒度错误码）-----
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
fail_logic_9:   li $a0, 0xDEAD1109; jal report_result; nop
fail_logic_10:  li $a0, 0xDEAD110A; jal report_result; nop
fail_logic_11:  li $a0, 0xDEAD110B; jal report_result; nop
fail_logic_12:  li $a0, 0xDEAD110C; jal report_result; nop
fail_logic_13:  li $a0, 0xDEAD110D; jal report_result; nop
fail_logic_14:  li $a0, 0xDEAD110E; jal report_result; nop
fail_logic_15:  li $a0, 0xDEAD110F; jal report_result; nop

# ============================================================
# 模块测试：Shift（移位指令）
# 错误码前缀：0xDEAD1200
# ============================================================
test_shift:
    # ===================== 基本功能测试 =====================

    # ----- 子用例1: SLL 基本功能 -----
    # 错误码: 0xDEAD1201
    li    $t0, 0x00000001
    sll   $t1, $t0, 4               # 左移4位 -> 0x10
    li    $t2, 0x00000010
    bne   $t1, $t2, fail_shift_1
    nop

    # ----- 子用例2: SRL 基本功能 -----
    # 错误码: 0xDEAD1202
    li    $t0, 0x80000000
    srl   $t1, $t0, 4               # 逻辑右移4位 -> 0x08000000
    li    $t2, 0x08000000
    bne   $t1, $t2, fail_shift_2
    nop

    # ----- 子用例3: SRA 基本功能（负数符号扩展）-----
    # 错误码: 0xDEAD1203
    li    $t0, 0x80000000
    sra   $t1, $t0, 4               # 算术右移4位 -> 0xF8000000
    li    $t2, 0xF8000000
    bne   $t1, $t2, fail_shift_3
    nop

    # ----- 子用例4: SRA 基本功能（正数）-----
    # 错误码: 0xDEAD1204
    li    $t0, 0x12345678
    sra   $t1, $t0, 4               # 算术右移4位 -> 0x01234567
    li    $t2, 0x01234567
    bne   $t1, $t2, fail_shift_4
    nop

    # ----- 子用例5: SLLV 基本功能 -----
    # 错误码: 0xDEAD1205
    li    $t0, 0x00000001
    li    $t1, 5
    sllv  $t2, $t0, $t1             # 左移5位 -> 0x20
    li    $t3, 0x00000020
    bne   $t2, $t3, fail_shift_5
    nop

    # ----- 子用例6: SRLV 基本功能 -----
    # 错误码: 0xDEAD1206
    li    $t0, 0x80000000
    li    $t1, 3
    srlv  $t2, $t0, $t1             # 逻辑右移3位 -> 0x10000000
    li    $t3, 0x10000000
    bne   $t2, $t3, fail_shift_6
    nop

    # ----- 子用例7: SRAV 基本功能（负数）-----
    # 错误码: 0xDEAD1207
    li    $t0, 0x80000000
    li    $t1, 2
    srav  $t2, $t0, $t1             # 算术右移2位 -> 0xE0000000
    li    $t3, 0xE0000000
    bne   $t2, $t3, fail_shift_7
    nop

    # ================== 边界测试 ==================

    # ----- 子用例8: SLL 移位量为0（结果不变）-----
    # 错误码: 0xDEAD1208
    li    $t0, 0x12345678
    sll   $t1, $t0, 0
    li    $t2, 0x12345678
    bne   $t1, $t2, fail_shift_8
    nop

     # ----- 子用例9: SLL 移位量大于31（取低5位）-----
    # 使用机器码: sll $t1, $t0, 32   (shamt=0, 因为32低5位为0)
    # 机器码: 0000 0000 0000 1000 0000 1001 0000 0000 = 0x00080900
    # 错误码: 0xDEAD1209
    li    $t0, 0x12345678
    .word 0x00080900               # sll $t1, $t0, 32
    li    $t2, 0x12345678
    bne   $t1, $t2, fail_shift_9
    nop

    # ----- 子用例10: SRL 移位量为0 -----
    # (保持不变)
    # 错误码: 0xDEAD120A
    li    $t0, 0x80000000
    srl   $t1, $t0, 0
    li    $t2, 0x80000000
    bne   $t1, $t2, fail_shift_10
    nop

    # ----- 子用例11: 移位冒险（RAW依赖）-----
    # 错误码: 0xDEAD120E
    li    $t0, 0x00000001
    addiu $t1, $zero, 8             # 移位量8
    sllv  $t2, $t0, $t1             # 依赖t0和t1，左移8位 -> 0x100
    li    $t3, 0x00000100
    bne   $t2, $t3, fail_shift_11
    nop

    # 全部通过，返回
    jr    $ra
    nop

# ----- 失败跳转点（错误码 0xDEAD1201 ~ 0xDEAD120B）-----
fail_shift_1:   li $a0, 0xDEAD1201; jal report_result; nop
fail_shift_2:   li $a0, 0xDEAD1202; jal report_result; nop
fail_shift_3:   li $a0, 0xDEAD1203; jal report_result; nop
fail_shift_4:   li $a0, 0xDEAD1204; jal report_result; nop
fail_shift_5:   li $a0, 0xDEAD1205; jal report_result; nop
fail_shift_6:   li $a0, 0xDEAD1206; jal report_result; nop
fail_shift_7:   li $a0, 0xDEAD1207; jal report_result; nop
fail_shift_8:   li $a0, 0xDEAD1208; jal report_result; nop
fail_shift_9:   li $a0, 0xDEAD1209; jal report_result; nop
fail_shift_10:  li $a0, 0xDEAD120A; jal report_result; nop
fail_shift_11:  li $a0, 0xDEAD120B; jal report_result; nop

# ============================================================
# 模块测试：Move（条件移动）
# 错误码前缀：0xDEAD1300
# ============================================================
test_move:
    # ===================== 基本功能 =====================

    # ----- 子用例1: MOVN 条件成立 (rt != 0) -----
    # 错误码: 0xDEAD1301
    li    $t0, 0x12345678
    li    $t1, 1               # rt != 0
    li    $t2, 0x0             # 原值
    movn  $t2, $t0, $t1        # t2 应变为 0x12345678
    li    $t3, 0x12345678
    bne   $t2, $t3, fail_move_1
    nop

    # ----- 子用例2: MOVN 条件不成立 (rt == 0) -----
    # 错误码: 0xDEAD1302
    li    $t0, 0x12345678
    li    $t1, 0               # rt == 0
    li    $t2, 0xAAAAAAAA      # 保留原值
    movn  $t2, $t0, $t1        # 不应移动
    li    $t3, 0xAAAAAAAA
    bne   $t2, $t3, fail_move_2
    nop

    # ----- 子用例3: MOVZ 条件成立 (rt == 0) -----
    # 错误码: 0xDEAD1303
    li    $t0, 0x87654321
    li    $t1, 0               # rt == 0
    li    $t2, 0x0
    movz  $t2, $t0, $t1        # t2 应变为 0x87654321
    li    $t3, 0x87654321
    bne   $t2, $t3, fail_move_3
    nop

    # ----- 子用例4: MOVZ 条件不成立 (rt != 0) -----
    # 错误码: 0xDEAD1304
    li    $t0, 0x87654321
    li    $t1, 2               # rt != 0
    li    $t2, 0xBBBBBBBB
    movz  $t2, $t0, $t1        # 不应移动
    li    $t3, 0xBBBBBBBB
    bne   $t2, $t3, fail_move_4
    nop

    # ================== 边界测试 ==================

    # ----- 子用例5: 条件寄存器冒险 (RAW) -----
    # 错误码: 0xDEAD1305
    li    $t0, 0x11223344
    li    $t1, 0               # 准备写入 t1 为 0
    addiu $t1, $t1, 5          # t1 变为 5 (非零)
    movn  $t2, $t0, $t1        # t1 非零，应移动
    li    $t3, 0x11223344
    bne   $t2, $t3, fail_move_5
    nop

    # ----- 子用例6: 源寄存器冒险 -----
    # 错误码: 0xDEAD1306
    li    $t0, 0x55667788
    addiu $t0, $t0, 1          # t0 变为 0x55667789
    li    $t1, 0
    movz  $t2, $t0, $t1        # t1==0，应移动
    li    $t3, 0x55667789
    bne   $t2, $t3, fail_move_6
    nop

    # 全部通过
    jr    $ra
    nop

fail_move_1:   li $a0, 0xDEAD1301; jal report_result; nop
fail_move_2:   li $a0, 0xDEAD1302; jal report_result; nop
fail_move_3:   li $a0, 0xDEAD1303; jal report_result; nop
fail_move_4:   li $a0, 0xDEAD1304; jal report_result; nop
fail_move_5:   li $a0, 0xDEAD1305; jal report_result; nop
fail_move_6:   li $a0, 0xDEAD1306; jal report_result; nop

# ============================================================
# 模块测试：HILO（乘除结果寄存器访问）
# 错误码前缀：0xDEAD1700
# ============================================================
test_hilo:
    # ===================== 基本功能 =====================

    # ----- 子用例1: MTHI / MFHI 基本读写 -----
    # 错误码: 0xDEAD1701
    li    $t0, 0x12345678
    mthi  $t0
    mfhi  $t1
    bne   $t1, $t0, fail_hilo_1
    nop

    # ----- 子用例2: MTLO / MFLO 基本读写 -----
    # 错误码: 0xDEAD1702
    li    $t0, 0x9ABCDEF0
    mtlo  $t0
    mflo  $t1
    bne   $t1, $t0, fail_hilo_2
    nop

    # ----- 子用例3: HI/LO 同时写入与读出（不干扰）-----
    # 错误码: 0xDEAD1703
    li    $t0, 0x11112222
    li    $t1, 0x33334444
    mthi  $t0
    mtlo  $t1
    mfhi  $t2
    mflo  $t3
    bne   $t2, $t0, fail_hilo_3
    bne   $t3, $t1, fail_hilo_3
    nop

    # ================== 边界测试 ==================

    # ----- 子用例4: 冒险 (MTHI -> MFHI 背靠背) -----
    # 错误码: 0xDEAD1704
    li    $t0, 0xAAAA5555
    mthi  $t0
    mfhi  $t1
    bne   $t1, $t0, fail_hilo_4
    nop

    # ----- 子用例5: 冒险 (MTLO -> MFLO 背靠背) -----
    # 错误码: 0xDEAD1705
    li    $t0, 0x5555AAAA
    mtlo  $t0
    mflo  $t1
    bne   $t1, $t0, fail_hilo_5
    nop

    # ----- 子用例6: HI 写入后 LO 写入不互相影响 -----
    # 错误码: 0xDEAD1706
    li    $t0, 0x12345678
    li    $t1, 0x87654321
    mthi  $t0
    mtlo  $t1
    mfhi  $t2
    mflo  $t3
    bne   $t2, $t0, fail_hilo_6
    bne   $t3, $t1, fail_hilo_6
    nop
        # ===================== HILO 乘除运算扩展 =====================
    # (错误码沿用 0xDEAD1700，子用例从 07 开始，避免与之前冲突)

    # ----- 子用例7: MULT 有符号乘法 -----
    # 错误码: 0xDEAD1707
    li    $t0, 0x1234
    li    $t1, 0x5678
    mult  $t0, $t1
    mflo  $t2
    mfhi  $t3
    # 期望 LO = 0x06260060, HI = 0x00000000 (无符号溢出到HI？实际乘积为0x06260060，未超过32位)
    li    $t4, 0x06260060
    bne   $t2, $t4, fail_hilo_7
    bne   $t3, $zero, fail_hilo_7
    nop

    # ----- 子用例8: MULTU 无符号乘法 -----
    # 错误码: 0xDEAD1708
    li    $t0, 0xFFFFFFFF
    li    $t1, 0xFFFFFFFF
    multu $t0, $t1
    mflo  $t2
    mfhi  $t3
    # 期望 HI=0xFFFFFFFE, LO=0x00000001
    li    $t4, 0x00000001
    li    $t5, 0xFFFFFFFE
    bne   $t2, $t4, fail_hilo_8
    bne   $t3, $t5, fail_hilo_8
    nop

    # ----- 子用例9: DIV 有符号除法 -----
    # 错误码: 0xDEAD1709
    li    $t0, 0x00000009
    li    $t1, 0x00000002
    div   $t0, $t1
    mflo  $t2
    mfhi  $t3
    li    $t4, 4                # 商
    li    $t5, 1                # 余数
    bne   $t2, $t4, fail_hilo_9
    bne   $t3, $t5, fail_hilo_9
    nop

    # ----- 子用例10: DIVU 无符号除法 -----
    # 错误码: 0xDEAD170A
    li    $t0, 0xFFFFFFFE
    li    $t1, 0x00000002
    divu  $t0, $t1
    mflo  $t2
    mfhi  $t3
    li    $t4, 0x7FFFFFFF        # 商
    li    $t5, 0                 # 余数
    bne   $t2, $t4, fail_hilo_10
    bne   $t3, $t5, fail_hilo_10
    nop

    # ----- 子用例11: MADD 乘加 -----
    # 错误码: 0xDEAD170B
    # 先初始化 HI/LO 为某个值，再执行 madd
    li    $t0, 0x00000002
    li    $t1, 0x00000003
    mthi  $t0                   # HI=2
    mtlo  $t1                   # LO=3，组合为 {2,3} = 0x0000000200000003
    li    $t2, 4
    li    $t3, 5
    madd  $t2, $t3              # {HI,LO} += 4*5 = 20 = 0x14
    mfhi  $t4
    mflo  $t5
    # 期望 HI=2, LO=3+20=23 (0x17)
    bne   $t4, $t0, fail_hilo_11
    li    $t6, 23
    bne   $t5, $t6, fail_hilo_11
    nop

    # ----- 子用例12: MSUB 乘减 -----
    # 错误码: 0xDEAD170C
    li    $t0, 0x00000005
    li    $t1, 0x00000064       # 100
    mthi  $t0
    mtlo  $t1                   # {5,100}
    li    $t2, 3
    li    $t3, 10
    msub  $t2, $t3              # 减去 30
    mfhi  $t4
    mflo  $t5
    # 期望 HI=5, LO=70
    bne   $t4, $t0, fail_hilo_12
    li    $t6, 70
    bne   $t5, $t6, fail_hilo_12
    nop



    # 全部通过
    jr    $ra
    nop

fail_hilo_1:   li $a0, 0xDEAD1701; jal report_result; nop
fail_hilo_2:   li $a0, 0xDEAD1702; jal report_result; nop
fail_hilo_3:   li $a0, 0xDEAD1703; jal report_result; nop
fail_hilo_4:   li $a0, 0xDEAD1704; jal report_result; nop
fail_hilo_5:   li $a0, 0xDEAD1705; jal report_result; nop
fail_hilo_6:   li $a0, 0xDEAD1706; jal report_result; nop
fail_hilo_7:   li $a0, 0xDEAD1707; jal report_result; nop
fail_hilo_8:   li $a0, 0xDEAD1708; jal report_result; nop
fail_hilo_9:   li $a0, 0xDEAD1709; jal report_result; nop
fail_hilo_10:  li $a0, 0xDEAD170A; jal report_result; nop
fail_hilo_11:  li $a0, 0xDEAD170B; jal report_result; nop
fail_hilo_12:  li $a0, 0xDEAD170C; jal report_result; nop

# ============================================================
# 模块测试：Arith（简单算术指令）
# 错误码前缀：0xDEAD1400
# ============================================================
test_arith:
    # ===================== 基本功能 =====================

    # ----- 子用例1: ADD 正常加法 -----
    # 错误码: 0xDEAD1401
    li    $t0, 0x12345678
    li    $t1, 0x11111111
    add   $t2, $t0, $t1
    li    $t3, 0x23456789
    bne   $t2, $t3, fail_arith_1
    nop

    # ----- 子用例2: ADDU 无符号加法 (不溢出) -----
    # 错误码: 0xDEAD1402
    li    $t0, 0x7FFFFFFF
    li    $t1, 0x00000001
    addu  $t2, $t0, $t1
    li    $t3, 0x80000000
    bne   $t2, $t3, fail_arith_2
    nop

    # ----- 子用例3: SUB 正常减法 -----
    # 错误码: 0xDEAD1403
    li    $t0, 0x56781234
    li    $t1, 0x12341111
    sub   $t2, $t0, $t1
    li    $t3, 0x44440123
    bne   $t2, $t3, fail_arith_3
    nop

    # ----- 子用例4: SUBU 无符号减法 (不溢出) -----
    # 错误码: 0xDEAD1404
    li    $t0, 0x00000001
    li    $t1, 0x00000002
    subu  $t2, $t0, $t1
    li    $t3, 0xFFFFFFFF
    bne   $t2, $t3, fail_arith_4
    nop

    # ----- 子用例5: ADDI 立即数加法 -----
    # 错误码: 0xDEAD1405
    li    $t0, 0x12345678        # $t0 ($8) = 0x12345678
    addi  $t1, $t0, 0x111        # $t1 ($9) = 0x12345789
    li    $t2, 0x12345789        # $t2 ($10) = 0x12345789
    bne   $t1, $t2, fail_arith_5
    nop

    # ----- 子用例6: ADDIU 立即数无符号加法 -----
    # 错误码: 0xDEAD1406
    li    $t0, 0x7FFFFFFF
    addiu $t1, $t0, 1
    li    $t2, 0x80000000
    bne   $t1, $t2, fail_arith_6
    nop

    # ----- 子用例7: SLT 有符号比较 (小于) -----
    # 错误码: 0xDEAD1407
    li    $t0, -1               # 0xFFFFFFFF
    li    $t1, 1
    slt   $t2, $t0, $t1         # -1 < 1 成立
    li    $t3, 1
    bne   $t2, $t3, fail_arith_7
    nop

    # ----- 子用例8: SLT 有符号比较 (大于) -----
    # 错误码: 0xDEAD1408
    li    $t0, 2
    li    $t1, 1
    slt   $t2, $t0, $t1         # 2 < 1 不成立
    bne   $t2, $zero, fail_arith_8
    nop

    # ----- 子用例9: SLTU 无符号比较 -----
    # 错误码: 0xDEAD1409
    li    $t0, -1               # 0xFFFFFFFF 无符号为最大数
    li    $t1, 1
    sltu  $t2, $t0, $t1         # 0xFFFFFFFF < 1 不成立
    bne   $t2, $zero, fail_arith_9
    nop

    # ----- 子用例10: SLTI 有符号立即数比较 -----
    # 错误码: 0xDEAD140A
    li    $t0, -5
    slti  $t1, $t0, 0           # -5 < 0 成立
    li    $t2, 1
    bne   $t1, $t2, fail_arith_10
    nop

    # ----- 子用例11: SLTIU 无符号立即数比较 -----
    # 错误码: 0xDEAD140B
    li    $t0, 5
    sltiu $t1, $t0, 0xFFFF      # 5 < 0xFFFF 成立
    li    $t2, 1
    bne   $t1, $t2, fail_arith_11
    nop

    # ----- 子用例12: MUL 乘法（低32位）-----
    # 错误码: 0xDEAD140C
    li    $t0, 0x1234
    li    $t1, 0x5678
    mul   $t2, $t0, $t1
    li    $t3, 0x06260060
    bne   $t2, $t3, fail_arith_12
    nop

    # ----- 子用例13: CLO 前导1计数 -----
    # 错误码: 0xDEAD140D
    li    $t0, 0x0FFFFFFF       # 前导4个0，即28个有效位，前导1个数为0？ 需要测试具体模式
    # 换一个明确的值：0xF0000000 -> 前导4个1
    li    $t0, 0xF0000000
    clo   $t1, $t0
    li    $t2, 4
    bne   $t1, $t2, fail_arith_13
    nop

    # ----- 子用例14: CLZ 前导0计数 -----
    # 错误码: 0xDEAD140E
    li    $t0, 0x0000FFFF       # 前导16个0
    clz   $t1, $t0
    li    $t2, 16
    bne   $t1, $t2, fail_arith_14
    nop

     # ================== 边界测试 ==================

    # ----- 子用例17: 冒险 (ADD -> SUB 数据依赖) -----
    # 错误码: 0xDEAD1411
    li    $t0, 100
    li    $t1, 20
    add   $t2, $t0, $t1
    sub   $t3, $t2, $t1         # t3 应等于 t0 (100)
    bne   $t3, $t0, fail_arith_17
    nop

    # 全部通过
    jr    $ra
    nop

# ----- 失败跳转点 (0xDEAD1401 ~ 0xDEAD1411) -----
fail_arith_1:   li $a0, 0xDEAD1401; jal report_result; nop
fail_arith_2:   li $a0, 0xDEAD1402; jal report_result; nop
fail_arith_3:   li $a0, 0xDEAD1403; jal report_result; nop
fail_arith_4:   li $a0, 0xDEAD1404; jal report_result; nop
fail_arith_5:   li $a0, 0xDEAD1405; jal report_result; nop
fail_arith_6:   li $a0, 0xDEAD1406; jal report_result; nop
fail_arith_7:   li $a0, 0xDEAD1407; jal report_result; nop
fail_arith_8:   li $a0, 0xDEAD1408; jal report_result; nop
fail_arith_9:   li $a0, 0xDEAD1409; jal report_result; nop
fail_arith_10:  li $a0, 0xDEAD140A; jal report_result; nop
fail_arith_11:  li $a0, 0xDEAD140B; jal report_result; nop
fail_arith_12:  li $a0, 0xDEAD140C; jal report_result; nop
fail_arith_13:  li $a0, 0xDEAD140D; jal report_result; nop
fail_arith_14:  li $a0, 0xDEAD140E; jal report_result; nop
fail_arith_15:  li $a0, 0xDEAD140F; jal report_result; nop
fail_arith_16:  li $a0, 0xDEAD1410; jal report_result; nop
fail_arith_17:  li $a0, 0xDEAD1411; jal report_result; nop

# ============================================================
# 模块测试：Branch（转移指令）
# 错误码前缀：0xDEAD1500
# ============================================================
test_branch:
    .set noreorder
        # 保存返回地址到栈中（因为模块内会使用jal修改$ra）
    addiu $sp, $sp, -8
    sw    $ra, 4($sp)
    sw    $s0, 0($sp)          # 可选，若需用$s0
    # ===================== 基本功能 =====================

    # ----- 子用例1: J 无条件跳转 -----
    # 错误码: 0xDEAD1501
    j     branch_j_target
    nop
    j     fail_branch_1        # 不应执行
    nop
branch_j_target:
    # 成功到达此处
    nop


    # ----- 子用例2: JAL 跳转并链接（修正版）-----
    # 错误码: 0xDEAD1502
    # 方法：利用 jal 将下一条指令地址存入 $ra，在目标中验证 $ra 非零且能正确返回
    li    $t0, 0x5A5A           # 特征值
    jal   branch_jal_target2
    addiu $t0, $t0, 0x1         # 延迟槽：t0 应变为 0x5A5B
    # 返回后检查延迟槽是否执行
    li    $t1, 0x5A5B
    bne   $t0, $t1, fail_branch_2
    nop
    # 检查 $ra 是否被修改（非零且不等于 test_branch 起始，简单判断）
    la    $t2, test_branch
    subu  $t3, $ra, $t2
    blez  $t3, fail_branch_2     # $ra 应大于 test_branch 起始地址
    nop
    j     branch_jal_next2
    nop

branch_jal_target2:
    # 验证 $ra 指向的地址处是否为 addiu 指令（可选，粗略检查）
    lw    $t4, 0($ra)
    li    $t5, 0x24095A5B  
    bne   $t4, $t5, fail_branch_2
    nop
    jr    $ra
    nop
branch_jal_next2:



    # ----- 子用例3: JR 寄存器跳转 -----
    # 错误码: 0xDEAD1503
    la    $t0, branch_jr_target
    jr    $t0
    nop
    j     fail_branch_3
    nop
branch_jr_target:
    nop

    # ----- 子用例4: JALR 寄存器跳转并链接 -----
    # 错误码: 0xDEAD1504
    li    $t0, 0xA5A5
    la    $t1, branch_jalr_target4
    jalr  $t1
    addiu $t0, $t0, 1           # t0=0xA5A6
    li    $t2, 0xA5A6
    bne   $t0, $t2, fail_branch_4
    nop
    la    $t3, test_branch
    subu  $t4, $ra, $t3
    blez  $t4, fail_branch_4
    nop
    j     branch_jalr_next4
    nop

branch_jalr_target4:
    li    $t5, 0xBEEF
    jr    $ra
    nop
branch_jalr_next4:
    li    $t6, 0xBEEF
    bne   $t5, $t6, fail_branch_4
    nop

    # ----- 子用例5: BEQ 相等则跳转 -----
    # 错误码: 0xDEAD1505
    li    $t0, 5
    li    $t1, 5
    beq   $t0, $t1, branch_beq_pass
    nop
    j     fail_branch_5
    nop
branch_beq_pass:
    # 验证不相等时不跳转
    li    $t0, 5
    li    $t1, 6
    beq   $t0, $t1, fail_branch_5
    nop

    # ----- 子用例6: BNE 不等则跳转 -----
    # 错误码: 0xDEAD1506
    li    $t0, 5
    li    $t1, 6
    bne   $t0, $t1, branch_bne_pass
    nop
    j     fail_branch_6
    nop
branch_bne_pass:
    # 验证相等时不跳转
    li    $t0, 5
    li    $t1, 5
    bne   $t0, $t1, fail_branch_6
    nop

    # ----- 子用例7: BGTZ 大于0跳转 -----
    # 错误码: 0xDEAD1507
    li    $t0, 1
    bgtz  $t0, branch_bgtz_pass
    nop
    j     fail_branch_7
    nop
branch_bgtz_pass:
    # 验证 ≤0 时不跳转
    li    $t0, 0
    bgtz  $t0, fail_branch_7
    nop
    li    $t0, -1
    bgtz  $t0, fail_branch_7
    nop

    # ----- 子用例8: BLEZ 小于等于0跳转 -----
    # 错误码: 0xDEAD1508
    li    $t0, 0
    blez  $t0, branch_blez_pass1
    nop
    j     fail_branch_8
    nop
branch_blez_pass1:
    li    $t0, -1
    blez  $t0, branch_blez_pass2
    nop
    j     fail_branch_8
    nop
branch_blez_pass2:
    # 验证 >0 时不跳转
    li    $t0, 1
    blez  $t0, fail_branch_8
    nop

    # ----- 子用例9: BLTZ 小于0跳转 -----
    # 错误码: 0xDEAD1509
    li    $t0, -1
    bltz  $t0, branch_bltz_pass
    nop
    j     fail_branch_9
    nop
branch_bltz_pass:
    # 验证 ≥0 时不跳转
    li    $t0, 0
    bltz  $t0, fail_branch_9
    nop
    li    $t0, 1
    bltz  $t0, fail_branch_9
    nop

    # ----- 子用例10: BGEZ 大于等于0跳转 -----
    # 错误码: 0xDEAD150A
    li    $t0, 0
    bgez  $t0, branch_bgez_pass1
    nop
    j     fail_branch_10
    nop
branch_bgez_pass1:
    li    $t0, 1
    bgez  $t0, branch_bgez_pass2
    nop
    j     fail_branch_10
    nop
branch_bgez_pass2:
    # 验证 <0 时不跳转
    li    $t0, -1
    bgez  $t0, fail_branch_10
    nop

    # ----- 子用例11: BLTZAL 小于0跳转并链接 -----
    # 错误码: 0xDEAD150B
    # 条件成立测试
    li    $t0, -1
    li    $t1, 0x1111
    bltzal $t0, branch_bltzal_target11
    addiu $t1, $t1, 1           # t1=0x1112
    j     fail_branch_11        # 不应到达
    nop

branch_bltzal_target11:
    li    $t2, 0x1112
    bne   $t1, $t2, fail_branch_11
    nop
    # 验证 $ra 指向 addiu 指令（粗略范围检查）
    la    $t3, test_branch
    subu  $t4, $ra, $t3
    blez  $t4, fail_branch_11
    nop
    # 条件不成立测试
    li    $t0, 0
    li    $t1, 0x2222
    bltzal $t0, fail_branch_11  # 不跳转
    addiu $t1, $t1, 1           # t1=0x2223
    li    $t2, 0x2223
    bne   $t1, $t2, fail_branch_11
    nop
    # 验证 $ra 指向该 addiu 之后的指令（范围检查）
    la    $t3, test_branch
    subu  $t4, $ra, $t3
    blez  $t4, fail_branch_11
    nop
    j     branch_bltzal_done11
    nop
branch_bltzal_done11:

 # ----- 子用例12: BGEZAL 大于等于0跳转并链接 -----
    # 错误码: 0xDEAD150C
    # 条件成立 (t0=0)
    li    $t0, 0
    li    $t1, 0x3333
    bgezal $t0, branch_bgezal_target12
    addiu $t1, $t1, 1           # t1=0x3334
    j     fail_branch_12
    nop

branch_bgezal_target12:
    li    $t2, 0x3334
    bne   $t1, $t2, fail_branch_12
    nop
    la    $t3, test_branch
    subu  $t4, $ra, $t3
    blez  $t4, fail_branch_12
    nop
    # 条件不成立 (t0=-1)
    li    $t0, -1
    li    $t1, 0x4444
    bgezal $t0, fail_branch_12
    addiu $t1, $t1, 1           # t1=0x4445
    li    $t2, 0x4445
    bne   $t1, $t2, fail_branch_12
    nop
    la    $t3, test_branch
    subu  $t4, $ra, $t3
    blez  $t4, fail_branch_12
    nop
    j     branch_bgezal_done12
    nop
branch_bgezal_done12:

    # ----- 子用例13: BAL 无条件链接 -----
    # 错误码: 0xDEAD150D
    li    $t0, 0x5555
    bal   branch_bal_target13
    addiu $t0, $t0, 1           # t0=0x5556
    li    $t1, 0x5556
    bne   $t0, $t1, fail_branch_13
    nop
    la    $t2, test_branch
    subu  $t3, $ra, $t2
    blez  $t3, fail_branch_13
    nop
    j     branch_bal_done13
    nop

branch_bal_target13:
    jr    $ra
    nop
branch_bal_done13:
    # ================== 边界测试 ==================

    # ----- 子用例14: 延迟槽执行验证 -----
    # 错误码: 0xDEAD150E
    li    $t0, 0
    jal   branch_delay_target14
    addiu $t0, $t0, 1           # 延迟槽，t0=1
    li    $t1, 1
    bne   $t0, $t1, fail_branch_14
    nop
    j     branch_delay_done14
    nop

branch_delay_target14:
    jr    $ra
    nop
branch_delay_done14:

    # ----- 子用例15: 分支冒险（RAW依赖）-----
    # 错误码: 0xDEAD150F
    li    $t0, 5
    addiu $t1, $t0, 5           # t1 = 10
    beq   $t0, $t1, fail_branch_15  # 5 != 10，不跳转
    nop

    # 验证正确到达此处
    bne   $t0, $t1, branch_raw_pass
    nop
    j     fail_branch_15
    nop
branch_raw_pass:

    # 全部通过
    lw    $ra, 4($sp)
    lw    $s0, 0($sp)
    addiu $sp, $sp, 8
    .set reorder
    jr    $ra
    nop


# ----- 失败跳转点 (0xDEAD1501 ~ 0xDEAD150F) -----
fail_branch_1:   li $a0, 0xDEAD1501; jal report_result; nop
fail_branch_2:   li $a0, 0xDEAD1502; jal report_result; nop
fail_branch_3:   li $a0, 0xDEAD1503; jal report_result; nop
fail_branch_4:   li $a0, 0xDEAD1504; jal report_result; nop
fail_branch_5:   li $a0, 0xDEAD1505; jal report_result; nop
fail_branch_6:   li $a0, 0xDEAD1506; jal report_result; nop
fail_branch_7:   li $a0, 0xDEAD1507; jal report_result; nop
fail_branch_8:   li $a0, 0xDEAD1508; jal report_result; nop
fail_branch_9:   li $a0, 0xDEAD1509; jal report_result; nop
fail_branch_10:  li $a0, 0xDEAD150A; jal report_result; nop
fail_branch_11:  li $a0, 0xDEAD150B; jal report_result; nop
fail_branch_12:  li $a0, 0xDEAD150C; jal report_result; nop
fail_branch_13:  li $a0, 0xDEAD150D; jal report_result; nop
fail_branch_14:  li $a0, 0xDEAD150E; jal report_result; nop
fail_branch_15:  li $a0, 0xDEAD150F; jal report_result; nop


# ============================================================
# 模块测试：Load/Store（访存指令）
# 错误码前缀：0xDEAD1600
# ============================================================
test_load_store:
    .set noreorder
       # ----- 子用例1: LW / SW 基本对齐读写 -----
    # 错误码: 0xDEAD1601
    la    $t0, test_data_base
    lw    $t1, 0($t0)               # 加载 0x12345678
    li    $t2, 0x12345678
    bne   $t1, $t2, fail_ls_1
    nop
    # 写回测试
    li    $t3, 0xAAAAAAAA
    sw    $t3, 0($t0)
    lw    $t4, 0($t0)
    bne   $t4, $t3, fail_ls_1
    nop
    sw    $t2, 0($t0)               # 恢复原数据

    # ----- 子用例2: LH / LHU 半字加载（符号/零扩展）-----
    # 错误码: 0xDEAD1602
    la    $t0, test_data_base
    lh    $t1, 2($t0)               # 加载 0x5678，符号扩展（正数不变）
    li    $t2, 0x00005678
    bne   $t1, $t2, fail_ls_2
    nop
    lhu   $t1, 2($t0)               # 零扩展
    li    $t2, 0x00005678
    bne   $t1, $t2, fail_ls_2
    nop
    # 测试负数符号扩展：0x89ABCDEF 的高半字为 0x89AB（负数）
    lh    $t1, 4($t0)               # 加载 0x89AB，符号扩展 -> 0xFFFF89AB
    li    $t2, 0xFFFF89AB
    bne   $t1, $t2, fail_ls_2
    nop
    lhu   $t1, 4($t0)               # 零扩展 -> 0x000089AB
    li    $t2, 0x000089AB
    bne   $t1, $t2, fail_ls_2
    nop

    # ----- 子用例3: LB / LBU 字节加载（符号/零扩展）-----
    # 错误码: 0xDEAD1603
    la    $t0, test_data_base
    lb    $t1, 0($t0)               # 0x12（正数）-> 0x00000012
    li    $t2, 0x00000012
    bne   $t1, $t2, fail_ls_3
    nop
    lb    $t1, 4($t0)               # 0x89（负数）-> 0xFFFFFF89
    li    $t2, 0xFFFFFF89
    bne   $t1, $t2, fail_ls_3
    nop
    lbu   $t1, 4($t0)               # 0x89 -> 0x00000089
    li    $t2, 0x00000089
    bne   $t1, $t2, fail_ls_3
    nop

    # ----- 子用例4: SB / SH 字节/半字存储 -----
    # 错误码: 0xDEAD1604
    la    $t0, test_data_base
    addiu $t0, $t0, 12              # 指向预留的 0x00 区域
    # 字节存储
    li    $t1, 0x5A
    sb    $t1, 0($t0)
    lb    $t2, 0($t0)
    bne   $t2, $t1, fail_ls_4
    nop
    # 半字存储
    li    $t1, 0x1234
    sh    $t1, 2($t0)
    lh    $t2, 2($t0)
    bne   $t2, $t1, fail_ls_4
    nop
    # 恢复清零
    sw    $zero, 0($t0)

    # ===================== 非对齐访存 =====================

    # ----- 子用例5: LWL / LWR 组合非对齐加载 -----
    # 错误码: 0xDEAD1605
    la    $t0, unalign_data
    # 从地址 0x01 加载字 0xAABBCCDD（实际在大端下从0x00开始为 AA BB CC DD）
    # 非对齐加载预期结果：组合后仍为 0xAABBCCDD
    lwl   $t1, 0($t0)               # 从字节0取高位部分（取决于地址低2位）
    lwr   $t1, 3($t0)               # 从字节3取低位部分
    li    $t2, 0xAABBCCDD
    bne   $t1, $t2, fail_ls_5
    nop

# ----- 子用例6: SWL / SWR 组合非对齐存储（大端序，正确版）-----
# 错误码: 0xDEAD1606
    la    $t0, test_data_base
    addiu $t0, $t0, 12              # $t0 指向第4个 word (地址 = test_data_base+12, 初始值 0x00000000)
    li    $t1, 0xDEADBEEF

    # 将 $t1 非对齐存储到地址 $t0+1（覆盖 $t0+1 ~ $t0+4）
    swl   $t1, 4($t0)               # 写入 $t0+4(0xDE), $t0+3(0xAD), $t0+2(0xBE), $t0+1(0xEF)
    swr   $t1, 1($t0)               # 写入 $t0+1(0xEF), $t0+2(0xBE), $t0+3(0xAD), $t0+4(0xDE) → 覆盖后为 0xEF,0xBE,0xAD,0xDE

    # 从同一非对齐地址 $t0+1 读回
    lwl   $t2, 4($t0)               # 读 $t0+4(0xDE), $t0+3(0xAD), $t0+2(0xBE), $t0+1(0xEF) → 高24位
    lwr   $t2, 1($t0)               # 读 $t0+1(0xEF), $t0+2(0xBE), $t0+3(0xAD), $t0+4(0xDE) → 低8位并合并
    # $t2 恢复为 0xDEADBEEF

    bne   $t2, $t1, fail_ls_6
    nop

    # 恢复内存（清除写入的两个 word，避免影响后续测试）
    sw    $zero, 0($t0)             # 清除 $t0 ~ $t0+3
    sw    $zero, 4($t0)             # 清除 $t0+4 ~ $t0+7


    

    # ===================== LL/SC 原子操作 =====================

    # ----- 子用例7: LL / SC 成功场景 -----
    # 错误码: 0xDEAD1607
    la    $t0, ll_sc_var
    sw    $zero, 0($t0)             # 初始化为0
try_sc:
    ll    $t1, 0($t0)               # 加载链接
    addiu $t2, $t1, 5               # 加5
    sc    $t2, 0($t0)               # 条件存储
    beq   $t2, $zero, try_sc        # 失败则重试
    nop
    # 验证存储成功
    lw    $t3, 0($t0)
    li    $t4, 5
    bne   $t3, $t4, fail_ls_7
    nop

    # ----- 子用例8: SC 失败场景（LLbit 被另一个 sc 清除）-----
    # 错误码: 0xDEAD1608
    la    $t0, ll_sc_var
    sw    $zero, 0($t0)           # 初始化内存为 0
    la    $t5, unalign_data       # 使用一个无关地址

    ll    $t1, 0($t0)             # LLbit=1，链接地址 = ll_sc_var
    # 执行一个对无关地址的 sc，这会清除 LLbit
    sc    $zero, 0($t5)           # sc 失败（因为之前没有 ll 该地址），但会清除 LLbit
    nop

    li    $t2, 0x200
    sc    $t2, 0($t0)             # LLbit 已被清除，sc 应失败，$t2 返回 0
    bne   $t2, $zero, fail_ls_8
    nop

    # 验证内存未被 sc 修改
    lw    $t3, 0($t0)
    bne   $t3, $zero, fail_ls_8
    nop

    # ===================== 边界测试 =====================

    # ----- 子用例9: 偏移量极值测试（最大正偏移/负偏移）-----
    # 错误码: 0xDEAD1609
    la    $t0, test_data_base
    # 最大正偏移 (0x7FFF)
    lw    $t1, 0x7FFF($t0)          # 实际访问地址可能超出数据区，但指令本身应正确执行
    # 此测试仅验证指令格式，不检查数据内容（避免越界）
    # 使用零偏移的 lb 验证地址计算未受影响
    li    $t2, 0x12345678
    lw    $t3, 0($t0)
    bne   $t3, $t2, fail_ls_9
    nop

    # 最大负偏移 (0x8000，符号扩展后为 -32768)
    lw    $t1, -32768($t0)          # 同样仅验证指令不触发异常
    lw    $t3, 0($t0)
    bne   $t3, $t2, fail_ls_9
    nop

    # ----- 子用例10: 符号/零扩展边界测试（0x80 / 0x7F）-----
    # 错误码: 0xDEAD160A
    la    $t0, test_bytes
    # 存储边界字节
    li    $t1, 0x80
    sb    $t1, 0($t0)
    lb    $t2, 0($t0)               # 符号扩展 -> 0xFFFFFF80
    li    $t3, 0xFFFFFF80
    bne   $t2, $t3, fail_ls_10
    nop
    lbu   $t2, 0($t0)               # 零扩展 -> 0x00000080
    li    $t3, 0x00000080
    bne   $t2, $t3, fail_ls_10
    nop

    li    $t1, 0x7F
    sb    $t1, 0($t0)
    lb    $t2, 0($t0)               # 符号扩展 -> 0x0000007F
    li    $t3, 0x0000007F
    bne   $t2, $t3, fail_ls_10
    nop
    lbu   $t2, 0($t0)               # 零扩展 -> 0x0000007F
    bne   $t2, $t3, fail_ls_10
    nop

    # 恢复原字节
    li    $t1, 0x55
    sb    $t1, 0($t0)

    # ----- 子用例11: 半字符号/零扩展边界（0x8000 / 0x7FFF）-----
    # 错误码: 0xDEAD160B
    la    $t0, test_halfs
    li    $t1, 0x8000
    sh    $t1, 0($t0)
    lh    $t2, 0($t0)               # 符号扩展 -> 0xFFFF8000
    li    $t3, 0xFFFF8000
    bne   $t2, $t3, fail_ls_11
    nop
    lhu   $t2, 0($t0)               # 零扩展 -> 0x00008000
    li    $t3, 0x00008000
    bne   $t2, $t3, fail_ls_11
    nop

    li    $t1, 0x7FFF
    sh    $t1, 0($t0)
    lh    $t2, 0($t0)               # 符号扩展 -> 0x00007FFF
    li    $t3, 0x00007FFF
    bne   $t2, $t3, fail_ls_11
    nop
    lhu   $t2, 0($t0)               # 零扩展 -> 0x00007FFF
    bne   $t2, $t3, fail_ls_11
    nop

    # 恢复原半字
    li    $t1, 0x1122
    sh    $t1, 0($t0)

    # ----- 子用例12: 非对齐地址边界（地址低位全1）-----
    # 错误码: 0xDEAD160C
    la    $t0, unalign_data
    addiu $t0, $t0, 3               # 地址低位为 0b11
    li    $t1, 0xABCD1234
    swl   $t1, 0($t0)               # 非对齐存储（只写高字节）
    swr   $t1, 3($t0)               # 非对齐存储（写剩余部分）
    # 验证能正确读回组合字
    lwl   $t2, 0($t0)
    lwr   $t2, 3($t0)
    bne   $t2, $t1, fail_ls_12
    nop

    # ----- 子用例13: LL/SC 边界地址及链接失效-----
    # 错误码: 0xDEAD160D
    la    $t0, ll_sc_var
    la    $t5, unalign_data       # 无关地址，用于清除 LLbit
    sw    $zero, 0($t0)           # 初始化内存为 0

    ll    $t1, 0($t0)             # LLbit=1，链接地址 = ll_sc_var
    # 用另一个 sc 清除 LLbit（即使地址不匹配，sc 也会清除 LLbit）
    sc    $zero, 0($t5)           # sc 失败，但会清除 LLbit
    nop

    li    $t2, 0x1234
    sc    $t2, 0($t0)             # LLbit 已清除，sc 应失败，$t2 返回 0
    bne   $t2, $zero, fail_ls_13
    nop

    # 确保内存未被 sc 修改
    lw    $t3, 0($t0)
    bne   $t3, $zero, fail_ls_13
    nop
    # 全部通过，返回
    .set reorder
    jr    $ra
    nop



# ----- 失败跳转点 (0xDEAD1601 ~ 0xDEAD1608) -----
fail_ls_1:   li $a0, 0xDEAD1601; jal report_result; nop
fail_ls_2:   li $a0, 0xDEAD1602; jal report_result; nop
fail_ls_3:   li $a0, 0xDEAD1603; jal report_result; nop
fail_ls_4:   li $a0, 0xDEAD1604; jal report_result; nop
fail_ls_5:   li $a0, 0xDEAD1605; jal report_result; nop
fail_ls_6:   li $a0, 0xDEAD1606; jal report_result; nop
fail_ls_7:   li $a0, 0xDEAD1607; jal report_result; nop
fail_ls_8:   li $a0, 0xDEAD1608; jal report_result; nop
# ----- 新增失败跳转点 (0xDEAD1609 ~ 0xDEAD160D) -----
fail_ls_9:   li $a0, 0xDEAD1609; jal report_result; nop
fail_ls_10:  li $a0, 0xDEAD160A; jal report_result; nop
fail_ls_11:  li $a0, 0xDEAD160B; jal report_result; nop
fail_ls_12:  li $a0, 0xDEAD160C; jal report_result; nop
fail_ls_13:  li $a0, 0xDEAD160D; jal report_result; nop

# ============================================================
# 模块测试：CP0（协处理器0寄存器访问及异常处理）
# 错误码前缀：0xDEAD1800
# 说明：
#   - 第一阶段：基本读写与冒险测试（无需异常处理）
#   - 第二阶段：Count 自增测试（无需异常处理）
#   - 第三阶段：定时中断测试（需要异常处理，可先注释）
# ============================================================
test_cp0:
    .set noreorder

    # ===================== 第一阶段：基本读写与冒险 =====================

    # ----- 子用例1: MTC0 / MFC0 Compare寄存器基本读写 -----
    # 错误码: 0xDEAD1801
    # Compare 寄存器 (rd=$11, sel=0) 可读写
    li    $t0, 0x12345678
    mtc0  $t0, $11, 0
    mfc0  $t1, $11, 0
    bne   $t0, $t1, fail_cp0_1
    nop
    # 写入另一个值验证
    li    $t0, 0xAAAAAAAA
    mtc0  $t0, $11, 0
    mfc0  $t1, $11, 0
    bne   $t0, $t1, fail_cp0_1
    nop

    # ----- 子用例2: MTC0 / MFC0 Status寄存器基本读写 -----
    # 错误码: 0xDEAD1802
    # Status 寄存器 (rd=$12, sel=0) 部分字段可读写，测试可写位
    # 注意：Status 中 IM[7:0] 和 IE 等位可写，CU0 等只读，写入后读回可能不同
    # 这里只验证可写位能够写入并读回
    mfc0  $t0, $12, 0             # 保存原值
    li    $t1, 0x0000FF01         # 设置 IM[7:0]=0xFF, IE=1
    mtc0  $t1, $12, 0
    mfc0  $t2, $12, 0
    andi  $t2, $t2, 0x0000FF01    # 屏蔽只读位
    bne   $t2, $t1, fail_cp0_2
    nop
    mtc0  $t0, $12, 0             # 恢复原值

    # ----- 子用例3: 冒险测试（MTC0 后紧接 MFC0 同一寄存器）-----
    # 错误码: 0xDEAD1803
    li    $t0, 0x5A5A5A5A
    mtc0  $t0, $11, 0
    # 无任何 nop，直接读取，验证转发或互锁
    mfc0  $t1, $11, 0
    bne   $t0, $t1, fail_cp0_3
    nop

    # ----- 子用例4: 不同 CP0 寄存器独立性 -----
    # 错误码: 0xDEAD1804
    li    $t0, 0x11111111
    li    $t1, 0x22222222
    mtc0  $t0, $11, 0             # 写 Compare
    mtc0  $t1, $12, 0             # 写 Status（可写位）
    mfc0  $t2, $11, 0
    bne   $t2, $t0, fail_cp0_4
    nop
    # 恢复 Status（清零可写位，根据实际实现调整）
    mfc0  $t3, $12, 0
    li    $t4, 0xFFFF0000         # 用 li 加载掩码（汇编器会展开为 lui+addiu）
    and   $t3, $t3, $t4           # 保留高16位，清零低16位
    mtc0  $t3, $12, 0

    # ===================== 第二阶段：Count 自增测试 =====================

    # ----- 子用例5: Count 寄存器可读且随时间递增 -----
    # 错误码: 0xDEAD1805
    # 注意：Count 寄存器不可写，只能读取
    mfc0  $t0, $9, 0              # 第一次读取 Count
    # 插入若干指令消耗时间
    li    $t1, 100
1:  addiu $t1, $t1, -1
    bne   $t1, $zero, 1b
    nop
    mfc0  $t1, $9, 0              # 第二次读取 Count
    subu  $t2, $t1, $t0
    # 差值应大于 0（实际可能很大，这里简单验证非零）
    beq   $t2, $zero, fail_cp0_5
    nop

    # ===================== 第三阶段：定时中断测试 =====================
    # 以下测试需要完整的异常处理机制（异常向量、EPC、Cause、eret 等）
    # 如果尚未实现，可以将整个第三阶段注释掉，不影响前两阶段运行。

.if 0   # 将此处的 0 改为 1 以启用第三阶段测试

    # ----- 子用例6: 定时中断触发与响应 -----
    # 错误码: 0xDEAD1806
    # 配置 Compare 触发中断，等待中断发生，在异常处理程序中验证并返回
    # 此处需要预先安装异常处理程序，或假设 CPU 已有默认向量
    # 简化版：直接读取 Cause 寄存器判断是否发生中断

    # 先禁止中断，清除 Cause 中 IP 位
    mfc0  $t0, $12, 0
    li    $t0, 0xFFFF00FF   # 清零 IE 和 IM 位
    mtc0  $t0, $12, 0

    # 设置 Compare 为一个较小的未来值
    mfc0  $t0, $9, 0             # 读取当前 Count
    li $t0, 500          # 期望在 500 周期后触发
    mtc0  $t0, $11, 0

    # 清除 Cause 中的 IP[7]（定时器中断位）
    mfc0  $t1, $13, 0
    li    $t2, 0xFFFF7FFF
    and   $t1, $t1, $t2
    mtc0  $t1, $13, 0

    # 使能中断：Status.IE=1, IM[7]=1
    mfc0  $t0, $12, 0
    ori   $t0, $t0, 0x00008001
    mtc0  $t0, $12, 0

    # 等待中断发生（循环直到 Cause.IP7=1）
wait_int:
    mfc0  $t1, $13, 0
    andi  $t1, $t1, 0x00008000   # IP7 位
    beq   $t1, $zero, wait_int
    nop

    # 中断已触发，验证 Cause.ExcCode 应为 0（硬件中断）
    mfc0  $t2, $13, 0
    srl   $t2, $t2, 2
    andi  $t2, $t2, 0x1F
    bne   $t2, $zero, fail_cp0_6   # 应为硬件中断码 0
    nop

    # 清除中断并返回（实际需要 eret，这里只做功能验证）
    # 恢复 Status
    mfc0  $t0, $12, 0
    li $t0, 0xFFFF7FFE
    mtc0  $t0, $12, 0

    # ----- 子用例7: EPC 寄存器读写 -----
    # 错误码: 0xDEAD1807
    # EPC ($14) 在异常发生时保存返回地址，也可直接读写
    la    $t0, epc_test_label
    mtc0  $t0, $14, 0
    mfc0  $t1, $14, 0
    bne   $t0, $t1, fail_cp0_7
    nop
epc_test_label:
    nop

    # ----- 子用例8: Cause 寄存器字段读写 -----
    # 错误码: 0xDEAD1808
    # Cause 中只有部分字段可写（如 IP[1:0] 软件中断位），测试写入 IP1
    mfc0  $t0, $13, 0
    ori   $t0, $t0, 0x00000200   # 设置 IP1
    mtc0  $t0, $13, 0
    mfc0  $t1, $13, 0
    andi  $t1, $t1, 0x00000200
    beq   $t1, $zero, fail_cp0_8
    nop
    # 恢复
    mfc0  $t0, $13, 0
    li    $t2, 0xFFFFFDFF
    and   $t0, $t0, $t2
    mtc0  $t0, $13, 0

.endif  # 第三阶段结束

    # 全部通过，返回
    .set reorder
    jr    $ra
    nop

# ----- 失败跳转点 (0xDEAD1801 ~ 0xDEAD1808) -----
fail_cp0_1:   li $a0, 0xDEAD1801; jal report_result; nop
fail_cp0_2:   li $a0, 0xDEAD1802; jal report_result; nop
fail_cp0_3:   li $a0, 0xDEAD1803; jal report_result; nop
fail_cp0_4:   li $a0, 0xDEAD1804; jal report_result; nop
fail_cp0_5:   li $a0, 0xDEAD1805; jal report_result; nop
fail_cp0_6:   li $a0, 0xDEAD1806; jal report_result; nop
fail_cp0_7:   li $a0, 0xDEAD1807; jal report_result; nop
fail_cp0_8:   li $a0, 0xDEAD1808; jal report_result; nop

# ============================================================
# 模块测试：异常处理机制
# 错误码前缀：0xDEAD1800
# 说明：
#   - 测试系统调用、自陷指令、溢出异常是否能正确触发并返回
#   - 若异常未触发或处理程序未返回，则跳转到对应失败标签
# ============================================================
test_exception:
    .set noreorder

    # ------------------------------------------------------------
    # 重新初始化 CP0，确保异常使能
    # ------------------------------------------------------------
    # Status 寄存器：设置 IM[7:0]=0xFF, IE=1，使能所有中断和异常
    li    $t0, 0x0000FF01
    mtc0  $t0, $12, 0
    # 清除 Cause 寄存器中的残余状态
    mtc0  $zero, $13, 0

    # ----- 测试1: syscall -----
    # 错误码: 0xDEAD1809
    la    $t0, syscall_flag
    sw    $zero, 0($t0)
    li    $v0, 1
    syscall
    nop
    la    $t0, syscall_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_1
    nop

    # ----- 测试2: teq -----
    # 错误码: 0xDEAD180A
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, 5
    li    $t2, 5
    teq   $t1, $t2
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_2
    nop

    # ----- 测试3: tne -----
    # 错误码: 0xDEAD180B
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, 1
    li    $t2, 2
    tne   $t1, $t2
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_3
    nop

    # ----- 测试4: tge -----
    # 错误码: 0xDEAD180C
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, 5
    li    $t2, 3
    tge   $t1, $t2
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_4
    nop

    # ----- 测试5: tgeu -----
    # 错误码: 0xDEAD180D
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, -1
    li    $t2, 1
    tgeu  $t1, $t2
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_5
    nop

    # ----- 测试6: tlt -----
    # 错误码: 0xDEAD180E
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, 2
    li    $t2, 5
    tlt   $t1, $t2
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_6
    nop

    # ----- 测试7: tltu -----
    # 错误码: 0xDEAD180F
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, 1
    li    $t2, 0x80000000
    tltu  $t1, $t2
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_7
    nop

    # ----- 测试8: teqi -----
    # 错误码: 0xDEAD1810
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, 0x1234
    teqi  $t1, 0x1234
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_8
    nop

    # ----- 测试9: tnei -----
    # 错误码: 0xDEAD1811
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, 0x1234
    tnei  $t1, 0x5678
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_9
    nop

    # ----- 测试10: tgei -----
    # 错误码: 0xDEAD1812
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, 10
    tgei  $t1, 5
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_10
    nop

    # ----- 测试11: tgeiu -----
    # 错误码: 0xDEAD1813
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, -1
    tgeiu $t1, 0x8000
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_11
    nop

    # ----- 测试12: tlti -----
    # 错误码: 0xDEAD1814
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, 3
    tlti  $t1, 10
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_12
    nop

    # ----- 测试13: tltiu (使用寄存器形式) -----
    # 错误码: 0xDEAD1815
    la    $t0, trap_flag
    sw    $zero, 0($t0)
    li    $t1, 0x100
    li    $t2, 0x80000000
    tltu  $t1, $t2
    nop
    la    $t0, trap_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_13
    nop

    # ----- 测试14: 溢出异常 (add) -----
    # 错误码: 0xDEAD1816
    la    $t0, ov_flag
    sw    $zero, 0($t0)
    li    $t1, 0x7FFFFFFF
    li    $t2, 0x7FFFFFFF
    add   $t3, $t1, $t2
    nop
    la    $t0, ov_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_14
    nop

    # ----- 测试15: 溢出异常 (addi) -----
    # 错误码: 0xDEAD1817
    la    $t0, ov_flag
    sw    $zero, 0($t0)
    li    $t1, 0x7FFFFFFF
    addi  $t2, $t1, 1
    nop
    la    $t0, ov_flag
    lw    $t1, 0($t0)
    li    $t2, 1
    bne   $t1, $t2, fail_exception_15
    nop

    .set reorder
    jr    $ra
    nop

# ============================================================
# 失败跳转点（错误码 0xDEAD1809 ~ 0xDEAD1817）
# ============================================================
fail_exception_1:   li $a0, 0xDEAD1809; jal report_result; nop
fail_exception_2:   li $a0, 0xDEAD180A; jal report_result; nop
fail_exception_3:   li $a0, 0xDEAD180B; jal report_result; nop
fail_exception_4:   li $a0, 0xDEAD180C; jal report_result; nop
fail_exception_5:   li $a0, 0xDEAD180D; jal report_result; nop
fail_exception_6:   li $a0, 0xDEAD180E; jal report_result; nop
fail_exception_7:   li $a0, 0xDEAD180F; jal report_result; nop
fail_exception_8:   li $a0, 0xDEAD1810; jal report_result; nop
fail_exception_9:   li $a0, 0xDEAD1811; jal report_result; nop
fail_exception_10:  li $a0, 0xDEAD1812; jal report_result; nop
fail_exception_11:  li $a0, 0xDEAD1813; jal report_result; nop
fail_exception_12:  li $a0, 0xDEAD1814; jal report_result; nop
fail_exception_13:  li $a0, 0xDEAD1815; jal report_result; nop
fail_exception_14:  li $a0, 0xDEAD1816; jal report_result; nop
fail_exception_15:  li $a0, 0xDEAD1817; jal report_result; nop


# ============================================================
# 模块测试：NOP / SSNOP / SYNC / PREF (空操作指令)
# 错误码前缀：0xDEAD1400 (沿用 arith 前缀，从 0xDEAD1412 开始)
# ============================================================
test_nop_sync:
    .set noreorder

    # ----- 子用例1: NOP 指令无副作用 -----
    # 错误码: 0xDEAD1412
    li    $t0, 0x12345678
    li    $t1, 0x9ABCDEF0
    nop                        # 纯空操作
    nop
    bne   $t0, $t1, 1f         # 故意用不相等比较，若寄存器被破坏则可能意外相等
    nop
    j     fail_nop_1
    nop
1:
    # 验证 $t0 和 $t1 保持原值
    li    $t2, 0x12345678
    bne   $t0, $t2, fail_nop_1
    nop
    li    $t3, 0x9ABCDEF0
    bne   $t1, $t3, fail_nop_1
    nop

    # ----- 子用例2: SSNOP 指令 (与 NOP 行为相同) -----
    # 错误码: 0xDEAD1413
    li    $t0, 0x5A5A5A5A
    li    $t1, 0xA5A5A5A5
    ssnop                      # 编译为 sll $0, $0, 1
    bne   $t0, $t1, 1f
    nop
    j     fail_nop_2
    nop
1:
    li    $t2, 0x5A5A5A5A
    bne   $t0, $t2, fail_nop_2
    nop
    li    $t3, 0xA5A5A5A5
    bne   $t1, $t3, fail_nop_2
    nop

    # ----- 子用例3: SYNC 指令 (空操作) -----
    # 错误码: 0xDEAD1414
    li    $t0, 0x11112222
    li    $t1, 0x33334444
    sync                       # 在 OpenMIPS 中应被视为 nop
    bne   $t0, $t1, 1f
    nop
    j     fail_nop_3
    nop
1:
    li    $t2, 0x11112222
    bne   $t0, $t2, fail_nop_3
    nop
    li    $t3, 0x33334444
    bne   $t1, $t3, fail_nop_3
    nop

    # ----- 子用例4: PREF 指令 (空操作) -----
    # 错误码: 0xDEAD1415
    li    $t0, 0xAAAA5555
    li    $t1, 0x5555AAAA
    # PREF 格式: pref hint, offset(base)
    # 使用无害的预取提示 (hint=0) 和有效地址
    la    $t4, test_data_base
    pref   0, 0($t4)           # 应被忽略，不产生异常
    nop
    bne   $t0, $t1, 1f
    nop
    j     fail_nop_4
    nop
1:
    li    $t2, 0xAAAA5555
    bne   $t0, $t2, fail_nop_4
    nop
    li    $t3, 0x5555AAAA
    bne   $t1, $t3, fail_nop_4
    nop

    # 全部通过
    .set reorder
    jr    $ra
    nop

# ----- 失败跳转点 -----
fail_nop_1:   li $a0, 0xDEAD1412; jal report_result; nop
fail_nop_2:   li $a0, 0xDEAD1413; jal report_result; nop
fail_nop_3:   li $a0, 0xDEAD1414; jal report_result; nop
fail_nop_4:   li $a0, 0xDEAD1415; jal report_result; nop




# ============================================================
# 模块测试：流水线机制（延迟槽、前推、互锁、冲刷）
# 错误码前缀：0xDEAD1900
# ============================================================
test_pipeline:
    .set noreorder

    # ===================== 延迟槽测试 =====================

    # ----- 子用例1: 延迟槽 - 分支发生 -----
    # 错误码: 0xDEAD1901
    li    $t0, 0x100
    li    $t1, 0x100
    beq   $t0, $t1, 1f
    addiu $t0, $t0, 0x111       # 延迟槽：t0 = 0x211
    j     fail_pipeline_1
    nop
1:
    li    $t2, 0x211
    bne   $t0, $t2, fail_pipeline_1
    nop

    # ----- 子用例2: 延迟槽 - 分支不发生 -----
    # 错误码: 0xDEAD1902
    li    $t0, 0x100
    li    $t1, 0x200
    beq   $t0, $t1, 2f
    addiu $t0, $t0, 0x111       # 延迟槽：t0 = 0x211（必须执行）
    j     3f
    nop
2:  # 意外跳转
    j     fail_pipeline_2
    nop
3:
    li    $t2, 0x211
    bne   $t0, $t2, fail_pipeline_2
    nop


addiu $sp, $sp, -4
sw    $ra, 0($sp)
    # ----- 子用例3: 延迟槽 - 跳转并链接 -----
    # 错误码: 0xDEAD1903
    li    $t0, 0x55
    jal   delay_slot_target
    addiu $t0, $t0, 0x11        # 延迟槽：t0 = 0x66
    # 返回后检查 t0
    li    $t1, 0x66
    bne   $t0, $t1, fail_pipeline_3
    nop
    j     delay_slot_done
    nop

delay_slot_target:
    # 验证 $ra 有效，并检查 t0 已被延迟槽修改
    li    $t2, 0x66
    bne   $t0, $t2, fail_pipeline_3
    nop
    jr    $ra
    nop
delay_slot_done:
lw    $ra, 0($sp)
addiu $sp, $sp, 4

    # ===================== 数据前推测试 =====================

    # ----- 子用例4: EX 冒险 (ALU -> ALU) -----
    # 错误码: 0xDEAD1904
    li    $t0, 5
    addiu $t1, $t0, 5           # t1 = 10
    addu  $t2, $t1, $t0         # t2 = 10 + 5 = 15
    li    $t3, 15
    bne   $t2, $t3, fail_pipeline_4
    nop

    # ----- 子用例5: MEM 冒险 (Load -> ALU) -----
    # 错误码: 0xDEAD1905
    la    $t0, test_data_base   # 数据段中预置 0x12345678
    lw    $t1, 0($t0)           # t1 = 0x12345678
    addiu $t2, $t1, 1           # t2 = 0x12345679
    li    $t3, 0x12345679
    bne   $t2, $t3, fail_pipeline_5
    nop

    # ----- 子用例6: HI/LO 冒险 (MTHI -> MFHI) -----
    # 错误码: 0xDEAD1906
    li    $t0, 0x12345678
    mthi  $t0
    mfhi  $t1
    bne   $t1, $t0, fail_pipeline_6
    nop

    # ----- 子用例7: 多重 HI/LO 冒险 -----
    # 错误码: 0xDEAD1907
    li    $t0, 0x11112222
    li    $t1, 0x33334444
    mthi  $t0
    mtlo  $t1
    mfhi  $t2
    mflo  $t3
    bne   $t2, $t0, fail_pipeline_7
    bne   $t3, $t1, fail_pipeline_7
    nop

    # ===================== Load-Use 互锁测试 =====================

    # ----- 子用例8: LW 后紧接依赖指令 -----
    # 错误码: 0xDEAD1908
    la    $t0, test_data_base
    lw    $t1, 0($t0)           # 加载 0x12345678
    addiu $t2, $t1, 1           # 依赖 t1，硬件应插入一个气泡
    li    $t3, 0x12345679
    bne   $t2, $t3, fail_pipeline_8
    nop

    # ===================== 流水线冲刷测试 =====================

    # ----- 子用例9: 分支成立时冲刷错误路径指令 -----
    # 错误码: 0xDEAD1909
    li    $t0, 5
    li    $t1, 5
    li    $t5, 0                # t5 初始为 0
    beq   $t0, $t1, 1f
    nop
    addiu $t5, $t5, 1           # 错误路径：若未冲刷，t5 会变为 1
    # 若未跳转，失败
    j     fail_pipeline_9
    nop
1:
    # 验证 t5 仍为 0（冲刷成功）
    bne   $t5, $zero, fail_pipeline_9
    nop

    # ----- 子用例10: 分支不成立时不冲刷（验证正确路径执行）-----
    # 错误码: 0xDEAD190A
    li    $t0, 5
    li    $t1, 6
    li    $t5, 0
    beq   $t0, $t1, 2f
    addiu $t5, $t5, 1           # 正确路径：应执行，t5 变为 1
    j     3f
    nop
2:  # 意外跳转
    j     fail_pipeline_10
    nop
3:
    li    $t6, 1
    bne   $t5, $t6, fail_pipeline_10
    nop

    # 全部通过
    .set reorder
    jr    $ra
    nop

# ============================================================
# 失败跳转点 (0xDEAD1901 ~ 0xDEAD190A)
# ============================================================
fail_pipeline_1:  li $a0, 0xDEAD1901; jal report_result; nop
fail_pipeline_2:  li $a0, 0xDEAD1902; jal report_result; nop
fail_pipeline_3:  li $a0, 0xDEAD1903; jal report_result; nop
fail_pipeline_4:  li $a0, 0xDEAD1904; jal report_result; nop
fail_pipeline_5:  li $a0, 0xDEAD1905; jal report_result; nop
fail_pipeline_6:  li $a0, 0xDEAD1906; jal report_result; nop
fail_pipeline_7:  li $a0, 0xDEAD1907; jal report_result; nop
fail_pipeline_8:  li $a0, 0xDEAD1908; jal report_result; nop
fail_pipeline_9:  li $a0, 0xDEAD1909; jal report_result; nop
fail_pipeline_10: li $a0, 0xDEAD190A; jal report_result; nop




# ============================================================
# 模块测试：定时器中断完整响应流程
# 错误码前缀：0xDEAD1A00
# ============================================================
test_timer_interrupt:
    .set noreorder
    # ------------------ 1. 初始化 CP0 和定时器 ------------------
    # Status: IE=1, IM0=1 (定时器中断掩码)
    li    $t0, 0x00000401          # bit 10 和 bit 0 置 1
    mtc0  $t0, $12

    # 清除 Cause 残余
    mtc0  $zero, $13

    # 设置 Compare 为当前 Count + 较小值（例如 +200 周期）
    mfc0  $t0, $9               # 读 Count
    addiu $t0, $t0, 200         # 200 周期后触发中断
    mtc0  $t0, $11

    # ------------------ 2. 清标志，等待中断 ------------------
    la    $t0, timer_int_flag
    sw    $zero, 0($t0)

    # 循环等待，直到标志被中断处理程序置 1
wait_timer:
    lw    $t1, 0($t0)
    beq   $t1, $zero, wait_timer
    nop

    # ------------------ 3. 验证标志被正确置位 ------------------
    li    $t2, 1
    bne   $t1, $t2, fail_timer_int
    nop

    # ------------------ 4. 再次触发：验证中断连续响应 ------------------
    # 错误码: 0xDEAD1A02 (可选，若第二次失败则单独上报)
    # 清标志
    la    $t0, timer_int_flag
    sw    $zero, 0($t0)

    # 重新配置 Compare，触发第二次中断
    mfc0  $t0, $9               # 读当前 Count
    addiu $t0, $t0, 200         # 200 周期后再次触发
    mtc0  $t0, $11

    # 确保 Status 仍然使能中断（如果之前未关闭）
    li    $t0, 0x00000401
    mtc0  $t0, $12

    # 等待第二次中断
wait_timer2:
    la    $t0, timer_int_flag
    lw    $t1, 0($t0)
    beq   $t1, $zero, wait_timer2
    nop

    # 验证第二次标志被正确置位
    lw    $t1, 0($t0)           # 再次加载，确保不是偶然
    li    $t2, 1
    bne   $t1, $t2, fail_timer_int2
    nop

    # 关闭中断
    li    $t0, 0x00000000
    mtc0  $t0, $12

    # 通过
    .set reorder
    jr    $ra
    nop

fail_timer_int:
    li    $a0, 0xDEAD1A01
    jal   report_result
    nop
fail_timer_int2:
    li    $a0, 0xDEAD1A02
    jal   report_result
    nop













# ============================================================
# 异常处理主入口
# ============================================================
    .globl _exception_entry
    .set   noat

_exception_entry:
    addiu  $sp, $sp, -128

    sw     $at,   0($sp)
    sw     $v0,   4($sp)
    sw     $v1,   8($sp)
    sw     $a0,  12($sp)
    sw     $a1,  16($sp)
    sw     $a2,  20($sp)
    sw     $a3,  24($sp)
    sw     $t0,  28($sp)
    sw     $t1,  32($sp)
    sw     $t2,  36($sp)
    sw     $t3,  40($sp)
    sw     $t4,  44($sp)
    sw     $t5,  48($sp)
    sw     $t6,  52($sp)
    sw     $t7,  56($sp)
    sw     $s0,  60($sp)
    sw     $s1,  64($sp)
    sw     $s2,  68($sp)
    sw     $s3,  72($sp)
    sw     $s4,  76($sp)
    sw     $s5,  80($sp)
    sw     $s6,  84($sp)
    sw     $s7,  88($sp)
    sw     $t8,  92($sp)
    sw     $t9,  96($sp)
    sw     $gp, 100($sp)
    sw     $fp, 104($sp)
    sw     $ra, 108($sp)

    mfc0   $k0, $13
    srl    $k1, $k0, 2
    andi   $k1, $k1, 0x1f

    li     $t0, 0x00
    beq    $k1, $t0, _int_handler
    nop

    li     $t0, 0x08
    beq    $k1, $t0, _syscall_handler
    nop

    li     $t0, 0x0d
    beq    $k1, $t0, _trap_handler
    nop

    li     $t0, 0x0c
    beq    $k1, $t0, _ov_handler
    nop

    li     $t0, 0x0a
    beq    $k1, $t0, _invalid_instr_handler
    nop

_unknown_exception:
    j      _unknown_exception
    nop

_int_handler:
    # 检查是否为定时器中断（Cause.IP0，位 10）
    mfc0  $k0, $13
    andi  $k0, $k0, 0x00000400    # IP0 (bit 10)
    beq   $k0, $zero, 1f
    nop

    # 是定时器中断：设置标志
    la    $k1, timer_int_flag
    li    $k0, 1
    sw    $k0, 0($k1)

    # 清除定时器中断：写 Compare 推迟下次中断，同时写 Cause.IP0 清零
    mfc0  $k0, $9                 # 读 Count
    addiu $k0, $k0, 1000          # 推迟 1000 周期
    mtc0  $k0, $11                # 写 Compare

    # 清除 Cause.IP0（写 1 清零）
    mfc0  $k0, $13
    ori   $k0, $k0, 0x00000400    # IP0 写 1 清零
    mtc0  $k0, $13

1:
    j     _exception_return
    nop

_syscall_handler:
    li    $t0, 1
    bne   $v0, $t0, 1f
    nop
    la    $t1, syscall_flag
    li    $t2, 1
    sw    $t2, 0($t1)
1:
    jal   _advance_epc
    nop
    j     _exception_return
    nop

_trap_handler:
    la    $t1, trap_flag
    li    $t2, 1
    sw    $t2, 0($t1)
    jal   _advance_epc
    nop
    j     _exception_return
    nop

_ov_handler:
    la    $t1, ov_flag
    li    $t2, 1
    sw    $t2, 0($t1)
    jal   _advance_epc
    nop
    j     _exception_return
    nop

_invalid_instr_handler:
    jal    _advance_epc
    nop
    j      _exception_return
    nop

_advance_epc:
    mfc0   $k0, $14          # EPC
    mfc0   $k1, $13          # Cause
    srl    $t0, $k1, 31      # BD

    beq    $t0, $zero, 1f
    nop
    addiu  $k0, $k0, 8
    b      2f
    nop

1:
    addiu  $k0, $k0, 4
2:
    mtc0   $k0, $14
    jr     $ra
    nop

_exception_return:
    lw     $at,   0($sp)
    lw     $v0,   4($sp)
    lw     $v1,   8($sp)
    lw     $a0,  12($sp)
    lw     $a1,  16($sp)
    lw     $a2,  20($sp)
    lw     $a3,  24($sp)
    lw     $t0,  28($sp)
    lw     $t1,  32($sp)
    lw     $t2,  36($sp)
    lw     $t3,  40($sp)
    lw     $t4,  44($sp)
    lw     $t5,  48($sp)
    lw     $t6,  52($sp)
    lw     $t7,  56($sp)
    lw     $s0,  60($sp)
    lw     $s1,  64($sp)
    lw     $s2,  68($sp)
    lw     $s3,  72($sp)
    lw     $s4,  76($sp)
    lw     $s5,  80($sp)
    lw     $s6,  84($sp)
    lw     $s7,  88($sp)
    lw     $t8,  92($sp)
    lw     $t9,  96($sp)
    lw     $gp, 100($sp)
    lw     $fp, 104($sp)
    lw     $ra, 108($sp)

    addiu  $sp, $sp, 128
    eret

    .set   at