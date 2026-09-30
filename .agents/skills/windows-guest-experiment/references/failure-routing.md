# 失败路由

本参考用于把失败定位到正确的语义平面，并判断：**应该修成熟能力、补交接、收割部分证据，还是确实需要换路线。**

## 先判断故障属于哪一层

| 现象 | 首先说明什么 | 下一步 |
|---|---|---|
| 成熟 runtime 无法启动 | 环境/依赖可能损坏 | 查官方文档、版本、服务和配置，优先修复 |
| MCP/API 能连但 job 失败 | runtime 已在线，任务或配置有问题 | 查 job/log/result，不另起 runner |
| job 创建成功但目标行为不对 | 提交语义或目标本身有问题 | 核对 package/options/参数/目标身份 |
| debugger 已配置但不命中 | 只证明没有观察到 hit | 核对地址、模块、时机和 observer，有效性不足时不要推业务结论 |
| debugger 状态陈旧/清理失败 | observer 生命周期失效 | 停止解释后续缺失行为，修 observer |
| VM Running 但 Guest command 失败 | 只证明 hypervisor 状态 | 修 control/runtime，不把 VM Running 当 readiness |
| Guest 报告文件存在但 Host/runtime 没拿到 | 只证明 Guest 观察到文件 | 修 artifact/data path |
| 路径立即报不存在 | 路径/上下文错误 | 立即修路径，不轮询 |
| Host 检查到文件但 Guest 消费者找不到 | 交付上下文或复制布局错误 | 在 Guest 读回目录、长度和哈希；确认最终路径后再启动消费者 |
| HostOutputPath 被当成 RunId/Guest 路径 | 标识符和路径语义混淆 | 重新解析结构化提交 envelope；保留原 job，无法确认时标为 `SUBMISSION_UNKNOWN`，不得盲目重提 |
| 参数在 PowerShell/JSON 层报绑定或转义错 | 参数 schema/序列化失败 | 改为结构化对象一次序列化，在接收端解析和回显校验 |
| Agent 初始消息与源 prompt 不一致 | 投递失败或编码/截断 | 读取原始 session 首个 `role=user`，标记 `delivery_truncated`；Agent 后续读文件不能补证 |
| Agent 有报告但工具调用未返回 | session 仍可能 ACTIVE | 收割原始 JSONL、toolCall/toolResult 和进程状态，不以报告终止 |
| runner 存活但没有报告 | 运行中或收口未完成 | 查看最后事件/心跳、未返回调用和硬截止；先收割再分类 |
| 状态仍为 RUNNING 但原始收割已完成 | 运行终结事务未提交 | 先写终态，再做下一项副作用操作 |
| 单个日志锁住或镜像缺失 | 部分收割失败 | 按文件收割，记录 `COPY_DEFERRED`，保留 canonical session path |
| debugger/observer 无命中或语法错误 | 仪器问题或未命中 | 先验证 observer 实际生效和本轮目标谱系，不能写成业务阴性 |
| 同样错误在相同输入下重复 | 没有新增信息 | 停止重复，查文档/换假设 |

## 禁止性推断

以下情况不能直接升级为业务结论，也不能直接触发“自己写一个替代方案”：

- 工具尚未安装；
- 不知道当前版本参数；
- 第一次调用失败；
- 服务未启动；
- 配置文件错误；
- 需要一次版本兼容修复。

先保留原始输出并判断失败所在平面。成熟能力仍能提供所需后置条件时先修；如果当前能力确实不能提供该语义，才进入薄适配或 Guest Agent 协作。

## 什么时候可以转入薄适配

只有至少满足一项：

- 官方能力明确不支持当前必要动作；
- 当前平台与成熟方案明确不兼容；
- 安装/修复成本明显超过当前任务价值；
- 安全/授权边界不允许部署；
- 已有 runtime 能覆盖大部分流程，只缺一个明确动作。

转入薄适配后只补缺口，不复制已有 runtime 的 task、artifact、retry、VM 生命周期。

## 统一恢复顺序

1. 保存原始请求、返回、日志、路径、PID、job/session/run 身份和当前文件状态。
2. 分类为身份、交付、控制、数据、完成、runtime、observer、Agent、收割/终结或目标业务层。
3. 执行一个能区分候选原因的最小检查；不要用同一失败方法机械重试。
4. 若有长任务或 Agent session，先收割再决定继续、修正、新 run 或停止。
5. 在清理前写明结论范围；通信/仪器失败保持为基础设施事实，不能冒充样本阴性。

