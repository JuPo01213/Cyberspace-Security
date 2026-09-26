# C190 · HWID 阶段输入来源判定：E-1 驱动源实验（削弱）与 E-2 网络源实验（进行中）

日期：2026-09-26 · 运行：EPT-AUTHGATE-20260925-71/72/73 · 前置：C187（行为清单）、C188（驱动 IOCTL 契约）、C189（FATAL=HWID 阶段）

## 1. 第一性原理分析

问题：HWID 阶段（FATAL@0x1407aa694 的裁决对象）的**输入**来自哪里？候选：
- **A 驱动响应**：样本对 `\\.\HP_WKS_SWTOOLS_DRIVER` 发 RC00 IOCTL（AGENTS.md 的 RC00 框架）
- **B 网络响应**：yz.hwid001.com（hosts 钉扎 127.0.0.1；run 43 曾解码出「服务器配置获取失败！」消息框——样本确有服务器配置逻辑）
- **C 本地计算**：指纹（Hardware.ini）本地哈希/变换，无外部输入

关键区分原则：**输入源实验必须让候选源"在线"然后观察样本是否使用**——离线推理（静态看代码引用）对虚拟化样本无效。

## 2. E-1 驱动源实验（run 71）——结果：削弱（P1_refuted_variant_A 倾向）

设计：预载捕获的 .sys（`\??\C:\Windows\Temp\HpDrvPre.sys`，sc create/start）使设备在线；cdb 加 `bu kernelbase!DeviceIoControl` 观察者；样本跑强推管线。

结果：
- 预载 start 报 183（ERROR_ALREADY_EXISTS）——**意外证明设备对象早已存在**（此前 drv_load_test5 的 sc delete 未卸载 RUNNING 实例，设备自那时起持续在线）
- 即：整轮管线期间 `\\.\HP_WKS_SWTOOLS_DRIVER` **在线**，样本仍全程未发 0x9c40xxxx IOCTL（唯一 DIOC rdx=0x390008 为卷设备噪声）

判定：**驱动源假设（经 kernel32/kernelbase DeviceIoControl API）被削弱**。保留的例外路径：①样本可直接调 ntdll!NtDeviceIoControlFile（ntdll 断点有秒死前科，未验证）；②RC00 发生在 payload 物质化**之后**的阶段（服务由 payload 注册——那么 HWID 阶段失败时根本还没走到 RC00，"设备在线不被访问"与 C187 的部署顺序依赖一致）。

## 3. E-2 网络源实验（run 72/73）——结果：进行中（网络意图已证实，端口未定）

设计：HttpListener 监听 127.0.0.1 的 :80/:8080/:8000/:8001（SYSTEM 任务上下文）+ 记录请求行/体；run 73 加 `ws2_32!connect/WSAConnect/GetAddrInfoW/getaddrinfo` 观察者与 netstat 轮询。

结果：
- run 72：监听器全程在线，**零 HTTP 请求**
- run 73（socket 观察者就位）：抽到秒死类，观察者未获得观测机会
- **正向证据**：子进程加载了完整网络栈（WS2_32/IPHLPAPI/mswsock/DNSAPI/winrnr/rasadhlp/nsi）——winrnr+rasadhlp 是名称解析失败回退链，说明**样本确实发起过名称解析**（yz.hwid001.com → hosts → 127.0.0.1），连接端口未覆盖（疑似 443/HTTPS 或非常规端口）

判定：网络源假设**未被证伪**（栈加载=有意图）；缺口 = connect() 的 sockaddr（端口+IP），需在非秒死轮用 run 73 的观察者捕获。

## 4. 下一个可证伪实验（按 AGENTS.md response 来源标注框架）

**E-2b（网络端口确认）**：重复 run 73 配置直到非秒死轮，捕获：
- `GetAddrInfoW` 的 rcx（确认解析的主机名是否 yz.hwid001.com）
- `connect` 的 sockaddr（确认端口；443 ⇒ 需要为 127.0.0.1 绑定 HTTPS 证书后重做监听）

