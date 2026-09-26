# 授权通过手段完整报告与补丁（authgate-force-v1）

日期：2026-09-26 · 适用：新会话接手 EPT 授权后分析 · 样本谱系见 §1
配套证据件：C184（强制链发现）、C185-C187（部署管线/行为清单）、C188-C202（驱动/协议/原语逆向）

---

## 1. 样本与谱系

- 权威原始样本：`<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe`（SHA-256 前缀 CA6B4C6A…）
- Guest 派生物：`C:\ept_core\Hardware.exe`（SHA-256 = CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7），源自 `<HOST_PATH>\EPT\artifacts\captures\hardware_guest_test.exe`
- 行为：安装器父进程 → 释放子进程 `C:\Windows\TEMP\EPT_XXXXXXXX_XXXXXXXX.exe`（~32MB，base 0x140000000，与父进程同映像）→ 授权/部署管线
- 隔离靶机：Hyper-V `<VM_LABEL>`（Win10 Pro 19045 zh-CN，Gen1，NIC 断开），基线检查点 **C173-gen1-ready2**（testsigning=Yes；注意：检查点内含历史 run 的 `System32\Hardware.exe/Hardware.ini/EPT.cmd` 残留——`Hardware.ini` 在该检查点中不存在，属正常）

## 2. 授权机制分析（样本怎么锁自己）

样本部署管线被四层门锁住（全部已在运行时定位并验证）：

### 2.1 入口闸门（授权全局变量，4 个）
- 地址：`0x141154ced` / `0x141154cf1`（dword）+ `0x141154ae7`（byte）+ `0x141154ce9`（dword）
- 作用：授权状态全局标志。不置 1 时管线在早期直接走失败分支
- 发现方式：C184 轮次中内存写入断点 + 值追踪

### 2.2 SDK 阶段校验函数（5 个，代码族返回零）
- 地址：`0x1403b34d0` / `0x1403b3280` / `0x1403c47e0` / `0x1403b3d30` / `0x1403c49d0`
- 作用：阶段校验函数，返回非零即阶段失败。补丁 `33 c0 c3`（xor eax,eax; ret）= 强制返回 0
- 附带：`0x14078ff03`（wrapper-1 码族强制，eax=0）与 `0x14078ff87`（wrapper-2 布尔族强制，ebx=1）为运行时硬件断点强制点

### 2.3 调度器二道闸（致命包装）
- 结构：`call 0x1407b1464`（判定函数）→ AL 决定继续或进致命包装 `0x1407c1d18` → thunk `0x14171f567`
- 强制方法：硬件断点 `ba e 1 1407b108f`（调用点，快照 rsp/rbx/rsi/rdi/r12-r15/rbp 至 $t0-$t8）+ 硬件断点 `ba e 1 14171f567`（thunk 入口，命中后**合成返回**：`r rsp=@$t0; …; r rip=1407b109b; r eax=1`）——把"致命"伪造成"校验通过继续"
- 该判定实际裁决对象：**HWID 阶段结果**（C189：致命路径泄漏明文标签 "HWID" @0x140f8e308）

### 2.4 直接退出路径（第二退出模式）
- 位置：虚拟化区 `0x143ae5d57` 直接 `call kernel32!ExitProcess`（不走 thunk）
- 拦截：`bu kernel32!ExitProcessImplementation`（注意：不能用裸名 `ExitProcess`——本地 PDB 缓存遮蔽导出名，详见 §6）+ 强制返回
- 该路径触发与否呈随机性（结果三分类，见 §5）

### 2.5 UI 链（需自动化点击）
- 窗口类：`NspFirstRunDisclaimerWindow`（免责声明）→ `NspSetupWindow`（主 Setup）
- 流程：「同意并继续」按钮 → KEY 编辑框输入卡密 → 「应用并启动」按钮
- 卡密值为占位（`1234567890`）：**网络授权从未通过**（yz.hwid001.com 钉扎 127.0.0.1），后续步骤靠 2.3 的合成返回续命

### 2.6 网络依赖
- `yz.hwid001.com:1029`（自定义 TCP 协议，非 HTTP）：连接每轮发生，响应缺失即 HWID 阶段失败
- 帧格式：`[u32 total_len=107][103B 密文体]`（C191）

## 3. 强制链逐项（对应 `cdb/authforce.cdb`）

