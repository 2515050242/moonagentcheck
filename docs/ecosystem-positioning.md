# MoonBit Agent 生态定位核对

**核对日期：**2026-10-09。版本与职责按当天可访问的 Mooncakes 包页和项目 README 核对；版本会变化，提交材料不将此次结果外推为永久状态。

| 项目 | 核对到的发布版本 | 项目页所述职责 | 与 MoonAgentCheck 的关系 |
| --- | --- | --- | --- |
| [moonbitlang/workflow](https://mooncakes.io/docs/moonbitlang/workflow%400.10.0) | `0.10.0`（核对时页面标记的 latest） | 面向多 Agent 的 workflow-as-code 编排，包含并发和调用上限、失败策略、typed outcomes、journal replay/resume、Runner、进程/CLI adapters 与运行观测事件。 | 处理工作流执行和恢复；与本项目的轨迹、重放及策略有相邻概念。MoonAgentCheck 的主要入口是已观察到的事件序列，判定 call/result/write-complete 的行为契约，不运行或恢复 workflow。 |
| [totto2727/agent-sdk](https://mooncakes.io/docs/totto2727/agent-sdk%400.2.1) | `0.2.1` | 为 Codex、OpenCode CLI session 提供 provider-neutral 接口，并保留各 provider 的原生事件、错误及续接行为。 | 提供 Agent CLI 会话调用接口；当前包页没有将确定性 call/result/write 行为契约评估列作其主要职责。SDK 或其日志可成为未来 adapter 的输入来源，仓库目前不声称已有该集成。 |
| [moonbit-community/opentelemetry](https://mooncakes.io/docs/moonbit-community/opentelemetry) | `0.1.7`（核对时页面标记的 latest） | 提供 traces、metrics、logs、context/propagation API，SDK providers 与 OTLP exporters。 | 负责埋点、遥测处理和导出；它可承载运行观测。本项目负责对应用映射后的事件做确定性规则检查和回归门禁，不替代遥测 SDK 或 Collector。 |

## 定位结论

MoonAgentCheck 与以上项目存在有意义的邻接和局部重叠，特别是 workflow 的 journal/replay、SDK 的调用记录以及 OpenTelemetry 的 traces/logs。申报时不应声称“MoonBit 生态没有类似项目”。本项目的可检验切口是：接入方把已记录的行为转换为 `Event`，MoonBit 核心离线、确定性地检查调用与结果关联、重试、策略约束和副作用完成，并给出稳定违规码及事件位置，供场景回归和 CI 使用。

这些项目可以分别负责运行编排、Agent 会话或遥测采集；若接入方需要跨事件契约检查，可在它们与 CI 之间增加字段映射。当前仓库没有集成上述项目，也不宣称能拦截真实工具副作用。适配需要遵循各项目实际暴露的字段语义并由后续 fixture 验证。

## 核查来源

- Mooncakes 包页记录包版本、许可证、仓库和 README 摘要：[workflow 0.10.0](https://mooncakes.io/docs/moonbitlang/workflow%400.10.0)、[agent-sdk 0.2.1](https://mooncakes.io/docs/totto2727/agent-sdk%400.2.1)、[opentelemetry 当前 latest](https://mooncakes.io/docs/moonbit-community/opentelemetry)。
- 上游仓库：[moonbitlang/workflow](https://github.com/moonbitlang/workflow)、[totto2727-org/agent-sdk](https://github.com/totto2727-org/agent-sdk)、[moonbit-community/opentelemetry.mbt](https://github.com/moonbit-community/opentelemetry.mbt)。
- 项目页面可反映后来版本；若在报名材料再次使用版本信息，应重新核对并更新日期。
