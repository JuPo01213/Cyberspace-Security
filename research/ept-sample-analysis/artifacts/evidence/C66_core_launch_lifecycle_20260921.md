# C66：核心启动与生命周期动态证据（2026-09-21）

## 结论

**核心 `Hardware.exe` 的真实启动已经被证明；业务解码完成仍未被证明。** 这是对 C65 的实质推进：不能再说“核心是否启动未知”，但也不能把“进程启动并持续运行”写成“卡密已解码”。

## OUTER4：共享目录证实 harness 已启动，但运行时依赖不完整

取证目录：`<HOST_PATH>\vmctl\offline_OUTER4`。

共享目录日志先记录了 `BOOT`、`HOSTS_PINNED` 和 `PRE_PROCESS`，随后结果为：

```text
exception_type=ModuleNotFoundError
exception=No module named 'pip'
```

这是实验 harness 重建 Python 3.13 运行时时漏掉 `pip` 的仪器错误，不是样本行为。补齐 host 原运行时中的 `pip` 后才进入下一次实验。

## OUTER5：原始调度器启动了核心，并卡在窗口探测

取证目录：`<HOST_PATH>\vmctl\offline_OUTER5`；原始实时共享目录为 `<HOST_PATH>\HexPatch\.ept-live-OUTER5`。

关键日志顺序：

```text
2026-09-21T07:56:39 CALL run_decode_from_exe
2026-09-21T07:56:40 解码程序部署完成
2026-09-21T07:56:41 即将执行 subprocess.Popen
2026-09-21T07:56:42 Popen 完成 pid=2784
2026-09-21T07:56:54 poll() 返回 poll_result=None
2026-09-21T07:56:55 _handle_disclaimer_dialog 开始
2026-09-21T07:56:56 find_target_pid
```

这证明：

- `run_decode_from_exe` 找到了投送的 genB 核心并将其部署到 `C:\Windows\System32\Hardware.exe`；
- 核心进程 PID 2784 被真实创建，8 秒后仍在运行；
- 外层随后进入免责/窗口探测，而不是在启动前置条件处失败。

宿主在 90 秒硬截止收尾前没有看到 `RESULT`、绑定文案、自然退出码或解码产物；该臂的收尾仍是 `instrument_failure`，所以 OUTER5 不证明业务解码。

## CORE1：绕过 GUI 探测直接观察核心生命周期

取证目录：`<HOST_PATH>\vmctl\offline_CORE1`；运行器直接启动同一份 genB：

```text
CORE_STARTED pid=1604
CORE_POLL after_seconds=6.702  poll=null
CORE_POLL after_seconds=11.602 poll=null
CORE_POLL after_seconds=24.163 poll=null
RESULT status=timeout_killed
taskkill returncode=0
```

该臂没有调用 Python 外层的 `find_target_pid`，因此它把“窗口探测卡住”和“核心自身不自然退出”分开了。结果表明核心至少在约 24 秒观察窗内持续运行，随后只能被外部终止；没有自然返回码，仍没有业务解码结果。

## 当前可交付分析

现在可以准确写成：

> 原始外层调度器已在客体内实际部署并启动 genB 核心；核心在观察窗内保持运行，外层卡在窗口探测，直接核心臂也未取得自然退出。业务解码、绑定响应、hard/soft 分支选择和阻断后的自然生命周期仍未观测到。

不能写成：

> 已完成解码、已验证卡密、已显示绑定弹框、或已确定核心走了某一分支。

虚拟机已恢复到 `saved / qoder-clean-20260920`。继续动态分析必须引入更强的独立观测（例如 VMM/调试器级进程与窗口/内存事件记录），而不是延长同一个 GUI 等待循环。
