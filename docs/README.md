# IC SoC Project Documentation

本目录用于存放该 SoC 项目的公开工程文档，内容从 Obsidian 知识库中筛选并清洗而来。

## 文档结构

| 路径 | 内容 |
|---|---|
| `00_project_vision.md` | 项目阶段定位与长期演进方向 |
| `01_requirements/soc_requirement.md` | SoC 系统需求说明 |
| `02_specifications/soc_specification.md` | SoC 系统技术规范说明 |
| `03_module_docs/icache_spec.md` | I-Cache 模块技术规格说明 |
| `03_module_docs/mips_cpu_core_spec.md` | MIPS CPU Core 技术规格说明 |
| `04_verification/icache_verification_v1.md` | I-Cache v1.0 验证计划 |
| `05_bug_reports/bug_001_div_timing.md` | DIV 模块时序 Bug 复盘 |
| `05_bug_reports/bug_002_icache_refill_timing.md` | I-Cache Refill 时序 Bug 复盘 |
| `assets/` | 文档引用图片 |

## 阅读建议

建议按以下顺序阅读：

1. `01_requirements/soc_requirement.md`
2. `02_specifications/soc_specification.md`
3. `03_module_docs/`
4. `04_verification/`
5. `05_bug_reports/`

## 说明

这些文档用于说明项目的系统边界、模块职责、接口关系、验证闭环和关键 Bug 复盘。RTL 源码、仿真脚本和软件测试程序应放在仓库对应的 `rtl/`、`sim/`、`sw/` 等目录中。
