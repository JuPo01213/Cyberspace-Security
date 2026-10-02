# 从零建设 Windows 分析工具

本参考用于“没有足够成熟能力，需要建设一个最小分析工具或通信底座”的任务。它指导建设边界、交接和验收，不规定某个 hypervisor 或工具栈。

## 先写建设契约

在安装或写代码前记录：

- 任务入口和调用者；
- Guest、账户、桌面/后台上下文和隔离/网络边界；
- Control、Data、Completion、Runtime、Observation 各自的成功后置条件；
- 输入、输出、session/job/run ID、artifact ID 和路径上下文；
- 硬截止、超时收割、精确清理和回滚；
- 哪些是安装事实、能力事实、真实任务事实和未知。

不要先以“工具数量”“VM 能启动”或 `--help` 通过作为完成目标。

## 最小垂直骨架

优先做一条可收口的纵向切片：

```text
结构化提交
  → Guest 内短控制探针
  → 一份有身份的输入交付
  → 一个明确的完成事件
  → Host 原始收割
  → 精确回收与终态写入
```

只有这条切片能被复现和分类后，才增加长 runner、GUI、调试、网络或复杂枚举。不要把每个工具的局部脚本拼成第二套 runtime。

## 建设完成度

对每项能力分别登记以下状态：

`discovered → installed → configured → bound → consumer_handshake → benign_task → harvestable → ready_for_task → ready_for_run`

每次升级都必须保留对应证据、适用范围、限制、版本、入口、失效条件和回滚。`ready_for_task` 说明能力能服务一类任务；`ready_for_run` 还要求当前 Guest、路径、身份、配置、通信 profile 和本轮 schema 已对齐；二者都不等于目标业务成功。

## 脚手架高风险交接

### 路径和文件

Host 路径与 Guest 路径是不同命名空间。路径必须在拥有该路径的机器内解析，复制后在 Guest 读取目录树、文件长度和哈希，再由 Host 逐文件收割并记录 `guest_exists`、`host_copied`、`host_hash`、`deferred` 和错误。复制到已存在目录可能产生多一层嵌套；scoped package 不能只凭目录名判断最终位置；manifest 不应把自己算作输入文件。

### 编码和参数

跨进程输入显式写 UTF-8 字节或明确编码，不依赖宿主默认编码；用结构化参数对象绑定入口，不把数组交给隐式 positional binding；JSON 由对象序列化一次并在接收端解析，不在多层 shell 字符串里手工拼接。中文路径、反斜杠、引号和空值都必须有接收端读回证据。

### 配置和消费者

安装包、版本和帮助输出只能证明组件存在。还要证明持久化配置写入正确层、监听/绑定地址和消费者入口明确、Guest 内完成握手或无害调用、错误能被 Host 收割。配置文件变更保留原文件哈希、备份、语法/启动验证和回滚方法。

### 长任务和收割

长任务脱离短控制连接运行，使用唯一 ID、硬截止、持久 completion event、原始日志和逐项产物。单个锁定日志或镜像文件不可使整个收割黑盒失败；按文件收割并保留 canonical session path。控制 wrapper、临时 `pwsh` 和子进程要按本批次 PID/命令行精确回收，不能只杀外层进程。

## 最小真实验收

使用一次无害但真实的目标任务，而不是固定 sentinel，验证从干净基线到第一条有效证据的时间、手工凭据/GUI 次数、Host/Guest 往返次数、失败后分类时间、同一 run 的证据闭合率和重建工作量。结果分为 `EFFICIENCY_POSITIVE`、`NO_MEASURABLE_GAIN`、`EFFICIENCY_NEGATIVE` 或 `UNKNOWN`，并写明未覆盖范围。


