# Windows 网络分析

当需要观察或模拟样本网络行为时，优先使用成熟网络分析工具，并保持分析网络与真实 LAN/互联网隔离。

## FakeNet-NG

FakeNet-NG 是 Mandiant/FLARE 维护的动态网络分析工具。Windows 上的典型模式是 `SingleHost`：FakeNet-NG 与待分析程序运行在同一 Windows 分析 VM 内，拦截/重定向流量并模拟常见网络服务。

它适合：

- 观察样本尝试连接的主机、端口和协议；
- 模拟 DNS/HTTP 等服务；
- 在不连接真实服务的情况下观察网络逻辑；
- 捕获网络特征。

Windows 下优先使用官方 release 的 standalone executable，避免为正常使用额外搭建 Python 依赖。

## 使用边界

- Windows `SingleHost` 适合单 VM 分析；FakeNet-NG 的 `MultiHost` 模式由 Linux 支持，不要在 Windows 上假设存在同等能力。
- FakeNet-NG 会修改/拦截网络流量，只在隔离 VM 中运行。
- 网络请求被捕获 ≠ 远端业务成功。
- 模拟响应 ≠ 自然真实服务器响应；若模拟内容会改变目标行为，应把它记录为 intervention。
- 如果已登记 runtime（例如 CAPEsolo）已经提供足够的网络结果，不重复启动第二套网络采集；需要主动服务模拟时再引入 FakeNet-NG。

## 上游

- FakeNet-NG: https://github.com/mandiant/flare-fakenet-ng

