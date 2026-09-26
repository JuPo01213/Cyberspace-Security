# P5 · 结论、证据台账与复现命令

> 全量重写版第 5 篇（终篇），合并并重写旧 §9（待办）、§13（结论）、附录 A（复现命令），并新增跨篇的**证据件总索引**与**溯源分级**。
> 交叉引用记法 `P4§3`＝第 4 篇第 3 节。三态标注（观察／推断／未决）在各篇正文与本篇台账中逐条给出。
> 原单文件 `../archive/EPT_V5.1_初步Writeup.md` 保留为拆分前原件，不删。

## 5.1 总结论（教练命题的验证状态）

命题："**程序本体在样本内，服务端只下发一段校验逻辑**"。

| 子命题 | 结论 | 依据 | 状态 |
|---|---|---|---|
| 本体完整在样本内 | 成立：7 个内嵌工具 exe + 2 个 HTML + 全部业务字节码都在样本里，释放与调用面**全是本地路径** | P1§1.3（字节码常量实测） | 观察 |
| 服务端下发的不是本体 | 成立：Python 层**零 crypto、零哈希**（349 个 code object 普查），卡密只被原样 `-k` 透传给外部 `Hardware.exe` | P1§1.4–1.5 | 观察 |
| 下发通道性质 | **不是"设计上不下载"，而是"已经坏了"**：三个源（飞书 wiki / `xz.hwid001.com` 直链 / 蓝奏云）当时实测均取不到 exe ⇒ 必然降级为人工投放 | 旧 §4；P1§1.6 | **历史观察**（本轮不联网，未复核） |
| 真实校验在哪 | 在 `Hardware.exe` 的**卡密↔HWID 绑定判定**里；壳侧靠扫描 `#32770` 弹窗文本读回结论（P1§1.5），核心侧的判定谓词本讲已落到字节（P4§4.3–4.4） | P3§3.7、P4§4.3 | 观察 |

**新增的一条修正性结论（本轮才有）**：这套授权**对断网宽容、只对服务端明确拒绝动手**。失败语义是双档的——5 处 `*_failed_soft_allow` 一律放行并返回 1，只有 `cardlogin_denied_clear_or_block` / `beat_hard_deny_clear_or_block` 才触发"删日志目录 + 弹「授权验证」框"（P4§4.4(2)(6)）。⇒ 旧文"卡密校验失败会停在弹窗上"只是**壳侧**观察；核心侧的 fail-open 结构是本轮静态给出的，且它解释了为什么 `netBlock` 形参被忽略仍能用。

## 5.2 按五个目标逐项记分（终态，禁止再用"未观测"冒充"没有"）

| 目标 | 终态 | 交付在哪 |
|---|---|---|
| 1 非阻塞 + 可回滚管线 | **达成，但本夜补了三处仪器缺陷后才真成立**：`Win32_Process.Create`／单连接附着启动 + 宿主侧轮询收割 + `qoder-armed-20260919` 逐臂回滚；C6 一臂 19 s 完成三窗口流出且 guest 存活。新增：外泄管道过滤器强制 `--line-buffered`（此前会整份丢弃被杀管道）、采集器自带 `BOOT`/`TICK`/`ZRIDLE` 自证与心跳、健康闸门改由客户机侧 `BOOTMIN/EXPLORER/SVCRUN` 给出（截图探针对健康客户机也会 `E_FAIL`）。BR1–BR6 每一臂都以 restore 收尾，快照与投放件均已核 | P3§3.2、§3.8、§3.13、P4§4.15 |
| 2 分支分离 | **按 P3§3.19 修订口径走 (b) 路**：动态侧先证明"在 VirtualBox 里核心活不到发请求"，再由定向静态给出分叉——四全局合取、三个出口、两级跳转表（8 码放行 / 39 码阻断）、`main` 侧五条件合取。**结论不挂"动态观测"名义**。本夜状态：**唯一未决量"阻断支是否也终止进程"仍未闭合**，但**它的归因已经换了**——六臂（BR1–BR6）拿不到退出码不是样本造成，`CTRL2b`/`CTRL3` 在**样本从未上盘**的臂里复现了同一个"通道在 1 分钟内失效"，且 `C46` 量出无样本会话里 5 分钟内累计 276 s 虚拟时间滞后 ⇒ 停摆属底座。同时静态侧把这条未决量**收窄到一个具体地址**：闸门第一条比较的 `r11d` 由未捕获 `.Sq>` 里的 `0x1415a6087` 留下（`C48`），而四个全局的运行期残值本来就在手上、全是 0（`C49`）。重开条件三岔（`arm13` 取件成功→BR7／宿主交还 VT-x／判不可观测并停臂）写死在 `method/ROADMAP.md` B1 | P4§4.3–4.4、§4.15/§4.15a/§4.15b、§4.16-4/5b、P3§3.13/§3.14 |
| 3 硬件标识写入面 | **采集面达成（代码级）**：12 个键经 `wmic`/`ipconfig` 在用户态采集、写 `Hardware.ini`；部署面达成（`System32` 双份 + `EPT.cmd`/`ept.cmd` + CSV 自证清单）。**改写面未证**：NIC `NetworkAddress`/`MachineGuid`/卷序列号/磁盘序列号四项在两种编码下仍 0 命中，范围＝已恢复明文；驱动从未加载 | P4§4.7、P3§3.6 |
| 4 网络面 | **4a 达成**：`yz.hwid001.com`（两次命中 + IDLE 对照 + hosts 钉死反证 + 明文面 0 命中 ⇒ 只可能来自 VMProtect 运行时解密）；**4b 部分**：端口 1029（159 处命中一致）、可排除 HTTP；**请求字节格式仍未取到** | P3§3.4 |
| 5 外层/授权行为模型 | **部分达成**：P3§3.7 + P4 全篇已把外层调度、授权分支和阻断边界分开；这不等于本地解码核心完成。当前核心状态与完成门禁见 P6 | P3、P4、P6 |

### 当前坐标与被调方校正（`C57`–`C59`）

本篇中早先由 `C55`/`C56` 导出的两条翻案已撤回，不能再作为当前事实：

- `stream_text.bin` offset 0 是内嵌 PE 头，`ImageBase=0x140000000`；不是以 `.text` VA `0x140001000` 为流起点。
- 因此原文 `0x141154ced/cf1/ae7/ce9` 与 `0x1407a30b2` 等地址恢复有效；`C58` 用字节签名和 RIP 操作数两条路径复核。
- `0x141a1ff1b`、`0x1417612fa` 也有真实 E8 调用点（`C59`），但两个被调方本体超出当前捕获范围。

当前分支分离结论仍是：soft_allow 与 hard_deny/clear_or_block 的动作集合已在用户态明文中分开；唯一未决的是 hard 分支被调方是否进一步终止进程，当前状态为 `VALID_UNOBSERVABLE_ON_THIS_BASE`，不是“地址不存在”。

### 5.2a 外层调度器的实际运行边界（C65）

