# Windows Guest Experiment Playbook

> 状态：LEGACY / 历史设计
>
> 适用：Agent 在稳定 Host 上控制不稳定 Windows Guest/靶机，涉及快照恢复、长任务、调试/观测、证据收割、多 Agent 接手。
>
> 这不是新的 workflow engine。优先复用现有平台的任务状态、重试、锁、artifact 和报告能力；只有平台没有这些能力时，才使用本文的最小 fallback。

## 一句话原则

**Host 保存权威事实，Guest 负责可丢弃执行；先证明观测链可用，再运行目标；副作用未知时先 reconcile，不盲重试；Host 真正取得 artifact 才算证据。**

## 优先级：先复用，再适配，最后才自研

1. 如果 CAPE/Cuckoo 等 sandbox 已经覆盖 VM 生命周期、task、result server、artifact 和恢复，直接使用其原生模型，不再额外维护一套 STATE/events。
2. 如果已有 durable workflow / job system，使用其任务历史、重试和恢复机制，不复制成自定义 receipt/journal。
3. 并发控制使用平台原生 lease/CAS、数据库事务或 OS mutex；不要用普通 JSON 文件假装成锁。
4. 证据 provenance 优先沿用 CASE/W3C PROV 的思路：记录来源、动作、执行者/工具和结果；不为同一事实建立多份实时台账。
5. 只有上述平台能力不存在时，才使用本文末尾的最小 Host fallback。

## 运行前：先固定目标，不先折腾仪器

每个实验先写清：

- `RUN_ID`：一次真实启动一个唯一 ID，失败重试也不得复用。
- `objective`：最终要回答的问题。
- `acceptance`：什么证据出现才算完成；instrumentation/harness/smoke 不能替代。
- `target identity`：样本/目标 hash、VM、baseline/snapshot。
- `observation model`：`natural`、`attach-after-launch` 或 `debugger-launch`，不同模型必须分 RUN。
- `deadline`：本轮最长等待。

如果动作不能说明它推进哪个 acceptance，最多把它当 instrumentation/diagnostic，不把它报告成业务进展。

## Canary：真实实验前必须证明观测链

恢复 VM 或切换通道后，先用无害探针证明：

- Host 能读取 VM 状态；
- Guest 身份、权限和工作目录符合预期；
- 短命令能够执行；
- Guest 能创建小文件；
- Host 能把该文件取回并核对内容/hash；
- 新会话使用的路径、共享、UNC、映射盘实际可见；
- 需要长任务时，runner 与控制会话生命周期已分离；
- 需要 debugger 时，先对 benign target 做 smoke。

`VM Running`、端口开放、SSH banner、Guest Additions ready、认证成功、命令成功、数据可收割不是同一事实。

Canary 不通过时停止正式目标实验。不要拿真实样本测试基础通信。

## 三个独立问题：控制、数据、完成

不要用一个 SSH/GuestControl/PSSession 同时承担所有职责。

### Control

只做短操作：deploy、trigger、query、stop、restore。控制调用返回不代表目标完成。

### Data

Guest 先本地落盘；Host 按需增量收割。stdout/stderr 只是辅助，不是唯一事实源。

### Completion

由目标/runner 的明确 terminal 状态、自然退出、预定义阶段闭合或 deadline 收尾判断。连接断开、空 stdout、VM Running、进程仍存在都不是完成。

## 长任务

长 runner 必须脱离前台控制连接，可使用计划任务、服务、独立 agent job 或平台原生 worker。

控制面采用：

`deploy → trigger → short confirm → later query/harvest`

Guest 不保存唯一长期状态；重要结果最终必须落到 Host 或平台 artifact store。

## 非幂等副作用：先识别，再执行，再验证

只有可能重复产生副作用的操作需要 operation identity，例如：

- 启动一次目标；
- 修改系统/目标状态；
- restore checkpoint/snapshot；
- 创建/删除持久化资源；
- 重复执行会改变 debugger/目标行为的动作。

执行前必须知道“断线后如何判断它是否已经生效”。

断线后只允许得到三种结论：

- `APPLIED`：已经生效，不再执行；
- `NOT_APPLIED`：证明未生效，可以使用新的 operation identity 重试；
- `UNKNOWN`：无法判断，停止自动重试并先恢复可判定性。

普通读取、健康检查、日志读取不需要 operation ID。

## Retry：失败必须增加信息，不能只增加次数

把失败至少区分为：

- path/not-found；
- auth/permission；
- transport/session；
- file-not-ready；
- instrument failure；
- target/business outcome。

相同错误且环境、参数、假设、通道均未改变时，不机械轮询。下一次尝试必须改变至少一个可判别条件。

## Artifact：Guest 说有，不等于 Host 有

证据等级按以下顺序提升：

`Guest observed → Host acquired → Host verified`

