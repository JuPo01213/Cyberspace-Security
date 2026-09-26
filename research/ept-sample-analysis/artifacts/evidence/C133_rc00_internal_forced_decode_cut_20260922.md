# C133：RC00 内部强制解码切口的静态定位（2026-09-22）

## 状态

`PARTIAL / STATIC_PATCH_SURFACE_IDENTIFIED_NOT_APPLIED`

本件只把下一轮“先让解码发生、再看靶机变化”的**最小运行时补丁面**固定下来；本轮没有修改原始样本、没有修改 VM、没有执行补丁，因此不宣称解码已经发生。

## 权威输入与坐标

- 样本上游：`<HOST_PATH>\EPT\sample\`
- EPT 代码捕获：`<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_text.bin`
- 捕获大小：`8,257,536 bytes`
- 捕获 SHA-256：`5AE354E2983A5BF407601B3629D114B8FAA1DDD731D074E8D2092C338ABDF757`
- 坐标不变量：捕获偏移 `0` 是内嵌 PE 头，`VA = 0x140000000 + stream_offset`
- 同身份运行时 PE 捕获：`<HOST_PATH>\EPT\artifacts\captures\hardware_guest_test.exe`
- 该 PE 捕获 SHA-256：`CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`（与 EPT 清单登记的 genB 身份一致）
- 工具：Python 3.13.15 + Capstone 5.0.7；只读读取与反汇编，无样本执行

## 已闭合的 RC00 静态链

在 EPT `stream_text.bin` 上按上述坐标逐字节反汇编得到：

- `0x14078ee73`：调用外部设备/授权接缝 `0x141757acd`；本轮不改这次调用。
- `0x14078ee9b`：调用 RC03 validator `0x14078db80`。
- `0x14078eea0`：`test eax, eax`。
- `0x14078eea2`：`jne 0x14078ef02`；失败返回时不会继续到 marker/RC06。
- `0x14078ef02`：读取 RC00 栈帧 marker `[rsp+0x44]`。
- `0x14078ef0d`：与 `g340`（`[0x14115c340]`）比较。
- `0x14078ef10`：`je 0x14078ef42`；marker 不相等时退出到错误路径。
- `0x14078ef42`：`lea rcx, [rsp+0x60]`。
- `0x14078ef47`：调用真实 RC06 变换 `0x14078ce60`。
- `0x14078ef4c..0x14078efb0`：把 268 bytes 从 RC00 栈帧复制到原始 caller `[r14] + 0x80`。
- `0x14078efe1`：成功路径把返回值整理为 `1` 后回到公共收尾。

## 最小“破解式”运行时切口（候选，尚未应用）

只在真实 EPT 派生样本已经解包、且目标子进程的实际代码地址可验证后，对进程内存做以下两处 2-byte 替换：

| 地址 | 原字节 | 候选字节 | 作用 |
|---|---|---|---|
| `0x14078eea2` | `75 5e` | `EB 5E` | 将 validator 结果分支改为无条件进入 marker 检查；不替换 validator、不中断设备调用。 |
| `0x14078ef10` | `74 30` | `EB 30` | 将 marker 等值分支改为无条件进入真实 RC06；不改 RC06 与 caller 写回。 |

这个组合的设计目的不是伪造输出，而是**保留真实设备调用和 RC00 栈帧，只强制越过 RC03/marker 两道内部闸门**，让真实 RC06 有机会执行。它与此前“改外层授权谓词”“在 `0x141757acd` 写 synthetic response”“只把 validator 替成 `mov eax,1;ret`”不同。

## 本轮不作的事

- 不修改 `<HOST_PATH>\EPT\sample\` 原始样本。
- 不把 `<HOST_PATH>\HexPatch` 的 runner、fixture 或日志当作样本证据。
- 不向设备接缝写 response，不把 request echo 当作真实 response。
- 不在宿主直接把 raw capture 当成自然样本成功；该切口必须在隔离 VM 的真实派生进程内验证。

## 下一轮唯一判据

同一 run 必须同时保存：

```text
真实目标子进程身份与样本 SHA-256
两个补丁地址的原始/新字节和命中时间
0x14078ef42 / 0x14078ef47 命中记录
native_return == 0x1
caller +0x80 changed_bytes > 0
caller +0x80 前后缓冲
靶机目标文件/目录/服务/驱动前后状态
```

若两个补丁均已写入但 `0x14078ef42` 未命中，结论是“RC00 未到达或运行时地址未匹配”，不是解码失败。若 RC06 命中但 `changed_bytes == 0`，结论是“强制进入成功叶但输入/响应数据未产生有效输出”，仍不能宣称完成。只有真实目标进程满足数值判据并有前后靶机证据，才推进核心分离完成。

## 机器生成的局部反汇编

`0x14078ed80` `c1 44 0f be 81` `rol dword ptr [rdi + rcx - 0x42], 0x81`
`0x14078ed85` `08 01` `or byte ptr [rcx], al`
`0x14078ed87` `00 00` `add byte ptr [rax], al`
`0x14078ed89` `48 8d 3d 60 d6 9c 00` `lea rdi, [rip + 0x9cd660]`
`0x14078ed90` `89 54 24 30` `mov dword ptr [rsp + 0x30], edx`
`0x14078ed94` `8b 51 04` `mov edx, dword ptr [rcx + 4]`
`0x14078ed97` `48 8d 0d 12 ea 7f 00` `lea rcx, [rip + 0x7fea12]`
`0x14078ed9e` `89 6c 24 28` `mov dword ptr [rsp + 0x28], ebp`
`0x14078eda2` `48 89 7c 24 20` `mov qword ptr [rsp + 0x20], rdi`
`0x14078eda7` `e8 b4 df ff ff` `call 0x14078cd60`
`0x14078edac` `49 8b 0e` `mov rcx, qword ptr [r14]`
`0x14078edaf` `48 8d 54 24 60` `lea rdx, [rsp + 0x60]`
`0x14078edb4` `0f 57 c0` `xorps xmm0, xmm0`
`0x14078edb7` `bb 02 00 00 00` `mov ebx, 2`
`0x14078edbc` `0f 11 44 24 50` `movups xmmword ptr [rsp + 0x50], xmm0`
`0x14078edc1` `8b c3` `mov eax, ebx`
`0x14078edc3` `48 8d 92 80 00 00 00` `lea rdx, [rdx + 0x80]`
`0x14078edca` `0f 10 01` `movups xmm0, xmmword ptr [rcx]`
`0x14078edcd` `48 8d 89 80 00 00 00` `lea rcx, [rcx + 0x80]`
`0x14078edd4` `0f 11 42 80` `movups xmmword ptr [rdx - 0x80], xmm0`
`0x14078edd8` `0f 10 49 90` `movups xmm1, xmmword ptr [rcx - 0x70]`
`0x14078eddc` `0f 11 4a 90` `movups xmmword ptr [rdx - 0x70], xmm1`
`0x14078ede0` `0f 10 41 a0` `movups xmm0, xmmword ptr [rcx - 0x60]`
`0x14078ede4` `0f 11 42 a0` `movups xmmword ptr [rdx - 0x60], xmm0`
`0x14078ede8` `0f 10 49 b0` `movups xmm1, xmmword ptr [rcx - 0x50]`
`0x14078edec` `0f 11 4a b0` `movups xmmword ptr [rdx - 0x50], xmm1`
`0x14078edf0` `0f 10 41 c0` `movups xmm0, xmmword ptr [rcx - 0x40]`
`0x14078edf4` `0f 11 42 c0` `movups xmmword ptr [rdx - 0x40], xmm0`
`0x14078edf8` `0f 10 49 d0` `movups xmm1, xmmword ptr [rcx - 0x30]`
`0x14078edfc` `0f 11 4a d0` `movups xmmword ptr [rdx - 0x30], xmm1`
`0x14078ee00` `0f 10 41 e0` `movups xmm0, xmmword ptr [rcx - 0x20]`
`0x14078ee04` `0f 11 42 e0` `movups xmmword ptr [rdx - 0x20], xmm0`
`0x14078ee08` `0f 10 49 f0` `movups xmm1, xmmword ptr [rcx - 0x10]`
`0x14078ee0c` `0f 11 4a f0` `movups xmmword ptr [rdx - 0x10], xmm1`
`0x14078ee10` `48 83 e8 01` `sub rax, 1`
`0x14078ee14` `75 ad` `jne 0x14078edc3`
`0x14078ee16` `48 8b 01` `mov rax, qword ptr [rcx]`
`0x14078ee19` `48 89 02` `mov qword ptr [rdx], rax`
`0x14078ee1c` `8b 41 08` `mov eax, dword ptr [rcx + 8]`
`0x14078ee1f` `48 8d 4c 24 60` `lea rcx, [rsp + 0x60]`
`0x14078ee24` `89 42 08` `mov dword ptr [rdx + 8], eax`
`0x14078ee27` `e8 34 e0 ff ff` `call 0x14078ce60`
`0x14078ee2c` `48 8d 4c 24 50` `lea rcx, [rsp + 0x50]`
`0x14078ee31` `e8 ca ea ff ff` `call 0x14078d900`
`0x14078ee36` `48 c7 44 24 38 00 00 00 00` `mov qword ptr [rsp + 0x38], 0`
`0x14078ee3f` `48 8d 44 24 40` `lea rax, [rsp + 0x40]`
`0x14078ee44` `48 89 44 24 30` `mov qword ptr [rsp + 0x30], rax`
`0x14078ee49` `4c 8d 44 24 50` `lea r8, [rsp + 0x50]`
`0x14078ee4e` `48 8d 44 24 50` `lea rax, [rsp + 0x50]`
`0x14078ee53` `c7 44 24 28 1c 01 00 00` `mov dword ptr [rsp + 0x28], 0x11c`
`0x14078ee5b` `41 b9 1c 01 00 00` `mov r9d, 0x11c`
`0x14078ee61` `48 89 44 24 20` `mov qword ptr [rsp + 0x20], rax`
`0x14078ee66` `8b d5` `mov edx, ebp`
`0x14078ee68` `c7 44 24 40 00 00 00 00` `mov dword ptr [rsp + 0x40], 0`
`0x14078ee70` `48 8b ce` `mov rcx, rsi`
`0x14078ee73` `e8 55 8c fc 00` `call 0x141757acd`
`0x14078ee78` `00 48 8b` `add byte ptr [rax - 0x75], cl`
`0x14078ee7b` `ac` `lodsb al, byte ptr [rsi]`
`0x14078ee7c` `24 b0` `and al, 0xb0`
`0x14078ee7e` `01 00` `add dword ptr [rax], eax`
`0x14078ee80` `00 85 c0 0f 84 60` `add byte ptr [rbp + 0x60840fc0], al`
`0x14078ee86` `01 00` `add dword ptr [rax], eax`
`0x14078ee88` `00 48 8d` `add byte ptr [rax - 0x73], cl`
`0x14078ee8b` `54` `push rsp`
`0x14078ee8c` `24 44` `and al, 0x44`
`0x14078ee8e` `c7 44 24 44 00 00 00 00` `mov dword ptr [rsp + 0x44], 0`
`0x14078ee96` `48 8d 4c 24 50` `lea rcx, [rsp + 0x50]`
`0x14078ee9b` `e8 e0 ec ff ff` `call 0x14078db80`
`0x14078eea0` `85 c0` `test eax, eax`
`0x14078eea2` `75 5e` `jne 0x14078ef02`
`0x14078eea4` `8b 05 96 d4 9c 00` `mov eax, dword ptr [rip + 0x9cd496]`
`0x14078eeaa` `48 8d 0d cf d4 9c 00` `lea rcx, [rip + 0x9cd4cf]`
`0x14078eeb1` `44 8b 44 24 50` `mov r8d, dword ptr [rsp + 0x50]`
`0x14078eeb6` `4c 8b cf` `mov r9, rdi`
`0x14078eeb9` `8b 54 24 40` `mov edx, dword ptr [rsp + 0x40]`
`0x14078eebd` `48 89 4c 24 30` `mov qword ptr [rsp + 0x30], rcx`
`0x14078eec2` `48 8d 0d a7 e9 7f 00` `lea rcx, [rip + 0x7fe9a7]`
`0x14078eec9` `89 44 24 28` `mov dword ptr [rsp + 0x28], eax`
`0x14078eecd` `8b 05 95 d4 9c 00` `mov eax, dword ptr [rip + 0x9cd495]`
`0x14078eed3` `89 44 24 20` `mov dword ptr [rsp + 0x20], eax`
`0x14078eed7` `e8 84 de ff ff` `call 0x14078cd60`
`0x14078eedc` `33 c0` `xor eax, eax`
`0x14078eede` `48 8b 9c 24 a8 01 00 00` `mov rbx, qword ptr [rsp + 0x1a8]`
`0x14078eee6` `48 8b 8c 24 70 01 00 00` `mov rcx, qword ptr [rsp + 0x170]`
`0x14078eeee` `48 33 cc` `xor rcx, rsp`
`0x14078eef1` `e8 ba 17 02 00` `call 0x1407b06b0`
`0x14078eef6` `48 81 c4 80 01 00 00` `add rsp, 0x180`
`0x14078eefd` `41 5e` `pop r14`
`0x14078eeff` `5f` `pop rdi`
`0x14078ef00` `5e` `pop rsi`
`0x14078ef01` `c3` `ret `
`0x14078ef02` `44 8b 44 24 44` `mov r8d, dword ptr [rsp + 0x44]`
`0x14078ef07` `8b 35 33 d4 9c 00` `mov esi, dword ptr [rip + 0x9cd433]`
`0x14078ef0d` `44 3b c6` `cmp r8d, esi`
`0x14078ef10` `74 30` `je 0x14078ef42`
`0x14078ef12` `8b 05 50 d4 9c 00` `mov eax, dword ptr [rip + 0x9cd450]`
`0x14078ef18` `48 8d 0d 61 d4 9c 00` `lea rcx, [rip + 0x9cd461]`
`0x14078ef1f` `8b 54 24 40` `mov edx, dword ptr [rsp + 0x40]`
`0x14078ef23` `44 8b ce` `mov r9d, esi`
`0x14078ef26` `48 89 4c 24 30` `mov qword ptr [rsp + 0x30], rcx`
`0x14078ef2b` `48 8d 0d 9e e9 7f 00` `lea rcx, [rip + 0x7fe99e]`
`0x14078ef32` `89 44 24 28` `mov dword ptr [rsp + 0x28], eax`
`0x14078ef36` `48 89 7c 24 20` `mov qword ptr [rsp + 0x20], rdi`
`0x14078ef3b` `e8 20 de ff ff` `call 0x14078cd60`
`0x14078ef40` `eb 9a` `jmp 0x14078eedc`
`0x14078ef42` `48 8d 4c 24 60` `lea rcx, [rsp + 0x60]`
`0x14078ef47` `e8 14 df ff ff` `call 0x14078ce60`
`0x14078ef4c` `49 8b 0e` `mov rcx, qword ptr [r14]`
`0x14078ef4f` `48 8d 54 24 60` `lea rdx, [rsp + 0x60]`
`0x14078ef54` `48 8d 89 80 00 00 00` `lea rcx, [rcx + 0x80]`
`0x14078ef5b` `0f 10 02` `movups xmm0, xmmword ptr [rdx]`
`0x14078ef5e` `48 8d 92 80 00 00 00` `lea rdx, [rdx + 0x80]`
`0x14078ef65` `0f 11 41 80` `movups xmmword ptr [rcx - 0x80], xmm0`
`0x14078ef69` `0f 10 4a 90` `movups xmm1, xmmword ptr [rdx - 0x70]`
`0x14078ef6d` `0f 11 49 90` `movups xmmword ptr [rcx - 0x70], xmm1`
`0x14078ef71` `0f 10 42 a0` `movups xmm0, xmmword ptr [rdx - 0x60]`
`0x14078ef75` `0f 11 41 a0` `movups xmmword ptr [rcx - 0x60], xmm0`
`0x14078ef79` `0f 10 4a b0` `movups xmm1, xmmword ptr [rdx - 0x50]`
`0x14078ef7d` `0f 11 49 b0` `movups xmmword ptr [rcx - 0x50], xmm1`
`0x14078ef81` `0f 10 42 c0` `movups xmm0, xmmword ptr [rdx - 0x40]`
`0x14078ef85` `0f 11 41 c0` `movups xmmword ptr [rcx - 0x40], xmm0`
`0x14078ef89` `0f 10 4a d0` `movups xmm1, xmmword ptr [rdx - 0x30]`
`0x14078ef8d` `0f 11 49 d0` `movups xmmword ptr [rcx - 0x30], xmm1`
`0x14078ef91` `0f 10 42 e0` `movups xmm0, xmmword ptr [rdx - 0x20]`
`0x14078ef95` `0f 11 41 e0` `movups xmmword ptr [rcx - 0x20], xmm0`
`0x14078ef99` `0f 10 4a f0` `movups xmm1, xmmword ptr [rdx - 0x10]`
`0x14078ef9d` `0f 11 49 f0` `movups xmmword ptr [rcx - 0x10], xmm1`
`0x14078efa1` `48 83 eb 01` `sub rbx, 1`
`0x14078efa5` `75 ad` `jne 0x14078ef54`
`0x14078efa7` `48 8b 02` `mov rax, qword ptr [rdx]`
`0x14078efaa` `48 89 01` `mov qword ptr [rcx], rax`
`0x14078efad` `8b 42 08` `mov eax, dword ptr [rdx + 8]`
`0x14078efb0` `89 41 08` `mov dword ptr [rcx + 8], eax`
`0x14078efb3` `49 8b 0e` `mov rcx, qword ptr [r14]`
`0x14078efb6` `8b 54 24 40` `mov edx, dword ptr [rsp + 0x40]`
`0x14078efba` `89 74 24 30` `mov dword ptr [rsp + 0x30], esi`
`0x14078efbe` `48 89 7c 24 28` `mov qword ptr [rsp + 0x28], rdi`
`0x14078efc3` `0f be 81 08 01 00 00` `movsx eax, byte ptr [rcx + 0x108]`
`0x14078efca` `44 8b 49 04` `mov r9d, dword ptr [rcx + 4]`
`0x14078efce` `44 8b 01` `mov r8d, dword ptr [rcx]`
`0x14078efd1` `48 8d 0d 68 e9 7f 00` `lea rcx, [rip + 0x7fe968]`
`0x14078efd8` `89 44 24 20` `mov dword ptr [rsp + 0x20], eax`
`0x14078efdc` `e8 7f dd ff ff` `call 0x14078cd60`
`0x14078efe1` `8d 43 01` `lea eax, [rbx + 1]`
`0x14078efe4` `e9` `.byte 0xe9`
`0x14078efe5` `f5` `cmc `
`0x14078efe6` `fe` `.byte 0xfe`
`0x14078efe7` `ff` `.byte 0xff`
