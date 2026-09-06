# AgentCheck 申报书素材草案

> 这不是最终申报书。九月章程要求参赛者人工撰写一页 Markdown；提交前应由本人根据已完成实验和真实证据重写。

## 项目名称

AgentCheck：面向 AI Agent 的行为契约与可重复测试工具

## 项目简介

待本人用一段话说明具体问题、MoonBit 生态缺口和首版交付范围。

## 三个预期使用场景

1. 数据处理 agent 遇到缺失列错误时，不能把错误当成成功。
2. 仓库助手写文件前必须读取目标并满足对应授权。
3. 工单处理 agent 的暂时错误重试不能超过上限，也不能重复写回。

## 核心功能

- 结构化事件模型与调用/结果关联
- 受控工具响应 fixture
- 前置条件、重试上限、重复副作用契约
- JSON/文本诊断和 CI 非零退出码
- MoonBit API、CLI、Python 接入示例

## 明确不做

LLM 推理、操作系统沙箱、完整 MCP 传输、云端多租户工作台和通用 JSON Schema 解析器不在九月首版范围内。

## 来源与差异化说明

必须列出查到的 `moonbitlang/workflow`、MoonReplayKit、agent-telemetry、MCP Inspector、OpenSeek test harness 等相关项目，并用本人实际实验解释本项目新增的行为语义和接入方式。不要声称生态空白或全球首创。

