# C65：外层实际解码调用的运行证据（2026-09-21）

## 结论

**截至本证据，业务解码没有被证明实际完成。** 本轮确实在客体内调用了原始 `auto_decode.pyc` 的 `DecodeEngine.run_decode_from_exe`，但第一次调用在“查找桌面解码程序”前置条件处返回；第二次修正 SYSTEM 桌面投送后，客体通信在核心路径附近失去响应，宿主按 90 秒硬截止收尾，未取得可用的返回值、退出码、弹框文字或解码产物。因此第二次只能记为 `instrument_failure/ABSTAIN`。

## OUTER2：调用已返回，但未进入核心解码

取证目录：`<HOST_PATH>\vmctl\offline_OUTER2`

- `outer_decode.result.json`：
  - `call = DecodeEngine.run_decode_from_exe`
  - `status = returned`
  - `elapsed_seconds = 7.351`
  - `result.final_status = failed`
  - 错误：`桌面上找不到解码程序，请确认已将文件放置桌面`
- `outer_decode.log` 的关键顺序为：
  - `BOOT pid=1912`
  - `CALL run_decode_from_exe`
  - `[ERROR] 桌面上找不到解码程序(.exe)`
  - `RESULT=... final_status=failed`
  - `SELF_SHUTDOWN_BEGIN result`
- 该臂证明的是：原始 Python 调度器被加载并执行，且其失败分支可观测；它**不证明**核心 `Hardware.exe` 已被调用，更不证明业务解码。

根因是运行身份为 SYSTEM，而投送文件只放在 Administrator 桌面；`run_decode_from_exe` 使用当前运行身份的桌面查找解码器。将 EXE 放到普通 Administrator 桌面不能满足 SYSTEM 任务的前置条件。

## OUTER3：修正投送路径后仍无可采信动态结果

取证目录：`<HOST_PATH>\vmctl\offline_OUTER3`

修正内容已在触发前确认：`Hardware.genB.exe` 放置于 `C:\Windows\System32\config\systemprofile\Desktop`，大小为 `32671232` 字节；任务重新注册为 SYSTEM。

实际观察：

- 触发命令返回成功，但约 90 秒后 SSH 在 banner 阶段超时；
- 宿主按时间盒执行 `VBoxManage controlvm poweroff`，因此这不是自然退出实验；
- 离线盘未发现：`ept_harness\outer_decode.log`、`ept_harness\outer_decode.result.json`、`Windows\System32\Hardware.exe`、`Hardware.exe` Prefetch；
- `NEWFILE_COUNT=79`，但内容主要是 Windows/OneDrive/Prefetch 的普通系统活动；该计数不能指向样本执行；
- VM 已恢复到 `qoder-clean-20260920`。

因此 OUTER3 不能升级为“已解码”“已进入核心”或“已走硬阻断”。最强可用表述是：**投送前置条件已修正，但运行结果在当前客体通信/存储收尾条件下不可观测；该臂弃权。**

## 与既有静态证据的合并解释

- `C60` 证明壳侧 `bind_error` 分岔和多个 `final_status` 出口在字节码控制流中存在；
- `C63` 证明核心捕获中存在壳侧识别的绑定文案，但不是运行时显示证据；
- `C59` 证明争议调用点存在，目标函数体超出捕获范围，运行效果仍未决；
- C6/BR7 的内存捕获证明保护代码自解密/解包，不等于业务解码成功；
- C65 新增的动态事实只闭合了“外层调度器可执行”和“前置查找失败分支可观测”，没有闭合业务解码或硬阻断后的进程生命周期。

## 当前分析边界

当前可以交付：

> 静态侧已经分离出分支触发条件、分支独有动作和壳侧识别接缝；外层调度器的失败出口也已由真实运行观察到。

当前不能声称：

> 卡密已被核心实际解码、硬阻断弹框已显示、解码成功产物已生成、或硬阻断叶已自然结束进程。

若继续动态实验，必须更换收尾/观测设计（例如把核心启动与外层等待拆成独立、可离线落盘的原生 watchdog），不能重复 OUTER3 的“同一客体内线程看门狗 + 宿主硬断电”方案。
