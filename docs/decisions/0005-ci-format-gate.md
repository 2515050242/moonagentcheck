# 决策记录 0005：CI 在编译前检查 MoonBit 格式

## 背景

本地验收已经使用 `moon fmt --check src main`，但公开 CI 只在格式之后开始的编译、测试和 demo 阶段执行。格式漂移因此不会在共享的复现入口中被明确指出。

## 决策

在现有 MoonBit job 中，于 `moon check` 之前运行 `moon fmt --check src main`。范围与本地验收命令一致：`src` 是产品核心，`main` 是公开可运行的验收 demo。

## 取舍

不加入第三方 linter、格式化封装脚本或 Agent runtime 集成。MoonBit 官方格式检查已足以把这一边界转成确定的 CI 失败；功能语义仍由后续的 `moon test` 和 `moon run main` 验证。
