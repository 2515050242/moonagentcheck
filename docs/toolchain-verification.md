# MoonBit 工具链复现与验证记录

## 要求与固定版本

本仓库十月开发线使用 MoonBit 编译器 `0.10.16+b1a0e846e` 作为验收验证基线。CI 的三个 job 共用 `MOONBIT_INSTALL_VERSION`，主 job 比较 `moonc -v` 输出的完整版本号，避免安装结果与声明的版本不一致。

工具链来自 [MoonBit 官方下载页](https://www.moonbitlang.com/download)，发布日期为 2026-10-16；下载归档已按官方 SHA-256 校验。该版本是项目实际验证目标，赛事强制要求以组委会正式通知为准。仓库根目录可按以下顺序复现检查：

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

记录日期：2026-10-20。

| 环境 | 工具链 | 检查结果 |
| --- | --- | --- |
| 源码验证 | `moonc v0.10.16+b1a0e846e`，`moon 0.1.20261016` | 格式检查、构建、静态检查和演示通过；96 项 MoonBit 测试、5 个 Python→MoonBit fixture 全部通过。静态检查保留 25 条既有弃用提示，无错误。 |
| 发布包消费与打包 | 同上 | 独立消费方通过 Mooncakes `0.2.0` 的构建及 1 项测试；`moon package --frozen` 通过。打包检查不等于发布新版本。 |
| GitHub Actions | 三个 job 统一固定 `0.10.16+b1a0e846e` | 每次推送运行源码验证、Python 接入和已发布包消费验证；以对应提交的 Actions 结果为准。 |

当前分支的运行记录：[GitHub Actions](https://github.com/2515050242/moonagentcheck/actions/workflows/ci.yml?query=branch%3Aoctober-review)。

## 历史版本记录

旧验证曾使用 `0.10.14+7d59c7ec9`，对应 [CI run 37947254736](https://github.com/2515050242/moonagentcheck/actions/runs/37947254736)。该结果仅作为历史工程记录，不代表 `0.10.16` 验证结果，也不作为当前赛事最低版本要求的依据。
