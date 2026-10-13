# Windows Guest 通用技能架构重组记录

## 依据

本次重组回读了两轮原始 session、109 个问题切片、Host/Guest 运行材料和现有通用技能。问题切片的共同模式不是某个 hypervisor 或样本参数错误，而是跨边界语义没有被验证：发送方把“已发出”当成接收方已收到，控制面把“在线”当成消费者已就绪，工具把“安装”当成任务可用，Agent 报告把“模型做过”当成原始 session 已投递和目标已完成，收割把“有一个报告文件”当成同一运行证据已闭合。

## 重新组织后的架构

技能现在按七个语义平面组织：任务、能力、交付、执行、观测、监督、恢复/校准。工具、VM、runtime、传输和 Guest Agent 都是这些平面的实现，不再是通用流程的上位权威。每个平面都规定自己的后置条件和证据来源，避免一层结果替代另一层结果。

新增三份核心 reference：

- `references/architecture.md`：平面边界、权威关系和过度约束审计；
- `references/tool-building.md`：从零建设最小分析工具的契约、脚手架、交接、收割和真实任务验收；
- `references/agent-collaboration.md`：Guest Agent 任务包、prompt 投递验证、原始 session 监督、超时收割和效率评价。

同时重写了主入口、能力 readiness、通信交付、标准运行流、失败路由、环境建设和设计依据。旧的固定视觉 wrapper、固定轮询默认值和“低层工具永远最后”的绝对规则已移除或改为条件性指导。

## 问题到架构的映射

| 观察到的切片模式 | 影响平面 | 通用约束 |
| --- | --- | --- |
| prompt 截断、默认编码导致中文损坏、Agent 后续读 prompt 被误认作成功投递 | 交付/协作/观测 | 比较源 prompt 与原始 session 首个 `role=user`；显式 UTF-8 字节；恢复读取单独记账 |
| Host 用自己的路径检查 Guest、复制目录多一层、scoped package 位置错误 | 交付/建设 | 在路径所属机器解析并读回目录、长度、哈希；记录消费者最终路径 |
| PowerShell 参数数组绑定错误、多层 shell JSON 转义错误、标识符与路径混淆 | 交付/参数 | 结构化 envelope，一次序列化，接收端解析；`RunId`、`HostOutputPath`、Guest 路径分开 |
| MCP 已接受但 job_id/输出未持久化，或响应丢失后重复提交 | 执行/监督/恢复 | durable job identity；响应丢失标为 `SUBMISSION_UNKNOWN`，先解析原运行再决定 |
| runner/工具仍在执行，因没有报告或状态停滞被提前终止 | 监督/观测 | 原始 JSONL、未返回 toolCall、最后事件和进程状态优先；硬截止先收割再分类 |
| 单个日志锁、错误镜像路径导致全量收割失败 | 收割/恢复 | 逐文件收割、保留 canonical path、标记 `COPY_DEFERRED` |
| 安装、help、哨兵或 VM Running 被当成端到端可用 | 能力/建设 | `installed → ... → harvestable → ready_for_task → ready_for_run`，再做一次真实无害任务 |
| 旧摘要/旧能力/旧 run 被直接复用，或项目目标被硬编码到通用技能 | 能力/恢复/校准 | 以当前 profile 和 run record 对账；问题切片先停在项目层，重复跨任务后才升级技能 |
| 代理协作被当成固定回显或报告生成，未比较 Host 往返和真实任务收益 | 协作/任务 | Agent 作为新的高效通信方法，必须以真实任务效率和原始证据验证 |

## 保留的边界

EPT 的样本身份、目标 seam、授权/干预和当前 VM 状态仍属于项目 overlay 与 run record。通用技能只提供能力契约、通信语义、Agent 协作和恢复规则，不把任何一次 EPT 运行升级成普遍事实。


