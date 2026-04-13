// core/mips/context.h
// 任务上下文管理（预留接口，当前仅定义异常帧结构）

#ifndef CORE_MIPS_CONTEXT_H
#define CORE_MIPS_CONTEXT_H

// 异常现场帧（与 exception.S 压栈顺序严格对应）
struct trap_frame {
    unsigned int at, v0, v1, a0, a1, a2, a3;
    unsigned int t0, t1, t2, t3, t4, t5, t6, t7;
    unsigned int s0, s1, s2, s3, s4, s5, s6, s7;
    unsigned int t8, t9, k0, k1, gp, sp, fp, ra;
    unsigned int epc, status, cause, badvaddr;
};

// 未来可在此添加任务上下文结构
// struct task_context {
//     unsigned int sp;      // 栈指针
//     unsigned int ra;      // 返回地址
//     unsigned int s[8];    // 保存寄存器
// };

#endif