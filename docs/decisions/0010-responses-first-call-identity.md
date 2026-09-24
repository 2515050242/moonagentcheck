# 决策记录 0010：Responses output 固定映射到首个 call 身份

## 背景

核心评估器把同一 `call_id` 的首条 `call` 当作不可改写的身份：重复 call 会产生 `duplicate-call-id`，但不能让后续 result 或写入改为匹配重复记录。Responses 适配器此前为了查找 `function_call_output` 的工具名和 `operation_id`，会把内部索引覆盖为最后一条同 ID 的 function call。这样一批事件在映射层和评估层对“这是谁的 output”得出了不同答案。

## 决策

适配器继续把每条可验证的 `function_call` 转为 event，以保留重复遥测供核心规则检查；其内部 `call_id` 索引只在第一次出现时写入。之后的 output 因此始终继承首条 call 的 `tool` 和 `operation_id`。

MoonBit 回归覆盖第一条 `write_file` / `export-47` 被第二条 `send_email` / `notify-48` 复用同一 ID 的边界，断言 output 仍回填首条身份，评估只报告重复 ID。Python fixture 覆盖同一公开字段形状，作为独立的可运行映射证据。

## 取舍

此策略不尝试猜测哪条重复遥测“才是真的”，也不丢弃原始重复事件。它只让 adapter 与核心的确定性身份契约一致；仍不添加 Responses 客户端、JSON parser、网络、文件写入或 Agent runtime。
