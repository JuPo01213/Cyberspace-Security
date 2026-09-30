# Windows 标准分析环境

本参考只回答一个问题：**当前没有成熟 Windows 分析环境时，优先建设什么，而不是临时拼什么。**

## 推荐基线

优先把一台可回滚 Windows VM 建设成标准分析工作站，再把它作为后续动态分析、调试和 GUI 观察的默认承载环境。

推荐基础：

- Windows 10+ 虚拟机；
- FLARE-VM：负责安装和维护逆向/恶意软件分析工具集；
- Hyper-V / VMware / VirtualBox 等成熟虚拟化平台负责快照和回滚；
- 需要 Agent 远程驱动时，再按任务增加 CAPEsolo、远程调试或 GUI 接口。

FLARE-VM 是 Mandiant 维护的 Windows VM 分析环境建设脚本。它解决“工具环境如何可重复建设”，**不负责**样本任务编排、远程 Agent 协议或完整沙箱生命周期。

## 平台与分析栈分离

FLARE-VM 和安装在 Guest 内的分析工具属于 Guest 能力；hypervisor 属于基础设施后端。Hyper-V、VMware、VirtualBox 等平台可以承载同一类 Guest 分析能力，但它们的快照、Host → Guest 控制、文件传输、隔离网络和 GUI 入口不同。

建设前先读 `capability-contract.md`，由任务所需能力选择后端。不得因为 Host 恰好安装了某个平台、某台 VM 已存在或某个低层命令最容易调用，就把该实现升级为通用流程要求。

选定后端后，至少验证当前任务依赖的：

```text
VM 生命周期
+ checkpoint / restore
+ 隔离网络
+ command/control
+ data/artifact
+ GUI session（若需要）
+ runtime/debugger 隔离连接（若需要）
```

这些验证结果登记在部署环境的本地 capability 配置中，不写入通用 Skill。

## 建设顺序

```text
确定任务所需 capability
→ 选择能提供所需后置条件的后端
→ 准备干净 Windows VM 与恢复点
→ 安装/配置 Guest 工具和任务需要的 runtime
→ 按 `tool-building.md` 验证入口、绑定、消费者握手、无害任务和 Host 收割
→ 建立当前 profile 的能力登记
→ 用一次无害但真实的任务验证从干净基线到有效证据
→ 将环境注册为 `ready_for_task` 或 `ready_for_run`
```

若标准分析环境不存在，优先建设它；不得因为临时 VM 更容易启动就绕过。建设阶段仍应以当前任务需要的能力为边界，不安装与后置条件无关的工具。

## 边界

- FLARE-VM 是工具工作站基线，不等于完整自动化沙箱。
- CAPEsolo、DbgEng、Noriben、FakeNet-NG 等是否加入，由当前任务需要决定。
- 不把“这些组件都成熟”写成“它们组合在一起已经被本项目端到端验证”。
- hypervisor 是可替换后端，不是分析语义；更换后端后必须重新验证对应 control、data、network、checkpoint 和 GUI 能力。

## 上游

- FLARE-VM: https://github.com/mandiant/flare-vm
- VM-Packages: https://github.com/mandiant/VM-Packages


