# OpenAI Responses 离线适配

`src/responses_adapter.mbt` 是一个面向 OpenAI Responses 函数调用项目的薄适配层。它只接收已经记录的字段、生成本项目的 `Event`，不解析 JSON、不发送请求，也不执行工具。

字段依据是官方 [Responses API reference](https://platform.openai.com/docs/api-reference/responses-streaming/response/web_search_call?lang=curl)：`function_call` 有 `call_id` 和 `name`，`function_call_output` 用 `call_id` 关联输出，输出项状态为 `in_progress`、`completed` 或 `incomplete`。

## 字段映射

| 已记录字段 | `Event` 字段 | 规则 |
| --- | --- | --- |
| `function_call.call_id` | `call_id` | 原样保留 |
| `function_call.name` | `tool` | 原样保留；output 通过前置 call 回填 |
| 应用遥测信封的 `operation_id` | `operation_id` | 显式提供；不要将 `response_id` 误作业务操作 |
| `function_call_output.status` + 执行器 `outcome` | `ok` | `incomplete` 为失败，`in_progress` 为未知，`completed` 仅保留明确的 `outcome` |

`response_id` 会被校验为非空，作为采集到的协议身份；当前核心 `Event` 没有该字段，因此不会把它改写为 operation ID。一个 response 可包含并行工具调用，这种改写会错误地把并行调用算作同一业务操作的重试。

## MoonBit 用法

```moonbit
let trace = adapt_responses_items([
  responses_function_call(
    "resp_42",
    Some("ticket-42"),
    "call_42",
    "update_ticket",
  ),
  responses_function_call_output(
    "call_42",
    responses_completed(),
    Some(true), // 由实际工具执行器观测
  ),
])
assert_true(trace.issues.length() == 0)
let violations = evaluate(trace.events, 2)
```

没有先前 `function_call` 的 output 不会凭空创建 `tool`；它会出现在 `trace.issues` 中。若应用确实完成了写入，仍需从执行器记录既有 `write-complete` 事件，让核心规则验证副作用与成功 result 的关联。

## 归档一批适配与评估证据

`responses_evaluation_report_json(items, context)` 将同一批的适配问题、策略来源和核心违规编码为稳定 JSON。顶层 `passed` 只有在没有 `mapping_issues`、也没有核心 `violations` 时才是 `true`；前者不是伪造的核心规则，后者仍保留 `AGC` 代码。

```moonbit
let context = PolicyContext::new(
  "ci/ticketing-policy",
  EvaluationPolicy::new(1, Some(["get_ticket"])),
)
let archive = responses_evaluation_report_json(items, context)
// {"adapter":"openai-responses-function-call", ...}
```

报告不读取或写入文件，也不解析网络响应；调用方仍负责提取并按观测顺序提供 `ResponsesItem`。

## 可复现 fixture

`examples/python_openai_responses_fixture.py` 用 Python 标准库构造相同的公开字段形状，验证 call/result 的关联和“不能由孤立 output 猜工具名”的边界。它是离线 fixture，不是产品的第二套规则实现。
