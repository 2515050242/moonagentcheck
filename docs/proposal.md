# MoonAgentCheck 项目申报书

## 基本信息

- **项目名称：** MoonAgentCheck：面向 Agent 应用的行为契约与可重复测试工具
- **参赛者：** 韦昌斌
- **联系方式：** 19877252036
- **GitHub 仓库链接：** [https://github.com/2515050242/moonagentcheck](https://github.com/2515050242/moonagentcheck)
- **Mooncakes 模块：** `2515050242/moonagentcheck`
- **项目方向：** MoonBit Agent 工程基础设施 / 行为测试与安全回归
- **是否为移植项目：** 否，原创项目
- **项目许可证：** Apache-2.0

## 项目简介

MoonAgentCheck 面向使用 MoonBit、Python、MCP 或 workflow 构建的 Agent 应用，提供一个与运行时解耦的行为契约和离线回归测试层。

Agent 应用的难点不只在于模型能否生成正确文本，更在于它是否按照正确的顺序调用工具、是否在失败后合理重试、是否在得到结果前继续执行，以及是否重复执行写文件、发消息、提交工单等不可逆副作用。传统单元测试通常只检查单个函数，日志系统只能记录已经发生的事情，难以直接表达这些跨事件的约束。

MoonAgentCheck 将 Agent 的工具调用记录规范化为事件流，再通过确定性的状态扫描检查行为契约。它不运行模型、不连接真实服务、不接管 Agent runtime，因此可以放进本地测试和 CI，复现同一段行为并得到同样的违规报告。

项目当前已经发布 `2515050242/moonagentcheck@0.1.4`，核心检查、MoonBit 测试、Python 对照 fixture、CI 和中文结构图均已进入公开仓库。比赛阶段将在此基础上继续补齐结构化报告和三个完整场景。

## 项目价值与生态定位

MoonBit 生态已经出现 Agent SDK、LLM、MCP、workflow、replay 和 telemetry 等方向的项目，但这些项目分别解决 Agent 如何运行、工具如何连接、流程如何编排、状态如何回放和日志如何观测的问题。它们之间仍缺少一个轻量的行为验证层，用来回答：

> 这段 Agent 行为是否满足预先声明的工程约束？

MoonAgentCheck 补齐的生态位如下：

```text
Agent / LLM / MCP / Workflow
              │
              ▼
       Event Adapter
              │
              ▼
        MoonAgentCheck
              │
              ▼
    可复现的违规与回归报告
```

项目不重新实现 Agent runtime，也不与 workflow、replay 或 telemetry 竞争。它只约束事件边界，因此可以作为这些项目的测试组件使用。

这个生态位的重要性在于 Agent 的错误可能产生真实副作用：重复写数据库、重复提交工单、覆盖文件、误发消息或在失败后继续执行。模型回复有时可以人工修正，但已经发生的副作用很难恢复。一个不依赖模型和网络的检查器，可以把这类问题提前变成 CI 中可复现的失败。

## 核心功能范围

### 已交付功能

- 提供 `Event` 事件模型，记录事件类型、工具名、`call_id`、`operation_id` 和结果状态；
- 提供 `Violation` 违规模型，记录规则名、事件索引和说明；
- 提供 `Event::new(...)` 构造函数；
- 提供 `evaluate(events, max_retries)` 确定性评估入口；
- 检查孤立结果 `orphan-result`；
- 检查调用结束时没有结果的 `missing-result`；
- 检查同一逻辑操作超过重试上限的 `retry-limit`；
- 检查重复完成同一逻辑写操作的 `duplicate-side-effect`；
- 检查没有对应调用就产生写入完成事件的 `write-without-call`；
- 检查同一事件流复用调用 ID 的 `duplicate-call-id`；
- 提供五个 MoonBit 可执行测试；
- 提供不访问模型、网络和真实文件系统的 Python 对照 fixture；
- 提供 GitHub Actions，自动执行 `moon check` 和 `moon test`；
- 提供中文 SVG 架构图、事件流程图和仓库结构图，降低项目审核成本。

### 比赛阶段计划交付

- 增加结构化 JSON 报告，便于 CI 和 Python adapter 消费；
- 增加三个完整可复现场景：数据处理 Agent、仓库助手 Agent、工单处理 Agent；
- 为缺失字段、重复调用、无结果写入、边界重试次数增加测试；
- 增加一个简洁的 Python adapter，把常见调用记录转换成 `Event`；
- 在 README 中提供从安装 Mooncakes 包到执行测试的完整示例；
- 保持核心评估器无网络、无模型、无隐式时间依赖；
- 发布一份真实开发记录和验收矩阵，让每个功能都能对应到源码、测试和运行命令。

## 预期验收产物

- GitHub 公开仓库：[2515050242/moonagentcheck](https://github.com/2515050242/moonagentcheck)；
- Mooncakes 包：`2515050242/moonagentcheck`；
- 可被其他 MoonBit 项目通过 `moon add 2515050242/moonagentcheck` 引入的核心库；
- 一套独立于 Agent runtime 的事件模型和行为评估器；
- 至少三个完整 Agent 场景的离线 fixture 和测试报告；
- 能够在 CI 中执行的 `moon check`、`moon test` 和示例验证命令；
- README、行为契约、架构图、范围决策和验收矩阵；
- Apache-2.0 许可证和清晰的来源说明。

验收重点是行为检查结果的可复现性，而不是承诺支持所有 Agent 框架。对于同一输入事件流，评估器应产生相同的违规规则、事件索引和说明。

## 实现路径与技术理解

项目没有采用“重新实现一个完整 Agent 框架”的路径，也没有绑定某个单一 SDK。实现路径是：

1. 用 adapter 将具体框架的调用日志转换为小型事件模型；
2. 用 `call_id` 关联一次具体调用，用 `operation_id` 关联一次业务动作；
3. 用 Map 和 Array 保存尝试次数、已解析调用和已完成副作用；
4. 对事件流做一次确定性扫描，输出违规集合；
5. 用离线 fixture 复现真实问题，再通过 MoonBit 测试和 CI 固化行为。

核心评估器的时间复杂度为 O(n)，空间复杂度为 O(n)，其中 n 是事件数量。评估器不会调用模型、网络或真实工具，因此测试不依赖模型随机性、网络状态和系统时间。

项目中特别区分 `call_id` 和 `operation_id`：一次业务动作可以因为临时失败产生多个调用，但同一个 `operation_id` 不能被重复标记为写入完成。这个区分使“允许有限重试”和“禁止重复副作用”能够同时成立。

## 明确不做的内容

- 不实现 LLM 推理和 Agent runtime；
- 不实现完整 MCP transport；
- 不实现操作系统级沙箱或权限隔离；
- 不实现云端控制台、账号系统和分布式 tracing；
- 不实现通用 JSON Schema 验证器；
- 不保证模型输出的自然性、事实性或稳定性；
- 不把回归报告当成密码学安全证明；
- 不承诺对所有第三方 Agent 框架自动接入。

这些内容可以在后续通过 adapter、插件或独立项目扩展，但不纳入本次首版验收，以保证核心库、测试和文档能够按期完成。

## 项目推进状态

当前公开版本为 `0.1.4`。已经完成源码包、Mooncakes 发布、CI、核心测试、Python fixture 和审核用 SVG 图。下一阶段重点是结构化报告、三个场景 fixture、Python adapter 和验收矩阵。提交历史会继续按真实功能拆分，避免空提交和只修改时间戳的提交。

