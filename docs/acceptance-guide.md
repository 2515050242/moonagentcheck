# MoonAgentCheck 十月验收指南

核对日期：2026-10-20。项目围绕已有社区项目继续开发；以下命令检查可运行成果，不代表组委会已完成最终验收。

## 材料入口与版本

| 材料 | 用途 |
| --- | --- |
| [项目申报书](项目申报书.md) / [PDF](../output/pdf/october-proposal.pdf) | 同一份公开申报正文，说明范围与交付 |
| [README](../README.md) | 安装、API 与示例入口 |
| [验收矩阵](acceptance-matrix.md) | 要求对应的源码、测试和 CI 证据 |
| [版本核对](release-alignment.md) | 已发布 `0.2.0` 与未发布源码 `0.3.0` 的区别 |
| [工具链验证](toolchain-verification.md) | 固定编译器、复现方法与历史结果 |
| [许可证](../LICENSE) / [来源说明](provenance.md) | Apache-2.0 与参考来源 |

仓库主页链接为 [2515050242/moonagentcheck](https://github.com/2515050242/moonagentcheck)，默认分支为 `master`；`october-review` 保留十月开发入口。评审时请核对所查看分支的最新 SHA 与 [CI](https://github.com/2515050242/moonagentcheck/actions/workflows/ci.yml)。不能用旧提交的绿色状态代替当前提交验证。

Mooncakes 当前 latest 仍为 `0.2.0`，源码 `moon.mod` 声明的 `0.3.0` 尚未发布。本页中的十月新行为按仓库源码验证；**新版本发布与独立安装复验仍待完成**。

## 1. 从默认分支运行 MoonBit

准备 MoonBit 编译器 `0.10.16+b1a0e846e`、配套核心库和 Python 3.12。该编译器是本项目的验证基线，赛事版本要求以组委会正式通知为准。首次安装工具链需要网络，fixture 本身不调用网络或模型。克隆时保留 LF 换行，避免 Windows Git 自动转为 CRLF 后干扰格式检查。

```sh
git -c core.autocrlf=false clone https://github.com/2515050242/moonagentcheck.git
cd moonagentcheck
moon version --all
moonc -v
moon fmt --check src main
moon build
moon check
moon test
moon run main
```

预期：完整编译器版本为 `v0.10.16+b1a0e846e`，格式、构建、静态检查成功，96 项 MoonBit 测试通过。静态检查存在 25 条既有弃用提示，不应描述为零警告。

无参演示故意重复完成同一写操作，报告包含 `AGC004`。命令正常退出说明演示断言成立，**不表示这条违规轨迹通过契约检查**。

## 2. 验证 Python 实际接入 MoonBit

在仓库根目录运行，确保 `moon` 在 PATH 中。Python 加 `-X utf8`，避免 Windows 默认编码影响子进程日志解码：

```sh
python -X utf8 examples/python_data_agent.py
python -X utf8 examples/python_repository_agent.py
python -X utf8 examples/python_ticket_agent.py
python -X utf8 examples/python_adapter.py
python -X utf8 examples/python_openai_responses_fixture.py
```

调用链为 Python fixture → `examples/moonbit_cli.py` → `moon run --quiet main -- <JSON>` → MoonBit 适配器 / 评估器 → JSON 报告 → Python 断言。缺少 MoonBit 或返回无效报告时示例会失败，不会回退到 Python 规则实现。

| 关键输入 | 预期结果与检查位置 |
| --- | --- |
| 数据导出调用、成功结果、写入完成正常关联 | 正常轨迹无违规；`python_data_agent.py` |
| 同一业务操作重复完成写入 | `AGC004`，不得作为正常轨迹通过；`python_repository_agent.py` |
| `completed` 缺少明确执行器 outcome | `passed: false`、`AGC018`；`python_openai_responses_fixture.py` |
| 消息 / 推理与工具项混合 | 保持调用关联；支持的非工具项不生成事件 |
| 未支持类型 / 没有前置 call 的 output | `passed: false`，保留输入索引与 `mapping_issues` |
| 非法 JSON、字段类型错误 | 失败报告；`main/responses_json_test.mbt` |

CLI 用 JSON 的 `passed` 表示契约是否成立；仅看 CLI 进程退出码不足以判定轨迹通过。Python fixture 会断言报告状态和违规明细，断言不满足时以非零退出码令 CI 失败。

这些输入是合成遥测，不是真实用户日志。`operation_id`、`outcome` 由应用侧提供；`completed` 本身不能证明工具成功。

## 3. 检查 CI 与已发布包

当前工作流有三个 job：

- `moonbit`：显示并校验固定编译器，运行格式检查、显式构建、静态检查、96 项测试和无参演示。
- `smoke-fixtures`：准备相同 MoonBit 工具链及 Python，运行上面的 5 个真实接入 fixture。
- `published-package-smoke`：将 `examples/mooncakes-consumer` 复制到仓库之外，`moon update` 后构建并运行 1 项测试，从 registry 消费固定的 `0.2.0`，不借用本仓库源码。

三个 job 均显示工具链版本。消费方测试验证已发布旧版的公开 API，不能代替未发布 `0.3.0` 的发布和安装检查。

## 4. 本期新增贡献

九月已发布 `0.2.0` 作为基础，不重复声称为十月新增。可按下列提交复核十月实现与回归：

| 提交 | 可核对变化 |
| --- | --- |
| `db96a0f` | MoonBit JSON 入口调用实际 Responses 适配器和评估器，覆盖正常、未知结果与未支持输出 |
| `5fc93c3` | Python fixture 改为调用 MoonBit CLI，不再独立判定规则 |
| `d279eae` / `ec4379f` | CI 运行真实 Python→MoonBit 接入，修复实际兼容问题 |
| `807fb69` | JSON 混合输出、非法输入与字段类型回归；澄清 CLI 边界 |
| `fd8cd27` / `0b24c73` | 独立 registry 消费方及 CI；补齐索引刷新 |
| `c676c13` | 三个 job 统一固定 `0.10.16+b1a0e846e`，在该版本重新验证 |

其他十月实现与完整先后顺序见 [提交记录](https://github.com/2515050242/moonagentcheck/commits/master) 和 [开发记录](development-log.md)。AI 辅助实现、整理回归用例和文档；本页不把自动验证描述为参赛者已经逐行人工审核。
