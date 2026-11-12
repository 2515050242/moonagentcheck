# MoonBit 工具链复现与验证记录

## 2026-11-12 维护复核

Windows x64 本地复核使用默认 `wasm-gc` 后端和 Python 3.12.14。CI 的三个 job 使用官方安装器的 `latest` 通道并记录实际版本。

`moon version --all` 输出的版本如下。实测 `moonc` 的 SHA-256 与[官方下载页](https://www.moonbitlang.com/download/)所列 Windows 最新版校验清单一致。

```text
moon 0.1.20261104 (940aa18 2026-11-04)
moonc v0.10.20+65efd5b93 (2026-11-05)
moonrun 0.1.20261104 (940aa18 2026-11-04)
Feature flags enabled: rr_moon_mod,rr_moon_pkg
```

在仓库根目录运行：

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

本地结果：格式、构建和静态检查通过，96 项源码测试与 5 个 Python fixture 全部通过。无参演示报告预期的 `AGC004`，README 的 JSON 参数示例返回 `passed: true`。独立消费方完成 `moon update` 后构建通过，Mooncakes `0.3.0` 的 2 项消费测试全部通过。

静态检查仍报告 24 条 `implicit_impl_as_method` 弃用警告，公开库生成的接口与维护前一致。远端基线提交 [`98a374f` 的 CI](https://github.com/2515050242/moonagentcheck/actions/runs/39521586672) 已通过；本次维护改动的 Ubuntu CI 尚未运行。

## 2026-10-21 发布复现

`0.3.0` 发布时使用 `0.10.16+b1a0e846e`，有 96 项源码测试。5 个 Python fixture 调用真实 MoonBit CLI；独立消费方固定 registry `0.3.0`，分别检查明确成功与未知 outcome 的 JSON 报告，共 2 项测试。发布打包使用 `moon package --frozen`，结果以对应提交的三个 CI job 为准。

## 历史验证快照

记录日期：2026-10-20，以下发布包消费结果只对应当时的 `0.2.0`。

| 环境 | 工具链 | 检查结果 |
| --- | --- | --- |
| 源码验证 | `moonc v0.10.16+b1a0e846e`，`moon 0.1.20261016` | 格式检查、构建、静态检查和演示通过；96 项 MoonBit 测试、5 个 Python→MoonBit fixture 全部通过。静态检查保留 25 条既有弃用提示，无错误。 |
| 发布包消费与打包 | 同上 | 独立消费方通过 Mooncakes `0.2.0` 的构建及 1 项测试；`moon package --frozen` 通过。打包检查不等于发布新版本。 |
| GitHub Actions | 三个 job 统一固定 `0.10.16+b1a0e846e` | 每次推送运行源码验证、Python 接入和已发布包消费验证；以对应提交的 Actions 结果为准。 |

默认分支的运行记录：[GitHub Actions](https://github.com/2515050242/moonagentcheck/actions/workflows/ci.yml?query=branch%3Amaster)。

## 历史版本记录

旧验证曾使用 `0.10.14+7d59c7ec9`，对应 [CI run 37947254736](https://github.com/2515050242/moonagentcheck/actions/runs/37947254736)。该结果仅作为历史工程记录，不代表 `0.10.16` 验证结果，也不作为当前赛事最低版本要求的依据。
