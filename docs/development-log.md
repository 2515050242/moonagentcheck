# 开发记录：从一条规则到一条证据链

这份记录只整理仓库里已经存在的提交，不补造过去不存在的工作。时间和 commit hash 以公开 Git 历史为准。

## 先把核心问题说小

- `f066212`：先实现最小行为契约评估器，验证调用、结果、重试和写入副作用这些核心关系。
- `6a524f6` / `a8dad80`：补充结构图和事件流程图，帮助审核者先理解边界，再看代码。
- `0ea4993` / `86adcc5`：记录范围决策与验收方式，明确不做 runtime、MCP transport 和云端控制台。

## 让失败真的能被复现

- `81149d5`：增加重复结果、缺少操作 ID 等回归检查，并把 Python 对照示例放进 CI。
- `5d7d030`：收窄 README，只承诺已经存在的结构化结果和离线测试能力。
- `0480e24`：加入仓库助手的读后写 smoke fixture，把“先读后写”变成可执行证据。

## 从规则走向可消费结果

- `fca34de`：增加 `AGC001`–`AGC009` 稳定错误码，未知规则保留 `unknown` 回退。
- `535d416`：把失败工具结果纳入核心检查，并补数据处理场景的回归测试。
- 本轮：增加 `AGC011`，拒绝工具名或 `operation_id` 与同一 `call_id` 不一致的 result，并让该调用不能成为成功结果。
- `306cef1`：修复无效的 MoonBit CI action，改用官方 CLI 安装脚本。
- `1e7c087`：刷新 README、CHANGELOG 和审计记录，让公开材料与代码、测试结果一致。

## 把项目从规则集合扩成工具层

- `4baa41c`：增加 `Trace` 构造器、事件统计和输入预检，把适配器收到的坏数据在语义扫描前明确拒绝；
- `4baa41c`：增加 `RuleSummary`、`SuiteSummary`、场景明细 JSON 和套件汇总 JSON，让多条轨迹的证据可以被 CI 消费；
- `4baa41c`：增加通用 Python 记录 adapter，并把缺字段、非法类型、未知事件的失败路径加入 smoke test；
- `4baa41c`：补充行为契约、验收矩阵、架构说明和申报材料，明确扩展的是验证工具边界，不是重新实现 Agent runtime。

本轮完成后，MoonBit 非测试源码为 537 行，测试源码为 439 行，`moon check` 通过且 32 个测试通过。这个数字用于审计当前规模，不作为单独的质量承诺；质量边界仍由可复现事件、测试和 CI 共同决定。

## 从工具层扩展到可运行的回归工作台

- `f1fc7ed`：增加 `TraceQuery`、`Replay` 和检查点能力，支持按工具/调用/操作检索、逐事件回放和前缀验证；
- `f1fc7ed`：增加 `diff_events` 字段级差分与 `collect_metrics` 风险统计，分别服务版本回归和问题定位；
- `f1fc7ed`：增加 `PolicyProfile`、`QualityGate`、`ScenarioCatalog` 和 `SuiteRunner`，让权限策略、场景选择、运行历史和 CI 门禁有可复用实现；
- `f1fc7ed`：为新增 API 增加 34 个回归测试，包版本推进到 `0.2.0`，同步更新申报材料和验收矩阵。

本轮完成后，MoonBit 非测试源码为 4,242 行，测试源码为 995 行，累计 66 个测试通过。规模增长来自不同职责的可执行模块；仍然不实现 Agent runtime、MCP transport 或模型调用。

## 当前工作方法

每个功能先有一个能说明问题的事件序列，再有 MoonBit 规则和测试，最后才补 Python fixture 或 CI。发现假设不成立时，优先修正规则和测试，不用增加一层空抽象。后续提交继续沿用 `feat`、`fix`、`test`、`docs` 前缀，但提交信息只描述实际发生的变化。

## 策略穿透多场景回归

- 本轮：补齐 `evaluate_scenarios_with_policy`，并让场景目录、质量门禁和 `SuiteRunner` 传递完整 `EvaluationPolicy`；此前它们只传递重试上限，会在回归批次中丢失工具 allowlist。
- 新增允许/拒绝场景、标签选择和单条运行的 MoonBit 回归，确保只读策略下的 `write_file` 保留 `AGC012`，而允许的读取轨迹不受其他场景影响。
- 这项修复不扩张到策略 DSL、外部授权或 Agent runtime；它只使已有离线策略在用户实际调用的套件入口与单轨入口一致。

## 策略来源成为可归档证据

- 本轮：新增 `PolicyContext` 与 `evaluation_report_json`，将策略的非空接入配置来源、allowlist、重试上限和违规明细放入同一稳定 JSON 证据；空来源固定报告 `AGC017`。
- 策略来源由接入方配置提供，不能从待检 trace 读取；这避免日志自述扩大权限，仍不引入外部权限服务或 Agent runtime。

## 写入完成必须回指同一调用

- 本轮：补齐 `write-complete` 的元数据关联检查。此前成功 result 仅按 `call_id` 使写入通过，错配的工具名或 `operation_id` 可以借用那次成功。
- 现在错误路径固定产生 `write-call-mismatch`（`AGC016`）；MoonBit 测试覆盖工具名和业务操作错配及正常路径，Python 离线 fixture 保持同一判断。
- 这是事件证据链的完整性修复，不增加 Agent runtime、传输层或外部副作用执行能力。

## CI 在编译前固定格式边界

- 本轮：在 MoonBit job 的 `moon check` 前加入 `moon fmt --check src main`，同时覆盖核心库和可运行验收 demo；
- 选择复用本地已执行的官方 MoonBit 格式检查，而非新增格式化工具或脚本，避免引入依赖和第二套规则；
- 格式漂移会在编译、测试和 demo 前立即失败，使公开复现路径与本地验收命令保持一致。

## 重复调用不能重定义证据链

- 本轮：重复 `call_id` 曾会覆盖已记录的 tool 和 `operation_id`，使后续 result 或 `write-complete` 能匹配错误的第二条 call；现改为保留首个 call，重复记录只报告既有的 `duplicate-call-id`。
- 新增 MoonBit 与 Python 离线回归：第二条 call 试图把文件写入改成邮件发送时，结果与写入分别固定报告 `result-call-mismatch`、`write-call-mismatch`，不能借用成功。
- 该修复只收紧不可信遥测的身份关联，不限制不同 call ID 的异步结果顺序，也不增加 Agent runtime 或外部状态。
