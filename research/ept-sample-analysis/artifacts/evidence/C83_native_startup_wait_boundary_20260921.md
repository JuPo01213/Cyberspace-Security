# C83 · native-startup wait boundary

## 判定

在不回放 `.Sq>`、不跳转伪造 `main` 的原生启动观察中，20 秒内没有命中 `main=0x1407a4b90`，也没有命中 RC00 调用点 `0x14078ee73`。3 秒进度断点取得的 RIP=`0x7ffbe736d624` 位于 `Hardware.exe` 镜像区间 `0x140000000+` 之外；因此当前证据只能判为 `NO_SAMPLE_ENTRY_OBSERVED / WAIT_BOUNDARY`，不能判为解码失败或成功。

这次观测的价值在于：同一短时窗口内，授权闸门替换、`.text` 恢复和两个观察断点均已成功，而样本线程的进度现场位于镜像外；RAX/RCX 的形状与句柄等待候选相符，但具体 API 尚未确认。它把“没有命中”从未知时序问题收窄为启动链/外部执行边界；但没有证明等待对象的业务含义，也没有证明驱动或网络被调用。

## 运行边界

- 客体快照：`qoder-clean-20260920`；运行期间网卡为 `null`。
- 命令：客体内直接启动 `C:\ept_core\Hardware.exe -k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 2 -m 1`。
- 首个 loader 断点处只恢复静态 `.text` 并替换授权闸门 `0x1407a3080`；没有写回 `.Sq>`，没有使用 direct-main stub。
- `main=0x1407a4b90` 与 RC00 callsite `0x14078ee73` 均在启动前布置断点。
- 3 秒时只请求一次 `DebugBreakProcess` 进度断点；总墙钟截止 20 秒。

## 原始阶段日志

```text
﻿2026-09-21T03:15:07.4634385Z phase=launch command=synthetic_core_no_network
2026-09-21T03:15:07.4791976Z phase=created pid=5236 tid=1636
2026-09-21T03:15:07.4791976Z phase=loader_created waiting_initial_breakpoint
2026-09-21T03:15:07.5496175Z phase=native_startup_prepare
2026-09-21T03:15:07.6139580Z phase=restore_plaintext bytes=8257536 sha256=5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757 written=8257536 ok=True
2026-09-21T03:15:07.6139580Z phase=bypass_auth_gate address=0x1407a3080 ok=True written=6
2026-09-21T03:15:07.6139580Z phase=arm_main_entry address=0x1407a4b90 ok=True original=48 error=0
2026-09-21T03:15:07.6139580Z phase=arm_callsite address=0x14078ee73 ok=True original=e8 error=0
2026-09-21T03:15:07.6139580Z phase=native_startup_resume
2026-09-21T03:15:10.5073973Z phase=native_progress_break_requested ok=True error=121
2026-09-21T03:15:10.5087086Z phase=exception code=0x80000003 address=0x7ffbe73710d0 rip=0x7ffbe736d624 rsp=0x1454f8
2026-09-21T03:15:10.5110488Z phase=native_progress_probe rip=0x7ffbe736d624 rsp=0x1454f8 rax=0x4 rcx=0x4d4 stack_error=0 stack_bytes=512
2026-09-21T03:15:27.5360362Z phase=timeout no_native_main_entry
2026-09-21T03:15:27.5360362Z phase=timeout no_rc00_callsite_hit
```

## 进度现场

- RIP=`0x7ffbe736d624`，RSP=`0x1454f8`，RAX=`0x4`，RCX=`0x4d4`；ReadProcessMemory 读取栈 `512` 字节成功。
- 栈首个 qword=`0x00007ffbe497b6ae`；后续栈内容保存在 `<HOST_PATH>\EPT\artifacts\captures\core_native_startup_20260921B\native_progress_stack.bin`，没有把它解释成业务返回地址。
- RIP 不在样本镜像 VA 范围内；仅凭地址形状不指定具体系统 DLL 或 API，因此“等待某个系统对象”保留为边界描述，而不是已确认的 API/驱动结论。
- 20 秒截止时没有 `RC00`、`RC03 decode_failed`、输出缓冲区、文件、注册表、设备或自然业务返回值。

## 证据解释

C83 不替代 C82：C82 证明“整段 `.Sq>` 快照直接重放会因栈/调度状态不匹配而在 `ret 8` 处异常”；C83 则证明“不回放 `.Sq>` 的原生启动在当前底座上进入样本镜像外的进度现场，未进入已布置的 `main`/RC00 观察点”。两者共同说明：当前底座的启动状态与保护运行时仍未形成可稳定复现的核心调用入口。

不应继续增加等待时间或重复同一启动臂；下一步若仍要推进，应改变判别量，例如在进度现场查询该进程句柄 `0x4d4` 的对象类型/关联线程，或取得更早的入口/模块加载事件。没有新判别量时，重复启动不会提高核心输入—变换—输出证据。

## 可复核材料与哈希

- 运行日志：`<HOST_PATH>\EPT\artifacts\captures\core_native_startup_20260921B\debug_core_call.log`；SHA-256 `339ca7e97200eb43627a451c6f522488bf4d7fe3683106fdc69fb9749a91e9b7`；长度 1259 字节。
- 进度栈：`<HOST_PATH>\EPT\artifacts\captures\core_native_startup_20260921B\native_progress_stack.bin`；SHA-256 `35267226c09d1582c3ebfc394e0a1e6954e7fe42aaf95b8cb8ba41f654886288`；长度 512 字节。
- 运行器：`<HOST_PATH>/vmctl/debug_core_call.ps1`；模式参数：`-NativeStartup`。

## 状态

`INCOMPLETE`: 已建立原生启动的短时等待边界，但本地解码核心的输入、变换、输出/副作用及用户态/驱动边界仍未闭合。
