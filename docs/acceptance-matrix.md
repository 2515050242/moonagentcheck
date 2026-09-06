# MoonAgentCheck 验收矩阵

这份矩阵把参赛要求转换为可检查的仓库证据。每一项都应能落到源码、测试、命令或文档，而不是只停留在描述中。

| 验收项 | 当前证据 | 验证方式 | 比赛阶段补强 |
| --- | --- | --- | --- |
| MoonBit 为主要实现语言 | `src/*.mbt`、`moon.mod` | `moon check` | 保持核心规则在 MoonBit 中实现 |
| 包可发布 | `moon.mod`、Mooncakes 版本 `0.1.4` | `moon publish --dry-run` / `moon publish` | 发布比赛截止前版本 |
| 调用与结果配对 | `src/contract.mbt` | `contract_test.mbt` | 增加多结果和重复结果边界 |
| 重试次数限制 | `attempts` 状态表 | `enforces retry limit` | 增加 0、1、最大值边界 |
| 副作用防重复 | `completed` 状态表 | `detects duplicate side effect` | 增加不同 operation_id 对照 |
| 写入前置调用 | `write-without-call` 规则 | `requires a call before a write` | 增加授权字段 adapter |
| 事件结束时完整性 | `missing-result` 规则 | `detects orphan and missing results` | 增加空事件流和多调用场景 |
| 可重复执行 | 无网络、无模型调用 | 连续运行 `moon test` | 固化 JSON fixture |
| Python 接入参考 | `examples/python_data_agent.py` | 本地 Python 运行 | 增加通用 adapter 和 JSON 输出 |
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

