# LAYOUT — 本仓库的目录与书写规则（固定，勿再漂移）

一句话原则：**一个东西只有一个家；引用它的人用同一个路径说话。** 结构靠 `<HOST_PATH>\vmctl\layout_gate.py` 机器检查，不靠记忆。

```
<HOST_PATH>\EPT\                    ← 分析工作仓（原工作位置）
├── LAYOUT.md                  ← 本文件：规则本体
├── README.md                  ← 入口
├── RUN_MANIFEST_genB.md       ← 每一轮"做了什么/产出什么/环境状态"的即时台账（唯一按时间追加的文件）
├── REORG_MANIFEST.md          ← 结构整理时的 原路径→新路径 对照，可逐条回退
├── writeup/                   ← 交付正文，只放 .md：00-index + 01..05（分篇）
├── method/                    ← 项目路线、模板与证据约定；稳定流程由固定加载的两个 Skills 持有
├── archive/                   ← 冻结件：拆分前的单文件原件 EPT_V5.1_初步Writeup.md
├── sample/                    ← 分析目标本体 + 其解包树
├── unpack/                    ← 脱壳工作产物（upx3.py / build_clean_pe.py / ept_dump_base.bin / ept_clean.exe）
└── artifacts/
    ├── evidence/              ← 证据件：C<n>[_<字母>]_<主题>，全部 < 5 MB
    ├── captures/              ← 原始捕获物：内存窗口、Ghidra 重建对象、pcap、采集流
    ├── deprecated/            ← 已作废产物，必须配 README.md 说明"为何不可用、被谁取代"
    └── CHECKSUMS.sha256       ← 所有不入库大文件的身份凭证（sha256sum -c 可全量复核）
```

## 1. 归位规则（按"这是什么"判，不按"我在哪写的"）

