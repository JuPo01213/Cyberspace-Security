# C67：核心运行态内存采集边界（2026-09-21）

## 结论

**本轮仍未证明业务层解码完成。** 采集已经证明核心进程在启动后仍存活，并且 ProcDump 确实开始生成大于 45 MB 的转储；但第一份转储在封口前被终止，第二份虽在客体日志中达到 100,286,462 字节，宿主未能取回可解析文件，客体随后失去 SSH/Guest Additions 响应。因此没有从内存中取得解码明文、成功标志、绑定弹框文本或硬/软分支运行态证据。

## COREDUMP3：可解析性不足的小转储

取证目录：`<HOST_PATH>\vmctl\offline_COREDUMP3`。

该臂使用 `rundll32 comsvcs` 生成 `Hardware_6s.dmp`，文件大小为 19,796 字节。`minidump` 解析结果可以列出 `Hardware.exe`、系统 DLL、线程和少量内存区域，但内存列表只有极小范围，PEB 解析失败。它足以证明模块/线程现场存在，不足以检索业务解码后的运行态数据。

## COREDUMP4：大文件但未封口

取证目录：`<HOST_PATH>\HexPatch\.ept-live-COREDUMP4`。

脚本日志记录：

```text
CORE_STARTED pid=9044
CORE_AFTER_6S exited=False
DUMP_START tool=C:\ept_harness\procdump64.exe ...
DUMP_TIMEOUT pid=668
CORE_AFTER_DUMP exited=False ... dump_exists=True dump_size=45615564
CORE_KILLED pid=9044
```

宿主取回的文件大小为 45,615,564 字节，SHA-256 为 `F9F85352695A5989A3E87FC4EFF69F422FC32EA3D8C46EDAD3F0160437D37CD3`。文件头的 stream directory 为空，`minidump` 解析器报 `AttributeError: 'NoneType' object has no attribute 'modules'`；因此这是未完成转储，不是可用的完整内存证据。

## COREDUMP5：延长等待后的客体失联

取证目录：`<HOST_PATH>\HexPatch\.ept-live-COREDUMP5`。

本臂将 ProcDump 等待窗口从 15 秒改为 60 秒，加入 `-n 1`，并在启动前删除旧转储。共享日志记录：

```text
CORE_STARTED pid=2336
CORE_AFTER_6S exited=False
DUMP_START tool=C:\ept_harness\procdump64.exe ...
DUMP_EXIT code=1
CORE_AFTER_DUMP exited=False exit_code= dump_exists=True dump_size=100286462
```

宿主随后无法通过 SSH 建立连接，VirtualBox Guest Additions 也无法建立 guest session；共享目录只回写了日志，没有回写转储文件。因此 `100286462` 是客体脚本观察到的文件大小，不是宿主已取得并解析的转储。该臂在此停止并恢复快照，不能升级为运行态解码证据。

## 对“实际是否解码”的回答

当前证据可以确认：

- 外层 `run_decode_from_exe` 曾被真实调用；
- 核心 `Hardware.exe` 曾被真实启动，并在至少 6 秒、以及此前约 24 秒观察窗内保持运行；
- 保护代码的自解密/解包已有既有内存证据；
- 新的 ProcDump 采集进入了核心运行态，但没有留下可用的、可检索业务明文的宿主转储。

当前证据不能确认：

- 业务解码函数是否实际返回成功；
- 卡密/绑定结果是否生成；
- 硬阻断或软允许分支是否被真实走到；
- 任何绑定文案或成功产物是否在运行时出现。

因此当前结论仍是：**核心启动已证实，保护层运行态采集已尝试但未形成可解析证据，业务解码完成仍未知，不应写成已发生。**

虚拟机最终状态：`saved / qoder-clean-20260920`。
