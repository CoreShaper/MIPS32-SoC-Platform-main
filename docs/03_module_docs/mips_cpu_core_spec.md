---
module: openmips
status: planning
date: 2026-04-26 12:15
design_owner: Author
tags:
  - module
  - cpu
  - mips
  - soc
---
# MIPS CPU Core 技术规格说明

## 1. 模块定位

MIPS CPU Core 是当前 SoC 系统中的主控制核，RTL 顶层模块名为 `openmips`。该模块负责执行裸机程序、访问片上存储器和 MMIO 外设、处理中断与异常，并作为后续 AXI、DMA、外设和系统互连验证的软件控制入口。

该 CPU 基于《自己动手写 CPU》中的 OpenMIPS 结构实现，保留原书中的五级流水线、指令执行、CP0、异常与中断等核心机制。本文档不重复描述书中已有的 CPU 内部实现细节，只定义该 CPU 在当前 SoC 工程中的功能边界、外部接口、工作流程和工程修改点。

当前 CPU 不作为后续项目的主要优化对象，而是作为稳定控制核使用。后续系统设计重点放在 SoC 集成、AXI/AXI-Lite 接入、System Interconnect、DMA 和验证闭环上。

---

## 2. 功能范围

| 功能项                             | 当前版本状态 | 说明                              |
| :------------------------------ | :----- | :------------------------------ |
| MIPS32 整数指令子集                   | 支持     | 按《自己动手写 CPU》OpenMIPS 实现         |
| 五级流水线                           | 支持     | IF / ID / EX / MEM / WB         |
| CP0                             | 支持     | 按原书及当前 RTL 实现                   |
| 异常与中断                           | 支持     | 当前工程统一入口为 `0x0000_0180`         |
| HI/LO 相关机制                      | 支持     | 按原书及当前 RTL 实现                   |
| LL/SC 相关机制                      | 支持     | 按原书及当前 RTL 实现                   |
| 非对齐访存相关指令                       | 支持     | 特殊非对齐访存指令按原书实现；普通访存仍要求满足对应对齐规则  |
| stall 机制                        | 支持，已验证 | 支持外部取指/数据访问等待                   |
| 指令/数据接口分离                       | 支持     | 当前工程直接引出 `inst_*` 和 `data_*` 接口 |
| Cache                           | 不支持    | 当前版本不实现内部 cache                 |
| MMU/TLB                         | 不支持    | 当前面向裸机 SoC，不支持虚拟地址转换            |
| FPU                             | 不支持    | 当前版本不实现浮点单元                     |
| AXI / AXI-Lite / APB / Wishbone | 不直接支持  | 后续由 wrapper 或 interconnect 转换   |
| 官方 MIPS32 ISA 合规认证              | 不进行    | 当前验证目标是 SoC 控制核可用，不是官方 ISA 认证   |

---

## 3. 接口定义

### 3.1 时钟、复位与中断接口

| 信号名           | 方向     | 位宽  | 描述                      |
| :------------ | :----- | :-- | :---------------------- |
| `clk`         | input  | 1   | CPU 工作时钟                |
| `rst`         | input  | 1   | 同步复位，高有效                |
| `int_i`       | input  | 6   | 外部中断输入，高有效              |
| `timer_int_o` | output | 1   | CP0 timer 中断输出          |
| `cpu_test`    | output | 待定  | 仿真/调试辅助信号，当前不作为核心功能接口描述 |

复位后，CPU 从 `0x0000_0000` 开始取指。复位期间 CPU 不发起有效取指或数据访问，相关访问控制信号处于无效状态。

---

### 3.2 指令访问接口

| 信号名               | 方向     | 位宽  | 描述           |
| :---------------- | :----- | :-- | :----------- |
| `inst_ce_o`       | output | 1   | 指令访问使能，高有效   |
| `inst_addr_o`     | output | 32  | 指令访问地址       |
| `inst_data_i`     | input  | 32  | 指令数据输入       |
| `inst_stallreq_i` | input  | 1   | 指令访问等待请求，高有效 |

指令接口为只读接口，CPU 不通过该接口写指令存储器。该接口不是 AXI、APB 或 Wishbone 协议，而是 CPU 原生取指接口。

当 `inst_stallreq_i` 拉高时，CPU 暂停流水线并保持当前取指上下文。stall 解除后，CPU 继续完成原取指流程。