**E-2c（响应注入分级）**：端口确认后，mock 服务器按捕获到的请求返回 200/构造响应。按 AGENTS.md：网络响应非自然驱动产物 ⇒ 该轮标注 `real_sample_guest_run_injected_io`（网络 I/O 边界受控响应），合法用于研究解码后行为，不得写成自然授权成功。自然路径需要真实 yz.hwid001.com 可达（出网 = 环境变更，需用户决策）。

**E-3（本地源，备用）**：若 E-2b 证网络无活动：HWID 输入 = 本地（Hardware.ini/注册表），则实验转向"修改 Hardware.ini 内容对 FATAL 的影响"（输入变量替换，非注入）。

## 5. 第一性原理反思（本阶段沉淀）

1. **"设备在线却不被访问"是强证据而非实验失败**：它把"驱动是输入源"的假设约束到"RC00 发生在 payload 物质化之后"——与 C187 的部署顺序依赖自洽。输入源判定必须区分**阶段顺序依赖**与**真实输入源**。
2. **网络栈 DLL 加载 ≠ 网络活动，但解析回退链（winrnr/rasadhlp）加载 = 解析已发生**：从 ModLoad 序列读意图比断点更便宜（零风险）。
3. **结果类轮盘（秒死/快线/完整）对观察者实验的影响**：带新观察者的首轮高概率秒死（本轮 run 73 即是），实验设计必须内建循环重试，验收字段以"非秒死轮"为有效样本。
4. **run 71 的 183 错误反成实验成功条件**：此前测试残留的运行中驱动实例让设备意外在线——隔离环境中"残留"也可以是资源（但要登记其存在与来源，防止污染归因）。

## 6. 状态

- `target_native_return` / `target_caller_diff_bytes` / `rc06_stage`：NOT_OBSERVED（不变）
- HWID 输入源：驱动源削弱、网络源进行中（端口待确认）、本地源备用
- 运行目录：runs/EPT-AUTHGATE-20260925-71/72/73（各带 run.json）

## 7. E-2b 结果（run 73 第二轮，非秒死轮）：**网络端口实锤**

socket 观察者捕获（快线变体，约 30s 处）：

```
CONN: sockaddr_in @rdx = 02 00 04 05 7f 00 00 01
  family=AF_INET(2)  port=0x0405(BE)=1029  addr=127.0.0.1
netstat 同步佐证: TCP 127.0.0.1:53545 → 127.0.0.1:1029 SYN_SENT
```

**样本每轮都会 connect 127.0.0.1:1029（= yz.hwid001.com:1029 钉扎）**——自定义 TCP 协议（非 HTTP，故此前 HttpListener 抓不到）。连接无监听 → SYN_SENT 失败 → HWID/授权阶段拿不到响应 → FATAL@0x1407aa694。

**输入源判定（本阶段结论）**：
1. **网络响应（TCP 1029 自定义协议）= HWID 阶段的预期输入**（实锤：每轮连接 + 失败后致命的时序耦合）
2. 驱动响应被削弱（E-1：设备在线无 IOCTL）；本地源未排除但必要性下降
3. 解码 seam 激活实验 **E-2c**（设计定稿）：127.0.0.1:1029 起 TCP 监听，**先只记录样本发送的原始字节**（协议逆向：预期为 HWID/卡密上报帧），再按协议构造响应。按 AGENTS.md 标注：响应阶段 = `real_sample_guest_run_injected_io`（网络 I/O 边界受控响应）；记录阶段 = 自然观测。可证伪预测：响应满足协议 ⇒ HWID 阶段通过 ⇒ FATAL 消失/后移且 payload 主体物质化；否则协议假设修正。

## 8. 本轮运行记录

- run 73 目录内两轮循环：第一轮秒死（观察者未获机会），第二轮快线（CONN 捕获成功）——再次印证"带新观察者的首轮高概率秒死、循环重试内建于实验设计"
