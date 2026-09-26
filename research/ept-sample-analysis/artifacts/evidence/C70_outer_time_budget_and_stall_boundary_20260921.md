# C70：外层时间预算与卡顿边界（2026-09-21）

## 结论

**16 分钟不是当前外层解码脚本的正常业务等待时间，也不能被解释为“解码需要 16 分钟”。** 原始 `auto_decode.pyc` 中可直接确认的固定等待只有秒级；`versionSelect=compat2` 分支另有固定 `180 s` 清理等待。超过这个量而没有新的业务标志，应先分类为调度器/客体/仪器停滞，而不是继续机械等待。

## 可确认的固定等待

来源是原始 `auto_decode.pyc`（SHA-256：`414476eacb0f3eee219b073eb3c3e85bbe5ac562af85e357fa80e499bd56dba2`），Python 3.13 `dis` 对以下代码对象的反汇编：

- `_call_spoofer_commandline`：启动 `Hardware.exe` 后固定 `sleep(8)`；随后只做 `poll()`。进程仍在运行时直接返回 `True`。
- `_handle_disclaimer_dialog`：调用 `_detect_disclaimer_dialog(timeout=5)`；命中免责窗口后最多运行约 `30 s` 的监控循环，自动点击后 `sleep(2)`。
- `run_decode_from_exe`：免责处理之后固定 `sleep(10)`；`compat2` 分支固定等待 `180 s`，间隔 `30 s`。
- 后续清理步骤还有短的固定 sleep，但没有形成十几分钟的核心授权等待。

因此，仅按固定常量计算，从核心启动到外层自称完成的名义等待是几十秒；即使取免责窗口和 `compat2` 分支，也约为几分钟量级，**不是 16 分钟**。这只是控制流预算，不是保证程序一定在该时限内返回。

## 为什么实际可能超过名义预算

名义预算没有覆盖若干原生 GUI 调用的墙钟耗时：

- `_detect_disclaimer_dialog` 的循环会调用 `find_target_pid`、`EnumWindows` 和窗口关键词读取；这些调用自身没有统一的外层硬截止时间。
- `_check_disclaimer_window_gone` 会同步调用 `EnumWindows`；其子窗口枚举线程虽然有 `3 s` 的 join 上限，但外层 Win32 枚举和窗口消息读取仍可能拖慢单次循环。
- 代码只是记录“枚举/窗口检查耗时超过 1–2 秒”的警告，并没有在警告后中止当前阶段。

所以“脚本还在等”可能实际表示 GUI 探测调用卡住、客户机响应停滞、Guest Additions/SSH 通道失效或宿主调度异常。它不表示核心仍在进行有效授权计算。

## 与本轮动态证据的对应

- OUTER5 的共享日志已记录核心 `Popen` 成功、8 秒后的 `poll_result=None`，随后进入 `_handle_disclaimer_dialog`。
- 日志在 `find_target_pid` 之后没有出现免责处理返回、10 秒验证等待完成、绑定检测结果或外层 `completed`。
- CORE1 绕过外层 GUI 后，核心在约 24 秒观察窗内仍未自然退出。
- C69 的 pcap 只有授权域名 DNS 查询/应答，没有到返回地址或 1029 端口的后续连接。

这些事实支持“外层/仪器在窗口探测处停滞，核心授权结果未返回”的解释；它们不支持“解码花了 16 分钟但最终成功”。

## 时间敏感判定规则

后续记录中，必须把以下状态分开：

1. 固定等待仍在名义预算内：`WAITING`，只能说明代码尚未到下一标志。
2. 超过阶段墙钟预算且没有新的阶段标志：`STALL_SUSPECTED`，立即检查进程存活、通道和资源状态。
3. 只有取得核心自然退出码、核心明确业务返回/弹窗结果，或独立的分支行为见证，才能写成业务结果。
4. `Popen` 成功、`poll=None`、外层 `final_status=completed`、文件大小或等待超时均不能单独升级为“已解码”。

## 当前结论

**解码实际发生并成功完成：未证实。** 已证实的是外层启动了核心，核心会进入域名解析前置阶段；尚未证实授权连接、服务端返回、核心分支结果或业务完成标志。现有 16 分钟等待应归入历史调度/仪器成本，不再作为本样本的合理运行时长。

## 可复核来源

- `<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe_extracted\PYZ.pyz_extracted\auto_decode.pyc`
- `artifacts/evidence/C66_core_launch_lifecycle_20260921.md`
- `artifacts/evidence/C68_outer_decode_completion_semantics_20260921.md`
- `artifacts/evidence/C69_core_network_progress_boundary_20260921.md`
