# moonagentcheck

给 agent 的工具调用做一遍离线体检。

MoonBit 核心库接收一串工具事件，按确定性的规则找出“调用没有结果”“结果找不到调用”“重试太多次”“失败或未确认的调用之后仍然写入”“同一个写操作完成了两遍”这类问题。它不连接模型，也不替你做沙箱；它只检查已经观察到的事件。

## 先跑起来

```powershell
moon check
moon test
python examples/python_data_agent.py
python examples/python_repository_agent.py
python examples/python_ticket_agent.py
```

`Event::new(...)` 用来构造观察记录，`evaluate(events, max_retries)` 返回 `Violation` 数组，并继续保持不限制工具的兼容行为。需要配置策略时，使用 `EvaluationPolicy::new(max_retries, tool_allowlist)` 和 `evaluate_with_policy(events, policy)`：`None` 表示不限制工具，`Some([])` 表示拒绝所有工具；allowlist 以外的调用报告 `tool-not-allowed`（`AGC012`），并继续检查其他规则。要在一次回归中检查多条独立轨迹，可用 `Scenario::new(name, events)` 和 `evaluate_scenarios(scenarios, max_retries)`；结果按输入顺序保留场景名称、通过状态和违规明细，每条轨迹单独评估。工具 result 必须与同一 `call_id` 的 call 在工具名和 `operation_id` 上一致；不一致会产生 `AGC011`，且不能使调用成为成功。写入完成必须关联到返回明确成功结果的调用；失败或状态未知会产生 `AGC010`。`violation_code(violation)`（或按规则名调用 `rule_code(rule)`）将内置规则映射为稳定的机器代码（`AGC001` 到 `AGC015`），未知规则返回 `unknown`，方便适配器做筛选和聚合。Python 文件是离线对照 fixture，不是第二套核心实现。
适配器也可以使用 `Trace::new()`、`trace.call(...)`、`trace.result(...)` 和 `trace.write_complete(...)` 逐步构造可回放事件流；`trace_stats(...)` 提供事件、调用、结果、写入以及成功/失败/未知结果的统计。`summarize_violations(...)` 和 `summarize_scenarios(...)` 可将逐事件证据聚合到规则与套件层。输入预检会报告空 `call_id`、空工具名、未知事件类型和负重试策略（`AGC013`–`AGC015`）。

## JSON 报告

`scenario_results_json(results)` 将 `evaluate_scenarios` 的结果转成紧凑、稳定的 JSON 数组。场景和违规项均保留输入/评估顺序；每个违规项固定包含 `code`、`rule`、`event_index` 与 `message`，适合 CI 采集和后续聚合。

```moonbit
let results = evaluate_scenarios(scenarios, 2)
let report = scenario_results_json(results)
// [{"name":"read-ok","passed":true,"violations":[]}]
```

报告使用 MoonBit 标准库 JSON 编码器，因此引号、反斜线、换行、控制字符和中文字符串都会被正确表示；API 不读写文件，也不引入 CLI。

`suite_summary_json(summarize_scenarios(results))` 输出场景通过数、失败数、违规总数和按规则聚合的稳定编码，适合作为 CI 门禁的单条汇总结果。

## 现在的边界

- 检查是确定性的，不访问网络、真实服务或真实文件系统；
- `call_id` 标识一次工具调用，`operation_id` 标识一次可能重试的逻辑操作；
- 当前结果提供结构化数组、稳定规则代码和稳定 JSON 报告；不提供 CLI；
- 事件格式和规则会先跟着真实场景长出来，再考虑更大的适配层。

## 仓库里的几条线

代码在 `src/`，可运行的离线样例在 `examples/`。`docs/` 里留着选题、验收和决策记录——它们是开发过程的旁证，不是使用手册。想看整体关系，可以从 [架构说明](docs/architecture.md)、[行为契约](docs/behavior-contract.md) 和 [开发记录](docs/development-log.md) 开始。

## 当前进度

当前开发线已经扩展为四层证据链：事件模型与规则评估、Trace/输入预检工具、场景与规则汇总、Python 记录适配器。MoonBit 测试覆盖核心规则和工具层，Python 侧保留三个真实问题 fixture，并在 CI 中执行通用 adapter smoke test。项目仍然不重新实现 Agent 框架；扩大的是可复用的验证边界，而不是堆叠与核心职责无关的组件。每个小步都应该有能运行的测试；如果实现和假设冲突，先修正假设。

## 许可

Apache-2.0，见 [LICENSE](LICENSE)。
