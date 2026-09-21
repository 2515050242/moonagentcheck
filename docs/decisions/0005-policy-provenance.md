# 决策记录 0005：策略必须带可审计来源

## 背景

`EvaluationPolicy` 已能限制工具和重试次数，但一个离线报告无法说明 allowlist 来自哪一份接入配置。把来源藏在事件日志中并不可靠：事件是待验证对象，不能借由自述内容提升自己的权限。

## 决策

新增 `PolicyContext`，由接入方在事件流之外显式提供非空 `source` 与 `EvaluationPolicy`。`evaluate_with_context` 使用该策略执行原有规则；若来源为空，先报告 `missing-policy-source`（`AGC017`）。`evaluation_report_json` 输出来源、实际策略参数、通过状态和稳定违规明细，供 CI 或离线审查保存。

`source` 是如 `ci/read-only-policy` 的可读配置标识，不是凭证，也不会从 trace 中读取。既有 `evaluate` 和 `evaluate_with_policy` 继续保留，避免破坏只需要基本评估的调用方。

## 取舍

本次不接入外部权限服务、不解析某个 Agent 框架的运行时对象，也不把报告当成访问控制器。它解决的是离线策略证据缺少来源这一实际审计缺口；具体框架仍只需把其配置位置映射为 `source`，再把已观察到的调用映射为稳定事件模型。
