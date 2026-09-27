# CAPEsolo MCP

当 Windows 分析 Guest 已安装 CAPEsolo，并且 Host Agent 可以通过 MCP 访问时，优先把 CAPEsolo 当作**样本任务 runtime**，不要再自制 runner、done marker 或 artifact 状态机。

## 角色

CAPEsolo 负责：

- 提交/运行分析 job；
- job 状态；
- CAPE 行为结果；
- dropped files / payload / debug logs；
- 可选交互式 debugger。

Host Agent 负责：

- 选择正确 package / options / timeout；
- 保证提交语义与任务目标一致；
- 解释结果；
- 判断是否需要额外 debugger、网络或 GUI 能力。

## Host → Guest MCP

Host 与 Guest 分离时，使用 CAPEsolo 的 `streamable-http` MCP 入口，并只绑定隔离/host-only 网络地址。不要把分析 MCP 暴露到真实 LAN 或互联网。

样本已在 Guest 内时，直接把 Guest 路径传给分析工具。Host 需要传文件时，可先用 CAPEsolo 上传能力；大文件若经模型上下文传 base64 成本过高，应使用已验证的数据通道把文件放进 Guest，再把 Guest 路径交给 CAPEsolo。

## 标准 job 流程

```text
确认目标文件身份
→ capesolo_analyze_sample
→ 保存 CAPEsolo job id
→ capesolo_get_job_status
→ completed 后 capesolo_get_results
→ 按需读取 dropped files / payloads / logs / HTML report
```

CAPEsolo 已有 job 状态时，不再维护第二套 RUNNING/PRECHECK/COMPLETED 状态机。

## 提交语义必须闭合

提交前必须确认当前任务真正需要的：

- `sample_path`
- `package`
- `options`
- `timeout`
- `enforce_timeout`
- 是否 `interactive_debug`

“成功创建 job”只证明 CAPEsolo 接受了任务，不证明样本通过了正确入口执行。

如果任务依赖 package-specific 参数或 options：

1. 查当前版本官方文档/本地帮助；
2. 按官方入口提交；
3. 读取 job/log/result 中能确认的实际配置；
4. 无法确认启动语义时，不把该轮解释成目标级有效运行。

## 交互式 debugger

若使用 CAPEsolo MCP debugger，提交时使用 `interactive_debug=true`。官方文档明确说明：不要只在 `options` 中手写 `idbg=1` 来替代该 flag。

典型流程：

```text
analyze_sample(interactive_debug=true, breakpoint options)
→ dbg_wait_break
→ inspect / step / set breakpoint
→ 删除不再需要的 breakpoint
→ 确认 debugger 状态符合预期
→ continue
→ get_results
```

可用的 MCP debugger 能力包括执行控制、寄存器、栈、内存、反汇编、模块、线程、硬件断点以及受控寄存器/内存修改。

## 证据边界

- job created ≠ 正确启动语义已验证；
- breakpoint configured ≠ breakpoint hit；
- debugger modification 必须作为 intervention 记录；
- debugger 失效或状态陈旧时，后续缺失行为不得自动解释为业务阴性。

## 上游

- CAPEsolo: https://github.com/CAPESandbox/CAPEsolo
- MCP guide: https://github.com/CAPESandbox/CAPEsolo/blob/main/mcp_server.md
- Interactive debugger: https://github.com/CAPESandbox/CAPEsolo/blob/main/interactive_debugger.md
