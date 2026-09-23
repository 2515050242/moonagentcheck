# 工程风险审计记录

## 审计范围

本次审计对照以下风险检查仓库：初始提交是否过大、提交说明是否能解释变化、目录是否存在空壳抽象、README 是否超出实现、CI 和示例是否可复现、测试是否覆盖真实回归、来源和许可证是否清楚。

审计只产生新的修复提交，不改写已有提交历史，也不补造过去不存在的测试或性能数据。

## 已发现并修复

- README 曾把 JSON 输出写成当前能力，已改为明确说明“当前返回 `Violation` 数组，JSON 报告计划中”；
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
moon check  → 通过
moon test   → 76 个测试通过
moon fmt --check src main → 通过
Python fixtures → 三个场景与通用 adapter 均通过
```

GitHub Actions 当前的 MoonBit 与 Python 两个 job 均通过。MoonBit job 会先执行 `moon fmt --check src main`，再进行编译、测试与 demo。工作区使用的是 Codex 提供的 Python 3.12.14 运行时，系统 PATH 里的 `python` 命令仍未配置；这不影响 fixture 本身的验证。

## 尚未宣称的能力

- JSON 报告已覆盖场景明细和套件汇总；尚未实现 CLI 文件输出；
- 尚未提供性能基准，因此不声称优于其他实现；
- 尚未接入真实 Agent、MCP 服务或云端系统，因此示例全部是离线 fixture；
- Mooncakes 已发布版本仍是 `0.1.4`，当前 GitHub 包元数据为 `0.2.0` 开发线；发布前仍需单独确认包内容和公开联系方式范围。
- 尚未提供性能基准或真实框架兼容承诺；当前证据仍是可复现的离线事件与 CI 测试。
