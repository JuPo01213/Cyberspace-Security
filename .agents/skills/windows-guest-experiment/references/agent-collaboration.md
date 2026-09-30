# Guest Agent 协作与通信

Guest Agent 是在目标 Guest 内工作的协作执行器。它适合回答 Guest 内的唯一未知、检查本地配置/文件/进程、调用已安装工具或做授权范围内的最小修复。它不能替代 Host 的身份、隔离、运行和证据权威。

## 任务包

派发前把以下字段写入当前 run record，并保存源 prompt 和哈希：

```text
objective
task_type: diagnose | repair | sample_analysis | communication_validation
known_evidence
single_unknown
allowed_paths_and_tools
forbidden_scope
expected_artifacts
rollback
model_egress
hard_deadline
host_acceptance
run_id / task_id / session_id
```

任务必须是真实目标；不要把实际诊断改写成固定回显、哨兵或要求模型输出某个成功单词。通信 probe 可以单独存在，但不能占用真实任务的验收名额。

## 投递和读取

Host 先保存 prompt 源字节，再通过明确的 stdin/file/session 入口投递。启动后从原始 session 读取首个 `role=user`，比较字节或规范化文本并记录 `delivery_verified`、`delivery_truncated`、编码和差异。Agent 后续用 `read` 或 `bash` 自行读取 prompt，只说明它恢复了上下文，不能证明初始投递成功。

session 路径、Guest 文件路径和 Host 镜像路径必须分别登记；不能把自定义 session 参数误称为默认位置，也不能用 Host 环境变量推导 Guest relay 路径。

## 监督状态

```text
PREPARED
  → DELIVERY_VERIFIED
  → ACTIVE
  → REVIEW
  → DECIDE
```

- `PREPARED`：任务包、源 prompt、run record 和回滚已持久化。
- `DELIVERY_VERIFIED`：原始 session 的首个用户消息与源 prompt 对齐。
- `ACTIVE`：原始 JSONL 有新事件，或仍有未返回的工具调用；Host 只做只读增量收割和进程观察。
- `REVIEW`：Agent 终态、工具调用明确失败、硬截止或用户改变方向；先完整收割。
- `DECIDE`：Host 根据原始材料决定继续同一 session、修正、开启新 run、接受部分产物或停止。

没有 `output.txt`、报告暂缺、状态标签停在 RUNNING 或单次工具调用耗时，不能单独终止 `ACTIVE`。硬截止不是自动续作配方。

## 权威与收割

权威顺序是：源 prompt/初始 `role=user`、原始 assistant thinking/text、toolCall、toolResult、error、responseId、token usage、Guest 产物、Host 收割物；Agent 报告、`status.json`、`output.txt` 和模型自述只是待核对材料。模型请求成功、runner 存活、报告存在和样本目标完成分别记录。

进入 `REVIEW` 后至少保留：完整 JSONL、工具调用及返回、错误流、状态/输出、Guest 产物和哈希、进程状态、session/job/run 身份、清理结果。部分修复可以作为经过 Host 验证的工作产物，但不能写成 Agent 完成或样本业务完成。

Host 负责样本/运行身份、网络与隔离、runtime/debugger 生命周期、原始收割、最终分类和清理；Agent 负责 Guest 内调查、工具调用和最小修复。双方不得同时写同一正式文件；临时 Guest 工作必须有归属和清理策略。

Agent 的模型出口与样本的运行网络是两个不同的边界。需要模型访问外部服务时，在任务包中声明并单独验证 `model_egress`；不能因为样本应隔离就默认切断 Agent，也不能因为 Agent 可联网就把样本流量放出隔离边界。

## 效率评价

Guest Agent 是一种新的高效通信方法，价值应以真实任务对比验证：从干净基线到第一条有效证据的时间、Host 控制调用和往返数、人工凭据/GUI 次数、失败到分类的时间、返工次数、同一 run 的交付/观测闭合率和剩余手工重建量。结果可以是正向、无可测收益、负向或未知；一次顺利 probe 不足以证明通用收益。

