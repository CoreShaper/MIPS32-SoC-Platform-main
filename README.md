
# cpu-soc-platform

基于 Verilog 实现的 MIPS 架构 CPU 核心，支持 80 余条 MIPS 指令，封装为模块化 SoC 平台，采用 AXI-Lite 总线互联并挂载 GPIO 外设。平台支持 MIPS 程序编译与板级运行，适合作为学习 CPU 架构、SoC 系统集成和 AXI 总线开发的参考项目。

---

## 🚀 项目特色

- ✅ 实现 MIPS 架构 80+ 指令（参考《自己动手做CPU》）
- ✅ 基于 AXI-Lite 总线封装 CPU 核心，接口标准、可扩展
- ✅ 构建完整 SoC 平台并挂载 GPIO 外设模块
- ✅ 支持交叉编译 MIPS 程序 + 板级加载运行验证
- ✅ 提供完整 Vivado 工程，支持上板测试和波形仿真
- ⚠️ 当前 AXI-Lite 接口存在已知时序 Bug，欢迎参与修复

---

## 🧱 项目目录结构

```bash
.
├── axi_lite_bus/     # AXI-Lite 总线接口模块
├── cpu_core/         # MIPS CPU 核心（AXI-Lite 接口，支持80+指令）
├── docs/             # 技术文档与调试记录
├── peripherals/      # GPIO 等外设模块
├── soc_top/          # 顶层 SoC 平台封装
├── software/         # MIPS 汇编测试程序
├── test_bench/       # 仿真验证平台
└── Reference/        # 编译与开发参考资料
```

---

## 🛠 安装与运行说明

### 1️⃣ 准备交叉编译工具链

本项目使用 `mips_gcc` 工具链进行 MIPS 汇编程序编译。建议使用 Linux 环境（如 Ubuntu 虚拟机）完成交叉编译配置。

安装示例：
```bash
sudo apt install gcc-mips-linux-gnu
```



---

### 2️⃣ Vivado 环境准备

- 使用 Vivado 2020.2+ 版本开发
- 安装完成后，配置系统 PATH 环境变量
- 打开 Vivado → 导入工程 → 设置顶层模块为 `soc_top`

---

### 3️⃣ 编译与上板运行

#### 编译 CPU 程序
1. 在 `software/` 编写 MIPS 汇编或 C 程序
2. 使用 `mips_gcc` 交叉编译生成 `.bin`

#### 下载 bitstream 至 FPGA

1. Vivado → 综合 → 实现 → 生成比特流
2. 下载至 FPGA 板卡进行 LED 闪烁 / IO 控制验证

---

## 📌 使用说明

- `cpu_core/` 为可复用的 MIPS CPU AXI-Lite 核心，可单独移植
- `soc_top/` 为平台封装模块，用于集成 CPU + 外设 + 总线
- `board_test/` 为针对特定板卡的验证工程，需要绑定实际引脚
- 所有模块接口文档见 `docs/interface_map.md`

---

## ⚠️ 已知问题与说明

- 当前 AXI-Lite 接口存在 `WREADY` 同步问题，
- GPIO 模块测试通过，但外设扩展部分接口尚未规范
- 软件加载方式暂未实现片上 Flash 支持，仅支持硬编码方式

---

## 🧩 后续计划

- [ ] 修复 AXI-Lite 写通道握手 bug
- [ ] 封装 AXI-Full → AXI-Lite 转换桥
- [ ] 添加 UART 与计时器外设模块
- [ ] 提供多个 demo：流水灯、串口收发、GPIO 输入检测
- [ ] 输出教学型文档 / 视频教程

---

## 📖 参考资料

- 《自己动手做CPU》书籍（指令集参考）
- Xilinx AXI-Lite 协议规范
- Vivado 官方开发文档

---

> 本项目基于学习与实验目的开发，欢迎交流讨论与 PR 合作 🤝
