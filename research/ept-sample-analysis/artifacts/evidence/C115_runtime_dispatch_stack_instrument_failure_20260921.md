# C115：runtime dispatch 栈现场臂的 Guest Control 仪器失败（2026-09-21）

## 状态

`INVALID_INSTRUMENT / CHANNEL_OR_GUESTCONTROL_HANG`

## 目的与改变量

该臂保持 C114 的样本、快照、断网、命令行和 child bypass 设计不变，只把父进程高地址断点动作从寄存器记录改为附加 `kv`、`dq @rsp L8` 和局部反汇编，试图取得 dispatch 的调用上下文。

## 实际结果

- 主机脚本：`<HOST_PATH>\VMs\<OTHER_VM_LABEL>\natural_dispatch_runtime_stack_v3.ps1`
- VM 曾成功启动为 `running`，运行期 `nic1=null`，但 Guest Control/收割流程在预期窗口外没有产生 `cdb_stdout.txt`、`run_meta.txt` 或 `probe.cdb`。
- 主机侧观察到该流程超过约 60 秒仍未返回；随后中止宿主编排进程。
- 没有可验证的 CDB marker、断点命中、样本退出码或业务输出，因此本臂不提供样本行为证据。

## 分类与清理

这是通信/仪器失败，不是 `VALID_NOT_REACHED`、不是核心不存在、不是解码失败，也不是 bypass 后的阴性。之后已手动完成 `poweroff → restore qoder-clean-20260920 → nic1=nat`，当前 VM 为 `saved`；空的临时捕获目录未作为正式产物保留。

在没有新的 Guest Control 收尾方案前，不重复同一栈现场臂；C114 的有效父 dispatch 证据独立保留。
