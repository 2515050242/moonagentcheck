# 来源、许可证与适配说明

## 项目来源

MoonAgentCheck 是为 MoonBit Agent 应用设计的原创项目，不是对某个现有 Agent 框架、MCP SDK、workflow 引擎或 replay 工具的代码移植。

选题阶段查阅过 Mooncakes 上的 Agent、LLM、MCP、workflow、replay 和 telemetry 相关包，用来确认职责边界和避免重复。现有项目的名称、能力和链接只用于生态定位，不作为本项目的代码来源。

## 代码来源

- `src/` 中的 MoonBit 代码由本项目编写；
- `examples/python_data_agent.py` 使用 Python 标准库编写，仅用于演示相同的事件规则；
- `docs/*.svg` 是仓库内手写的 SVG 矢量图，不包含第三方图片资源；
- 项目没有复制第三方仓库的源代码、测试夹具或生成文件。

## 许可证

本项目使用 Apache-2.0，完整文本见仓库根目录的 [LICENSE](../LICENSE)。如果未来添加第三方 adapter 或 fixture，会在对应目录和提交说明中记录来源、原许可证以及 MoonBit 适配改动。

## 适配方式

MoonAgentCheck 不要求调用方替换 Agent runtime。调用方只需将自己的工具调用记录转换为 `Event`：

- `call_id` 标识一次具体调用；
- `operation_id` 标识一次业务操作；
- `kind` 表示 `call`、`result` 或 `write-complete`；
- `ok` 保留工具结果状态，但不会被评估器擅自解释为业务成功。

这种适配方式把框架差异留在 adapter 中，把契约判断集中在 MoonBit 核心库中。
