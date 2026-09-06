# AgentCheck

给 agent 的工具行为写可重复测试。

AgentCheck 计划提供一个 MoonBit 核心库：把 agent 的工具调用记录规范化为事件流，用行为契约检查调用与结果是否配对、是否满足资源前置条件、是否超过重试上限、是否发生重复副作用。测试使用受控 fixture，不访问真实服务；结果可输出为人类可读文本或 JSON，便于放进 CI。

## 当前状态

这是 2026 年 9 月 MoonBit 黑客松的开发中项目。当前仓库先交付设计、一个 Python 参考实现和 MoonBit 核心实验；API、目录和行为规则会在真实用例验证后稳定下来。

## 计划中的三个场景

1. 数据处理 agent：工具返回缺失列错误时，测试 agent 是否把错误误当成成功。
2. 仓库助手：没有先读取目标文件，或没有获得对应授权时，测试是否阻止写入完成事件。
3. 工单处理 agent：暂时错误触发重试时，测试重试上限和重复写回。

## 快速试用 Python 参考实现

```powershell
python examples/python_data_agent.py
```

参考实现只用于验证事件模型和场景，不替代 MoonBit 核心。它不连接模型、网络或真实文件系统。

## MoonBit 计划接口

首版会稳定以下概念：`Event`、`Contract`、`Violation`、`RunReport` 和 `evaluate`。具体构造器和 `moon.pkg` 配置以实际安装的 MoonBit 工具链验证结果为准。

## 边界

首版不实现 LLM 推理、操作系统沙箱、完整 MCP 传输、云端工作台或通用 JSON Schema 解析器。行为检查验证观察到的事件，不提供实时安全隔离。

## 许可证

Apache-2.0，见 [LICENSE](LICENSE)。

