# MoonAgentCheck 推进路线

## 已完成

- 完成选题查重和生态边界分析；
- 定义 `Event`、`Violation`、`call_id` 和 `operation_id`；
- 实现确定性事件扫描；
- 覆盖孤立结果、缺失结果、重试限制、重复副作用、无调用写入和重复调用 ID；
- 发布 Mooncakes `0.1.4`；
- 添加 GitHub Actions、Python fixture 和中文 SVG 审核图；
- 添加申报书、验收矩阵和工程决策记录。

## 比赛阶段

### 里程碑一：报告可消费

- 增加 JSON 报告构造和稳定字段；
- 为每条规则提供机器可读的错误码；
- README 增加 JSON 示例。

### 里程碑二：三个真实场景

- 数据处理 Agent：缺失列错误不能被当成成功；
- 仓库助手 Agent：读取和写入必须保持顺序；
- 工单 Agent：有限重试后不能重复写回。

### 里程碑三：适配器和回归证据

- 提取 Python adapter；
- 固化 JSON fixture；
- 增加边界测试和错误输入测试；
- 在 GitHub Actions 中执行示例 smoke test。

## 版本策略

每个版本都对应可运行的功能或可审查的发布证据。不会为了满足提交数量制造空提交；提交信息会描述真实的行为、测试、文档或发布变化。