| # | 命令 | 作用 |
|---|---|---|
| 1 | `ed 0x141154ced 1; ed 0x141154cf1 1; eb 0x141154ae7 1; ed 0x141154ce9 1` | 释放入口闸门 |
| 2 | `sxi av/c0000005/e06d7363/80000003/80000004/c000001d/c0000094/e0434352/6d9` | 异常穿透（壳的常规异常不被断） |
| 3 | `eb 0x1403b34d0/0x1403b3280/0x1403c47e0/0x1403b3d30/0x1403c49d0 33 c0 c3` | SDK 五阶段校验归零 |
| 4 | `bu user32!MessageBoxA/W` + `SoftModalMessageBox` | 消息框跳过（伪造返回继续，如「服务器配置获取失败！」） |
| 5 | `bu kernel32!ExitProcessImplementation` | 直接退出路径拦截（跳过） |
| 6 | `bu ws2_32!connect / kernelbase!DeviceIoControl / CreateFileW(kernel32+kernelbase 双层)` | 行为观测（详见 C188/C192：样本会绕 kernel32 直接走 kernelbase） |
| 7 | `ba e 1 14078ff87` | wrapper-2 布尔族强制=1 |
| 8 | `ba e 1 1407b108f` | 调度调用点上下文快照（合成返回的还原源） |
| 9 | `ba e 1 14171f567` | 致命 thunk 拦截 + 合成返回（eax=1 = 判定通过） |

**硬件断点只用 3 个 DR 槽**（ff87/108f/171f567）；第 4 槽空闲可给临时观测（如 mutator 0x1405d5f80）。
**注意**：硬件断点不写内存，壳的完整性扫描发现不了；软件断点（0xCC）在 image 内有被扫风险，在 kernel32/kernelbase 出口上经验证大部分可用，但 `.dump`、`k` 之外的动作要控制体积。

## 4. 配套基础设施

| 脚本 | 位置 | 作用 |
|---|---|---|
| `host/host_prep.ps1` | 宿主 | 清 spool → 禁 cdb 符号缓存 → 推送脚本 → canary 自检 → 注册 SYSTEM 计划任务启动 |
| `guest/guest_launch.ps1` | Guest | 钉 hosts → 起父进程 → 等子进程 → cdb 附加（`-p <pid> -cf authforce.cdb`）→ 起 winproc |
| `guest/winproc.ps1` | Guest | UI 自动化：枚举窗口 → 点「同意并继续」→ KEY 框写卡密 → 点「应用并启动」 |
| `guest/watcher.ps1` | Guest | 500ms 轮询 Temp 文件尺寸+即时捕获新文件（抓自清理的 .sys） |
| `host/wait_harvest.ps1` | 宿主 | 轮询等待进程自然结束（**必须等待，提前收割会截断运行**） |
| `host/host_harvest.ps1` | 宿主 | 杀 cdb → post_snapshot → 拉全部工件 |
| `host/monitor_run.ps1` | 宿主 | 轻量进度轮询 |
| `host/restore_now.ps1` | 宿主 | 检查点恢复+地面判据验证（spool 目录消失=真恢复） |

## 5. 使用方法

1. 恢复检查点：`restore_now.ps1`（必须验证输出含 `RESTORE_VERIFIED` 且 spool 目录消失——cmdlet 成功≠恢复发生）
2. `host_prep.ps1`（自动：禁符号缓存 → canary → watcher 自检 → 起任务）
3. 等待 3-6 分钟（进程自然结束，`wait_harvest.ps1` 轮询 procs=0）
4. `host_harvest.ps1` 收割全部工件
5. **结果三分类**（15+ 轮统计）：完整线（GUI+指纹+payload 尝试+FATAL）/ 快线（无 GUI 直达 FATAL）/ 秒死（管线前 ExitProcess）——比例约随机，**需要循环重试**，完整线出现率约 1/3
6. 每轮必查 `cdb.stdout` 中的标记计数（RECV/FATAL/CWEXA/CFW…）判定本轮类别

## 6. 已知问题与陷阱（全部实测踩坑，勿重蹈）

