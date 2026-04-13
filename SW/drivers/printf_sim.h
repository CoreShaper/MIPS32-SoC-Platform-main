// SW/drivers/uart_sim.h
// 仿真 UART 驱动头文件

#ifndef DRIVERS_UART_SIM_H
#define DRIVERS_UART_SIM_H

#include "printf_sim.h"
#include "common.h"
// 仿真调试输出寄存器：写入 ASCII 字符或 32 位值，由 testbench $display 显示
#define SIM_DBG_OUT     (*(volatile uint32_t *)0xFFFFFFE0)
// 初始化仿真串口（目前无需配置，保留接口）
void printf_sim_init(void);

// 输出一个字符到仿真控制台
void printf_sim_putc(char c);

// 输出字符串到仿真控制台
void printf_sim_puts(const char *s);

void printf_sim_put_hex32(uint32_t x);   // 输出 0x00000000
void printf_sim_put_dec(uint32_t x);     // 输出无符号十进制
void printf_sim_put_int(int32_t x);      // 输出有符号十进制（可选）
void printf_sim_printf(const char *fmt, ...);   // 轻量版
#endif /* DRIVERS_UART_SIM_H */
