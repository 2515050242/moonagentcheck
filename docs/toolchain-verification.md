# MoonBit 工具链复现与验证记录

## 要求与固定版本

项目要求 MoonBit 编译器 `moonc >= 0.10.14`。CI 使用官方安装脚本，并通过 `MOONBIT_INSTALL_VERSION` 固定到 `0.10.14+7d59c7ec9`；随后仍运行版本门禁，避免实际安装结果低于项目要求。固定版本保证 CI 结果可复现，版本门禁负责检查安装结果。

工具链安装方法见 [MoonBit 官方安装说明](https://docs.moonbitlang.com/en/latest/tutorial/tour.html#installation)。仓库根目录可按以下顺序复现检查：

```sh
moon version --all
moonc -v
moon fmt --check src main
moon build
moon check
moon test
moon run main
python examples/python_data_agent.py
python examples/python_repository_agent.py
python examples/python_ticket_agent.py
python examples/python_adapter.py
python examples/python_openai_responses_fixture.py
```

运行 Python fixture 需要 Python 3.12 或兼容版本；无需网络或模型凭据。

## 验证记录

记录日期：2026-10-09。

| 环境 | 工具链 | 检查结果 |
| --- | --- | --- |
| 本地复现 | `moonc v0.10.14+7d59c7ec9`，`moon 0.1.20260920` | 格式检查、构建、检查、测试和演示均通过；测试 89 项通过、0 项失败；5 个 Python fixture 均通过。`moon check` 输出 25 条弃用提示，无错误。 |
| GitHub Actions | `moonc v0.10.14+7d59c7ec9`（run `37947254736`） | 版本门禁、格式、构建、检查、测试、演示及 5 个 Python fixture 全部通过。 |

GitHub Actions 运行记录：[CI run 37947254736](https://github.com/2515050242/moonagentcheck/actions/runs/37947254736)。本记录描述的是该次提交的实际验证结果；后续代码或工具链变更需要重新运行以上命令和 CI，再更新记录。
