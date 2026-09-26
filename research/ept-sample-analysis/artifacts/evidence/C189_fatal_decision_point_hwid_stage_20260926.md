# C189 · FATAL@0x1407aa694 决策点 = HWID 阶段失败判定（运行中转储实证）

日期：2026-09-26 · 运行：EPT-AUTHGATE-20260925-69/70 · 证据：`runs/EPT-AUTHGATE-20260925-70/cdb.stdout.txt`、`fatal_region.bin`（12,288B=0x3000，VM 变异流原始字节）

## 1. 方法

FATAL_THUNK 硬件断点（0x14171f567）动作扩展：合成返回前先 `u 0x1407aa580 L28`（运行时反汇编决策点——attach 时该区域全零，运行时才生成）+ 转储决策点参数引用的固定字符串 + `.writemem` 全区转储（注意命令带点：`.writemem`；`writemem` 会解析失败使动作串中断）。

## 2. 实测结果（run 70，快线变体）

1. **0x1407aa580-0x1407aa694 为虚拟化/变异流**：常量展开（`movabs r11,0C51C6203BC00B308h; lea r11,[+48B05716h]; lea r11,[-54FDA5E3h]`）、VM push 序列（pushfq/push r11/r13/r15）、远跳 VM handler（0x418deba4/0x419cec7c/0x417f7808 等）。算法静态还原不可行（设计如此）。
2. **变异流末段泄漏真实调用**（穿透 VM 的观测点）：
   ```
   test ebx,ebx; je +0x54
   mov eax,[rsp+78h]; test eax,eax; je +0x3a
   lea r8,[0x140f8e308]      ← 固定地址字符串
   mov edx,64h               ← 长度 100
   mov rcx,[rsp+68h]         ← 上下文指针
   ```
3. **`da 0x140f8e308` → `"HWID"`**：致命路径的日志/处理消息标签明文为 **"HWID"**。即 0x1407aa694 处的失败判定属于 **HWID 阶段**——指纹采集→HWID 处理→解码→payload 填充链路的最后一个可观测失败点。
4. `fatal_region.bin`（0x1407aa000 起 0x3000 字节）已落盘，供 VM 字节码离线分析。

## 3. 与 C187/C188 的闭合

- C187 假设"7.9MB payload=解码输出（头 MZ+主体全零）"：本件证实最终失败在 HWID 阶段 → 指纹已采集（C187 §3.1-3.2）但 HWID 处理/解码产出为空 → payload 主体零填充 → FATAL。
- C188 驱动契约：HWID 处理的正常路径依赖 `\\.\HP_WKS_SWTOOLS_DRIVER` 的内核服务（端口/MSR/PCI/物理内存读写——改机执行机构）。隔离环境驱动未加载 + WHQL 2019 过期 ⇒ HWID 阶段无法完成。
- 三者合成完整因果链：**授权强推通过 → 指纹采集成功 → HWID 内核改写阶段失败（驱动缺失/签名过期）→ payload 主体为空 → FATAL@0x1407aa694**。

## 4. 下阶段优先级

1. 驱动加载实测：`sc create + StartService` 该 .sys，取签名拒绝码（验证 §3 的"过期证书"分支）。
2. fatal_region.bin VM 变异流离线分析（0x2437b697 常量、HWID 消息结构 100B 布局）。
3. 解码 seam 激活：HWID 阶段的正常输入源（驱动响应/网络响应）与 AGENTS.md 的 response 来源标注框架对齐。

## 5. 附录：驱动加载实测（2026-09-26，反转记录）

将捕获的 .sys 以 `\??\C:\Windows\Temp\HpDrvTestDrv.sys` 注册（sc create type= kernel）并 start，在 testsigning=Yes 的 Guest 上：

```
create=[SC] CreateService 成功
STATE : 4  RUNNING (KERNEL_DRIVER)
```

**驱动成功加载并运行——"WHQL 2019 过期阻断加载"假设证伪**（testsigning 豁免过期校验）。前两轮实测报"找不到文件(error 2)"均为宿主→Guest 文件复制静默失败所致（仪器问题，非样本行为）。

修正后的因果链：驱动本身**可**加载；样本 HWID 阶段失败不是驱动签名问题，而是**其部署顺序依赖 payload 物质化**（AntiCheatExpert 服务的 binPath 由 payload 注册）——payload 为空 ⇒ 服务未创建 ⇒ RC00 设备从未在线。下一步：解码 seam 激活研究（含"手动加载驱动 + 用户态合法探测 IOCTL"的合约研究路径，标注为 contract_research，不计入目标级完成）。