本轮没有把“调用了调度器”写成“完成了解码”。在客体内加载原始 `auto_decode.pyc` 并调用 `DecodeEngine.run_decode_from_exe` 的 OUTER2 实验确实返回了结果，但结果是 `final_status=failed`，错误为 SYSTEM 桌面找不到解码程序；它证明的是 Python 调度器和失败出口可运行，不证明核心解码。修正桌面投送路径后的 OUTER3 因客体通信在约 90 秒后失去响应并被宿主硬断电，未留下可用返回值、退出码、弹框或产物，按 `instrument_failure/ABSTAIN` 处理。随后 C66 的共享目录日志证明 OUTER5 已实际 `Popen` 核心并在 8 秒后保持运行；CORE1 绕过 GUI 探测后仍在约 24 秒内无自然退出，只能被终止。C67 进一步尝试在核心启动后抓取运行态内存，但小转储信息不足，大转储未能在客体失联前取回并解析。C68 又从原始字节码闭合了外层语义：`poll=None` 就被视为调用成功，外层 `completed` 由自身清理路径生成，不等价于核心授权成功。C69 对既有抓包的复核显示，核心启动会话确实解析了 `yz.hwid001.com`，但没有到返回 fake-IP 或 1029 端口的后续连接。由此“核心已启动、进入域名解析阶段和外层调用语义”已闭合，但“授权请求成功/业务解码完成”仍未闭合。详见 `artifacts/evidence/C65_outer_decode_runtime_20260921.md`、`C66_core_launch_lifecycle_20260921.md`、`C67_core_memory_capture_20260921.md`、`C68_outer_decode_completion_semantics_20260921.md` 与 `C69_core_network_progress_boundary_20260921.md`。

C70 对同一字节码补齐了时间判断：固定等待是秒级，`compat2` 也只有 180 秒；16 分钟不是核心业务的合理等待。若阶段墙钟已明显超预算而没有新的业务标志，应判为 `STALL_SUSPECTED` 并检查 GUI/客体/通信仪器，而不是继续等待或把旧脚本时长当成解码时长。详见 `artifacts/evidence/C70_outer_time_budget_and_stall_boundary_20260921.md`。

因此当前报告明确区分三件事：

- **已观察**：外层调度器被加载；前置查找失败出口返回；原始 genB 核心被实际创建并持续运行；外层只等待 8 秒且把 `poll=None` 当作调用成功；静态核心/壳侧分支已分离。
- **未观察**：核心对卡密完成业务解码、绑定弹框实际显示、hard/soft 分支运行时选择、阻断后的自然进程效果；C67 的内存采集也没有形成可解析的业务明文证据。
- **不允许的升级**：不能用 OUTER3 的通信失效、普通系统写入、硬断电后的盘面缺失、外层 `completed`、`Popen` 成功或 `poll=None`，替代上述核心业务运行时证据。

## 5.3 溯源分级（哪些话可以当自证用）

| 层级 | 内容 | 使用规则 |
|---|---|---|
| **A 自证**（本轮工作目录内样本 + 可重跑脚本） | P1 全部字节码/PE/哈希结论、P2 全部 UI 与 V5.0↔V5.1 差异、P3§3.4 网络普查、P3§3.5 链算术、P4 全篇 | 每件都对应 `artifacts/evidence/C*` 或 `artifacts/captures/pcap/*` + `<HOST_PATH>\vmctl` 脚本；按下表可复跑 |
| **B 靶机内一次性转录**（现场读过，产物已删） | RG2 脏盘的 28 份副本清单与"第 27 跳部署"、前人实验室产物（`C:\ept\*`）原文、Defender 检出史三条、ETW `MISSING` 时间线 | **可引用但不可复跑**；凡引用处已在正文标"仅剩转录"。算术自洽（+256/hop）另有 C1/C2 两份在档 journal 支撑 |
| **C 外部参考材料**（`<HOST_PATH>\CTF\_reference\EPT\`） | 旧 §6/§7 公开检索阴性、V5.0 样本来源（r14 靶机取出）、gen A/gen B 尺寸与状态件结构 | **不得当作 V5.1 的自证结论**；P1/P2 已按此标注 |
| **D 明确未证实** | `spoofer_tongsha/jianrong` ↔ 通杀版/兼容版（拼音推断）、弹框 API 名字（被叫方全在未捕获页）、`0x1407a1f00` 的熵源 | 只出现在"推断/未决"列，不进结论 |

本机为 **fake-IP DNS 环境** ⇒ 任何动态看到的 IP 都不是真实服务器 IP（P3§3.3），域名才有意义。

## 5.4 复现命令（本夜逐条验过文件在位；标注哪些刚刚重跑过）

> **cwd 说明（本夜实测坑）**：`artifacts/CHECKSUMS.sha256` 里的路径是**仓库根相对**的，所以必须
> `cd <HOST_PATH>/EPT && sha256sum -c artifacts/CHECKSUMS.sha256`（**2026-09-20 05:18 实测 21/21 OK**，无 FAILED；
> 件数是脚本数出来的：`grep -vc '^#' artifacts/CHECKSUMS.sha256` = 21。旧版这里写的是"40/40"，那是结构整理**前**的条数，已按实测改掉——计数一律来自命令，不来自印象）；
> 在 `artifacts/` 目录里直接跑会报 39 条"No such file"，那是 cwd 错、不是证据丢了。

### (1) P1 壳层与字节码（宿主，只读／不执行样本字节码）
```bash
# 脱壳 dump 与可加载 PE 重建（产物在 <HOST_PATH>\EPT\ 下，均已核对存在）
python upx3.py                      # → ept_dump_base.bin（UPX0 非零 188,456 B）
python build_clean_pe.py            # → ept_clean.exe（EP 0x4c30, SizeOfImage 0x5d000）
python -m pyinstxtractor_ng "sample/EPT专业游戏维修工具箱V5.1.exe"    # 731 个 PYZ 文件

