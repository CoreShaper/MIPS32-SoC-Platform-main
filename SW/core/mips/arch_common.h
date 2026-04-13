// core/mips/arch_common.h
// MIPS 架构相关常量（严格匹配 OpenMIPS RTL 实现）

#ifndef CORE_MIPS_ARCH_COMMON_H
#define CORE_MIPS_ARCH_COMMON_H

// ------------------------------------------------------------
// 异常类型码（ExcCode，来自 Cause[6:2]）
// ------------------------------------------------------------
#define EXC_INT         0x00    // 中断（硬件或软件）
#define EXC_SYSCALL     0x08    // 系统调用
#define EXC_RI          0x0A    // 无效指令
#define EXC_OV          0x0C    // 算术溢出
#define EXC_TRAP        0x0D    // 自陷

// ------------------------------------------------------------
// Status 寄存器位域（CP0 Register 12, sel 0）
// ------------------------------------------------------------
#define STATUS_IE       0x00000001  // 全局中断使能（bit 0，可写）
#define STATUS_EXL      0x00000002  // 异常级（bit 1，硬件自动管理）

// 中断屏蔽位 IM[7:0] 位于 bits 15:8
#define STATUS_IM0      0x00000100  // 软件中断屏蔽位 0（bit 8，可写）
#define STATUS_IM1      0x00000200  // 软件中断屏蔽位 1（bit 9，可写）
#define STATUS_IM2      0x00000400  // 硬件中断屏蔽位 2，对应 int_i[0]（bit 10，可写）
#define STATUS_IM3      0x00000800  // 硬件中断屏蔽位 3，对应 int_i[1]（bit 11，可写）
#define STATUS_IM4      0x00001000  // 硬件中断屏蔽位 4，对应 int_i[2]（bit 12，可写）
#define STATUS_IM5      0x00002000  // 硬件中断屏蔽位 5，对应 int_i[3]（bit 13，可写）
#define STATUS_IM6      0x00004000  // 硬件中断屏蔽位 6，对应 int_i[4]（bit 14，可写）
#define STATUS_IM7      0x00008000  // 硬件中断屏蔽位 7，对应 int_i[5]（bit 15，可写）

// 常用组合
#define STATUS_IM_SOFT  (STATUS_IM0 | STATUS_IM1)
#define STATUS_IM_HARD  (STATUS_IM2 | STATUS_IM3 | STATUS_IM4 | STATUS_IM5 | STATUS_IM6 | STATUS_IM7)
#define STATUS_IM_ALL   (STATUS_IM_SOFT | STATUS_IM_HARD)

// ------------------------------------------------------------
// Cause 寄存器位域（CP0 Register 13, sel 0）
// ------------------------------------------------------------
#define CAUSE_BD        0x80000000  // 延迟槽指示（bit 31，只读）

// 中断挂起位 IP[7:0] 位于 bits 15:8
#define CAUSE_IP0       0x00000100  // 软件中断挂起位 0（bit 8，可读写）
#define CAUSE_IP1       0x00000200  // 软件中断挂起位 1（bit 9，可读写）
#define CAUSE_IP2       0x00000400  // 硬件中断挂起位 2，来自 int_i[0]（bit 10，只读）
#define CAUSE_IP3       0x00000800  // 硬件中断挂起位 3，来自 int_i[1]（bit 11，只读）
#define CAUSE_IP4       0x00001000  // 硬件中断挂起位 4，来自 int_i[2]（bit 12，只读）
#define CAUSE_IP5       0x00002000  // 硬件中断挂起位 5，来自 int_i[3]（bit 13，只读）
#define CAUSE_IP6       0x00004000  // 硬件中断挂起位 6，来自 int_i[4]（bit 14，只读）
#define CAUSE_IP7       0x00008000  // 硬件中断挂起位 7，来自 int_i[5]（bit 15，只读）

// 常用组合
#define CAUSE_IP_SOFT   (CAUSE_IP0 | CAUSE_IP1)
#define CAUSE_IP_HARD   (CAUSE_IP2 | CAUSE_IP3 | CAUSE_IP4 | CAUSE_IP5 | CAUSE_IP6 | CAUSE_IP7)

// 异常码掩码及移位
#define CAUSE_EXCCODE   0x0000007C  // bits 6:2
#define CAUSE_EXCCODE_SHIFT 2

#endif