---

### 3.3 数据访问接口

| 信号名 | 方向 | 位宽 | 描述 |
| :--- | :--- | :--- | :--- |
| `data_ce_o` | output | 1 | 数据访问使能，高有效 |
| `data_addr_o` | output | 32 | 数据访问地址 |
| `data_we_o` | output | 1 | 写使能，`1` 表示写，`0` 表示读 |
| `data_sel_o` | output | 4 | 字节选择信号 |
| `data_wdata_o` | output | 32 | 写数据 |
| `data_rdata_i` | input | 32 | 读数据 |
| `data_stallreq_i` | input | 1 | 数据访问等待请求，高有效 |

数据接口用于执行 load/store 访问。CPU 当前按大端数据组织方式工作，`data_sel_o` 用于指示 32-bit 数据通路中的有效字节 lane。后续 RAM、MMIO 外设、AXI wrapper 或 System Interconnect 需要保持与 CPU 端字节选择规则一致。

CPU 本身不区分 RAM、MMIO 或非法地址区域，只输出 32-bit 地址和访问控制信号。具体地址译码、外设选择和非法地址处理由 SoC 顶层或后续 System Interconnect 完成。

当 `data_stallreq_i` 拉高时，CPU 暂停流水线并保持当前访存上下文，包括地址、读写方向、字节选择和写数据。stall 解除后，CPU 继续完成原数据访问流程。

---

## 4. 工作流程

### 4.1 取指流程

CPU 复位解除后，从 `0x0000_0000` 开始取指。正常运行时，CPU 通过 `inst_ce_o` 和 `inst_addr_o` 发起指令访问，并从 `inst_data_i` 获取 32-bit 指令。

若外部指令存储器或后续总线 wrapper 无法及时返回指令，可拉高 `inst_stallreq_i` 请求 CPU 等待。CPU 等待期间保持当前取指访问状态，直到 stall 解除。

---

### 4.2 数据读写流程

当 CPU 执行 load/store 指令时，通过 `data_*` 接口发起数据访问。读访问时，`data_we_o = 0`，CPU 从 `data_rdata_i` 获取读数据；写访问时，`data_we_o = 1`，CPU 输出写地址、写数据和字节选择信号。

CPU 只负责产生访问请求，不负责判断该地址属于 RAM、MMIO 外设还是非法区域。外部 SoC 结构应根据 `data_addr_o` 完成地址译码和目标选择。

---

### 4.3 异常与中断流程

异常或中断发生后，CPU 统一跳转到 `0x0000_0180`。硬件侧保存异常相关状态，软件侧通过统一异常入口完成现场保存、异常类型分发、外设中断清除和异常返回处理。

普通异常发生时，EPC 保存异常指令地址。若异常发生在分支延迟槽中，EPC 保存对应分支指令地址，并设置 Cause 寄存器中的 BD 位。异常返回统一通过 `eret` 完成。

外部中断由对应外设或中断源清除。timer 中断由 CP0 Count/Compare 机制产生，清除方式按原书及当前 RTL 实现处理。

---

## 5. 时序说明

### 5.1 普通取指时序

普通取指过程中，CPU 输出有效的 `inst_ce_o` 和 `inst_addr_o`，外部指令存储器返回 `inst_data_i`。若外部取指路径为固定延迟结构，则可直接返回指令；若后续接入可变延迟总线，则需要通过 `inst_stallreq_i` 控制 CPU 等待。

---

### 5.2 普通数据访问时序

普通数据访问过程中，CPU 输出 `data_ce_o`、`data_addr_o`、`data_we_o`、`data_sel_o` 和 `data_wdata_o`。对于读访问，外部返回 `data_rdata_i`；对于写访问，外部根据 `data_sel_o` 和 `data_wdata_o` 写入目标字节 lane。

---

### 5.3 stall 等待时序

当 `inst_stallreq_i` 或 `data_stallreq_i` 任一拉高时，CPU 暂停流水线。stall 期间，CPU 保持当前访问上下文，避免访问地址、写数据、写使能或字节选择信号在访问未完成前发生变化。

当前 stall 机制已完成验证，可用于后续接入可变延迟 RAM、MMIO、AXI wrapper 或 System Interconnect。