| 你要放的东西 | 放这里 | 判据 |
|---|---|---|
| 一个结论的正文 | `writeup/0N-*.md` | 中文、分篇、带三态标注 |
| 一次可复跑的检查输出（表格/清单/反编译） | `artifacts/evidence/C<n>_*.txt\|tsv\|json\|c` | 必须 < 5 MB，且文件名以 `C<n>_` 开头 |
| 原始字节捕获（内存、抓包、镜像、重建 exe） | `artifacts/captures/` | ≥ 5 MB 或本身就是捕获物；不入库，进 `CHECKSUMS` |
| 被自己否证/被后续轮次推翻的产物 | `artifacts/deprecated/` | 必须在同目录 `README.md` 里写"作废原因 + 取代它的件号" |
| 一次性分析脚本（本项目专用） | `<HOST_PATH>\vmctl\` | 保持原位，**不复制进仓库**（见 §3） |
| 跨项目可复用的流程脚本 | 固定加载 Skill 的 `scripts/` | 只有被 Skill 引用的才算 |
| 分析目标与其解包树 | `sample/` | 只有这两类 |
| 拆分前的历史文档 | `archive/` | 冻结，只读，不再改写（见 §4） |

## 2. 命名规则

- **证据件号 = `C<序号>[_<小写字母>]_<主题>`**，序号只递增、**永不复用**；同一轮的第二件用后缀字母（`C36` / `C36b`）。
- 件号与**动态臂号**（RG2、C1…C7b、LEG1、TRAP1…）是两套名字，从 C6 起重合：`C6_*` 既是那一臂也是那批件。写文档时要么写 `臂 C6`，要么写 `件 C6_anchor_xrefs.tsv`，不许裸写 `C6`。
- 任何计数型断言的落盘件，必须自带**控制位**（"如果这项为 0，说明仪器死了而不是样本没做"）——这是本项目已经付过学费的规矩（SKILL §9）。
- 新增证据件时，同一条 commit 里把它登记进对应篇的**证据台账**（主张 → 件 → 复核动作 → 结论）
- **判定器/工具的固定输出名不算存证**：`judge_branch.py` 永远写同一个 `C39_branch_run_verdict.txt`，第二臂会把第一臂的判定**原地覆盖**。规则：一臂结束后若要再跑同型臂，先把这一臂的判定件与原始流按 `C<n>_<字母>_<臂号>…` 复制留存（今天实际发生：BR4 会覆盖 BR3，已另存为 `C39b_BR3_partial_verdict.txt` / `C39b_BR3_stream.txt`）。凡是"输出路径写死"的脚本都适用这一条，与臂号是否相同无关。
- **臂号（BR1、BR2…）只出现在 `<HOST_PATH>\vmctl` 的日志与流文件名里，不进入件号**；件号只标"这是第几件证据"，臂号只标"这是第几次开机"。一臂可以产出多件，多臂也可能只补同一件的空缺——写台账时以**件**为主键，以臂为出处。。

## 3. 脚本与"两份真相"禁令

分析脚本留在 `<HOST_PATH>\vmctl\`，仓库里**不放副本**。原因有过实锤：探针读的是未重建的旧副本，于是"改了没生效"是假的。要引用脚本就写绝对路径（`<HOST_PATH>\vmctl\pcap_census.py`），并在 `RUN_MANIFEST_genB.md` 的当轮条目里记它产出了哪些件。
例外：跨样本复用的流程工具进 `method/scripts/`（如 `diff-chain.py`）。

## 4. 冻结件

`archive/EPT_V5.1_初步Writeup.md` 是分篇前的原件，保留只为可追溯。**不改写它内部的旧路径与旧章节号**——里面裸写的 `§14.x`、`artifacts/mem/...` 描述的是拆分/整理当时的布局。新篇互指一律 `P4§3` 记法；引用原件时写明"旧 §14.x"。

## 5. 机器门禁（每次 commit 前自动跑）

```bash
python <HOST_PATH>/vmctl/layout_gate.py      # A. 引用是否失效  B. 文件是否放对目录、命名是否合规
```
已挂到 `.git/hooks/pre-commit`（本地钩子，不入库）。它检查：
- **STALE**：任何 .md/.py/.sh/.ps1 引用的 `artifacts|unpack|sample|archive|writeup|method/...` 路径必须存在；
- **ROOT**：顶层不得出现散文件；**SIZE**：`evidence/` 内 >5 MB 即报错；**KIND**：捕获物不得散进 `evidence/`；
- **NAME**：`evidence/` 内文件必须匹配 `C<n>_` 或在白名单（`genB_*`、`anchors_for_xref.tsv`、`RG2_region_strings_full.tsv`、`CHECKSUMS.sha256`）；
- **DOC**：`deprecated/` 里的每个文件都必须在 `deprecated/README.md` 里被说明。

要改规则就同时改本文件与 `layout_gate.py`，并在同一 commit 里说明理由——规则只写在人能读的地方 = 没有规则。

## 6. 大文件与可回退性

- 不入库：样本 exe、解包树、内存镜像、pcap、Ghidra 重建对象。它们的**哈希**入 `artifacts/CHECKSUMS.sha256`。**清单在 `artifacts/` 里，但路径是仓库根相对的** ⇒ 复核必须在根目录跑：`cd <HOST_PATH>/EPT && sha256sum -c artifacts/CHECKSUMS.sha256`（**2026-09-20 05:18 实测 21 条全 OK、无 FAILED**；条数用 `grep -vc '^#' artifacts/CHECKSUMS.sha256` 现算，别照抄本文或正文里任何历史条数——旧版这里写"40/40"是结构整理前的清单，已作废）。在 `artifacts/` 里直接 `sha256sum -c CHECKSUMS.sha256` 会报 39 条"No such file"——那是 cwd 错，不是文件丢（本夜实测踩过，写死在这里免得下一个人再把它读成"证据没了"）。每次移动或改结构后都要重新生成清单，并用上面那条命令复核。
- **清单的覆盖范围是一条需要显式声明的规则**（否则会误以为"没列出的大文件=丢了"）：登记**顶层产物**（样本 exe、`unpack/` 的重建对象、`captures/` 的区段与 pcap、`<HOST_PATH>/vmctl/out/` 的投放件）；**`*_extracted/` 解包树的 731 个文件不逐一登记**——它们由 `sample/*.exe` 的哈希经 `pyinstxtractor_ng` 传递性决定，登记父件即可。新增大文件时：若是父件派生物，只登父件；若是独立采证产物（新内存区段、新抓包），必须单独登记。
- 结构性移动一律先提交"移动前快照"，再用脚本产出 `REORG_MANIFEST.md` 式的 原→新 对照；禁止无对照的手工 `mv`。
- 文档完整性由 `layout_gate.py` 机器检查，覆盖 `writeup/*.md`、`method/*.md`、`RUN_MANIFEST_genB.md`、`LAYOUT.md`：`TABLE`（列数一致）、`REF/VMC`（引用与整理前路径）、`SHRINK`（比上次提交小一半 ⇒ 疑似截断）、`ENC`（不是合法 UTF-8）、`CTRL`（正文里出现 C0 控制字节就报错，制表与换行除外。起因：脚本用非 raw 字符串写 Windows 路径时，“反斜杠 + v” 两个字符被 Python 解释成一个垂直制表符；文档里留下的那个字节肉眼看不出来，读起来却仍像一条正常路径）。`LEDGER`（机器可读台账 `evidence/C54_*.csv`：必须存在、表头就是那 10 个列名、每行 10 列且字段非空、`status ∈ {open, closed}`、`failure_id` 唯一且形如 `I-<n>`、不得只有表头。起因：`I-22` 里一个没加引号的 `open(p,'w',newline=...)` 把该行切成 12 列，`csv.DictReader` 于是把它之后每一列都错位报出——`status` 被读成了 `affected_sections`，而这类错位**不会**抛错）。每条规则都跑过负对照（注入 → 报错 → 还原 → 干净）。
- 本仓库不用 `--amend` 已共享的提交、不 `push`；git 身份一律 `-c user.name=... -c user.email=...` 临时传入，不写任何 git config。

## 7. 环境侧不变式（与文件结构同级）

靶机 `<OTHER_VM_LABEL>` 的快照树（**2026-09-23 02:00 起 16 个节点**；2026-09-20 曾为 15 个，其后实验增长到 48 个，C155 治理删除了 32 个死端分支快照，详见 `artifacts/evidence/C155_disk_governance_20260923.md`）、`qoder-armed-20260919`（边界条款点名的可回滚点）、V5.0 对照样本、`<HOST_PATH>\CTF\_reference\` 下的前人材料——**都不得销毁**。实验盘只读挂载不写；宿主级不可逆变更先报告确认。

- 新增的 `qoder-clean-20260920`（`ec1a5369-26a4-43e3-a09a-aea591461edf`）由 `arm11.sh` 在**客户机侧健康双读 + 宿主可见 `NAT: Link up`** 之后冻结，是各臂当前使用的回滚点；它是**追加**，不是替换——`qoder-armed-20260919` 仍在树上。改这条要连同 `arm10.sh` 的第 4 参、`arm12.sh`/`arm13.sh` 的 `SNAP` 默认值一起改，并把 `C46` 重跑一遍（基线延迟是按会话量的，换基线要重量）。
- **臂的顺序不变式**：`poweroff → restore → startvm`（不得制造冷启动）；**先收割证据、后回滚**（`arm12/arm13` 的存在理由）；任何臂的"闸门失败"路径**不得**顺手回滚掉还能救的证据。
