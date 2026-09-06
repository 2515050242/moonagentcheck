# 0001：先做行为契约，不做通用 agent 框架

## 背景

Mooncakes 已有 LLM 客户端、多个 agent loop、`moonbitlang/workflow`、MCP SDK/Inspector、事件回放和 OpenTelemetry agent 遥测项目。直接实现又一个 agent 框架会产生明显重合。

## 决策

首版只实现跨框架的工具行为检查：受控 fixture、事件关联、重试和重复副作用诊断。核心逻辑由 MoonBit 提供，Python 仅作为接入示例。

## 取舍

这样能在约 20–40 小时内交付可运行的库、CLI 和测试证据，且与现有 workflow 的调度/恢复、MoonReplayKit 的通用回放、agent-telemetry 的埋点边界分开。代价是首版不提供模型路由、长时任务、网页工作台和完整 MCP 协议支持。

## 重新评估条件

若第一个真实场景无法证明行为检查比应用内断言更有用，或社区反馈已有项目应直接扩展，则停止新包扩张，改为向相关项目提交适配器、fixture 或测试改进。

