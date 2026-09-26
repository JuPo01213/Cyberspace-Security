# C84 · native progress probe variance

## 判定

C84 是对 C83“查询 RCX 等待句柄”假设的区分性反证。新的一次原生启动仍未命中 `main=0x1407a4b90` 或 RC00 `0x14078ee73`；3 秒进度断点却得到不同的 RIP=`0x143a4a035`、RCX=`0x3e9`，对该值执行 `DuplicateHandle` 返回 Windows 错误 6（无效句柄）。因此不能把 C83 的 RCX=`0x4d4` 升级为已确认的等待对象，也不能用猜测的句柄类型解释启动停滞。

状态为 `RUNTIME_PROGRESS_NONDETERMINISTIC / NO_CORE_ENTRY_OBSERVED`：两个短时原生启动都没有到达核心观察点，且进度断点现场不稳定；它们都不是本地解码阴性或成功证据。

## 运行边界

- 客体快照：`qoder-clean-20260920`；网卡为 `null`。
- 启动前只恢复 `.text`、替换授权闸门，并布置 `main`/RC00 断点；不回放 `.Sq>`，不使用 direct-main stub。
- 3 秒请求一次进度断点，总墙钟截止 20 秒；探针只复制 RCX 对应值并调用 `NtQueryObject`/进程线程标识查询，不修改样本内存。

## 原始阶段日志

```text
﻿2026-09-21T03:23:44.4596907Z phase=launch command=synthetic_core_no_network
2026-09-21T03:23:45.3012297Z phase=created pid=8800 tid=1904
2026-09-21T03:23:45.3086089Z phase=loader_created waiting_initial_breakpoint
2026-09-21T03:23:45.3672637Z phase=native_startup_prepare
2026-09-21T03:23:45.6797544Z phase=restore_plaintext bytes=8257536 sha256=5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757 written=8257536 ok=True
2026-09-21T03:23:45.6797544Z phase=bypass_auth_gate address=0x1407a3080 ok=True written=6
2026-09-21T03:23:45.6797544Z phase=arm_main_entry address=0x1407a4b90 ok=True original=48 error=0
2026-09-21T03:23:45.6797544Z phase=arm_callsite address=0x14078ee73 ok=True original=e8 error=0
2026-09-21T03:23:45.6797544Z phase=native_startup_resume
2026-09-21T03:23:48.3608886Z phase=native_progress_break_requested ok=True error=121
2026-09-21T03:23:48.3608886Z phase=exception code=0x80000003 address=0x7ffbe73710d0 rip=0x143a4a035 rsp=0x14f3a0
2026-09-21T03:23:48.3697846Z phase=native_progress_probe rip=0x143a4a035 rsp=0x14f3a0 rax=0x1f rcx=0x3e9 stack_error=0 stack_bytes=512
2026-09-21T03:23:48.3734687Z phase=native_progress_handle value=0x3e9 duplicate_ok=false error=6
2026-09-21T03:24:05.3730737Z phase=timeout no_native_main_entry
2026-09-21T03:24:05.3730737Z phase=timeout no_rc00_callsite_hit
```

## 现场

- 进度 RIP=`0x143a4a035`，RSP=`0x14f3a0`，RAX=`0x1f`，RCX=`0x3e9`；栈读取成功，首 qword=`0x0000001400000007`。
- 句柄探针原始结果：`2026-09-21T03:23:48.3734687Z phase=native_progress_handle value=0x3e9 duplicate_ok=false error=6`。`DuplicateHandle` 的错误 6 使“RCX 是有效内核对象句柄”这一解释不能成立。
- C83 的同类现场是 RIP=`0x7ffbe736d624`、RCX=`0x4d4`；C84 的现场不同，说明一次进度断点不足以建立稳定的启动状态模型。
- C84 窗口内没有 `main`、RC00、RC03、输出缓冲区、文件、注册表、设备调用或自然业务返回值。

## 结论边界

C84 关闭了“继续猜 RCX 等待对象”的低价值方向，也说明单纯重复原生启动不会提高核心证据强度。若继续推进，需要新的早期模块/线程事件或另一套可复现底座；在当前底座上，核心输入—变换—输出链仍未闭合。

## 可复核材料与哈希

- 运行日志：`<HOST_PATH>\EPT\artifacts\captures\core_native_startup_20260921C\debug_core_call.log`；SHA-256 `a970366ace47a64225472786cf59e594e3595f8d122f63844fdc56a275596d1f`；长度 1352 字节。
- 进度栈：`<HOST_PATH>\EPT\artifacts\captures\core_native_startup_20260921C\native_progress_stack.bin`；SHA-256 `41dae4c33fe3496fd67a55e6111dcaef9e4699c31b264b983134b43ddc1dc4e7`；长度 512 字节。
- 运行器：`<HOST_PATH>/vmctl/debug_core_call.ps1`；模式参数：`-NativeStartup`。

## 状态

`INCOMPLETE`: C84 只收窄了原生启动现场的可解释范围，没有取得解码返回值或本地副作用。
