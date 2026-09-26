# C80 · post-launch attach boundary

## 判定

**SUPPLEMENTARY / NO_CORE_RETURN_OBSERVED**。
这批材料只说明在当前客户机基线、断网条件和 post-launch attach 观测方式下，哪些断点能够装上、哪些断点在 8 秒有界窗口内没有命中。它没有得到 RC00 返回值、RC03 返回值、最终输出缓冲区、文件/注册表/设备副作用或自然业务退出，因此不能宣称本地解码核心已完成。

## 固定条件

- 样本：Hardware.genB.exe；参数为合成的 -k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 2 -m 1。
- 客户机网络：nic1=null；本批次没有把网络证据作为核心完成条件。
- 观测：样本先正常启动，宿主在启动后 250 ms 或 2.2 s attach；有些臂只观察 RC00，有些臂同时观察 main、gate 和 RC00 callsite。
- 授权替换：只有日志明确含有 bypass_auth_gate 的臂才记录授权门写入成功；这只是前置条件替换，不是解码算法替换。
- 时间盒：每臂在断点准备后约 8 s 停止；没有阶段进展不继续等待。

## 运行材料

| 臂 | 分类 | 观测目的 | 日志大小 | 运行跨度 | SHA-256 |
|---|---|---|---:|---:|---|
| A250-control | valid control | 250 ms post-launch attach; RC00 callsite byte was 00 | 424 B | 8.123s | e6f61d95bdf947bc3a924e8ebdf088b5da99e74c0e2c258d263682eb8377fe7c |
| A2200-control | valid control | 2.2 s post-launch attach; RC00 callsite byte was E8 | 424 B | 8.068s | 4ee627c2ec55f6a94612b9900481e11f499ba7c61efdb3e80aaf6a56cace0d54 |
| A2200-auth | valid | auth-gate patch recorded; RC00 callsite and gate were not hit | 515 B | 8.096s | 27983032cd2ee644423b92034ee79dda7fe9d347ea121e5e28f7a00a4182c1ab |
| A250-auth | valid | auth-gate patch recorded; delayed callsite arm; RC00 was not hit | 599 B | 8.087s | e028c97a2c1327c6855803f3e3a6893a80859e0e9cbef9ca54cc46e65aea999c |
| A250-gate-rc00 | valid | gate and RC00 callsite breakpoints were both armed | 679 B | 8.004s | fa0b68d9d6740c7e8154316d1891d51f050b5b971c61bafdf11ea1564a8b38d4 |
| A250-main-gate-rc00 | valid | main, gate, and RC00 callsite breakpoints were all armed | 842 B | 8.012s | e09b0770140d208f1dfa14d997eddff2bb4269fb7ef342a3f735e98ff8d051b7 |
| INVALID-stale-copy | invalid instrumentation | expected auth-gate marker is absent; do not use as sample evidence | 424 B | 8.082s | 9e008a401f659eefacbc19362ed8551c1300a60107d7a61255f81fb51e93224c |

## 实际观察

A250-control 只在启动后 250 ms attach，RC00 callsite 首字节仍为 00。这只能作为时间控制，不能解释成样本没有走 RC00。

A2200-control 在 2.2 s attach 时读到 RC00 callsite 首字节为 E8，但没有 RC00 callsite 命中。该臂没有授权门替换，也没有同时监控 main/gate，因此只能说明该时点代码页已可观察。

A2200-auth 记录了授权门地址 0x1407a3080 的 6 字节写入成功，RC00 callsite 字节为 E8，但没有 RC00 命中。A250-auth 在初始断点后把 RC00 callsite 延迟装上，同样没有命中。

A250-gate-rc00 中 gate callsite 0x1407a6a4e 与 RC00 callsite 0x14078ee73 均成功装断点，8 秒内二者均未命中。

A250-main-gate-rc00 进一步确认 main 入口 0x1407a4b90 的首字节为 0x48，main、gate 和 RC00 callsite 三组断点均成功装载，8 秒内均未命中。这仍然是 post-launch attach 条件下的有界结果，不是“样本永远不进 main”的普遍结论。

attach_core_call_authbypass.log 缺少授权门 bypass 阶段标志，虽然文件名暗示了 bypass，但它是旧客体脚本副本造成的无效仪器记录，不能作为样本阴性证据。

## 未得到的核心证据

- RC00 的真实输入、返回值和输出缓冲区。
- RC03 decode_failed 的真实返回契约。
- 0x14078ce60 局部 0x10c 变换与最终业务输出之间的已验证数据流。
- .Sq> 保护运行时完整字节、驱动/辅助组件字节、设备调用结果。
- 解码产生的文件、注册表、设备或其他本地副作用。

## 停止条件与下一步

同一 post-launch attach、同一外层启动方式和同一断网基线不再重复。继续运行相同实验只会重复“断点已装但未命中”，不会提高核心调用链证据强度。要继续闭合，必须得到完整 .Sq> 运行时字节、配套驱动/辅助组件字节，或一个能够在进程早期稳定捕获运行时解密函数及其返回值的新观测基线。

## 可复核来源

- 生成器：<HOST_PATH>\vmctl\synthesize_attach_evidence.py
- 入口脚本：<HOST_PATH>\vmctl\attach_core_call.ps1
- 原始日志目录：<HOST_PATH>\EPT\artifacts\captures\core_debug_probe
- 综合报告：<HOST_PATH>\EPT\artifacts\evidence\C79_local_decoder_core_synthesis_20260921.md
