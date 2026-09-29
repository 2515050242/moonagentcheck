# 工程风险审计记录

## 审计范围

本次审计对照以下风险检查仓库：初始提交是否过大、提交说明是否能解释变化、目录是否存在空壳抽象、README 是否超出实现、CI 和示例是否可复现、测试是否覆盖真实回归、来源和许可证是否清楚。

审计只产生新的修复提交，不改写已有提交历史，也不补造过去不存在的测试或性能数据。

## 已发现并修复

- 仓库原 `LICENSE` 只有 Apache-2.0 的简短提示而非完整条款；已替换为 Apache 官方完整文本，并经 GitHub API 确认为 SPDX `Apache-2.0`；
- CI 原本通过 `moon run main` 间接编译；现单列 `moon build`，使验收要求中的构建步骤可见且可单独失败；
- 早期 README 对 JSON 能力的描述曾落后于实现，现已补齐场景明细、套件汇总、策略来源和 Responses 适配报告的说明；
- CI 只有 MoonBit 检查，已加入 Python 3.12 示例 smoke test；
- `duplicate-call-id` 没有独立回归测试，已补充；
- 重复结果此前没有明确报告，已加入 `duplicate-result` 规则和测试；
- 写入事件缺少 `operation_id` 时此前会被忽略，已加入 `missing-operation-id` 规则和测试；
- Python 对照实现此前会从 pending 集合中移除调用，和 MoonBit 的状态模型不完全一致，已统一；
- 已增加来源、许可证与适配说明，明确项目是原创实现，没有复制第三方代码。
- 已增加稳定的违规编码，未知规则保留 `unknown` 回退，便于适配器升级。
- 已把失败工具结果纳入契约检查，并用数据处理 fixture 固化“失败不能当成功”。
- 已增加仓库助手的读后写 smoke fixture，并让它进入 CI。
- 已将 CI 的失效 MoonBit action 替换为官方 CLI 安装脚本。
- 已把场景评估扩展为 Trace 构造、输入预检、事件统计和规则/套件聚合，避免只靠核心扫描器堆叠规则。
- 已加入通用 Python 记录 adapter，缺字段、非法类型和未知事件会在进入评估器前失败，并进入 CI smoke test。
- 已补充轨迹查询、回放、差分、指标、策略、场景目录、运行器和质量门禁，并为新增 API 配套回归测试。

## 当前验证

```text
moonc v0.10.14 → 满足赛事最低版本
moon fmt --check src main → 通过
moon build → 通过
moon check  → 通过
moon test   → 85 个测试通过
moon run main → 通过
Python fixtures → 三类业务场景、通用 adapter 和 Responses fixture 共 5 个均通过
消费方 smoke → 安装 `2515050242/moonagentcheck@0.2.0`，import `src` 包并调用 `Event::new`、`evaluate`，`moon run cmd/main` 通过
```

提交 `554bd08` 的 [GitHub Actions](https://github.com/2515050242/moonagentcheck/actions/runs/36593685126) 两个 job 均通过。MoonBit job 显式执行格式检查、最低版本门禁、`moon build`、`moon check`、`moon test` 和验收演示；另一个 job 执行 5 个 Python fixtures。后续改动推送后仍应核实最新 SHA 的两个 job，而不是沿用旧提交结果。

许可证文本与 [Apache 官方 2.0 文本](https://www.apache.org/licenses/LICENSE-2.0.txt)逐行一致；GitHub API 将其识别为 `Apache-2.0`。

为避免覆盖本机现有安装，本轮在临时隔离目录使用 `moonc v0.10.14` 验证；系统默认终端仍可能解析到 `v0.10.11`，本机后续直接运行时应先按 README 升级工具链。最初 0.10.14 检查报告的 440 条警告中，415 条来自测试文件隐式引用同包符号；本地修正后，这类警告已清零。当前仍有 24 条派生 trait 隐式提升为方法的弃用提示，以及 1 条未使用包提示（合计 25 条非阻断警告）。这些警告没有被屏蔽，也不阻止构建和测试。

## 尚未宣称的能力

- JSON 报告已覆盖场景明细和套件汇总；尚未实现 CLI 文件输出；
- 尚未提供性能基准，因此不声称优于其他实现；
- 尚未接入真实 Agent、MCP 服务或云端系统，因此示例全部是离线 fixture；
- 尚未提供性能基准或真实框架兼容承诺；当前证据仍是可复现的离线事件与 CI 测试。
