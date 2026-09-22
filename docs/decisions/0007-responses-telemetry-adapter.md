# 决策记录 0007：以 Responses 函数调用记录构造可审计轨迹

## 背景

OpenAI Responses API 的 `function_call` 项包含生成的 `call_id` 与函数 `name`；对应的 `function_call_output` 只带同一 `call_id` 和输出项状态。官方参考也说明输出项的状态为 `in_progress`、`completed` 或 `incomplete`。[Responses API reference](https://platform.openai.com/docs/api-reference/responses-streaming/response/web_search_call?lang=curl) 是本适配 fixture 的字段来源。

这带来两个容易被掩盖的边界：output 本身没有工具名，且 `completed` 表示 API 项已完成，并不能证明应用工具的业务副作用成功。Responses 格式也没有 MoonAgentCheck 所需的逻辑业务操作 ID。

## 决策

新增 MoonBit `ResponsesItem` 和 `adapt_responses_items`。`function_call` 的 `call_id` 映射到 `Event.call_id`、`name` 映射到 `Event.tool`；output 仅通过此前的 call 按 `call_id` 回填工具名和 operation。调用方的遥测信封显式提供 `operation_id`，避免把一次 response 的 ID 错当作业务操作并将并行函数调用计为重试。

`incomplete` 映射为失败；`in_progress` 映射为未知；`completed` 仅保留执行器单独观察到的 `outcome`，缺失 outcome 时仍为未知。没有前置 call 的 output 产生映射问题而不伪造 Event。Python 文件只作为相同格式的离线 fixture，规则仍由 MoonBit 核心执行。

## 取舍

本次不添加 JSON 解析、HTTP 客户端或 Responses runtime，也不宣称 output 文本能表示业务成功。适配层接收已提取且按观测顺序排列的字段，保持核心可离线复现；真实应用若需写入完成证据，仍必须从其执行器追加既有 `write-complete` 事件。
