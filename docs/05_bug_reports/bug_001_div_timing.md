---
bug_id: BUG-001
module: div.v
severity: 高
status: open
date: "2026-05-07 22:32"
tags:
  - bug
  - RTL编码规范
design_owner: Author
---
---

# Bug BUG-001：DIV 模块被除数/除数载入时序错误
## 1. 现象描述

`selftest.S` 中 HILO 除法相关子用例（9～12）仿真失败，错误码 `0xDEAD1709` 等，表现为除法结果（商、余数）与预期不符。其余所有测试正常。

---

## 2. 复现步骤

1. 使用 Icarus Verilog 或 Verilator 运行 `selftest.S`。
2. 观察仿真输出，报 `TEST FAILED! Error code: 0xDEAD1709`，模块号 `HILO`。
3. 反汇编定位到子用例 9 的 `div` 指令附近。
4. 波形中观察 `div` 模块的 `dividend` / `divisor` 寄存器，在 `DivStart` 后首拍其值与 `opdata1_i` / `opdata2_i` 不一致。

---

## 3. 根因分析

**位置**：`div.v` 中 `DivFree` 状态，被除数 / 除数载入逻辑。

**错误代码**：
```verilog
if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1) begin
    temp_op1 <= ~opdata1_i + 1;   // 非阻塞赋值
end else begin
    temp_op1 <= opdata1_i;
end
// ...
dividend[32:1] <= temp_op1;       // 非阻塞赋值，读取的是 temp_op1 的旧值
divisor <= temp_op2;
```

**根因**：
- `temp_op1` / `temp_op2` 是**本周期计算、本周期立即使用**的临时变量，不期望跨周期存储。
- 但在时序 `always` 块内对它们使用了**非阻塞赋值（`<=`）**，导致：
  - `temp_op1 <= ...` 在本周期末才会更新。
  - `dividend[32:1] <= temp_op1` 右手边立即求值，读到的是**上一周期的旧值**。
- 综合工具会按语义为 `temp_op1` 推断出**一个多余的 32 位寄存器**，硬件行为与功能需求不符。
- 当除法器启动时，实际装入的被除数 / 除数总是晚一拍，因而除出错误的商和余数。

**本质**：混淆了"寄存器"与"组合逻辑中间节点"的 RTL 描述方式。

---

## 4. 修复方案

**方案 A（推荐）—— 直接使用组合表达式，消除临时变量**：
```verilog
dividend[32:1] <= (signed_div_i && opdata1_i[31]) ? (~opdata1_i + 1) : opdata1_i;
divisor        <= (signed_div_i && opdata2_i[31]) ? (~opdata2_i + 1) : opdata2_i;
```

如需消除 lint 的 BLKSEQ 警告，使用方案 A 或添加 `verilator lint_off BLKSEQ`。

**修复后综合结果**：`temp_op1` / `temp_op2` 被优化为纯组合逻辑，零额外寄存器，面积更小，时序正确。

---

## 5. 验证结果

- [x] 修复后仿真通过（`selftest` 子用例 9～12 全部 PASS）
- [x] 波形确认 `dividend` / `divisor` 在 `DivStart` 后首拍即为正确值

---

## 🐛 Bug 追踪

| Bug ID | 描述 | 状态 |
|--------|------|------|
| BUG-001 | 写满后再写未拉高满标志 | 待处理 |
| BUG-002 | 异步复位后状态机未回到 IDLE | ✅ 已修复 |
| **BUG-003** | **DIV 模块被除数/除数载入时序错误** | **✅ 已修复** |

---

## 6. 沉淀为设计规范

**RTL 编码规则（写入团队 Checklist）**：

> **规则 1**：在 `always @(posedge clk)` 块中，**所有需要跨周期保持状态的变量必须用非阻塞赋值（`<=`）**。  
> **规则 2**：**仅在当前周期有效、不需要保存的中间量，禁止用 `reg` + `<=` 描述**，应使用：  
> - 组合 `assign` 或 `wire`，或  
> - 直接在目标寄存器的非阻塞赋值右手边写组合表达式。  
> **规则 3**：若确实需要在时序块内使用临时变量，必须采用阻塞赋值（=），并确保其生命周期不超过当前时钟周期，同时增加注释说明。  
> **规则 4**：代码审查时重点检查状态机启动序列中的操作数锁存逻辑，确认无跨周期延迟的语义错误。  
> **规则 5**：所有乘除/多周期运算模块的输入数据路径，必须通过波形验证：在 `start` 信号有效的同一时钟周期内，内部数据寄存器已被正确装载。

---

**案例关联**：`div.v` BUG-003

**应避免的模式**：
```verilog
// ❌ 错误：临时变量用非阻塞赋值，导致数据晚一拍
reg [31:0] temp;
always @(posedge clk) begin
    temp <= compute(...);
    result <= temp;         // 读到旧值
end
```

**推荐模式**：
```verilog
// ✅ 正确：组合表达式直连
always @(posedge clk) begin
    result <= compute(...);
end
```

```verilog
// ✅ 也可：临时变量用阻塞赋值（需加注释）
always @(posedge clk) begin
    reg [31:0] temp;
    temp = compute(...);    // 阻塞赋值，立即生效
    result <= temp;
end
```
