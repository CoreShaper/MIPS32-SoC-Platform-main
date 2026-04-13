// SW/drivers/printf_sim.c
// 仿真 printf 驱动实现：通过写 SIM_DBG_OUT 寄存器在仿真控制台打印字符

#include "printf_sim.h"
#include "./common.h"
#include <stdarg.h>

// 初始化函数（当前无需额外操作）
void printf_sim_init(void) {
    // 仿真串口无需硬件初始化
}

// 输出单个字符
void printf_sim_putc(char c) {
    // 向调试输出地址写入字符，testbench 捕获并 $display
    SIM_DBG_OUT = (uint32_t)c;
}

// 输出字符串
void printf_sim_puts(const char *s) {
    while (*s) {
        printf_sim_putc(*s++);
    }
}

// 输出 0x00000000
void printf_sim_put_hex32(uint32_t x) {
    static const char hex_digits[] = "0123456789abcdef";
    int32_t i;

    printf_sim_putc('0');
    printf_sim_putc('x');

    for (i = 7; i >=0; i--) {
        uint32_t nibble = (x >> (i * 4)) & 0xF;
        printf_sim_putc(hex_digits[nibble]);
    }
}

// 输出无符号十进制
void printf_sim_put_dec(uint32_t x) {
    char buf[10];   // uint32_t 最大 4294967295，共 10 位
    int32_t i = 0;

    if (x == 0) {
        printf_sim_putc('0');
        return;
    }

    while (x > 0) {
        buf[i++] = (char)('0' + (x % 10));
        x /= 10;
    }

    while (i > 0) {
        printf_sim_putc(buf[--i]);
    }
}

// 输出有符号十进制
void printf_sim_put_int(int32_t x) {
    int32_t mag;

    if (x < 0) {
        printf_sim_putc('-');
        // 这样写可正确处理 INT32_MIN
        mag = (uint32_t)(-(x + 1)) + 1u;
        printf_sim_put_dec(mag);
    } else {
        printf_sim_put_dec((uint32_t)x);
    }
}

// 轻量版 printf
// 支持: %c %s %x %d %u %%
void printf_sim_printf(const char *fmt, ...) {
    va_list ap;
    char ch;

    va_start(ap, fmt);

    while ((ch = *fmt++) != '\0') {
        if (ch != '%') {
            printf_sim_putc(ch);
            continue;
        }

        ch = *fmt++;
        if (ch == '\0') {
            break;
        }

        switch (ch) {
            case 'c': {
                int c = va_arg(ap, int);
                printf_sim_putc((char)c);
                break;
            }

            case 's': {
                const char *s = va_arg(ap, const char *);
                if (s == 0) {
                    printf_sim_puts("(null)");
                } else {
                    printf_sim_puts(s);
                }
                break;
            }

            case 'x': {
                uint32_t x = va_arg(ap, uint32_t);
                printf_sim_put_hex32(x);
                break;
            }

            case 'd': {
                int32_t d = va_arg(ap, int32_t);
                printf_sim_put_int(d);
                break;
            }

            case 'u': {
                uint32_t u = va_arg(ap, uint32_t);
                printf_sim_put_dec(u);
                break;
            }

            case '%': {
                printf_sim_putc('%');
                break;
            }

            default: {
                // 未支持的格式，原样吐出，便于调试
                printf_sim_putc('%');
                printf_sim_putc(ch);
                break;
            }
        }
    }

    va_end(ap);
}