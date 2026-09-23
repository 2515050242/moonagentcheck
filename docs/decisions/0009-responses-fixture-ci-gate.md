# 决策记录 0009：Responses 字段映射纳入 CI 复现门禁

## 背景

`responses_adapter.mbt` 已用 MoonBit 回归测试覆盖 OpenAI Responses 的函数调用与输出映射，`python_openai_responses_fixture.py` 则保留同一公开字段形状的离线可运行样例。此前 CI 的 Python smoke job 没有运行这一 fixture，因此公开推送无法验证该样例仍能从仓库根目录复现。

## 决策

把现有 fixture 加入已有的 Python smoke job。它与其余 fixture 共用 Python 标准库和工作目录，不增加依赖、网络请求或新的 CI job。

## 取舍

CI 只验证 fixture 的字段映射边界：output 必须有前置 call，且 `completed` 不能在缺失执行器结果时伪造成成功。核心行为规则和适配器契约仍由 MoonBit 测试维护；本次不添加 Responses 客户端、JSON 解析器或 Agent runtime。
