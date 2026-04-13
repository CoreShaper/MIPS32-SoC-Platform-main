// core/mips/cp0.h
// MIPS CP0 寄存器读写内联函数（仅保留 OpenMIPS 已实现的寄存器）

#ifndef CORE_MIPS_CP0_H
#define CORE_MIPS_CP0_H

// 通用读写宏
#define mfc0(reg, sel) ({ \
    unsigned int __value; \
    __asm__ volatile("mfc0 %0, $" #reg ", " #sel : "=r"(__value)); \
    __value; \
})

#define mtc0(value, reg, sel) \
    __asm__ volatile("mtc0 %0, $" #reg ", " #sel :: "r"((unsigned int)(value)))

// 已实现的 CP0 寄存器读取函数
static inline unsigned int cp0_read_count(void)   { return mfc0(9, 0);  }
static inline unsigned int cp0_read_compare(void) { return mfc0(11, 0); }
static inline unsigned int cp0_read_status(void)  { return mfc0(12, 0); }
static inline unsigned int cp0_read_cause(void)   { return mfc0(13, 0); }
static inline unsigned int cp0_read_epc(void)     { return mfc0(14, 0); }
static inline unsigned int cp0_read_prid(void)    { return mfc0(15, 0); }
static inline unsigned int cp0_read_config(void)  { return mfc0(16, 0); }

// 已实现的 CP0 寄存器写入函数
static inline void cp0_write_count(unsigned int v)   { mtc0(v, 9, 0);  }
static inline void cp0_write_compare(unsigned int v) { mtc0(v, 11, 0); }
static inline void cp0_write_status(unsigned int v)  { mtc0(v, 12, 0); }
static inline void cp0_write_cause(unsigned int v)   { mtc0(v, 13, 0); }
static inline void cp0_write_epc(unsigned int v)     { mtc0(v, 14, 0); }
// PRId 和 Config 通常是只读的，无需写函数

#endif