# Mooncakes 与仓库开发线版本核对

**核对日期：**2026-10-09。此页区分已发布包和当前 GitHub 开发分支；仓库提交不等同于 registry 发布。

| 核对位置 | 核对结果 | 含义 |
| --- | --- | --- |
| [Mooncakes 包页](https://mooncakes.io/docs/2515050242/moonagentcheck) | `0.2.0` 标记为 latest | 这是目前可安装的公开版本；消费者固定版本可用 `moon add 2515050242/moonagentcheck@0.2.0`。 |
| 本仓库 `october-review` 分支的 `moon.mod` | `0.3.0` | 这是后续开发线版本号，不代表该版本已经出现在 Mooncakes。 |
| `CHANGELOG.md` | `0.3.0 - Unreleased` | 列出 0.3.0 开发内容；在新包发布前不能称为已发布功能。 |
| GitHub Actions | 在本分支提交上运行 | 验证源代码与 fixture；CI 通过不等于创建 registry release。 |

## 对外表述

- 描述可安装的发布包时使用 Mooncakes 最新包页显示的版本 `0.2.0`。
- 描述本仓库十月开发线时使用 `0.3.0`，并标明 **未发布**。
- 十月分支新增的 `AGC018`、Responses JSON fixture 等开发内容，不声称已包含在 `0.2.0` 包中。
- 本次只核对和整理版本说明，没有运行 `moon publish`、创建 release 或更新 Mooncakes。

## 复核步骤

1. 打开 Mooncakes 包页，查看顶部版本列表及 `latest` 标记。
2. 查看仓库分支的 `moon.mod` 和 `CHANGELOG.md`。
3. 检查 README、申报材料和验收矩阵是否把已发布版本与未发布开发线分开描述。
4. 若版本信息发生变化，记录新的核对日期并先核实 registry 状态，再更新面向参赛者的说法。
