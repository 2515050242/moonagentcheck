# Changelog

## Unreleased

- 增加 `duplicate-result` 和 `missing-operation-id` 行为检查；
- 增加重复调用、重复结果和缺少操作 ID 的回归测试；
- CI 增加 Python 对照示例的可运行验证；
- 增加来源、许可证与工程风险审计说明。
- 增加 `failed-result` 规则，拒绝把失败工具结果当成成功；
- 增加稳定违规编码（`AGC001`–`AGC009`）和未知规则回退；
- 增加仓库助手的读后写 smoke fixture；
- 修复 CI 中失效的 MoonBit action，改用官方 CLI 安装脚本。

## 0.1.4 - 2026-09-06

- 发布 MoonBit 核心事件模型和确定性行为评估器；
- 支持孤立结果、缺失结果、重试限制、重复副作用和重复调用 ID 检查；
- 发布中文项目结构图、事件流程图和仓库结构图；
- 发布到 Mooncakes：`2515050242/moonagentcheck@0.1.4`。
