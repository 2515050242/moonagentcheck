# Mooncakes 与仓库版本核对

**发布日期：**2026-10-21。十月版本为 `0.3.0`；历史 `0.2.0` 发布记录保留原日期与功能范围。

| 核对位置 | 对应版本 | 检查内容 |
| --- | --- | --- |
| [Mooncakes 包页](https://mooncakes.io/docs/2515050242/moonagentcheck@0.3.0) | `0.3.0` | 确认版本、作者 `2515050242`、Apache-2.0 及包构建状态 |
| 仓库 `master` / `october-review` 的 `moon.mod` | `0.3.0` | 两个分支的最终发布提交应一致 |
| `CHANGELOG.md` / [发布说明](releases/0.3.0.md) | `0.3.0 - 2026-10-21` | 区分十月新增能力与九月基础 |
| 独立消费样例 | 固定 `2515050242/moonagentcheck@0.3.0` | CI 复制到仓库外，从 registry 安装，不使用本地源码替换 |
| 消费回归 | 2 项 | 明确成功通过；未知 outcome 拒绝并包含 `AGC018` |

## 安装

```sh
moon add 2515050242/moonagentcheck@0.3.0
```

核心 API 从 `2515050242/moonagentcheck/src` 导入。`main` 是源码包内的示例入口，克隆仓库后可用 `moon run main` 运行；将库加入消费项目不会自动创建该项目的 CLI 目录。

## 复核

1. 打开版本包页，确认 `0.3.0` 可见且构建成功。
2. 对照 `moon.mod`、README、CHANGELOG 与申报材料的版本及日期。
3. 查看最新提交 `published-package-smoke` job：下载 `0.3.0` 后构建并运行 2 项消费测试。
4. 源码测试仍为 96 项；消费方 2 项单独计算。只看源码 CI 不足以证明 registry 包可安装。
5. 发布包不可覆盖；后续修复应使用新版本并记录真实变化。
