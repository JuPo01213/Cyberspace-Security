# Windows 分析能力路由手册

本文件只处理“成熟能力不可直接使用时怎么办”。不要把它当成固定实验流水线。

## 先找能力，不先找机器

先读 `capability-contract.md`。任务契约定义需要什么，能力登记只回答本地哪个环境能够满足；本地发现不能反向改变任务语义。

先确定当前任务真正需要的能力，例如：

- Windows 动态执行与行为采集；
- 用户态或内核调试；
- 网络模拟/抓取；
- GUI 交互；
- 静态逆向；
- VM 快照、恢复和隔离。

然后按以下顺序查找：

1. 当前项目是否已经声明默认能力或标准分析环境；
2. 当前环境是否已经安装并验证成熟工具/runtime；
3. 官方或社区是否有维护中的成熟方案可以合理部署。

如果当前 Host 的能力完全未知，并且有 PowerShell shell，可选运行 `scripts/preflight.ps1` 做**只读发现**。它只能帮助发现 Hyper-V、VirtualBox、SSH、Host debugger 等基础能力，不能替代成熟分析 capability 的识别。

机器名、hypervisor、IP 和命令只是能力的承载或实现，不应成为首要选择依据。发现某个平台或某台 VM 只能产生候选，不能自动产生选择结论。

## 成熟能力存在

直接使用其最高层入口。

如果 runtime 已经管理：

- task/job；
- 启动与完成；
- retry/recovery；
- artifact/result；
- VM 生命周期；

就让它继续管理，不在外面再造一套 runner、done marker、轮询协议或状态文件。

若 runtime 不管理 VM 生命周期，则 checkpoint、隔离和 Guest 控制仍由已登记的基础设施后端负责；不得把 runtime 未声明的能力补写成其既有能力。

## 成熟能力不存在

“没有安装”不是 fallback 条件。

在授权、资源和安全允许时：

```text
选择成熟方案
→ 安装/启用
→ 配置
→ 用无害对象验证
→ 注册为可用能力
→ 再执行真实任务
```

如果安装失败，先查官方文档、版本兼容和环境依赖并尝试修复。

只有出现明确的不适用条件，例如平台不兼容、必要能力确实不存在、部署成本明显超过任务价值或安全边界不允许，才进入替代方案。

## 成熟能力只有局部缺口

先明确缺的是哪一个动作，然后只补这一层。

例如：

```text
成熟 runtime 已负责样本任务和 artifacts
但缺精确 debugger 操作
→ 只补 debugger adapter
```

不要因此重新实现样本启动、任务状态、artifact 收集或 VM 调度。

## 低层直连是最后手段

只有在前述判断完成后，才选择 PowerShell Direct、VBoxManage、SSH、SMB、CDB 等低层机制。

使用低层机制时，只验证当前任务真正依赖的能力；不要顺手扩展成新的通用 workflow engine。

## 完成后

若本次暴露了新的缺口：

1. 先记录为一次真实运行事实；
2. 判断它是环境特例还是可复用问题；
3. 查成熟方案是否已经解决；
4. 只有反复出现、通用且长期收益高于维护成本时，才晋升为 Skill 规则或可复用适配器。


## 对应参考

- 能力分层与登记：`capability-contract.md`
- 建设 Windows 分析环境：`windows-analysis-stack.md`
- CAPEsolo MCP runtime：`capesolo-mcp.md`
- Microsoft debugger：`debugger-stack.md`
- 行为采集：`behavior-capture.md`
- 网络分析：`network-analysis.md`
- GUI：`gui-analysis.md`
- 低层 fallback：`adapters.md`
- 失败判断：`failure-routing.md`