流水线控制优先级按当前 RTL 设计理解为：

```text
reset > exception/interrupt flush > stall > normal
````

---

## 6. 与原书设计的差异

|编号|修改点|说明|
|:--|:--|:--|
|1|去除原书后续总线封装|当前 CPU 不使用原书实践版中的 Wishbone 总线接口|
|2|直接引出取指接口|使用 `inst_ce_o`、`inst_addr_o`、`inst_data_i`、`inst_stallreq_i`|
|3|直接引出数据接口|使用 `data_ce_o`、`data_addr_o`、`data_we_o`、`data_sel_o`、`data_wdata_o`、`data_rdata_i`、`data_stallreq_i`|
|4|异常与中断入口统一|统一入口地址为 `0x0000_0180`|
|5|CPU 与具体总线协议解耦|后续 AXI、AXI-Lite、APB 或其他协议由外部 wrapper / interconnect 适配|

---

## 7. 当前限制

- 当前 CPU 不支持内部 cache。
    
- 当前 CPU 不支持 MMU/TLB，因此不支持 Linux。
    
- 当前 CPU 不支持 FPU。
    
- 当前 CPU 不直接支持 AXI、AXI-Lite、APB 或 Wishbone。
    
- 当前 CPU 不作为后续项目优化主线，只作为 SoC 控制核使用。
    
- 当前 CPU 未进行官方 MIPS32 ISA 合规认证。
    
- CPU 文档不重复描述原书已有的流水线、译码、执行、CP0 等内部细节，相关内容以《自己动手写 CPU》和当前 RTL 为准。
    

---

## 8. 验证点清单

|验证项|状态|说明|
|:--|:--|:--|
|指令功能测试|已完成|主要指令功能已验证|
|异常测试|已完成|`syscall`、`trap`、overflow、invalid instruction 等|
|中断测试|已完成|外部中断和 timer 中断|
|stall 测试|已完成|指令/数据接口 stall 已验证|
|基础 SoC 联调|已完成|CPU 已能运行基础 SoC 程序|
|MMIO 访问测试|已完成|通过数据接口访问仿真控制或调试输出模块|
|官方 ISA 合规验证|不进行|不属于当前项目主线|
|ISS 对照随机验证|不进行|当前阶段不作为必要目标|

---

## 9. 设计决策记录

|编号|决策|原因|影响|
|:--|:--|:--|:--|
|DDR-CPU-001|保留 OpenMIPS CPU 核心结构|当前项目重点不是重新设计 CPU，而是推进 SoC/AXI/DMA 系统|降低 CPU 侧不确定性|
|DDR-CPU-002|去除原书后续总线封装，直接引出 native 指令/数据接口|便于后续接入自定义 SoC 顶层和 AXI wrapper|CPU 不绑定具体总线协议|
|DDR-CPU-003|CPU 不直接支持 AXI/Wishbone/APB|保持 CPU Core 边界清晰|协议转换放在外部 wrapper 中实现|
|DDR-CPU-004|异常与中断统一入口为 `0x0000_0180`|简化软件异常入口和分发流程|软件 handler 需要统一读取 CP0 并分发异常/中断类型|
|DDR-CPU-005|保留并验证外部 stall 机制|为后续可变延迟访问路径做准备|可接入 RAM、MMIO、AXI wrapper 或 System Interconnect|
|DDR-CPU-006|CPU 作为 SoC 控制核使用|与当前 AXI/DMA 主线一致|后续不围绕 CPU 性能优化展开|
|DDR-CPU-007|不声明官方 MIPS32 ISA 合规|当前未进行官方合规认证|对外表述更稳妥|
|DDR-CPU-008|地址映射由外部 SoC 定义|CPU 只输出地址和访问控制信号|地址译码、非法访问和错误响应放到 SoC/Interconnect 文档中定义|

---

## 10. Bug 追踪

|Bug ID|状态|问题描述|原因|修复方式|备注|
|:--|:--|:--|:--|:--|:--|
|BUG-CPU-001|Open|暂无|暂无|暂无|后续开发和联调过程中补充|

---

## 11. 变更记录

|日期|版本|修改内容|说明|
|:--|:--|:--|:--|
|2026.04.26|v0.1|创建文档|初始版本，定义 CPU Core 的功能边界、接口、时序、修改点和限制|
