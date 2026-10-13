# 逆向工具路由参考

按当前问题选择最小工具链，不按工具数量证明严谨性：

- 文件身份、PE 布局、导入导出、hash：独立 PE parser/LIEF/pefile，必要时 sigcheck；
- 字符串和能力候选：FLOSS、capa、YARA；
- 函数、xref、反编译：Ghidra headless/交互式，使用独立字节检查做坐标交叉核验；
- 用户态返回值、异常、栈和退出：WinDbg/CDB；窄 API 事件才使用 Frida；
- 文件/注册表/进程行为：窄过滤 Procmon 或 ETW；
- 网络字节：保留原始捕获并使用确定性解析器；
- 内存镜像：Volatility 3/WinDbg，只有问题确实需要系统上下文时才生成大镜像。

一个问题选一个主工具，最多一个轻量交叉验证工具。每个重要结果记录输入 hash、工具版本、命令、作用域、artifact 路径/hash、覆盖范围、未覆盖区域和未决替代解释。

