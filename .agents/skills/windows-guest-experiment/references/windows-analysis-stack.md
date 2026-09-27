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

## 建设顺序

```text
准备干净 Windows VM
→ 满足 FLARE-VM 前置条件
→ 安装 FLARE-VM
→ 验证关键工具可启动
→ 安装任务需要的额外 runtime（例如 CAPEsolo）
→ 建立干净 checkpoint
→ 用无害程序做一次端到端验证
→ 将该环境注册为可用分析 capability
```

若标准分析环境不存在，优先建设它；不得因为临时 VM 更容易启动就绕过。

## 边界

- FLARE-VM 是工具工作站基线，不等于完整自动化沙箱。
- CAPEsolo、DbgEng、Noriben、FakeNet-NG 等是否加入，由当前任务需要决定。
- 不把“这些组件都成熟”写成“它们组合在一起已经被本项目端到端验证”。

## 上游

- FLARE-VM: https://github.com/mandiant/flare-vm
- VM-Packages: https://github.com/mandiant/VM-Packages
