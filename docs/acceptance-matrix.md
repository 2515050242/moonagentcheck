# MoonAgentCheck 验收矩阵

核对日期：2026-10-21。矩阵对应当前源码的检查入口；历史发布快照见 [审计记录](audit.md)。完整命令及预期结果见 [验收指南](acceptance-guide.md)。

| 验收项 | 当前证据 | 验证方式与边界 |
| --- | --- | --- |
| MoonBit 为主要实现语言 | `src/*.mbt`、`main/main.mbt`、`moon.mod` | 核心评估与 Responses 适配在 MoonBit 内运行；Python 不作为评估真值来源 |
| 工具链 | 三个 CI job 共用 `0.10.16+b1a0e846e` | 主 job 校验完整版本号；各 job 显示实际工具链 |
| 构建、检查与回归 | 96 项 MoonBit 测试 | `moon fmt --check src main`、`moon build`、`moon check`、`moon test`；25 条既有弃用提示不等于错误 |
| 调用与结果关联 | `src/contract.mbt`、`contract_test.mbt` | `AGC011` 检查工具名和操作 ID；重复 call ID 不能改写首个身份 |
| 重试与重复副作用 | `attempts`、`completed` 状态及核心回归 | 重试超限与重复写入 `AGC004` 的正反例 |
| 写入前置条件 | `AGC010`、`AGC016` | 写入必须关联同一工具和操作的成功调用，未知或失败结果不能授权写入 |
| 未知结果失败关闭 | `AGC018` | `ok: null` 独立产生违规；Responses completed 无 outcome 时归档报告 `passed: false` |
| 工具策略与来源 | `EvaluationPolicy`、`PolicyContext`、套件策略传递 | allowlist、空列表、来源缺失与多场景入口回归；不把来源字符串当授权凭据 |
| 输入预检与稳定报告 | `AGC013`–`AGC015`、JSON 报告 | 空字段、未知事件、负重试策略与 JSON 字符编码回归 |
| 场景工具层 | Trace、检索、回放、差分、指标、Catalog、SuiteRunner、QualityGate | 对应 `src/*_test.mbt`，检查隔离、顺序、统计与策略传递 |
| 可运行 MoonBit 入口 | `main/main.mbt`、`main/responses_json_test.mbt` | 无参断言 AGC004；JSON 输入测试正常、未知结果、混合输出、未支持项和非法输入 |
| Python 实际接入 | 5 个 fixture 与 `examples/moonbit_cli.py` | 子进程调用 MoonBit；解析报告后断言，失败不回退 Python 评估器 |
| Responses 混合输出 | `src/responses_adapter.mbt` 及回归 | 只跳过 message/reasoning；未支持类型保留 item_index 并令报告失败 |
| 自动验证 | `.github/workflows/ci.yml` | 当前 SHA 的 moonbit、smoke-fixtures、published-package-smoke 三个 job 均须成功 |
| 已发布包消费 | `examples/mooncakes-consumer` 固定 `0.3.0` | CI 复制到仓库之外，`moon update`、`moon build`、`moon test`，2 项测试真实调用并解析公开 Responses 报告，验证成功通过与未知结果 AGC018 拒绝 |
| 新版本发布 | Mooncakes、源码与消费依赖统一为 `0.3.0` | 包页版本与构建状态、registry 安装和消费测试分别核对；见[发布说明](releases/0.3.0.md) |
| 开源与来源 | 完整 Apache-2.0、`moon.mod`、`docs/provenance.md` | 原创实现、公开接口参考与许可范围清楚 |
| 申报可读性 | [申报 Markdown](项目申报书.md)、[PDF](../output/pdf/october-proposal.pdf)、README | 项目名、版本、测试数与真实接入行为一致，不宣称未完成的集成或性能 |

## 判断原则

同一事件序列应产生相同规则码和事件位置。未知结果、映射失败和非法输入不得成为通过报告；负例测试通过，是指程序正确拒绝该负例。实际项目完成度与最终验收结论由组委会评定。