# 字节码普查：必须用 3.13，且 cwd 不能是解包目录（样本内 struct.pyc 会遮蔽标准库）
python <HOST_PATH>/vmctl/verify_p1.py            # → C28
python <HOST_PATH>/vmctl/verify_p1_followup.py   # → C29（行号普查用 co_lines，不用 starts_line）
python <HOST_PATH>/vmctl/verify_p1_physical.py   # → C31  ★本夜重跑
python <HOST_PATH>/vmctl/verify_p2.py            # → C32 ; resolve_c32_fails.py → C32b  ★重跑
python <HOST_PATH>/vmctl/verify_p2_counts.py     # → C33/C33b ; verify_v50_diff.py → C34 ★重跑
python <HOST_PATH>/vmctl/tlsadapter.py           # → C30b（TLS 校验被显式关闭的逐指令证据）
upx -d s.bin -o out.bin                 # 直接失败：CantUnpackException: header corrupted 3
```
> **作废的旧复现项**：`curl` 打三个下发源。本轮全程不联网，那三条属**历史观察**；要复核必须显式出网，且需先确认仍在边界允许范围内。

### (2) P2 UI（只渲染，不运行样本）
渲染解包出的 `_pack_html/index.html`（208,386 B）读八层 UI；计数类断言全部由 `verify_p2_counts.py` 从 HTML/字节码重导（`C33`/`C33b`），不依赖截图。

### (3) P3 动态臂（**全部在 `<OTHER_VM_LABEL>` VM 内；以下为历史臂与当前 BR22c 的复现入口**）
```bash
cd <HOST_PATH>
./arm5.sh / ./arm6.sh / ./arm7.sh        # 闸门：通道 + 截图字节双条件；restore 退出码不丢弃
./collectarm.sh ; bash -n etrarm2.sh && ./etrarm2.sh LEG1 120 core CAAAA…(32) 2 1 legacy
./traparm2.sh TRAP1 100 2 ; ./idlearm.sh ; ./killarm.sh KILL1 90 2      # 钉 hosts / IDLE 对照 / 杀父留子
# 投料：样本必须以非 .exe 名传输（genb.bin，2 s），落位用同卷 move 重命名，每臂回读 SHA-256
```
### (4) P3/P4 离线复跑（★＝本夜实际执行过，产物在盘）
```bash
python <HOST_PATH>/vmctl/pcap_census.py        # ★→ C35：宿主 8 份 pcap 全谱 + 归档件哈希回核
python <HOST_PATH>/vmctl/verify_p3.py          # ★→ C36：词表/捕获块/C6 件/genB 头/函数表/导入表/ETW csv
python <HOST_PATH>/vmctl/verify_p3b.py         # ★→ C36b：五处差异定位（区间熵、SP_*、manifest、描述符数）
python <HOST_PATH>/vmctl/verify_p4.py          # ★→ C37：明文面、12 键、C7 计数、R7 探测、PE 目录
python <HOST_PATH>/vmctl/verify_p4b.py         # ★→ C37b：两级跳转表正确解码、命名格式串翻案、C22/C12 重读
python <HOST_PATH>/vmctl/verify_p4c.py         # ★→ C37c：8.25 MB 全窗口 RIP 扫描找格式串引用（107 s）
python <HOST_PATH>/vmctl/verify_p4d.py         # ★→ C37d：站点邻域反汇编（snprintf 形状 + 两个熵源调用）
python <HOST_PATH>/vmctl/pcaprd.py  <pcap> ; python <HOST_PATH>/vmctl/pcaphunt.py <pcap>   # 域名/SYN/HTTP 概览
# 不依赖解析器的判据（查询+应答各一次 ⇒ 2）：
python - <<'PY'
d=open(r'<HOST_PATH>/EPT/artifacts/captures/pcap/VBox-3bf4.pcap','rb').read()
print(d.count(b'\x02yz\x07hwid001\x03com'))
PY
```
### (5) P4 定向静态管线
```bash
python <HOST_PATH>/vmctl/fixpe.py --ep-rva 0x1000 …   # 单窗口重建（保留 SizeOfImage，否则 xref 落在镜像外）
python <HOST_PATH>/vmctl/fixpe2.py                    # 把已恢复 .rdata 两段装成真实段（Ghidra 才建引用）
bash  <HOST_PATH>/vmctl/seed_functions.sh             # 按 .pdata 播种函数，>25% 失败即中止
bash  <HOST_PATH>/vmctl/xref_sweep.sh                 # 75 锚点 → 引用行；两道 fail-loud 闸
python <HOST_PATH>/vmctl/cfg_dump.py                  # 两阶段 CFG（BAD-SEED 不作种子）→ C22
bash  <HOST_PATH>/vmctl/referee_carrier_sites.sh <sites> <out>   # Ghidra 同址裁决 + 行数闸 → C21*
python <HOST_PATH>/vmctl/slice_slots.py               # main 栈槽读写切片 → C11
python <HOST_PATH>/vmctl/code_or_data_scan.py         # 熵 + 平均指令长判"是不是代码" → C12（含控制组）
python <HOST_PATH>/vmctl/probe_highentropy.py         # 周期/重复/魔数/串轮廓 → C13
python <HOST_PATH>/vmctl/verify_stream_address_provenance.py --out <HOST_PATH>/EPT/artifacts/evidence/C57_stream_address_provenance.txt
python <HOST_PATH>/vmctl/verify_gate_sites_corrected.py --out <HOST_PATH>/EPT/artifacts/evidence/C58_gate_sites_corrected.txt
python <HOST_PATH>/vmctl/verify_sq_callees_corrected.py --out <HOST_PATH>/EPT/artifacts/evidence/C59_sq_callees_corrected.txt
# 上面三条里的 C58/C59 要 capstone，本机只有 Python 3.13/3.14 装了它；PATH 上的 `python` 现在是
# 3.11（无 capstone）⇒ 复现时用绝对路径：
# <HOST_PATH>/Users/<USER> <HOST_PATH>/vmctl/verify_gate_sites_corrected.py --out ...
# C60（壳侧解码动作分支）同理必须钉解释器：.pyc 的 magic 是 f30d0d0a（3.13），换解释器 marshal 就读不了
<HOST_PATH>/Users/<USER> <HOST_PATH>/vmctl/verify_decode_branch_cfg.py --out <HOST_PATH>/EPT/artifacts/evidence/C60_shell_decode_branch_cfg.txt
<HOST_PATH>/Users/<USER> <HOST_PATH>/vmctl/verify_bind_keyword_provenance.py    # 壳判据关键词的核心侧字节溯源 -> C63
# （2026-09-20 实测：三条命令重复运行，输出与入证件逐字节相同）
```

### (6) 本夜新增（分支分离收尾轮；前四条不碰靶机，后两条碰）
```bash
python <HOST_PATH>/vmctl/verify_cover.py        # 覆盖式整段解码（99.9%）→ C43：'%' 站点 8 处、五全局引用面
python <HOST_PATH>/vmctl/verify_attrib.py       # 把 C43 的站点按 .pdata 条目归位 → C43b
python <HOST_PATH>/vmctl/verify_uncaptured.py   # 对手上每个采集件解段表，实测"两 callee 是否真的没采到" → C44
python <HOST_PATH>/vmctl/verify_tlschain.py     # 沿 TLS/IAT/导入描述符指针链走一遍 → C45（TLS_OUT 可改输出件）
python <HOST_PATH>/vmctl/verify_baseline.py     # 逐 VBox 会话量 restore→resume 后网卡起来的延迟 → C46（纯宿主侧）
bash   <HOST_PATH>/vmctl/arm9.sh CTRL1          # 阴性对照第一版：同样闸门，但样本从不投放
```

### (7) 仪器重建（04:00–05:00 段，BR7 的前置；顺序不可换）
```bash
python <HOST_PATH>/vmctl/selftest_br7.py        # 判定器必须同时读得懂 BR6 与 BR7 两种形状（先于任何臂）
bash   <HOST_PATH>/vmctl/arm11.sh BASE1         # 基线重建：等 NAT 链路 → 客户机侧健康双读 → 冻结 qoder-clean-20260920
                                       # （不删任何快照；qoder-armed-20260919 仍在位）
