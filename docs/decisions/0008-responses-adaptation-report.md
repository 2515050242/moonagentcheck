# 决策记录 0008：适配问题与核心违规共用一份归档报告

## 背景

Responses 的离线适配分成两个阶段：先把可确认字段转成 `Event`，再用策略评估这些事件。前一阶段可能因为空身份字段或没有前置调用的 output 而无法产生可信事件；后一阶段则可能发现策略或行为契约违规。若调用方只归档后者，映射失败会被误读成一条通过的空轨迹。

## 决策

新增 `responses_evaluation_report_json(items, context)`。它在一次调用中运行既有的 `adapt_responses_items` 和 `evaluate_with_context`，产出稳定 JSON，包含适配器标识、已映射事件数、按输入顺序的 `mapping_issues`、策略来源与值，以及按评估顺序的核心 `violations`。顶层 `passed` 仅在两类证据均为空时为真。

`mapping_issues` 不是核心规则，不伪造 `Violation` 或占用 `AGC` 代码；每项只保留其原始 `item_index` 和诊断消息。核心违规仍使用既有稳定编码。这能让接入方区分“没有足够证据产生事件”和“产生的事件违反了契约”。

## 取舍

报告仍只接受调用方已提取、按观测顺序排列的 `ResponsesItem`，不增加 JSON parser、HTTP 客户端、文件写入或 Responses runtime。也不把 `mapping_issues` 当作工具失败或自动修复它们；这样不会把不完整遥测提升为成功证据。
