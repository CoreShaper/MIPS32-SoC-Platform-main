#include "common.h"
#include "core/mips/cp0.h"
#include "core/mips/arch_common.h"
#include "drivers/printf_sim.h"
//flag 用于指示中断是否发生
extern volatile int count; 
int main(void) {
    // 使能全局中断和定时器中断
    // unsigned int status = cp0_read_status();
    // status |= STATUS_IM2|STATUS_IE;   // IE
    // cp0_write_status(status);
    // unsigned int count1 = cp0_read_count();
    // cp0_write_compare(count1 + 1000);
    printf_sim_printf("hello\n");
printf_sim_printf("c=%c s=%s\n", 'A', "test");
printf_sim_printf("x=%x\n", 0x1234ABCD);
printf_sim_printf("u=%u d=%d\n", 123456789u, -12345);
printf_sim_printf("percent=%%\n");

    // while (count < 5) {
    //     // 这里我们简单地等待中断发生
    // }

    // status = cp0_read_status();
    // status &= ~(STATUS_IM2|STATUS_IE);  // 关中断

    sim_pass();
    return 0;
}