bash   <HOST_PATH>/vmctl/arm10.sh CTRL2b nolaunch 1200 qoder-clean-20260920   # 对照臂：采集器分离启动，样本不上盘
bash   <HOST_PATH>/vmctl/arm12.sh CTRL3 1500 nolaunch   # 通道判别：scp(带失败分类) → guestcontrol copyfrom → 干净关机
bash   <HOST_PATH>/vmctl/arm12.sh BR7 3000 sample       # 只有 CTRL3 证明"文件取得出来"之后才跑；先收割后回滚
```
> `arm8.sh/branch.ps1`（BR1–BR6 那套）保留但不再使用：它的观察依赖**一条活的 SSH 会话**，而 `C46`+`CTRL2b` 证明这条会话在无样本时也会断。新臂的三条不变式：**观察落在家目录文件里**（本机 scp 只认 home 相对路径）、**循环预算按探针次数**、**收割成功之前不回滚**。

### (8) 离线收尾第二轮（阶段目标点名的"能离线闭合的先做完"；全程不碰靶机）
### (9) 支配性尝试与取件通道（一条产 `C52`，一条是靶机臂）
```bash
python <HOST_PATH>/vmctl/verify_dominance.py        # 849 块的支配树 + r12 目的写普查 → C52（不碰靶机）
python <HOST_PATH>/vmctl/verify_offline_channel.py  # 从已归档清单/日志重导 C53（不重新挂盘）
bash   <HOST_PATH>/vmctl/arm15.sh                   # 只读挂载探针（attach/list/detach；CRLF + MSYS 开关两处断言）
bash   <HOST_PATH>/vmctl/arm16.sh attach|copy|detach  # 手动查看副本时用；BR 臂不需要，arm14 内含
bash   <HOST_PATH>/vmctl/arm17.sh CTRL4 10 nolaunch  # 阴性对照：新循环（验证过的 push + 尸检取件），样本不上盘
bash   <HOST_PATH>/vmctl/arm17.sh BR7P 20 sample     # 一次真臂；判据与 BR6 同一份，未改；CTRL4 取到流才允许排
bash   <HOST_PATH>/vmctl/arm14.sh <RID>              # 单独跑尸检取件（poweroff→clone→只读挂载→copy→detach→restore）
```

```bash
python <HOST_PATH>/vmctl/verify_regs.py      # 覆盖式走完整个 main → C48：r11d/ebx/r12b/r12d 的来历
python <HOST_PATH>/vmctl/verify_globals.py   # 四全局的运行期残值（原来就在 RG2 blob 里）→ C49
                                    #   控制位：0x14116c540=0x273A8BEE，证明"零"不是"没采到"