正式结论依赖的关键 artifact 至少满足 Host acquired；容易损坏、不可重复或用于正式证据时再记录 size/hash。

原始日志、dump、截图、PCAP 等保留原文件；报告、summary、handoff 是派生视图，不反向成为新的运行时权威。

## Outcome：基础设施失败不能写成业务阴性

一轮实验结束时使用清晰分类：

- `POSITIVE`：验收要求的目标行为被有效观测并有证据。
- `NEGATIVE`：预定义观察窗口完整，观测器有效且覆盖足够，目标行为未出现。
- `INCONCLUSIVE`：timeout、通道失败、证据缺失或覆盖不足，无法判断业务结果。
- `INVALID_INSTRUMENT`：调试器/脚本/过滤器/观测器本身失败或改变了本轮有效性。
- `INFRA_FAILURE`：VM/控制/数据基础设施在目标实验前或期间失效。

`timeout`、`WAIT_TIMEOUT`、GuestControl/SSH 失联、debugger 没命中，默认都不能直接升级成 `NEGATIVE`。

## Observer interference

自然运行和带 instrumentation 的运行分开记录、分 RUN_ID。

推荐顺序：

1. 先建立无调试自然基线；
2. benign debugger smoke；
3. 必要时自然启动后 attach；
4. debugger-launch 作为独立实验；
5. 任何带 instrumentation 的阴性结果不得自动代表自然运行阴性。

## 多 Agent / 多进程

同一 VM、debugger session 或其他可变资源默认只有一个 writer。

获取 writer 权限必须使用真正的原子原语：平台 Lease/CAS、数据库事务、文件锁或 OS mutex。禁止依靠“先读 JSON 再写 owner”来实现互斥。

Agent 切换时，新 Agent 只需要：

1. 读取当前 run/task 状态；
2. 读取最近关键事件/平台 task history；
3. 读取当前结论依赖的关键 artifacts；
4. reconcile 未决副作用；
5. 再取得 writer 权限。

默认不持续维护 handoff.md；需要人工阅读时按需生成。

## 收尾顺序

`停止新增副作用 → harvest → verify关键证据 → 记录 outcome → restore/cleanup → 重新 canary`

回滚/强制关机前先尽可能 harvest。恢复 baseline 后不要继承旧会话 readiness。

## 最小 fallback（仅当现有平台没有持久任务模型）

不要先实现新的 workflow engine。最小目录足够：

```text
runs/<RUN_ID>/
├── run.json       # 当前 run 的少量当前事实，原子替换
├── events.ndjson  # 只追加的重要事件
└── artifacts/     # Host 已取得的原始证据
```

`run.json` 只保存当前仍需消费的事实：目标/验收、run identity、phase、当前 writer、未决副作用、Guest 增量游标、blocker。

`events.ndjson` 只记录状态变化、非幂等操作生命周期、关键 marker、artifact acquire/verify、通道故障/恢复、deadline、会改变路线的判断。普通轮询和重复错误不记。

不要额外实时维护 manifest、channel-state、lease.json、handoff、summary、artifact-index、NEXT.md；这些需要时从事实源生成。

## 明确禁止的反模式

- 一个动作同步五六份文档；
- 每条命令一个 OP receipt；
- 用 heartbeat 文件证明业务完成；
- 控制连接返回 = 长任务完成；
- 空 stdout = Guest 没执行；
- Guest 文件存在 = Host 已取得；
- banner = 可登录/可执行；
- VM Running = Guest ready；
- instrumentation success = acceptance progress；
- static candidate = dynamic fact；
- debugger negative = natural negative；
- path/auth/transport 错误全部写成 timeout；
- Git commit/push 作为运行时同步协议。

## 采用依据

本 Playbook 是“成熟模式的场景化 profile”，不是声称存在一个覆盖全部问题的单一行业标准。主要依据：

- CAPE Sandbox：Windows analysis guest、agent、snapshot、task 状态和 result/artifact 管理。
  - https://capev2.readthedocs.io/en/latest/installation/guest/agent.html
  - https://capev2.readthedocs.io/en/latest/installation/guest/saving.html
  - https://capev2.readthedocs.io/en/latest/usage/utilities.html
- Temporal：持久执行、worker 故障/网络故障后的恢复和 event-history 思路。
  - https://docs.temporal.io/
- Kubernetes Lease：单 writer / leader election 与乐观并发控制。
  - https://kubernetes.io/docs/concepts/architecture/leases/
  - https://kubernetes.io/docs/concepts/cluster-administration/coordinated-leader-election/
- CASE / W3C PROV：数字调查中证据来源、处理动作、工具和结果的 provenance。
  - https://caseontology.org/
  - https://www.w3.org/TR/prov-overview/

更详细的模式映射见 `research/windows-guest-experiment-reliability-patterns.md`。
