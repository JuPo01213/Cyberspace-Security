# Incident Patterns

这不是实时台账。只有出现相似症状时按需读取。

## 控制输出假空

症状：外部命令 exit code 正常但 stdout/stderr 不可靠。

处理：让目标环境先落盘，再由 Host 读取文件；命令退出、日志内容和目标状态分开判断。

## VM Running 但 Guest 未 ready

症状：VM 已启动，但 NAT、Guest agent、登录会话、共享路径尚不可用。

处理：恢复后重新做短 canary；不要复用旧会话状态。

## 前台控制会话杀掉 runner

症状：GuestControl/SSH/PSSession 结束后长 runner 一并终止。

处理：长任务 detach；控制面只 trigger/query；状态留 Guest spool。

## 路径错误被轮询掩盖

症状：第一次其实已经 path-not-found，后续机械等待多轮。

处理：区分 path/auth/transport/file-not-ready；同类错误无新信息达到预算即停。

## Guest 声称有文件但 Host 没拿到

症状：Guest 报告 dump/log 大小，但 Host 无完整文件。

处理：Guest report 只是 observation；正式证据看 Host 是否实际 acquire，关键文件再 verify hash/size。

## 会话映射/权限作用域不共享

症状：另一个 PSSession 看不到映射盘或 UNC 上下文不同。

处理：每个新会话首次使用路径时先 canary，不继承假设。

## 调试器改变自然行为

症状：自然运行会创建 child，带 debugger 时不出现，或时序明显变化。

处理：自然/调试运行分 RUN_ID；调试器阴性不能升级成自然运行阴性。

## 记录系统本身拖慢实验

症状：一个动作之后同步多份 manifest、handoff、summary、evidence、status 文档。

处理：v3 只维护 STATE + events + artifacts；其他都是按需生成视图。
