# OpenAI Responses 离线适配

`src/responses_adapter.mbt` 是一个面向 OpenAI Responses 输出项的薄适配层。它只接收已经记录的字段、生成本项目的 `Event`，不解析 JSON、不发送请求，也不执行工具。Responses 输出还可能包含消息和推理项；适配器只忽略明确支持的非工具项，不会把未知项当成已验证的工具行为。

字段依据是官方 [Responses API reference](https://platform.openai.com/docs/api-reference/responses-streaming/response/web_search_call?lang=curl)：`function_call` 有 `call_id` 和 `name`，`function_call_output` 用 `call_id` 关联输出，输出项状态为 `in_progress`、`completed` 或 `incomplete`。官方 [Responses API 指南](https://developers.openai.com/api/docs/guides/migrate-to-responses)也将 `message`、`reasoning`、`function_call` 和 `function_call_output`列为不同的项目类型。

## 字段映射

| 已记录字段 | `Event` 字段 | 规则 |
| --- | --- | --- |
| `function_call.call_id` | `call_id` | 原样保留 |
| `function_call.name` | `tool` | 原样保留；output 通过前置 call 回填 |
| 应用遥测信封的 `operation_id` | `operation_id` | 显式提供；不要将 `response_id` 误作业务操作 |
| `function_call_output.status` + 执行器 `outcome` | `ok` | `incomplete` 为失败，`in_progress` 为未知，`completed` 仅保留明确的 `outcome` |
| `message`、`reasoning` | 不生成 `Event` | 使用 `responses_non_tool_item(...)` 显式标记；不改变调用关联或评估结果 |

`response_id` 会被校验为非空，作为采集到的协议身份；当前核心 `Event` 没有该字段，因此不会把它改写为 operation ID。一个 response 可包含并行工具调用，这种改写会错误地把并行调用算作同一业务操作的重试。

若采集流里重复出现同一 `call_id`，适配器仍保留两条 call 事件，交给核心规则报告 `duplicate-call-id`；但后续 output 只会回填**首条** call 的工具名和 `operation_id`。这与核心的身份固定契约一致，避免晚到的重复遥测把 result 伪装成另一工具的成功。

## 混合输出用法

Responses 的 `output` 是带类型的项目序列，可以同时出现消息、推理内容和函数调用。调用方将相关字段转换为 `ResponsesItem` 时，应按原顺序传入；目前 `message` 与 `reasoning` 会被跳过，其他未支持类型会生成带原始项目索引的映射问题，不会被静默当作成功。

## MoonBit 用法

```moonbit
let trace = adapt_responses_items([
  responses_non_tool_item("message"),
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
  responses_non_tool_item("reasoning"),
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

`examples/fixtures/responses-ticket-traces.json` 是人工构造的合成遥测样例，不来自真实用户或线上会话。它保留了 Responses 工具调用的公开字段形状，并显式标注 `operation_id` 与 `outcome` 为应用侧遥测信封，用来表示核心事件模型需要的业务操作和执行器判断；这两个字段不声称是 Responses API 原生字段。

| 样例 | 预期结果 |
| --- | --- |
| `synthetic-ticket-update-success` | call 与成功 output 配对，违规列表为空 |
| `synthetic-ticket-update-unknown-outcome` | `completed` 缺少执行器 outcome，产生 `unknown-result` |
| `synthetic-output-without-call` | 拒绝没有前置 call 的 output，并报告映射错误 |
| `synthetic-unsupported-output-item` | 不静默忽略未支持类型，保留输入位置并报告映射错误 |

`examples/python_openai_responses_fixture.py` 使用标准库读取这份 JSON fixture，再调用离线参考 adapter 和行为规则逐项比对预期。GitHub Actions 将它作为单独步骤运行；MoonBit 的字段映射、未知结果及归档报告行为由 `src/responses_adapter_test.mbt` 覆盖。该 Python 脚本只充当测试夹具，不是产品的第二套规则实现，也不发起 API 请求。
