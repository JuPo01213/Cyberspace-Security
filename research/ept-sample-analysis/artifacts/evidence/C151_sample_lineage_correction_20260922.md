# C151：EPT 外层样本与 Hardware.exe 的谱系纠正（2026-09-22）

## 结论

本件纠正当前动态入口：`<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe` 是样本上游；`Hardware.exe` 不是该外层 PyInstaller 解包树中的原始文件，而是外层 `auto_decode.pyc` 在运行时下载后部署到 `C:\Windows\System32\Hardware.exe` 的运行时目标。

因此，直接启动已有的 `C:\ept_core\Hardware.exe` 可以用于历史内部地址验证，但不能单独证明“从 EPT 样本自然触发了解码”。后续核心分离实验必须从外层 EPT 样本启动，并在同一运行编号中记录实际下载/部署目标的 SHA-256，再对该目标做最小授权分支放行。

## 身份锚点

- 外层样本：`<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe`
- 外层样本 SHA-256：`CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2`
- `main.pyc`：`<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe_extracted\main.pyc`
- `main.pyc` SHA-256：`DE746C511178B8748A265A9C56E4C7A21E9703C1CE89DEA2609B1BA6BE33E274`
- `auto_decode.pyc`：`<HOST_PATH>\EPT\sample\EPT专业游戏维修工具箱V5.1.exe_extracted\PYZ.pyz_extracted\auto_decode.pyc`
- `auto_decode.pyc` SHA-256：`414476EACB0F3EEE219B073EB3C3E85BBE5AC562AF85E357FA80E499BD56DBA2`
- 解包树内按文件名 `Hardware.exe` 的匹配数：`0`

## 静态事实

1. `auto_decode.pyc` 的 `run_decode` / `run_decode_from_exe` 调用 `_download_file`，下载目标是解码程序，而不是从外层 `_pack_tools` 直接复制 `Hardware.exe`。
2. `_deploy_hardware` 把下载得到的程序移动到 `C:\Windows\System32\Hardware.exe`。
3. `_call_spoofer_commandline` 读取 `HARDWARE_EXE_PATH`，以 `-k <卡密> -n <序列模式> -m <解码模式>` 启动该部署目标。
4. `auto_decode.pyc` 中出现 `UVT-EPT.exe` 下载路径；带签名查询参数不在本证据件中复述或固化。
5. 因而 `<HOST_PATH>\HexPatch\ept-out\Hardware.genB.exe`、此前投放到 `C:\ept_core\Hardware.exe` 的副本以及 H/E/F 等直接目标运行，只能作为外部实验材料，不能替代本轮从 EPT 外层样本产生的目标身份。

## 本轮静态产物

以下文件均由上述 EPT 上游静态分析生成，未修改原始样本：

- `<HOST_PATH>\EPT\artifacts\captures\outer_sample_static_20260922\main_code_metadata.txt`
- `<HOST_PATH>\EPT\artifacts\captures\outer_sample_static_20260922\main_string_hits.txt`
- `<HOST_PATH>\EPT\artifacts\captures\outer_sample_static_20260922\pyc_string_hits.tsv`
- `<HOST_PATH>\EPT\artifacts\captures\outer_sample_static_20260922\auto_decode_code_index.txt`
- `<HOST_PATH>\EPT\artifacts\captures\outer_sample_static_20260922\auto_decode_selected_dis.txt`

## 对核心分离路线的影响

下一轮不再把“直接启动已有 Hardware.exe”作为主入口。正确入口是：

`EPT 外层样本 → 自然下载/部署 Hardware.exe → 在本轮实际部署目标上做两个最小授权分支补丁 → 让真实 RC00→RC03→RC06 自然执行 → 采集 native_return、caller +0x80 前后缓冲和靶机前后变化`。

本件不宣称解码成功；`native_return == 0x1` 与 `changed_bytes > 0` 尚未在该正确谱系上同时验证。
