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
    # 后续模块测试调用暂时注释，待逐个添加
     jal   test_move
     nop
     jal   test_arith
     nop
     jal   test_branch
     nop
    # jal   test_load_store
    # nop
     jal   test_hilo
     nop
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
# 模块测试：Logic（细化版）ba
# 错误码前缀：0xDEAD1100
# ============================================================
test_logic:
# =====================基本功能===========================
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

    # ----- 子用例15: ADD 溢出 (正数溢出) -----
    // # 注意：若CPU支持异常则可能跳转，这里只测结果是否不破坏目标寄存器（或触发异常机制）
    // # 如果异常未实现，则只验证计算值；若实现异常，此处需配合异常处理测试。
    // # 错误码: 0xDEAD140F
    // li    $t0, 0x7FFFFFFF
    // li    $t1, 0x7FFFFFFF
    // add   $t2, $t0, $t1
    // # 溢出时，根据MIPS规范，结果未定义，但通常为模2^32结果：0xFFFFFFFE
    // # 这里仅作为边界用例占位，可根据实际实现调整
    // li    $t3, 0xFFFFFFFE
    // bne   $t2, $t3, fail_arith_15
    // nop

    // # ----- 子用例16: SUB 溢出 (负数溢出) -----
    // # 错误码: 0xDEAD1410
    // li    $t0, 0x80000000
    // li    $t1, 1
    // sub   $t2, $t0, $t1
    // li    $t3, 0x7FFFFFFF
    // bne   $t2, $t3, fail_arith_16
    // nop

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
    # ===================== 基本对齐访存 =====================

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

    # ----- 子用例6: SWL / SWR 组合非对齐存储 -----
    # 错误码: 0xDEAD1606
    la    $t0, test_data_base
    addiu $t0, $t0, 12              # 使用预留区域
    li    $t1, 0xDEADBEEF
    swl   $t1, 1($t0)               # 非对齐存储高位
    swr   $t1, 4($t0)               # 非对齐存储低位
    # 验证：读回组合后的字
    lw    $t2, 0($t0)
    bne   $t2, $t1, fail_ls_6
    nop
    sw    $zero, 0($t0)             # 恢复

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

    # ----- 子用例8: SC 失败场景（LLbit 被清除）-----
    # 错误码: 0xDEAD1608
    la    $t0, ll_sc_var
    li    $t1, 0x100
    sw    $t1, 0($t0)               # 写入初始值
    ll    $t2, 0($t0)               # 设置 LLbit
    # 故意用普通存储破坏链接
    sw    $zero, 0($t0)
    li    $t3, 0x200
    sc    $t3, 0($t0)               # 应失败，$t3 返回 0
    bne   $t3, $zero, fail_ls_8
    nop
    # 验证内存未被修改
    lw    $t4, 0($t0)
    bne   $t4, $zero, fail_ls_8
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
    # 地址非对齐访问（SC应失败或触发异常，此处仅验证不影响后续）
    # 先正常初始化
    sw    $zero, 0($t0)
    # 故意在非对齐地址执行 LL（若硬件支持非对齐LL，则测试其行为）
    ll    $t1, 0($t0)
    # 用普通存储破坏
    sw    $zero, 0($t0)
    li    $t2, 0x1234
    sc    $t2, 0($t0)               # 应失败
    bne   $t2, $zero, fail_ls_13
    nop
    # 确保内存未被修改
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

