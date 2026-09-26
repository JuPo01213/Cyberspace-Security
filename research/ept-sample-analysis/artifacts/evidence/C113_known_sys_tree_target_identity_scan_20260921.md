# C113：已知宿主 `.sys` 树中的目标驱动身份扫描

日期：2026-09-21  
状态：`TARGET_DRIVER_NOT_PRESENT_IN_KNOWN_HOST_SYS_TREES`

## 范围与方法

本轮只读扫描以下宿主目录中的全部 `.sys` 文件：

```text
<HOST_PATH>\VMs\<OTHER_VM_LABEL>\share
<HOST_PATH>\CTF
```

共枚举 40 个文件，总大小 848,240 bytes。逐文件读取原始字节，并分别按 ASCII
和 UTF-16LE 搜索以下目标身份字符串：

```text
HP_WKS
SWTOOLS
HP_WKS_SWTOOLS_DRIVER
\\Device\\HP_WKS
\\DosDevices\\HP_WKS
```

## 结果

- ASCII 命中：0；
- UTF-16LE 命中：0；
- 没有任何已知宿主 `.sys` 能由目标设备名或驱动名关联到
  `\\.\\HP_WKS_SWTOOLS_DRIVER`。

目录中的 `hwidsrc`、`hwidsmbios`、`tpmspoof` 等文件属于实验室辅助组件；本轮不把
它们当作 genB 目标驱动，也没有启动、加载或修改它们。

## 结论边界

这条结果与 C101/C103 一致，并把排除范围扩展到当前宿主已知 `.sys` 树：目标驱动
字节不是“已存在但尚未命名”的普通宿主 `.sys` 文件。

它不能排除以下来源：客体内存中的临时映像、无明文身份字符串的加密/分片载荷、
未取回的快照祖先层或运行时映射后即删除的驱动。因此它不能替代真实驱动响应，
也不能把现有实验室驱动接入 genB harness。

