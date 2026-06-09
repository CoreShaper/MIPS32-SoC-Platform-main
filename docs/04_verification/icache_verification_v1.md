---
module_under_test:
testbench_owner:
date: 2026-05-01 15:11
tags:
  - verification
  - 未处理
design_owner: Author
---

# 验证计划：I-cache v1.0

## 1. 验证目标

| 编号 | 功能点 | 描述 |
|------|--------|------|
| F-01 | 旁路模式 | `icache_en=0` 时，CPU 请求直通 RAM，数据正确，stall 行为正确 |
| F-02 | Cache 使能 | `icache_en=1` 时，命中返回正确数据，缺失触发 Refill |
| F-03 | 命中判断 | Valid + Tag 匹配 → hit=1，数据在下一拍返回，stall=0 |
| F-04 | 缺失 Refill | Miss 时进入 REFILL，发出 8 次读请求，全部写入 SRAM 后释放 stall |
| F-05 | 整行填充正确性 | Refill 完成后，该行 8 个字全部正确，与 Golden Model 一致 |
| F-06 | 冲突替换 | 同 Index 不同 Tag 访问时，旧行被正确替换，原地址再访问重新 Miss |
| F-07 | 复位清除 | `rst_sync` 有效后，所有 Valid 位清 0，再次访问必须重新 Refill |
| F-08 | 使能动态切换 | `icache_en` 从 0→1 或 1→0 切换时，行为正确，无数据错乱 |
| F-09 | `ram_inst_ready` 握手 | Cache 所有内部状态推进均基于 `ram_inst_ready`，适配任意 RAM 延迟 |
| F-10 | Stall 时序 | Miss 时 stall 在同一周期拉高，Refill 完成后 stall 同一周期释放 |
| F-11 | 旁路 Stall | 旁路模式下，CPU 取指需等待 `ram_inst_ready`，不丢请求 |
| F-12 | 性能计数器 | hit/miss/stall/cycles 计数准确 |

---

## 2. 测试环境

- **仿真器**：Icarus Verilog（iverilog）+ GTKWave
- **验证方法学**：模块级定向测试 + SoC 级软件自测试（selftest）
- **模块级 Testbench**：`test_bench/module_bench/module_bench.v`
- **SoC 级 Testbench**：`test_bench/myopenmips_min_sopc_tb.v`
- **软件测试程序**：`SW/core/mips/cpu_selftest.S`
- **RAM 模型**：`soc_top/dual_port_ram.v`（支持 `I_LATENCY` 参数，组合/延迟可切换）

---

## 3. 测试用例清单

| 用例ID | 测试场景 | 预期结果 | 状态 |
|:---|:---|:---|:---|
| TC-001 | 旁路模式读地址 0x0 | `cpu_data` = Golden Model，stall=0 | ✅ 通过 |
| TC-002 | 旁路模式读地址 0x14 | `cpu_data` = Golden Model，stall=0 | ✅ 通过 |
| TC-003 | Cache 使能，首次访问 0x100（Miss） | Refill 完成，`cpu_data` = Golden Model，stall 持续 8+N 拍 | ✅ 通过 |
| TC-004 | 再次访问 0x100（Hit） | `cpu_data` 正确，stall=0 | ✅ 通过 |
| TC-005 | 访问不同 Index（0x20），Miss+Hit | 行为同 TC-003/004 | ✅ 通过 |
| TC-006 | 同 Index 不同 Tag 冲突（0x20 → 0x10020 → 0x20） | 替换后原地址再次 Miss，数据正确 | ✅ 通过 |
| TC-007 | 复位后重新访问已缓存地址 | 再次 Miss，Refill 正确 | ✅ 通过 |
| TC-008 | Miss 后立即再次访问同一地址 | Hit，stall=0，数据正确 | ✅ 通过 |
| TC-009 | Miss 后访问同行其他偏移（0xF80 → 0xF84） | Hit，数据正确 | ✅ 通过 |
| TC-010 | 填充 Index 12 行后，填充 Index 11 行，再回读 Index 12 行 | Index 12 数据未被破坏 | ✅ 通过 |
| TC-011 | 从 0xF60 顺序读到 0xF90 | 所有命中数据正确，无意外 stall | ✅ 通过 |
| TC-012 | Miss 时 stall 在同一周期拉高 | 波形确认 stall 与 miss_req 同步 | ✅ 通过 |
| TC-013 | SoC 级 selftest（Cache ON） | 全部子用例 PASS | ✅ 通过 |
| TC-014 | SoC 级 selftest（旁路） | 全部子用例 PASS | ✅ 通过 |
| TC-015 | 性能计数器（Cache ON） | hit/miss/stall/cycles 输出合理 | ✅ 通过 |
| TC-016 | IMEM_LATENCY=4，Cache ON vs 旁路 | Cache 加速明显 | ⏳ 待完成 |

---

## 4. 覆盖率目标

- **代码覆盖率**：90%+（核心状态机 100%）
- **功能覆盖率**：
  - 旁路/Cache 模式交叉覆盖：✅
  - 命中/Miss/冲突 交叉覆盖：✅
  - 复位/使能切换 交叉覆盖：✅
  - 不同 RAM 延迟配置：⏳（待补完 IMEM_LATENCY 实验）

---

## 5. 仿真结果记录

### TC-013：SoC 级 selftest（Cache ON, I_LATENCY=0）

```
========================================
         TEST PASSED!
--- I-Cache Performance ---
  Cycles:  10816
  Hits:    7350
  Misses:  385
  Stalls:  3466
  Hit rate: 95.0%
========================================
```

### TC-014：SoC 级 selftest（旁路, I_LATENCY=0）

```
========================================
         TEST PASSED!
  Cycles:  7381
========================================
```

### TC-016：IMEM_LATENCY=15 实验

| 模式 | Cycles | Hits | Misses | Stalls | Hit rate |
|------|--------|------|--------|--------|----------|
| Cache ON | 54000 | 7130 | 385 | 46870 | 94.9% |
| 旁路 | 55396 | 0 | 0 | 51932 | - |

*注：旁路数据暂未完整体现慢速 Flash 的每条指令延迟，待 RAM 模型 `i_ready` 改为脉冲型后重新采集。*

---

## 6. 遗留问题

无

---

## 🐛 Bug 追踪

| Bug ID  | 描述                                  | 状态    |
| ------- | ----------------------------------- | ----- |
