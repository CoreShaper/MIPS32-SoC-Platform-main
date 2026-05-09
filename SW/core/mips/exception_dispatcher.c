// exception_dispatcher.c - 方案一：trap_frame 为唯一真相
#include "core/mips/arch_common.h"
#include "core/mips/cp0.h"


volatile int count = 0;

// 异常现场帧（必须与 exception.S 压栈顺序严格对应）
struct trap_frame {
    unsigned int at, v0, v1, a0, a1, a2, a3;
    unsigned int t0, t1, t2, t3, t4, t5, t6, t7;
    unsigned int s0, s1, s2, s3, s4, s5, s6, s7;
    unsigned int t8, t9, k0, k1, gp, sp, fp, ra;
    unsigned int epc, status, cause, badvaddr;
};

// ------------------------------------------------------------
// 工具函数：推进 EPC（只改 trap_frame，不直接改 CP0）
// ------------------------------------------------------------
static inline void trapframe_advance_epc(struct trap_frame *tf, int in_delayslot) {
    tf->epc += in_delayslot ? 8 : 4;
}

// ---------- 弱定义的中断服务函数 ----------
void __attribute__((weak)) timer_isr(struct trap_frame *tf) {
    unsigned int count1 = cp0_read_count();
    cp0_write_compare(count1 + 10000);
    count++;

}

void __attribute__((weak)) uart_isr(struct trap_frame *tf)  { (void)tf; }
void __attribute__((weak)) dma_isr(struct trap_frame *tf)   { (void)tf; }
void __attribute__((weak)) gpio_isr(struct trap_frame *tf)  { (void)tf; }
void __attribute__((weak)) pcie_isr(struct trap_frame *tf)  { (void)tf; }
void __attribute__((weak)) eth_isr(struct trap_frame *tf)   { (void)tf; }
void __attribute__((weak)) soft_isr0(struct trap_frame *tf) { (void)tf; }
void __attribute__((weak)) soft_isr1(struct trap_frame *tf) { (void)tf; }

// ---------- 弱定义的同步异常处理函数 ----------
void __attribute__((weak)) handle_syscall(struct trap_frame *tf) {
    (void)tf;
    while (1);
}
void __attribute__((weak)) handle_trap(struct trap_frame *tf) {
    (void)tf;
    while (1);
}
void __attribute__((weak)) handle_ov(struct trap_frame *tf) {
    (void)tf;
    while (1);
}
void __attribute__((weak)) handle_ri(struct trap_frame *tf) {
    (void)tf;
    while (1);
}

// ---------- 主分发函数 ----------
void mips_exception_dispatcher(struct trap_frame *tf) {
    unsigned cause = tf->cause;
    unsigned exc_code = (cause & CAUSE_EXCCODE) >> CAUSE_EXCCODE_SHIFT;
    int in_delayslot = (cause & CAUSE_BD) != 0;

    switch (exc_code) {
        case EXC_INT:   // 中断
            // 注意：这里如果要更严谨，可用 pending = cause.IP & status.IM 再分发
            if (cause & CAUSE_IP2) timer_isr(tf);
            if (cause & CAUSE_IP3) uart_isr(tf);
            if (cause & CAUSE_IP4) dma_isr(tf);
            if (cause & CAUSE_IP5) gpio_isr(tf);
            if (cause & CAUSE_IP6) pcie_isr(tf);
            if (cause & CAUSE_IP7) eth_isr(tf);
            if (cause & CAUSE_IP0) soft_isr0(tf);
            if (cause & CAUSE_IP1) soft_isr1(tf);
            break;

        case EXC_SYSCALL:
            handle_syscall(tf);
            trapframe_advance_epc(tf, in_delayslot);
            break;

        case EXC_TRAP:
            handle_trap(tf);
            trapframe_advance_epc(tf, in_delayslot);
            break;

        case EXC_OV:
            handle_ov(tf);
            trapframe_advance_epc(tf, in_delayslot);
            break;

        case EXC_RI:
            handle_ri(tf);
            trapframe_advance_epc(tf, in_delayslot);
            break;

        default:
            while (1);
            break;
    }
}