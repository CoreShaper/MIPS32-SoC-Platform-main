// SW/common.h
// 与 CPU 架构无关的公共定义、仿真控制接口和调试工具

#ifndef COMMON_H
#define COMMON_H

// ------------------------------------------------------------
// 基本类型定义（适配裸机环境）
// ------------------------------------------------------------
#define NULL ((void*)0)
typedef unsigned int   uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char  uint8_t;
typedef int            int32_t;
typedef short          int16_t;
typedef char           int8_t;
typedef unsigned int   size_t;

#define true  1
#define false 0
typedef int bool;

// ------------------------------------------------------------
// 仿真控制寄存器（MMIO 地址）
// ------------------------------------------------------------
// 写入 0x1 表示测试通过，仿真自动结束
#define SIM_CTRL_PASS   (*(volatile uint32_t *)0xFFFFFFF0)
#define PASS_CODE       0x00000001

// 写入失败码（高16位 0xDEAD）表示测试失败，仿真结束
#define SIM_CTRL_FAIL   (*(volatile uint32_t *)0xFFFFFFF0)
#define FAIL_CODE(code) (0xDEAD0000 | ((code) & 0xFFFF))

// // // 仿真调试输出寄存器：写入 ASCII 字符或 32 位值，由 testbench $display 显示
// #define SIM_DBG_OUT     (*(volatile uint32_t *)0xFFFFFFE0)

// ------------------------------------------------------------
// 仿真辅助宏
// ------------------------------------------------------------
// 上报测试通过并终止仿真
#define sim_pass()      do { SIM_CTRL_PASS = PASS_CODE; while(1); } while(0)

// 上报测试失败并终止仿真
#define sim_fail(code)  do { SIM_CTRL_FAIL = FAIL_CODE(code); while(1); } while(0)

// ------------------------------------------------------------
// 常用工具宏
// ------------------------------------------------------------
#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))
#define ALIGN_UP(addr, align) (((addr) + (align) - 1) & ~((align) - 1))
#define BIT(n) (1UL << (n))


#endif /* COMMON_H */