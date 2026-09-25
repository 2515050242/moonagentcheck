# MoonAgentCheck 架构说明

MoonAgentCheck 不把自己做成 Agent runtime。它更像一段放在 runtime 之后的“行为体检回路”：输入已经发生的工具事件，输出可以进入测试和 CI 的违规证据。

## 一条证据回路

```text
工具日志 / 受控 fixture
          │
          ▼
     Event adapter
          │  call_id：哪一次调用
          │  operation_id：哪一个业务动作
          │
接入配置 → PolicyContext(source + allowlist)
          ▼
     validate_events 预检
          │
          ▼
     evaluate 一次扫描
          │
          ├── Violation(rule, event_index, message)
          └── rule_code / violation_code
                    │
                    ▼
       场景/规则聚合 → JSON 报告
                    │
                    ▼
       MoonBit test + Python adapter + CI
```

这条线刻意没有模型、网络、真实工具和隐式时间条件。它让错误能够在没有服务凭证的环境里复现，也让“为什么失败”可以回到某一条事件和某一条规则。

## 两把钥匙

项目里最重要的不是目录数量，而是两个 ID 的分工：

- `call_id` 是一次具体工具调用的钥匙，用来配对 `call` 和 `result`，也用来发现重复调用和重复结果；
- `operation_id` 是一次业务动作的钥匙，用来统计重试次数和保护写入副作用。

一次业务动作可以有多个调用，但不能因为重试就把同一个写操作完成两遍。这种双钥匙模型比把所有状态压成一个 ID 更容易表达“可以重试，但不能重复副作用”。

## 当前代码落点

- `src/model.mbt`：事件和违规数据模型；
- `src/contract.mbt`：确定性状态扫描；
- `src/trace.mbt`：可回放轨迹构造和事件统计；
- `src/trace_query.mbt`：按工具、调用、操作和窗口查询轨迹；
- `src/validation.mbt`：适配器输入预检；
- `src/diagnostics.mbt`：严重级别、建议和诊断 JSON；
- `src/policy.mbt`：策略预设、权限决策和策略审计；
- `src/replay.mbt`：逐步回放、检查点和前缀验证；
- `src/diff.mbt`：期望轨迹与实际轨迹的字段级差分；
- `src/metrics.mbt`：工具和 operation 维度的风险统计；
- `src/scenarios.mbt` / `src/catalog.mbt`：内置场景和可检索目录；
- `src/quality_gate.mbt` / `src/runner.mbt`：CI 门禁与套件运行历史；
- `src/analysis.mbt`：规则与场景聚合；
- `src/report.mbt`：稳定规则编码和 JSON 报告；
- `src/*_test.mbt`：规则、边界和报告编码测试；
- `examples/`：三类业务场景、通用 Python 记录适配器和 Responses function-call fixture；
- `.github/workflows/ci.yml`：MoonBit 和 Python 的公开验证入口。

## 有意留下的空位

CLI、完整 MCP transport 和真实 Agent runtime 没有被提前塞进核心层。JSON 报告、Trace 工具和 Python adapter 已经接在 `Violation` 之后；`PolicyContext` 只记录接入配置的来源，不从待验证 trace 接受权限声明。它们仍保持无网络、无模型、无真实副作用的质量边界。这是质量边界，不是遗漏的隐藏功能。

模块之间保持单向依赖：模型和扫描器不依赖报告；查询、诊断、差分和指标只消费事件/违规；目录、运行器和门禁组合这些能力服务于回归，不反向改变核心规则。
