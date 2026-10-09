# Changelog

## 0.3.0 - Unreleased

- 已知的 Responses 非工具项继续跳过，未支持类型保留输入索引并报告映射问题；
- `ok: null` 产生 `unknown-result`（`AGC018`），诊断和归档报告会阻止轨迹判为通过；
- 增加合成 Responses JSON 轨迹 fixture，并由离线 Python fixture 和独立 CI 步骤核对预期；
- 生态定位说明按 2026-10-09 核对的 Mooncakes 页面补充来源与职责边界；
- 当前开发线包含 89 项 MoonBit 回归测试；本节对应未发布开发内容，尚未创建 Mooncakes 发布。

## 0.2.0 - 2026-09-29

- 增加策略上下文与来源审计报告；拒绝空策略来源，并保留稳定机器码；
- 扩展调用/结果/写入关联检查，固定重复 `call_id` 的首个身份，防止错配结果授权后续写入；
- 增加多场景目录、套件运行器、轨迹回放与查询、事件差分、统计指标和质量门禁；
- 增加 Python 通用记录 adapter 与 Responses function-call 离线 fixture；
- 扩展 MoonBit 回归测试至 85 项；CI 覆盖格式、最低编译器版本、显式构建、检查、测试、验收演示和 5 个 Python fixtures；
- 补齐完整 Apache-2.0 许可证文本。

## 0.1.4 - 2026-09-06

- 发布 MoonBit 核心事件模型和确定性行为评估器；
- 支持孤立结果、缺失结果、重试限制、重复副作用和重复调用 ID 检查；
- 发布中文项目结构图、事件流程图和仓库结构图；
- 发布到 Mooncakes：`2515050242/moonagentcheck@0.1.4`。
