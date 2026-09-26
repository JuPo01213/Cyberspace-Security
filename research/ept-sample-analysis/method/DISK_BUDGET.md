# E 盘空间预算与防膨胀规则（2026-09-23 制定）

背景：E: 曾降至 18G 可用（99%），导致 WSL 因磁盘不足崩溃。C155 治理后可用 272G（详见 artifacts/evidence/C155_disk_governance_20260923.md）。
以下规则用于**防止再次膨胀**，每轮实验前后来一遍。

## 1. 硬阈值

| 阈值 | 值 | 动作 |
|---|---|---|
| 停止线 | E: 可用 < 60G | 禁止新建快照、禁止跑样本、禁止转储/克隆；先做回收 |
| 警戒线 | E: 可用 < 100G | 允许只读分析；新实验需先说明回收方案 |
| 正常 | E: 可用 >= 100G | 正常推进 |
| 单轮上限 | 单轮新增占用 <= 8G | 超出则本轮结束后必须回收 |

## 2. 快照规则（最主要膨胀源）

- 每轮实验**最多新建 1 个快照**。
- 快照命名必须带轮次与日期，description 必须写用途。
- 实验后立即判定：若为 postmortem / not evidence / instrument failure，在**当轮收尾时删除**，不要留到下一轮。
- 不得为“以防万一”保留多个同描述的迭代快照（C155 清理中 11 个 qoder-baked-* 描述完全重复）。
- 死端叶子快照删除不触发父盘合并，代价极低（0.5–2s），没有理由囤积。
- 保留基线：pre-ept、当前 armed 基线、一个 clean 基线；其余按需。

## 3. 离线取证规则

- 需要离线查看磁盘时，**优先 attach 现有快照并只读挂载**，不要 clone 出新 VHD。
- 若必须导出副本：写清用途、当轮用完即删，并在收尾时确认文件已消失。
- 禁止把 _read 类目录当作长期存档；提取出的制品才是证据，源盘是临时物。
- 任何快照/克隆/VHD 副本都必须在 C15x 证据里登记：路径、大小、mtime、用途、去向。

## 4. 日志与转储

- 每轮日志/探针输出总量上限 1G；超出则先聚合再保留。
- 大体积二进制（stream_text.bin 8M、*.pdb 15M 等）如为重复副本，只留一份。
- RUN_MANIFEST / artifacts/evidence 只保留文本级结论，不放大文件。

## 5. 工具与安装包

- 安装包/压缩包（ghidra.zip、jdk21.zip、python-*.exe、vs_BuildTools.exe 等）一律放 C: 或下载后即删，不留在 <HOST_PATH>\VMs\<OTHER_VM_LABEL>\share。
- WSL 侧工具优先放系统盘或项目内小体积目录；<HOST_PATH>（2.8G）属可接受范围。

## 6. 每轮收尾检查清单

1. 跑 bash <HOST_PATH>，记录可用空间前后值。
2. 本轮的临时快照是否已按第 2 节处理？
3. 本轮是否产生 > 100M 的新文件？是否可删或需登记？
4. 是否有指向已删除文件的 VirtualBox 介质登记？有则 closemedium 注销。
5. 记录到 RUN_MANIFEST_genB.md：本轮空间前后值 + 回收动作。

## 7. WSL 侧 VHDX

- WSL 本体在 <HOST_PATH>\WSL\Ubuntu\ext4.vhdx（约 19.9G）。
- 如需压缩，必须在 WSL 停机状态下用 diskpart / Optimize-VHD，且先确认宿主机可用空间 > 30G。
- 不要在 E: 可用 < 60G 时尝试压缩（压缩过程需要临时空间）。

## 8. VBoxManage 调用方式（WSL 互操作）

WSL 下 VBoxManage.exe 的 stdout 不被捕获，必须走文件重定向：

    cmd.exe /C "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" <子命令> > 输出.txt 2>&1