1. **cdb 本地符号缓存遮蔽导出名**：`Debuggers\x64\sym\` 内有 PDB 时 `bu kernel32!ExitProcess` 整行硬失败（PDB 名为 ExitProcessImplementation）。prep 已做"每轮重命名 sym 目录"处理；断点必须用验证过的形式（kernelbase!CreateProcessW 而非 kernel32! 裸名）
2. **断点动作串内的反斜杠路径**：`.dump/.writemem` 路径必须用正斜杠（`C:/ept_obs/...`），反斜杠会被吞并吞并后续命令
3. **`.writemem` 尺寸上限 ~100KB**：大块转储静默失败；全进程捕获用 `.dump /ma`（`/f` 用户态不支持）；路径同样正斜杠
4. **检查点恢复必须地面判据验证**：以"检查点之后创建的工件必须消失"为判据（cmdlet 成功≠恢复发生）
5. **变异流手工反汇编对齐陷阱**：从流中间对齐会产生假指令流——运行时区段分析一律从真实 rip 出发（`u poi(@rsp)`）或 Ghidra 载入运行时转储
6. **磁盘映像节是运行时解码的**：静态字节≠运行时字节——分析协议引擎必须用运行时转储（已捕获 `child_full_recv2.dmp` 107MB + `text_runtime.bin` 1.77MB）
7. **harvest 前必须等待进程自然结束**：提前杀 cdb 会截断运行（正在写的文件丢失）
8. **heredoc 内联写脚本会丢反斜杠层级**（`\10`→0x08、`\v`→0x0B）：脚本一律用文件写入工具+ParseFile 校验

## 7. 效果边界（诚实声明）

**能做到**：安装器全部预授权阶段强制推进；授权后自然行为已观测（指纹采集 11×wmic+ipconfig、Hardware.ini 落盘、HpDrv*.sys 驱动投放、AntiCheatExpert 伪装服务 config、EPT.cmd 重写、加密日志追加）。

**做不到 / 未发生**：
- **解码从未执行**（payload 主体全零——103B 帧体是服务端响应的解码输入，无真实服务器响应即无解码）
- FATAL@0x1407aa694 = HWID 阶段校验失败判定，强推只能续命不能让它通过
- `target_native_return` / `target_caller_diff_bytes` / `rc06_stage`：NOT_OBSERVED
- 解码后自然行为（R3.exe、`\Microsoft\Hardware` 计划任务、`System32\Logs`/`HardwareLogs`）：未观测

**两条推进路径**：①离线：mutator 链（5925 调用点已提取，`mutator_triples.json`）+ dmp 分析 → 重建 103B 帧编解码器；②需决策：放行 Guest 真实出网 yz.hwid001.com:1029 一次，抓真实协议交互。

## 8. 关键地址速查

| 地址 | 含义 |
|---|---|
| 0x141154ced/cf1/ae7/ce9 | 入口授权全局变量 |
| 0x1403b34d0 等 ×5 | SDK 阶段校验函数 |
| 0x14078ff03 / 0x14078ff87 | wrapper-1（码族归零）/ wrapper-2（布尔族置一）强制点 |
| 0x1407b108f / 0x1407b1464 | 调度器二道闸调用点 / 判定函数 |
| 0x14171f567 | 致命包装 thunk（HW 断点拦截点） |
| 0x1407b109b | 合成返回目标（eax=1=通过） |
| 0x143ae5d57 | 直接 ExitProcess 调用点（第二退出模式） |
| 0x1407aa694 | FATAL 决策点调用者（=HWID 阶段校验，运行时生成代码） |
| 0x1405d5f80 | 稀疏 XOR mutator 原语（5925 调用点，C201） |
| 0x140fa18f0 / 0x1402a18f0 / 0x1402a4588 | 加密派遣表基全局 |
| 0x140f8e308 | "HWID" 失败标签串 |

## 9. 证据件索引

C184 强制链发现 · C185 服务随机化 · C186 部署管线 · C187 行为清单 · C188 驱动 IOCTL 契约 · C189 FATAL=HWID 判定+驱动加载反转 · C190 输入源判定 · C191 帧捕获+echo · C192 recv 调用方捕获 · C193 事件图谱+派遣表 · C194 缓冲区生命周期 · C195 堆布局漂移 · C196 Ghidra 管线 · C197 .dump 修正 · C198 双挂点仪器 · C199 minidump 解析器 · C200 handler 枚举 · C201 mutator 原语解码 · C202 踪迹数据集

## 10. 补丁包内容与使用注意

```
patches/authgate-force-v1/
├── README.md                 ← 本报告
├── cdb/authforce.cdb         ← 强制链主脚本（§3 全表）
├── guest/guest_launch.ps1    ← 参数 -RunId（含驱动预载与 mock 监听启动，可选）
├── guest/winproc.ps1         ← UI 自动化
├── guest/tcp1029.ps1         ← 1029 端口协议监听（Respond: 0=仅记录 / 1=echo）
├── guest/watcher.ps1         ← 文件尺寸轮询 + 即时捕获
├── host/host_prep.ps1        ← 默认 RunId 需按新运行修改或用 -RunId 覆盖
├── host/wait_harvest.ps1     ← 等待进程自然结束（30s 轮询）
├── host/host_harvest.ps1     ← 收割（含 cdb 击杀，必须在进程结束后执行）
├── host/monitor_run.ps1      ← 轻量进度查询
├── host/restore_now.ps1      ← 检查点恢复 + 地面判据验证
└── guest/HpDrvPre.sys        ← 预载驱动（C188 契约的样本自投放驱动副本，SHA bf07c46e…）
```

- 驱动预载（HpDrvPre）为可选实验分支：guest_launch 中对应块失败不阻断运行（实测 error 183 仅登记）
- `host_prep.ps1` 的默认 RunId 请按新运行改名（sed 替换 EPT-AUTHGATE-20260925-82 → 新 ID）
- 全部脚本经 `Parser::ParseFile` 校验；反斜杠路径禁止在 heredoc 内联生成（C197 §8 教训）
