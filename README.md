# MIPS CPU SoC Platform
## 1. 项目简介
这是一个基于 Verilog 的 MIPS CPU SoC 仿真平台，当前版本已经打通从裸机软件构建到 RTL 仿真的完整链路，包括：CPU 执行、片上双口 RAM、异常/中断处理、仿真 PASS/FAIL 控制以及 `printf_sim` 调试输出。
## 2. 当前版本实现内容
- `openmips` MIPS CPU 核
- 双口 RAM 指令/数据存储结构
- 基于 MMIO 地址译码的最小 SoC 顶层
- 仿真控制寄存器 `SIM_CTRL`
- 仿真调试输出寄存器 `SIM_DBG_OUT`
- MIPS 裸机软件链路：启动、链接、异常入口、中断分发
- `printf_sim` 轻量调试输出接口
- Icarus Verilog + GTKWave 仿真支持
## 3. 工程结构
```text
.
├── Makefile
├── Makefile.sim
├── filelist.f
├── soc_top/
├── SW/
├── test_bench/
├── Reference/
└── cpu_test.gtkw
```
## 4. 环境要求
建议在 Linux 环境下运行，并安装以下工具：
```bash
sudo apt install gcc-mips-linux-gnu iverilog gtkwave
```
## 5. 快速开始
### 5.1 一键运行
在工程根目录执行：
```bash
make
```
该命令会：
1. 编译 `SW/` 下的软件源码
2. 生成 `SW/obj/program.hex`
3. 编译 RTL 与 testbench
4. 运行仿真
### 5.2 分步执行
只编译软件：
```bash
make sw
```
只运行仿真：
```bash
make run
```
查看波形：
```bash
make wave
```
清理生成文件：
```bash
make clean
```
### 5.3 关键输出文件
```text
SW/obj/program.elf   # 链接后的裸机 ELF
SW/obj/program.bin   # 二进制镜像
SW/obj/program.hex   # 供 RAM 初始化加载
SW/obj/program.dis   # 反汇编结果
simv                 # 仿真可执行文件
waveform.vcd         # 波形文件
```
## 6. 仿真输出说明
### 6.1 PASS/FAIL
软件通过向 `0xFFFFFFF0` 写入控制码向 testbench 报告结果：
- `0x00000001`：PASS
- `0xDEADxxxx`：FAIL
### 6.2 printf_sim 调试输出
软件通过向 `0xFFFFFFE0` 写入字符实现调试打印，testbench 检测该地址上的写事务后，将低 8 位按 ASCII 输出到控制台。
## 7. 详细文档入口
详细的工程说明、目录结构、硬件/软件/仿真链路、Makefile 作用、默认地址约定等内容见：
- `mips_cpu_soc_说明.md`
