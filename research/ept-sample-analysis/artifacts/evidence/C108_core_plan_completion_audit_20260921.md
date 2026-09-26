# C108：5.1 本地解码核心计划逐项验收

日期：2026-09-21  
对象：`Hardware.genB.exe`，SHA-256 `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`  
总状态：`INCOMPLETE / REAL_RESPONSE_PRODUCER_UNOBSERVED`

本件把用户计划中的完成条件逐项映射到当前证据。`VERIFIED` 只表示对应范围已经有直接证据；`PARTIAL` 表示局部 seam 已闭合但自然路径或真实输入仍缺失；`MISSING` 表示当前没有足够证据。

| 计划要求 | 状态 | 当前证据与边界 |
|---|---|---|
| 目标对象是当前 genB，而非外壳/授权流程 | `VERIFIED` | genB 文件与恢复 `.text` 哈希见 C96、C99；C105/C106 只使用恢复用户态代码。 |
| 排除网络、DNS、支持请求、GUI、`StoredVerify`、`final_status` | `VERIFIED`（研究入口范围） | C99、C105 的 harness 不启动外壳、不联网、不加载授权；这些逻辑仅保留为入口排除证据。 |
| 从原生入口建立调用图和数据流 | `PARTIAL` | C71–C75、C85 建立了 RC00/RC03 与 helper 的静态关系；自然 `-n/-m` 分发仍未闭合，见 C100/C107。 |
| 确认 `-n/-m` 进入的本地处理路径 | `MISSING` | parser/consumer 已定位，但没有到 `0x14078f250/0x14078f060` 的可验证自然调用边；C75/C107 只证明缺口。 |
| 确认 `RUN apply soft_success` 的真实调用链 | `MISSING` | 现有 C20–C63 是授权/阻断分支证据，不能替代核心调用链；当前没有把该文案/动作连接到解码函数的直接证据。 |
| 确认 RC00 后的本地入口和调用契约 | `PARTIAL` | C85、C90–C94 确认 0x10c→16-byte state→0x11c buffer→`DeviceIoControl` 包装；有效设备返回未取得。 |
| 确认 RC03 的返回值、失败和输出 | `PARTIAL` | C105/C106 原生与参考实现确认 `RC03`、`RC04`、`RC06` 分支和 `+0x80` 输出；输入为合成 response，真实设备产生条件未确认。 |
| 建立独立研究入口或 harness | `VERIFIED`（用户态 seam） | `core_local_decode_harness.py`、`core_response_validator_reference.py`、`core_predevice_reference.py`；入口不依赖外壳/网络/授权。 |
| 不修改解码算法本体，只替换前置条件 | `VERIFIED`（seam 实验） | C90–C94 的直接 caller seam 仅替换授权/合成通信前提；算法字节保持原始恢复 `.text`。 |
| 直接运行核心并观察输入→变换→输出 | `PARTIAL` | 原生 transform、state、validator 和响应后第二次 transform 已逐字节复现；真实 `DeviceIoControl` response 缺失。 |
| 观察文件、注册表、设备/驱动、进程副作用 | `PARTIAL` | 用户态成功分支的可见副作用是 caller `+0x80`；空句柄 seam 无设备输出；真实有效会话副作用未决。 |
| 划分用户态核心与驱动/辅助边界 | `PARTIAL` | C93/C94 已确认进入 `DeviceIoControl`/ntdll；C86/C87/C98/C103 证明目标驱动字节未取得，但不能解释其内部语义。 |
| 动态运行有阶段标志和短墙钟上限 | `VERIFIED` | 离线入口毫秒级；caller/API seam 约 8 秒；旧 20 秒探针明确记为未观测，未升级为成功。 |
| 交付核心调用图、函数说明、输入/变换/输出/副作用 | `PARTIAL` | 已在 C71–C108、`writeup/06-local-decoder-core.md` 和三个 harness 中交付；真实 response 生产端仍是空白。 |
| 交付驱动/缺失字节导致的真实未决项 | `VERIFIED` | C86–C88、C97–C103、C108 明确记录缺失目标驱动/辅助字节和真实 response，而没有用参考驱动替代。 |

## 当前可复现核心范围

```text
284-byte response-shaped input
    ├─ 0x14078db80  native validator
    ├─ marker == g340
    └─ 0x14078ce60  second 268-byte XOR transform
                         └─ caller structure +0x80
```

该入口已经是可复现的用户态响应后核心，但不是包含真实设备响应生产端的完整业务解码器。当前最强结论是：用户态存在独立本地解码动作；真实 response 的生产者、自然 `-n/-m` 路径和目标驱动/辅助字节仍未闭合。

## 继续工作的唯一高价值门槛

后续新增实验必须至少提供以下一种新信息：

1. 当前 genB 的有效 `DeviceIoControl` 会话及其 0x11c 返回 buffer；
2. 运行时分发表初始化和自然 `-n/-m` 到 caller seam 的实际命中；
3. 当前身份匹配的目标驱动/辅助组件字节。

否则不再重复外层脚本、TCP 等待、相同空句柄 seam、旧快照启动或当前 `.text` 的同类指针扫描。

