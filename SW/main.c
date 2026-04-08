#include "common.h"

int main(void)
{
    // 简单的 CPU smoke test
    int a = 1, b = 2;
    int c = a + b;
    if (c == 3) {
        SIM_EXIT_ADDR = PASS_CODE;
    } else {
        SIM_EXIT_ADDR = FAIL_CODE;
    }

    // 永远不该执行到这里
    while(1);
    return 0;
}
