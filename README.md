# moonagentcheck

给 agent 的工具调用做一遍离线体检。

这个项目目前很小：MoonBit 核心库接收一串工具事件，按确定性的规则找出“调用没有结果”“结果找不到调用”“重试太多次”“同一个写操作完成了两遍”这类问题。它不连接模型，也不替你做沙箱；它只检查已经观察到的事件。

## 先跑起来

```powershell
moon check
moon test
python examples/python_data_agent.py
```

`Event::new(...)` 用来构造观察记录，`evaluate(events, max_retries)` 返回 `Violation` 数组。`violation_code(violation)`（或按规则名调用 `rule_code(rule)`）将内置规则映射为稳定的机器代码（`AGC001` 到 `AGC009`），未知规则返回 `unknown`，方便适配器做筛选和聚合。Python 文件是一个离线对照 fixture，不是第二套核心实现。

## 现在的边界

- 检查是确定性的，不访问网络、真实服务或真实文件系统；
- `call_id` 标识一次工具调用，`operation_id` 标识一次可能重试的逻辑操作；
- 当前结果是结构化数组和稳定规则代码；JSON 报告和 CLI 还没有稳定下来；
- 事件格式和规则会先跟着真实场景长出来，再考虑更大的适配层。

## 仓库里的几条线

代码在 `src/`，可运行的离线样例在 `examples/`。`docs/` 里留着选题、验收和决策记录——它们是开发过程的旁证，不是使用手册。想看整体关系，可以从 [架构说明](docs/architecture.md)、[行为契约](docs/behavior-contract.md) 和 [开发记录](docs/development-log.md) 开始。

## 当前进度

第一轮核心能力已经落地：`Violation` 有稳定错误码，失败工具结果会被报告，数据处理和仓库助手各有一个离线 fixture，GitHub Actions 会跑 MoonBit 与 Python 两组检查。接下来再评估 JSON 报告和工单重试场景，不为了堆功能提前扩大范围。每个小步都应该有能运行的测试；如果实现和假设冲突，先修正假设。

## 许可

Apache-2.0，见 [LICENSE](LICENSE)。
