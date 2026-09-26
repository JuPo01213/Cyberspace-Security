# C68：外层“解码完成”与核心业务结果的语义分离（2026-09-21）

## 结论

**`run_decode_from_exe` 的 `final_status=completed` 不是核心授权成功的证明。** 字节码显示，外层只负责启动核心、处理窗口、等待固定时间并执行后续部署/清理；它没有读取核心退出码来决定“完成”，也没有从核心返回值中取得业务授权结果。

## `_call_spoofer_commandline` 的真实判定

来自样本原始 `auto_decode.pyc`，Python 3.13.15 `dis`，代码对象 `<module>._call_spoofer_commandline`：

- 检查 `HARDWARE_EXE_PATH` 存在；不存在才直接返回 `False`。
- `codeType=static` 映射为 `-n 0`，其他类型映射为 `-n 2`；`mode1/2/3` 映射为 `-m 1/2/3`。
- 以 `subprocess.Popen([Hardware.exe, -k, card_key, -n, ..., -m, ...], stdout=PIPE, stderr=PIPE)` 启动核心。
- 固定 `sleep(8)` 后调用 `proc.poll()`。
- 如果 `poll()` 返回 `None`，立即记录“解码程序已启动并正在运行”并返回 `True`；不等待核心结束，也不取得核心退出码。
- 只有核心已经退出时，才 `communicate(timeout=5)`，且退出码为 0 才返回 `True`；非零码返回 `False`。
- `False` 在调用方只触发“调用异常，继续执行”的警告，不会直接让 `run_decode_from_exe` 返回失败。

这解释了 C66/CORE1 的动态结果：`Popen` 成功且 8 秒后 `poll=None` 只能证明核心仍在运行，不能证明核心已完成授权判断。

## `run_decode_from_exe` 的后续控制流

核心调用之后，外层依次执行：

1. `_handle_disclaimer_dialog()`；返回假值才返回 `{'final_status': 'stopped'}`。
2. 固定 `sleep(10)`，日志写作“等待验证结果”。这不是读取核心结果。
3. `_detect_bind_error_dialog()`；命中绑定弹窗才抛出 `CardKeyBoundError` 并返回 `card_bound`。
4. 未命中绑定弹窗时进入后续部署路径；`versionSelect=compat2` 还会固定等待 `180` 秒，每次间隔 `30` 秒。
5. 调用 `_add_hidden_auto_start()`、`_run_trace_cleanup()`，最后由壳自身记录“解码完成，请重启电脑生效”，返回 `{'final_status': 'completed'}`。

因此该 `completed` 出口表达的是“外层流程走完自己的步骤”，不是“核心返回授权成功”。尤其是硬阻断文案与壳侧绑定关键词不相同的情况下，未命中绑定弹窗不能推出核心放行。

## 与动态证据的合并

- OUTER2 在桌面查找前置失败，返回 `failed`，没有进入核心。
- OUTER5 的实时日志证明核心已 `Popen`，随后外层卡在免责窗口探测。
- CORE1 绕过 GUI 探测后，核心在约 24 秒内仍无自然退出。
- C67 的运行态内存采集没有取得可解析的业务明文或核心结果。

所以当前最强结论是：**外层启动链已闭合，核心确实运行过；核心业务解码是否返回成功仍未知。任何把外层 `completed`、`poll=None` 或“启动成功”写成“已解码”的表述均不成立。**

## 可复核来源

- 样本：`<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe_extracted\PYZ.pyz_extracted\auto_decode.pyc`
- 既有控制流证据：`C60_shell_decode_branch_cfg.txt`
- 动态启动证据：`C66_core_launch_lifecycle_20260921.md`
- 内存采集边界：`C67_core_memory_capture_20260921.md`