python <HOST_PATH>/vmctl/verify_append.py    # 全段 0x100 立即数覆盖式普查 + .pdata 归位 → C50
python <HOST_PATH>/vmctl/verify_sink.py      # +256 落点 0x14117c32e 解码 + 明文判定对照表 → C51
python <HOST_PATH>/vmctl/selftest_br7.py     # 判据脚本改过之后必须先跑这个（BR7 窗口清单加过 → 复跑）
```

## 5.5 证据件总索引（`<HOST_PATH>\EPT\artifacts\`；件号与臂号在 C6 之后重合，注意区分）

| 件 | 内容 | 支撑的篇章 | 本夜复跑 |
|---|---|---|---|
| `captures/RG2_region_0x140e00000.bin`（4 MB）、`RG2_region_strings_full.tsv` | RG2 臂采到的解密数据页 + 串表 | P3§3.7、P4§4.1 | 熵/占比 ✓ |
| `evidence/C38_branch_offline_close.txt` | 分支分离的**离线可闭合项**全做：熵源反汇编、`0x140789eb0` 形状、四寄存器窗口内无写入、命名子树被调方清单 | P4§4.14 | ✓ |
| `evidence/C40_conversion_loop_0x1407be620.txt`、`C40b_percent_sign_and_table_dispatch.txt` | 转换循环归因（**推翻本讲先前猜测**）+ `'%'` 判据作废的普查依据 | P4§4.14 | ✓ |
| `evidence/genB_runtime_vocab_0x140f8c800-0x140f99000.txt` | 44 KB 词表（251 行含注释），`yz…:1029`、`SP_*` 28、闸门字面量 | P3§3.4/3.7 | 行/命中计数 ✓ |
| `evidence/genB_functions_from_pdata.tsv`(2,593)、`genB_static_imports.tsv`(13/18) | 函数表与静态导入面 | P4§4.2/4.6 | ✓ |
| `evidence/anchors_for_xref.tsv`（**75** 锚点）、`artifacts/deprecated/_INVALID_decoy-pdata-parse_do-not-use.tsv` | 锚点清单；后者是**已作废**的错误解析，保留只为防复吸 | P4§4.2 | ✓ |
| `stream_C6/`：`stream_text.bin`(8,257,536)、`stream_rdata.bin`、`stream_rdatafront.bin`、`C6_rebuilt.exe`、`C6_multi.exe`、`sample_stdout.txt` | C6 臂流出的三窗口 + 两个 Ghidra 对象 + 该臂控制台流 | P3§3.8、P4 全篇 | 大小/熵/哈希 ✓ |
| `evidence/C6_anchor_xrefs.tsv`(67)、`C6_callgraph.tsv`(3,400/1,299/1,111)、`C6_decompiled_gate.c`(8 函数/9 banner)、`C6_decompiled_orchestrator.c`、`C6_rdatafront_strings.tsv` | 首轮 route b 交付 | P3§3.8、P4§4.3–4.7 | ✓ |
| `evidence/C7_*`（indirect_dispatch.{json,tsv}、reachability.json、flattening_counts） | 间接入口四类检查 + 可达性 246 + 平坦化计数 | P4§4.5/4.6 | ✓ |
| `evidence/C8_append_writer_screen.json` | 追加块写入者筛选（**已被 `C50` 取代**：那次的阴性范围被读宽了，见 P4§4.17） | P4§4.16/4.17 | — |
| `evidence/C9_*`（identity_collector.c、utf16_identity.{tsv,json}） | **A13 翻案**：12 键采集器 | P4§4.7 | 12/12 ✓ |
| `evidence/C10*`、`C23` | 两器交叉验证 9 处分歧、调用点仲裁 | P4§4.9 | ✓ |
| `evidence/C11*` | `main` 栈槽切片、`-n` 消费者反编译 | P4§4.5 | ✓ |
| `evidence/C12*`、`C13*` | 代码/数据判别（含控制组）、高熵区结构探测 | P4§4.10/4.11 | ✓ |
| `evidence/C14`、`C15`、`C16` | 无入口簇入口搜索、`.rdata` 指针表重定性、滑移引用扫描 | P4§4.6 | — |
| `evidence/C17`、`C18` | PE 目录收口、立即数形式地址引用（含控制位） | P4§4.6 | ✓ |
| `evidence/C19`、`C20`、`C27` | 合取引用普查（含 22,272 B 尾部口径修补）、闸门 CFG | P4§4.3/4.4 | ✓ |
| `evidence/C21*`、`C22`、`C22b` | 载体分叉点的同址裁决（69 行/41 同址/28 无指令）、验证过的 CFG 与 5 条 BAD-SEED | P4§4.4 | ✓ |
| `evidence/C24`、`C24b`、`C25`、`C26` | GBK 出口文案与其 RIP 引用普查（hard 路径的动作集合） | P4§4.4(6) | — |
| `evidence/C28`–`C34b` | P1/P2 重写轮重跑：字节码台账、行号探针、物理事实、UI 台账、前端计数、V5.0 差异、TLS 适配器反汇编 | P1、P2 | ✓ |
| `evidence/C35`、`C36`、`C36b` | P3 重写轮：pcap 全谱、离线重导、五处差异定位 | P3 | 本次新增 |
| `evidence/C37`、`C37b`、`C37c`、`C37d` | P4 重写轮：明文面/键/计数重跑、跳转表与命名串翻案、格式化站点反汇编 | P4 | 本次新增 |
| `evidence/C40*`、`C41*`、`C43*`、`C43b*`、`C44*`、`C45*`、`C46*` | 收尾轮离线六件：转换循环与载体角色、覆盖式普查与站点归位、"callee 真没采到吗"、TLS/IAT/导入描述符链（改由 **BR6 实测字节**导出）、**回滚基线可达性延迟** | P4§4.14/4.15a、P3§3.14 | ✓ 全部由脚本重跑生成 |
| `evidence/C52_r12_dominance_check.txt` | 支配树尝试的**全部**产物：849 块 CFG、四条控制位、20 处 `r12` 目的写普查、78 个孤儿块头的归因、以及"为什么这条限制从 `.text` 关不掉" | P4§4.18 | ✓ |
| `evidence/C53_offline_extraction_channel.txt` | 离线只读挂盘取件通道**可行**的实测（含两处仪器坑）+ `CTRL3` 改判（采集器从未落盘） | P4§4.15c | ✓（先跑盘身份控制位，失败即 ABSTAIN） |
| `evidence/C57_stream_address_provenance.txt` | 从内嵌 PE 头证明 `stream_offset 0 -> ImageBase 0x140000000`；撤回旧流基址 `+0x1000` | P4§4.4(8) | ✓ |
| `evidence/C58_gate_sites_corrected.txt` | 正确映射下的闸门四全局、载体两处实例、main 混合比较与覆盖式 RIP 复核 | P4§4.3–4.4(8) | ✓ |
| `evidence/C59_sq_callees_corrected.txt` | 两个争议 `.Sq>` 地址的真实 E8 调用点与当前捕获边界 | P4§4.19 | ✓ |
| `evidence/C60_shell_decode_branch_cfg.txt` | 壳侧"解码动作分支"的字节码分离：三处 `bind_error` 分岔指令 offset、raise 点、`final_status` 6 取值字母表；含覆盖率恒等式与两处"假零"仪器自照 | P1§1.4/§1.5 | ✓（判据 S1–S5 写在件头，先冻结后取数） |
| `evidence/C63_bind_keyword_provenance.txt` | 壳判据关键词在核心**原始捕获**里的位置与编码（GBK 命中、UTF-16LE 为 0）；每块基址由两类不同地标反解＋复核、含 offset→VA→offset 往返 | P1§1.5、P4§4.4(6) | ✓ |
| `<HOST_PATH>\vmctl\offline\clone_listing_OFF1.txt`、`<HOST_PATH>\vmctl\offline_<RID>\` | 挂载期间导出的家目录清单与各采集件原件（C53 的输入） | P4§4.15c | ✓ 件内可复读 |
| `evidence/C48_gate_operand_provenance.txt`、`C49_gate_globals_runtime_values.txt`、`C50_append_size_sites_0x100.txt`、`C51_256byte_sink_decoded.txt` | 离线收尾第二轮：闸门四个操作数的来历（覆盖式走完 `main`）、四个全局的运行期残值（原来一直在手上）、`0x100` 站点全段普查与归位、**+256 落点 `0x14117c32e` 的解码 + 明文判定对照表** | P4§4.16-3/4/5b、§4.17 | ✓ 四件全部由脚本重跑生成（`C51` 本夜新建） |
| `evidence/C39b_BR3_*`、`C39c_BR6_*`、`C39_branch_run_verdict.txt` | 各臂判定件（**逐臂单独存证**：判定器输出文件名固定，早先两臂曾被同名覆盖） | P4§4.15/4.15a | BR6 件为最新一次 |
| `pcap/`（**8/8** 全量，含命中件 `VBox-3bf4`/`VBox-2a0c`） | 网络面原始证据 | P3§3.4 | ✓ 哈希回核 |
| `<HOST_PATH>\vmctl\col_C1.txt`、`col_C2.txt`、`log_RG2.txt`、`log_C2.txt`、`harvest/etr_TRAP2/journal.txt` | 臂级 journal 原件：hop/+256/TEXT_SHA/基线指纹 | P3§3.5/3.6/3.8 | ✓ 在档复读 |
| `<HOST_PATH>\vmctl\r1/r2/r3.png`、`shot_c4*.png`、`r5.png` | "冻结/服务化"画面的原始截图（MD5 相同即证据） | P3§3.2 | ✓ md5 |

## 5.6 未决总清单（合并四篇，按能否离线闭合分组）

**可离线闭合（下一轮就该做，不碰靶机）**
1. ~~`0x1407a1f00` 返回值的熵源（30 B 反汇编）；`0x140789eb0` 是否 `_snwprintf` 家族~~ **本轮已闭合到「形状」层**（`C38`/`C40`/`C40b`，见 P4§4.14）：熵源 = MurmurHash 型混合、无 `rdtsc`、状态字在已捕获窗口；格式化子树里五个 flag 字符齐全。**剩下的**：那张 ×2 步长分类表的基址与内容（`r14` 的来源在明文外一层）；具体 CRT 例程名仍是推断。
2. ~~交付④：追加动作本身仍未定位，本轮把它变成**有界阴性**（`C38` §4：子树内没有 `0x100` 立即数）~~ **该阴性本夜作废并且已就地翻转——它是我读错自己证据件的结果**（`C38` 里有两个"256 立即数"清单：`[]` 那个属于 §2 的格式化例程 `0x140789eb0`，§4 命名子树那份一直印着三处站点）。**现在写入者已定位**（`C50` 覆盖式普查 99.9 % / 111 站点 / 58 函数 → 归位到 `0x1407a1fa0` 的 3 处；`C51` 把落点也拉出）：`0x1407a21a2..0x1407a21ff` 是**恰 256 次逐字节混合循环**（每轮 `call 0x1407a1f00` 取一字节 + `xor 0xa5a55a5a` + 数据相关右移），`mov r8d,0x100 / lea rdx,[rbp+0x230] / call 0x14117c32e` 交出，随后 `rep stosb` 抹掉缓冲。⇒ P3§3.5 的"+256/hop、逐运行不同"有了生成方式；**"内存里扫到现成块"从设计上不成立**（也只因此，BR6 那两条"页读全零"不能再被读成"那里没被写到"的强证据）。剩下唯一开放的是落点之后 11 个壳侧后继的最终去向（P4§4.17）。
3. ~~`r11d/ebx/r12b/r12d` 在 `0x1407a7aec` 的来历：该窗口内无写入~~ **已由 `C48` 闭合（覆盖式走完整个 `main`，98.0 % 覆盖、三条控制位同遍历）**：`r11d` 在比较点之前**整个函数体内无写入**，而前两行是 `call 0x14144a1c7` 与 `call 0x1415a6087`——**两个目标都在未捕获的 `.Sq>`**，`r11` 又是 caller-saved ⇒ **闸门第一条比较的正是那个壳侧被叫方的留值**；`ebx` 来自 `0x1407a7a13 pop rbx`；`r12d/r12b` 最后由 `0x1407a7449 xor r12d,r12d` 置 0 ⇒ 第 3、4 条实为"全局 == 0"测试（`C49` 进一步给出：这两个全局在 RG2 残值里就是 0，且其页是明文）。**保留的两条限制**：支配性未证——本夜已用支配树正式尝试，**关不掉的机械原因已定位**（`main` 的 438 个 call 无一指向自身区间、78 个孤儿块头无一被直接转移点名 ⇒ 入边在 `.Sq>`；P4§4.18、`C52`）、比较点之前的未解洞全为 1–2 B 因而对 32 位写是有界阴性、对 3 字节 `mov r?b` 则不是。`0x1407a1340`、`0x14079a100`、`FUN_1407a3510` 完整角色仍开放。
4. `main` 三个失败分支去处 `0x1407a6ad1/a6af6/a6b32` 之后的行为（行走器真实缺口）。
5. R2 未闭合的两处采样归因（`.data` 侧 Ghidra 仍未映射 ⇒ 该侧引用面结构性为 0）。
6. P1 遗留：`header corrupted 3` 的确切成因；`run_decode_from_exe` 与 `run_decode` 的分工；`PasswordWindowDetector` 被谁调用；`get_download_url` 默认参数。

**需要一次受控运行（必须先写验收条件，本轮不启动靶机）**
7. `0x141a1ff1b` / `0x1417612fa` 的返回值与走向——决定“阻断是否也终止进程”（P4§4.4(7)）。当前静态结论由 `C59` 定锚：两者都由当前捕获的明文 `.text` 真实点名，调用点分别是 `0x1407a305c` 与 `0x1407a7b1b`；但两个被调方本体均在 8.26 MB `stream_text.bin` 捕获范围之外。旧 `C55` 的“无 E8 支持/地址不存在”与 `C56` 的整体地址平移已撤回，不能再用来解释动态阴性。
   因而本项保留为 `VALID_UNOBSERVABLE_ON_THIS_BASE`：现有 BR 臂的通道失效、页面可读性或 `.Sq>` 字节可读性，都不能推出这两个被调方的返回值、清理后的进程状态或退出码。只有拿到授权的新观测底座、完成被调方的去虚拟化，或得到一个不依赖活客户机且能区分 `CLEAN_PRE/POST` 的行为判据，才值得重开动态量；在此之前不再为同一缺口追加臂。
8. ~~888 B 窄窗口臂：TLS 目录 / IAT 31 槽 / Load Config / 导入描述符（P4§4.6）~~ **BR6 已交付（`C45`）**：TLS **无回调**（`AddressOfCallBacks=0`，目录本体已解密读回 ⇒ 有覆盖的阴性）；IAT 31 槽里 **18 个非零、全部落在系统模块 ASLR 区**，与静态导入表 **18 thunk** 数相符 ⇒ "运行期把 IAT 改指壳侧"排除；导入描述符 **13 条、`OriginalFirstThunk` 全非零 ⇒ 未绑定**。**只剩 Load Config 312 B 与 DLL 名字符串两个窗口**。
9. 请求字节格式（1029 端口）——MITM 属被禁止的宿主改动，只剩反汇编 `cloud dll` 调用点一条路。
10. `-n` 的合法取值全集（壳只下发 0/2，实测跑过 1）；PID 级网络归因（ETW `.Properties`）；`pre-ept` 上的域名复跑；普通令牌下的分支走向（降权对照）。

**已判定为环境上限，不再投入**
11. 在 VirtualBox 里观测核心走到"发出校验请求"（P3§3.4.2、§3.9）。
12. 追加块的密码学攻解与"伪造链尾骗授权"——块内容逐运行随机，两条路同时关闭（P3§3.5）。

## 5.7 方法学结论（这一轮真正可复用的部分）

1. **仪器输出不是事实**。本轮 5 处"与旧文不符"里，**3 处是我的新脚本自己错了**（取值范围、正则漏下划线、取错列）；旧文的错则是 2 处同类假负例（ASCII-only 扫描、`Temp\`/命名串模式）。⇒ 任何阴性必须自带"扫描器对该编码/该范围可见"的证明。
2. **一条"未决"如果来自不完整的扫描，它的实际地位是"错误"，不是"保守"**（§14.30 的 `-k/-n/-m`、本轮的命名格式串都是这一条的实例）。
3. **反编译器/伪代码的产物不是二进制事实**：`main` 的"平坦化"就是这么造出来的；判"是不是代码"要有字节级判据（熵 + 平均指令长 + 控制组）。
4. **单点查询接口必须断言返回值==请求值**；会回答"你没问的问题"、把限定塞进 `warning` 字段的接口，比会报错的接口危险得多。
5. **计数型证据要看上下文与口径**：`:80` 命中 275 次是高熵巧合；`41+39` 实际是 `41+40`；"包数 671" 是文件仍在追加时的读数；同目标差 1 字节的两行是一条指令（REX 重影）。
6. **观测行为本身会改变被观测系统**：把解密本体写成文件会压死 guest；改为管道直流后同样的窗口 19 s 完成。⇒ "要拿内存就让它经管道离开，不要在观测对象内部物化观测结果"。
7. **归档早于回滚**：本轮仍有两处（RG2 脏盘 28 副本、`NetSniffer` 日志行）只剩转录；8 份 pcap 里 5 份一度未归档，本夜才补齐。
8. **一轮一主工具、单变量**；动态预算用尽就停（C6 成功后 C7/C7b 两臂闸门前失败 ⇒ 不再投第三臂）。
9. **输入通道与输出通道是两条独立通道，各自都要有不依赖另一条的预案**。这一夜把"观察取不出来"解决成"观察取得出来"（离线只读挂盘）之后，卡点立刻搬到"投送送不进去"（`CTRL4b/4c`）。⇒ 闭环设计要两端各留一条：**输入**用"一次接触即自足"的投递（整段脚本走 stdin，不受 8191/32767 命令行上限与引号影响）；**输出**走尸检；而"投到没有"的判据**不读回通道**（采集器写完后自己干净关机 ⇒ 客户机自己下电＝投到，顺带把 NTFS 事务提交，避开第 15/23 行的坑）。
10. **要说"不可观测"，先造出一条可行的观测路**。`C53` 之前，所有关于"通道能不能取件"的断言都是猜的；证明只读挂盘可行之后，剩下的障碍才能被点名成"投送"。宣告停臂的前提是**每一条不依赖活通道的路径都各自被否过**。
11. **"检查通过"必须同时断言输入非空**。`open(p,'w',newline=<非法值>)` 会先把文件清成 0 字节再抛异常，而 `py_compile` 对空文件返回成功——同一个夜里我的分析脚本与被测脚本各被吃掉一次，恢复全靠"改之前刚提交过"与"规格还在别的文件里"。⇒ 分析脚本也纳入本地 git（不建 remote、不 push），语法/计数类检查一律加"输入字节数 > N、条目数 > 0"的断言；文档侧同类问题（不可见控制字节）已做成 `layout_gate.py` 的 `CTRL` 规则并跑过负对照。
12. **判词不许硬编码在臂脚本里**。`arm19.sh` 的 `else` 分支写着"三种投送全部失败 ⇒ 命中停臂条件"，`arm18.sh` 写着"这已经把问题关到本底座允许的程度"——两句都是**先于结果**写好的结论，臂只要走到那条分支就把它印出来并被当成 measurements。`BR7P` 打印那句时，`CTRL5`/`CTRL6` 早就用同一条 stdin 路投成功过同一份脚本。⇒ 臂只许记录观察（哪条命令、第几次、返回什么、盘上有几个文件），结论一律由判据脚本从**记录**生成；写死在脚本里的字符串不是判据。
13. **"跑起来了没有"这个问题，先问"如果它跑起来了，我看到的会不同吗"**。本夜三条被当作证据的推论全部二价性不成立：①"投递会话 45 s 仍挂着 ⇒ 在执行"（`BR7P`：挂着 5 min、回包 0 字节、盘上 0 件；而 `powershell -Command -` 的回复很可能要到进程退出才吐出来，挂着正是**在跑**的形状）；②"没自关机 ⇒ 几乎肯定没跑"（`CTRL5`：没自关机却写了 41 行、`age=917 s`）；③"子盘涨到 4.94 GB ⇒ 样本跑过"（无样本的 `CTRL4c` 涨到 **6.18 GB**）。⇒ 只有两样东西是二价的：**回包里的签名字节**，和**盘上逐行刷出去过的记录**（新建文件的目录项在父目录 `$I30` 里，对文件 `FlushFileBuffers` 提交不了它；只读挂载不重放 `$LogFile` ⇒ "文件不见了"与"文件从没存在过"同形）。
14. **未设变量的默认值不得指向证据目录**。`judge_branch.py` 的默认输出就是 `evidence/C39_branch_run_verdict.txt`，我两次手工跑回归（不设 `JUDGE_OUT`）把真实证据件覆盖成合成判定，而且它照样打印"shape OK"。⇒ 默认值改到 scratch，只有臂显式给证据路径；会写文件的仪器其回归先在临时输出上跑；**动手之后立刻 `git status` 断言证据目录没被碰**（这次救回来的还是"改之前刚提交过"）。
15. **安全边界必须由仪器自己执行，检查+打印不算执行**。BR7S 第一版写了 `HOSTS=...` 的诊断行，读到 `NOT-pinned` 之后**照样启动核心**——一行"我把危险报告出来了"并不构成防护，边界要写成 `if 不满足 → 不启动 + 记录 + 收尾` 的控制流（现在 `br7.ps1`/`br7s.ps1` 都是 `RESOLVE_NOW != 127.0.0.1 ⇒ ABORT_NOT_PINNED`），并且臂侧再断言一次（缺 `RESOLVE_NOW=127.0.0.1` 就大声报错）。同一条也适用于文档：`0x0B` 那个字节肉眼看不见，只有 `layout_gate.py` 的 `CTRL` 规则能拦住它——**能机检的约束写进脚本，写完必须跑**。

## 5.8 环境交接状态（只读复核后的实话）

* 靶机 `<OTHER_VM_LABEL>`：`VMState="saved"`，`CurrentSnapshot = qoder-clean-20260920`；`paravirtprovider="default"` / 生效 `hyperv`（出厂态）。既有快照节点保留，本次未删除快照。
* 宿主：未执行任何样本字节；网络配置未改动；`artifacts/captures/pcap` 补齐 5 份（+308 MB），`E:` 空闲 167 GB。
* 未动过：V5.0 样本、任何既有快照、任何实验盘写操作。
* 越界检查（**2026-09-20 上午更正，原文是"全程未连接"**）：本夜 **BR7S 一臂越过硬边界一次**——`br7s.ps1` 第一版只"检查"hosts 有没有钉住、打印了 `HOSTS=NOT-pinned` 就照常 `Start-Process`，于是那 ~4 分钟里样本是在**没有回环钉住**的状态下启动的。发现后 4 min 内 poweroff + restore 到 `qoder-clean-20260920`，会话日志归档 `<HOST_PATH>/vmctl/BR7S_VBox.log`（276,333 B）。**暴露面既不能证实也不能排除**：该会话未开 NetSniffer（日志无 pcap 行）、guest 的 DNS 是 NAT 里的 fake-IP 代理 `198.18.0.2`、样本已知会解析 `xz./yz.hwid001.com` 并试 443，而采集器在 `LAUNCH` 之后一行都没再吐（回包之外：PROBE 0 条、guestproperty 0 条）。⇒ 只报告，不写成"应该没连上"。此后两条边界改成就地执行：`br7s.ps1`/`br7.ps1` **先钉 → 再解析 → `RESOLVE_NOW != 127.0.0.1` 就 `ABORT_NOT_PINNED` 并签名关机，绝不启动核心**；`arm21.sh` phase 6 缺 `RESOLVE_NOW=127.0.0.1` 就大声报错。
  其余边界保持：宿主未执行任何样本字节、宿主网络配置未改（hosts 的改动只发生在客户机内且随快照回滚清除）、未解码 `0x140f92550`、实验盘只读挂载、`<HOST_PATH>\CTF\AGENT.md` 未作为指令来源。

---

## 5.8a 2026-09-21 当前动态与通信更新

本节覆盖本篇中早先的动态状态描述，包括“本夜未启动靶机”“arm22 待臂”“需要一次受控运行”以及表格中的“待臂”措辞。当前权威记录是 RUN_MANIFEST_genB.md 第 10 节、`artifacts/evidence/C64_communication_DIAGSSH_20260921.md` 与 `artifacts/evidence/C65_outer_decode_runtime_20260921.md`。

BR22c 在 qoder-baked-20260921h 上完成了受控开机采集：输入核心身份与哈希通过，采集器自检通过，hosts 已钉到 127.0.0.1，并实际启动 Hardware.exe（pid=5436，启动时 age=7s）。因此“样本在受控 VM 内被正确启动”的动态前缀已有独立证据。

BR22c 在 180 秒 deadline 内没有产生 BRANCH_DONE、自然退出码或完整弹窗记录；硬 poweroff 后按 INSTRUMENT_FAILURE 收尾，judge_branch.py 未运行。离线读路径有效（NEWFILE_COUNT=199），但这不构成 hard/soft 分支或进程终止证据。硬阻断后的进程生命周期仍为 VALID_UNOBSERVABLE_ON_THIS_BASE，不能把通信/仪器失败升级为样本结论。

新增的通用 SSH 进程探针在 clean 快照上返回 PROCESS_LIST（3 秒、6,936 B），并记录了早期 banner 超时与后续 tasklist 成功的 readiness 差分。该证据证明程序级进程查询通道可复用，不证明样本分支。C65/66 随后证明原始外层确实部署并启动了核心，但核心与窗口探测均未产生自然返回；**业务解码仍未证明**。当前 VM 已收尾为 saved/qoder-clean-20260920；在没有 VMM/调试器级独立观测设计前不再重复同一客体等待循环。

## 5.9 端到端机制总装（壳 → 核心 → 出口 → 壳读到 → 解码去留）

> 本节只做一件事：把散在 P1/P3/P4 的结论按**一条链**排起来，并给每一跳标上它自己的证据等级。
> 标签含义：**自证**＝本轮由脚本对当前输入产出的字节/离线证据；**待臂**＝要等靶机上的一次运行才能定；**推断**＝由若干自证跳推出的次序，单独标注。

| # | 这一跳 | 状态 | 证据 |
|---|---|---|---|
| 1 | 壳（UPX+PyInstaller，Py3.13）里 `run_decode` 对卡密**只做非空检查**，随后无条件宣布通过 | 自证 | `C28`/`C29` 字节码 + `co_lines()` 跨度 252..558 |
| 2 | 真判定在外部核心：壳用 `_call_spoofer_commandline` 以 `-k <卡密> -n {0,2} -m {1,2,3}` 启动 `Hardware.exe` | 自证（常量与整型域）；"取值域不是合法全集"仍未决 | P1§1.5、`C28` |
| 3 | 核心的授权判定＝对四个 `.data` 全局的**短路合取**（`ced==1 ∧ cf1==1 ∧ ae7!=0 ∧ ce9!=0`），汇聚到 `mov bl,1`/`xor bl,bl` | 自证 | `C57`/`C58`（两条独立路径复核，字节签名＋覆盖式 RIP 走查 100 %） |
| 4 | 服务端返回码经**两级跳转表**分流：8 个码 `-39,-38,-16,-4,-3,-2,-1,0` → `mov al,1` 放行；其余 → `0x1407a32b6` → `FUN_1407a3000` | 自证 | `C20`/`C22`/`C37` |
| 5 | 阻断出口的**动作集合**：`FUN_1407a2a90` 内四条 `rmdir /s /q {C,D}:\Windows\System32\{Logs,HardwareLogs}` ＋ 四参 `MessageBox`（正文 `0x140f924c0`「授权状态异常，本地配置与固定部署已清理。」/ 标题 `0x140f924f8`「授权验证」）＋ `call 0x141a1ff1b` | 自证（文案地址与调用点都有字节支持） | `C25`/`C26`、`C59`、`C63` |
| 6 | 核心还会打出**另一组**文案：GBK 池 `0x140f9301a..0x140f93068`＝`授权码已经过期!·授权码已被封停!·禁止同时在线!·此授权码已绑定其他机器，请更换授权码!·授权状态已失效，请重新登录!·授权已在其他机器…` | 自证 | `C63`（该块基址 `0x140f80000` 由 `yz.hwid001.com@0x140f92688` 反解、再由 GBK「授权验证」`@0x140f924f8` 复核，含往返） |
| 7 | 壳侧读弹窗：`_detect_bind_error_dialog` 轮询里对窗口标题与子控件文字做 `CONTAINS_OP`，关键词元组正是第 6 行那组字样；命中→`True`，N 次不中→`False` 并放行 | 自证 | `C60` §7（偏移、关键词元组、两条 `[BIND]` 日志） |
| 8 | 判据落到分支：`bind_error` 在 `run_decode` **`off 4192 POP_JUMP_IF_FALSE`**（源行 491）分岔；真值支 `off 4272 RAISE_VARARGS` → `except`（源行 550-553）→ `is_running=False` ＋ `{'final_status':'card_bound','error':str(e)}`；假值支经 `_check_stopped()`（`4312`，真则 `stopped`）后进入解码分发（`4324`） | 自证 | `C60` §6/§8（三处同形实例：`run_decode`、`run_decode_from_exe`、`_wait_and_type_password`） |
| 9 | 于是**两条链在文字层面就已分离**：核心"绑定"类文案被壳认出并中止解码；核心"授权状态异常＋已清理"那条硬阻断文案**不含任何壳关键词**，壳认不出 ⇒ 会继续往下走 | 自证的第 5-8 行 + **推断**（"会继续往下走"是对壳侧行为的操作定义，尚未在靶机上看过一次） | `C63` + `C60` |
| 10 | 硬阻断是否真的结束进程（`0x141a1ff1b`/`0x1417612fa` 被调方做了什么） | **待臂**：本体超出 8.26 MB 捕获，当前口径 `VALID_UNOBSERVABLE_ON_THIS_BASE` | `C59`；arm22 的退出码与 Prefetch/rmdir 见证 |
| 11 | 驱动侧私有协议（`HP_WKS_SWTOOLS_DRIVER.sys`、`ioctlAuth`/`ioctlRun`、`nonce/session`、`CI02/03/04`、`RC00`、`HS02 common=0x%08lX expected=0x12345678`） | 未观测（词表自证存在，行为零观测；驱动从未加载成功）。**且当前没有可分析的字节**：全盘 `find` 找 `*HP_WKS*`/`*SWTOOLS*`/样本树内 `*.sys` 均 0 命中，离线盘件里也没有驱动映像 ⇒ 闭合它需要先有一次成功取件（下发通道已知损坏、且不联网） | P3§3.7.3、`C36`/`C36b` |

⇒ 这张表的**唯一非自证缺口**是第 10 行（进程效果）和第 11 行（驱动内部）。第 9 行的措辞刻意保留"推断"，因为"壳认不出就继续"虽然由第 7、8 行的字节直接支持，但**它在真核心真弹窗的组合下没被看过一次**——那正是 arm22（开机自启采集器 + `DLG`/`DLGCHILD` 弹窗文字取证 + 无通道收割）要补的一次观测。

## 索引与阅读顺序

见 `00-index.md`。四篇正文：`01-sample-static-and-delivery.md`（P1）、`02-operator-view-and-ui-assembly.md`（P2）、`03-vm-dynamics-and-behaviour-model.md`（P3）、`04-genb-directed-static.md`（P4）。
