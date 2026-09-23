# 决策记录 0006：重复调用 ID 不能改写原始身份

## 背景

`call_id` 表示一项具体的工具调用，契约已经报告同一事件流中的重复 ID。此前评估器仍会把第二个 `call` 写入内部调用表；若该记录携带另一个工具或 `operation_id`，随后的 result 和 `write-complete` 便会与错误记录匹配，看起来像一次成功的副作用。

## 决策

首个 `call_id` 记录是该 ID 的唯一关联身份。后续同 ID 的 call 继续生成 `duplicate-call-id`，但不改变调用元数据、待完成状态或重试计数。之后的 result 与 write-complete 仍必须匹配首个调用，错配分别产生既有的 `result-call-mismatch` 或 `write-call-mismatch`。

## 取舍

这不是对乱序或异步调用施加限制；不同 ID 的 result 仍可按其自身 ID 在后续任意位置匹配。对于同一个 ID，保留首个观测既与“具体调用”的定义一致，也避免不可信的重复遥测重定义已经建立的证据链。该调整不增加运行时、传输层或外部状态。
