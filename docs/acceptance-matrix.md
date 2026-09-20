# MoonAgentCheck 验收矩阵

这份矩阵把参赛要求转换为可检查的仓库证据。每一项都应能落到源码、测试、命令或文档，而不是只停留在描述中。

| 验收项 | 当前证据 | 验证方式 | 比赛阶段补强 |
| --- | --- | --- | --- |
| MoonBit 为主要实现语言 | `src/*.mbt`、`moon.mod` | `moon check` | 保持核心规则在 MoonBit 中实现 |
| 包可发布 | `moon.mod`、Mooncakes 版本 `0.1.4` | `moon publish --dry-run` / `moon publish` | 发布比赛截止前版本 |
| 调用与结果配对 | `src/contract.mbt` 的 `result-call-mismatch` / `AGC011` | 工具名不匹配、`operation_id` 不匹配与完全匹配的 MoonBit/Python 回归 | 增加乱序结果边界 |
| 可配置工具策略 | `EvaluationPolicy`、`evaluate_with_policy`、`evaluate_scenarios_with_policy`、`tool-not-allowed` / `AGC012` | allowlist 允许、拒绝、空列表、策略感知套件与旧 API 兼容的 MoonBit/Python 回归 | 增加 adapter 权限来源 |
| 重试次数限制 | `attempts` 状态表 | `enforces retry limit` | 增加 0、1、最大值边界 |
| 副作用防重复 | `completed` 状态表 | `detects duplicate side effect` | 增加不同 operation_id 对照 |
| 写入前置调用 | `write-without-call` 规则 | `requires a call before a write` | 增加授权字段 adapter |
| 事件结束时完整性 | `missing-result` 规则 | `detects orphan and missing results` | 增加空事件流和多调用场景 |
| 结果唯一性 | `duplicate-result` 规则 | `detects duplicate results` | 增加乱序结果和失败结果场景 |
| 写入关联完整性 | `missing-operation-id` 规则 | `requires an operation id for a write` | 接入 adapter 时保留业务操作 ID |
| 写入成功前置条件 | `write-without-successful-result` / `AGC010` | 失败、未知或 `AGC011` 关联不一致后的写入回归测试 | 增加授权字段 adapter |
| 可重复执行 | 无网络、无模型调用 | 连续运行 `moon test` | 固化 JSON fixture |
| MoonBit 可运行演示 | `main/main.mbt` | `moon run main`，断言重复写入返回 `AGC004` 并输出 JSON | 持续扩展真实适配示例 |
| 多场景回归 | `Scenario`、`ScenarioResult`、`evaluate_scenarios`、`suite_summary_json` | `suite_test.mbt` 与 `analysis_test.mbt` 检查隔离、顺序和汇总 | 增加违规阈值门禁 |
| 轨迹构造与统计 | `Trace` builder、`TraceStats`、`trace_stats` | `trace_test.mbt` 检查 call/result/write 和状态计数 | 提供框架 adapter 的字段映射 |
| 输入预检 | `validate_events` / `AGC013`–`AGC015` | 空字段、未知事件、负重试策略测试 | 增加错误定位和 adapter 诊断 |
| 违规聚合 | `RuleSummary`、`SuiteSummary` | `analysis_test.mbt` 检查规则计数和套件汇总 | 接入 CI 门禁与阈值 |
| 轨迹检索与回放 | `TraceQuery`、`Replay`、检查点 | `trace_query_test.mbt`、`replay_test.mbt` | 接入真实日志查看器 |
| 期望/实际差分 | `diff_events`、字段级 `EventDiff` | `diff_test.mbt` 检查新增、删除和元数据变化 | 增加跨版本 fixture |
| 工具与操作指标 | `collect_metrics`、风险统计 | `metrics_test.mbt` 检查成功率和重复写入 | 输出长期趋势 |
| 策略与 CI 门禁 | `PolicyProfile`、`QualityGate`、`SuiteRunner` | `policy_test.mbt`、`quality_gate_test.mbt`、`runner_test.mbt` | 增加报告归档 |
| Python 接入参考 | `examples/python_adapter.py`、三个场景 fixture | 本地 Python 运行与 malformed-record smoke test | 增加更多框架字段映射 |
| CI 自动验证 | `.github/workflows/ci.yml` | GitHub Actions | 增加示例 smoke test |
| 审核可读性 | `docs/*.svg`、`README.md` | GitHub 直接查看 | 保持图文与代码同步 |
| 开源合规 | `LICENSE`、`moon.mod` | 查看 Apache-2.0 声明 | 继续记录第三方参考来源 |

## 当前命令

```powershell
moon check
moon test
moon publish --dry-run
```

## 验收原则

同一事件序列必须产生同样的规则名、事件索引和说明。评估器不应通过网络请求、模型调用或隐藏的时间条件改变结果。

