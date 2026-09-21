# Changelog

## Unreleased

- 增加 `PolicyContext`、`evaluate_with_context` 与 `evaluation_report_json`：受限策略必须带非空配置来源，空来源报告 `missing-policy-source` / `AGC017`，便于离线 CI 审计 allowlist 的来处。
- 增加 `write-call-mismatch` / `AGC016`：写入完成必须与对应成功调用的工具名和业务操作 ID 一致，并加入 MoonBit/Python 对照回归。
- 增加策略感知的多场景与目录评估 API；`SuiteRunner` 现在完整传递工具 allowlist，避免回归套件意外放宽权限检查。

- 增加 `duplicate-result` 和 `missing-operation-id` 行为检查；
- 增加重复调用、重复结果和缺少操作 ID 的回归测试；
- CI 增加 Python 对照示例的可运行验证；
- 增加来源、许可证与工程风险审计说明。
- 增加 `failed-result` 规则，拒绝把失败工具结果当成成功；
- 增加稳定违规编码（`AGC001`–`AGC010`）和未知规则回退；
- 写入必须关联到明确成功的调用结果，新增 `AGC010` 并覆盖失败/未知状态；
- 增加仓库助手的读后写 smoke fixture；
- 修复 CI 中失效的 MoonBit action，改用官方 CLI 安装脚本。
- 增加 `result-call-mismatch` / `AGC011`，拒绝工具名或 `operation_id` 不一致的工具 result。
- 增加命名场景套件 API，批量评估多条相互隔离的 trace 并保留逐场景结果。
- 增加 Trace 构造器、输入预检、轨迹统计和规则/套件级聚合，扩大库的复用边界。
- `0.2.0` 开发线增加轨迹查询、逐步回放、字段级差分、工具/操作指标、策略审计、场景目录、套件运行器和质量门禁；
- 新增 34 个工具层回归测试，当前 MoonBit 测试总数为 66 个；

## 0.1.4 - 2026-09-06

- 发布 MoonBit 核心事件模型和确定性行为评估器；
- 支持孤立结果、缺失结果、重试限制、重复副作用和重复调用 ID 检查；
- 发布中文项目结构图、事件流程图和仓库结构图；
- 发布到 Mooncakes：`2515050242/moonagentcheck@0.1.4`。
