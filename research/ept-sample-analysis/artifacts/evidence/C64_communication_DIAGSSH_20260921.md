# 程序级通信与 BR22 动态证据（2026-09-21）

## 范围

本件把“靶机通信是否可用”和“样本是否走到某个分支”分开登记。SSH 进程清单只证明控制/诊断通道及客户机服务状态；BR22c 的开机采集器才是样本臂。两者不能互相替代。

实验对象为 VirtualBox VM <OTHER_VM_LABEL>。所有样本运行仍在 VM 内，yz.hwid001.com 未连接，宿主网络未修改。当前收尾状态已复核为 VMState="saved"、CurrentSnapshotName="qoder-clean-20260920"。

## 通信能力控制臂

通用脚本：

<HOST_PATH>\Users\<USER>\.agents\skills\reverse-engineering-workbench\scripts\ssh_guest_process_probe.sh

脚本 SHA-256：

511A4AEEB4DA877E9DC4198FCF35B032A1852F2AE21B9D0BB24C2AF706D3F262

运行配置：

    run_id=DIAGSSHWRAP_20260921_044000
    transport=ssh
    target=<VM_USER>@<LOOPBACK>:2222
    command=tasklist /fo csv /nh
    timeout_sec=15

实际结果：

    started_at=2026-09-21T04:39:33+08:00
    ended_at=2026-09-21T04:39:36+08:00
    elapsed_sec=3
    status=PROCESS_LIST
    rc=0
    bytes=6936
    sha256=F7F3949D2E06423700379AAEE3554E12EE541E1CCE8CCE330CD1782ACAA7BFFF

原始输出：

<HOST_PATH>\vmctl\process_probe\DIAGSSHWRAP_20260921_044000_tasklist.raw.txt

sidecar：

<HOST_PATH>\vmctl\process_probe\DIAGSSHWRAP_20260921_044000_tasklist.meta.txt

这是一条在 clean 快照、样本未投放条件下的通信控制证据，不是样本行为证据。

此前同一类 SSH 诊断还记录到就绪延迟：DIAGSSH_20260921_042642 的 15 秒探针在 banner exchange 阶段超时（原始文件 88 B，SHA-256 86CD293077D343BCCB1AC92854245A39FF5833B72811040C6F3E53064C3FD26A），35 秒探针随后返回完整 tasklist（3,999 B，SHA-256 A370466B8277BA5479B7967930C1EFA19970BDDC681C6AEBF887948732C7DB6E）。这证明“早期 SSH 未就绪、后续进程清单成功”是通信时序现象，不能写成“靶机没有进程”或“样本没有运行”。

## BR22c 样本臂

来源快照：qoder-baked-20260921h。采集器输入身份为：

    size=32671232
    sha256=CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7

独立动态观察来自：

<HOST_PATH>\vmctl\offline_BR22c\arm_log.txt

该文件 SHA-256 为 0ADED63D2580B4648D1E14352B0BC9759C31C33F4CD897E7073519D76EA1466B。它记录了：

- 采集器启动并完成自身 PEEK_CONTROL；
- 核心身份与哈希复核通过；
- CLEAN_PRE=Y--- D:vol；
- hosts 已钉回环，RESOLVE_NOW=127.0.0.1；
- Hardware.exe -k <key> -n 2 -m 1 启动，pid=5436，启动时 age=7s。

这闭合了“在受控 VM 内、输入身份正确、网络边界正确、目标核心确实被启动”的动态前缀。

但该臂在 180 秒 deadline 内没有产生 BRANCH_DONE、自然退出码或完整弹窗记录；控制日志明确将其分类为 WAIT_TIMEOUT 后的硬 poweroff / INSTRUMENT_FAILURE，因此 judge_branch.py 没有运行。离线取件本身成功（本次 NEWFILE_COUNT=199），但 CLEAN_POST 的目录状态不能单独升级为 hard/soft 分支结论。

控制日志：

<HOST_PATH>\vmctl\log_BR22c.txt

SHA-256：

6A638C0820B6C37EA1CFEE8644FD1ABCD17F6C6B0746460862065570C714E56F

## 当前结论

通信工作流固定为三平面：

- 控制面：短时 SSH/Guest Control 诊断和状态查询；
- 数据面：客户机本地 spool，结束后离线只读收割；
- 完成面：显式 marker、自然退出或 VM 状态；超时必须分类为仪器失败并保留材料。

SSH PROCESS_LIST 已有真实控制臂验证；SSH 超时、Guest Control 不可用和样本臂超时均只表示观测仪器结果。BR22c 提供了独立的样本启动证据，但“hard 阻断后的进程生命周期”仍为 VALID_UNOBSERVABLE_ON_THIS_BASE，不能用通信失败替代该结论。
