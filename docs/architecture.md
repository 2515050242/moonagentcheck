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
          ▼
     evaluate 一次扫描
          │
          ├── Violation(rule, event_index, message)
          └── rule_code / violation_code
                    │
                    ▼
       MoonBit test + Python fixture + CI
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
- `src/report.mbt`：稳定规则编码；
- `src/*_test.mbt`：规则、边界和报告编码测试；
- `examples/`：数据处理与仓库助手的离线对照 fixture；
- `.github/workflows/ci.yml`：MoonBit 和 Python 的公开验证入口。

## 有意留下的空位

JSON 报告、CLI、完整 MCP transport 和真实 Agent adapter 没有被提前塞进核心层。它们将来可以接在 `Violation` 之后，但只有在事件格式和使用场景稳定后才进入主线。这是质量边界，不是遗漏的隐藏功能。
