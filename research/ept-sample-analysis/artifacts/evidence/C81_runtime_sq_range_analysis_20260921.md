# C81 · full runtime .Sq> range analysis

## 判定

这批材料是当前核心分析的实质推进：在靶机内启动 Hardware.exe 后，目标页出现的 +2.443 秒内读取了整个 .Sq> 虚拟区间。
共 3814 页、15,622,144 字节，全部 ReadProcessMemory 成功，3812 页含非零字节。
这证明当前基线能够提供完整运行时页面集合；它仍不等于已经解释所有 VMProtect 语义，也不等于已经得到业务输出。

## 采集边界

- VA 区间：0x141174000–0x14205a000，页大小 0x1000。
- 原始范围 SHA-256：1daf7ec28a09b43eb456f2027bcbaeb047aafab6b1a290ce14edc9cce761d1d4。
- 客体网卡为 null；没有配置 endpoint；脚本在扫描后立即停止核心。
- 运行时页面在扫描前由目标页 0x141757000 的非零转变确认；扫描本身约 8.94 秒完成，总脚本跨度约 11.48 秒。
- 静态 .pdata 表中 .Sq> 函数条目：870。

## 已知 RC00 链在完整范围中的函数归属

- post_send_wrapper 0x141757acd：运行时观察窗口 0x141757acd–0x141757b2f，长度 98 字节，边界证据=runtime-observed-first-ret。
- call_1415844d3 0x1415844d3：运行时观察窗口 0x1415844d3–0x1415854d3，长度 4096 字节，边界证据=runtime-observed-first-ret。
- call_1419060e7 0x1419060e7：运行时观察窗口 0x1419060e7–0x1419070e7，长度 4096 字节，边界证据=runtime-observed-first-ret。
- call_14171631b 0x14171631b：运行时观察窗口 0x14171631b–0x14171731b，长度 4096 字节，边界证据=runtime-observed-first-ret。
- call_141a93e50 0x141a93e50：运行时观察窗口 0x141a93e50–0x141a93f11，长度 193 字节，边界证据=runtime-observed-first-ret。

完整范围中，post_send_wrapper 的 direct-call 边如下；这些是运行时字节上的真实边，不是从字符串锚点推测：

- 0x141757acf call 0x1415844d3，目标函数归属 outside-function-table。
- 0x141757af5 call 0x1419060e7，目标函数归属 outside-function-table。
- 0x141757afc call 0x14171631b，目标函数归属 outside-function-table。
- 0x141757b15 call 0x141a93e50，目标函数归属 outside-function-table。

## 与既有页面证据的交叉校验

| 页面 | 新范围非零数 | 新范围 SHA-256 | 与既有 4K 页面相同 |
|---|---:|---|---|
| 0x141757000 | 4023/4096 | bd28f2187520e18924a85ce23b8a603f62721abb180ea3d8599b0ef0c17bc9e7 | True |
| 0x141584000 | 4050/4096 | 2dd3932e028bf7a0f023f7b51eb6f2aa561798c5eb5a2bb5457cf52b2cc3a1ec | False |
| 0x141906000 | 4064/4096 | 931bd3f536ce8c4d0ab23e28fc30470f88d52830564f0899725edd8dc967dd98 | True |
| 0x141716000 | 4051/4096 | 54cb25070363e3ae4911394279006ce48425c9540eed6a089707b4a39f974b91 | False |
| 0x141a93000 | 4045/4096 | 17d37da46aa64a52d9b3830277f04bfcbbc599589e2561cdb8edb5ed216879d4 | True |

## 关键函数的运行时反汇编摘要

### post_send_wrapper 0x141757acd–0x141757b2f（98 字节）
解码指令数 22，覆盖 98 字节；direct edges=4，RIP refs=0。
    0x141757acd: 50                               push     rax
    0x141757ace: 55                               push     rbp
    0x141757acf: e8 ff c9 e2 ff                   call     0x1415844d3
    0x141757ad4: 48 8b 6c 24 18                   mov      rbp, qword ptr [rsp + 0x18]
    0x141757ad9: 48 8b 6c 25 00                   mov      rbp, qword ptr [rbp + riz]
    0x141757ade: 48 c7 44 24 18 29 de a5 d2       mov      qword ptr [rsp + 0x18], 0xffffffffd2a5de29
    0x141757ae7: f7 5c 24 18                      neg      dword ptr [rsp + 0x18]
    0x141757aeb: 80 64 24 18 3a                   and      byte ptr [rsp + 0x18], 0x3a
    0x141757af0: 48 f7 5c 24 18                   neg      qword ptr [rsp + 0x18]
    0x141757af5: e8 ed e5 1a 00                   call     0x1419060e7
    0x141757afa: 41 53                            push     r11
    0x141757afc: e8 1a e8 fb ff                   call     0x14171631b
    0x141757b01: 9c                               pushfq
    0x141757b02: 48 81 44 24 08 08 e1 30 00       add      qword ptr [rsp + 8], 0x30e108
    0x141757b0b: 48 b9 a6 f5 88 ce 11 9f 9a 12    movabs   rcx, 0x129a9f11ce88f5a6
    0x141757b15: e8 36 c3 33 00                   call     0x141a93e50
    0x141757b1a: 66 f7 5c 24 30                   neg      word ptr [rsp + 0x30]
    0x141757b1f: 48 87 44 24 60                   xchg     qword ptr [rsp + 0x60], rax
    0x141757b24: ff 74 24 50                      push     qword ptr [rsp + 0x50]
    0x141757b28: 9d                               popfq
    0x141757b29: 48 8d 64 24 60                   lea      rsp, [rsp + 0x60]
    0x141757b2e: c3                               ret

### call_1415844d3 0x1415844d3–0x1415854d3（4096 字节）
解码指令数 73，覆盖 343 字节；direct edges=10，RIP refs=0。
    0x1415844d3: 48 bd 25 90 a6 90 9a 91 93 27    movabs   rbp, 0x2793919a90a69025
    0x1415844dd: 9c                               pushfq
    0x1415844de: 48 81 ed b9 59 20 20             sub      rbp, 0x202059b9
    0x1415844e5: 0f 88 01 db 2e 00                js       0x141871fec
    0x1415844eb: 0f 85 fb 69 48 00                jne      0x141a0aeec
    0x1415844f1: 66 c1 64 24 18 6e                shl      word ptr [rsp + 0x18], 0x6e
    0x1415844f7: 41 50                            push     r8
    0x1415844f9: 4c 8b 44 24 20                   mov      r8, qword ptr [rsp + 0x20]
    0x1415844fe: 41 55                            push     r13
    0x141584500: 45 23 c2                         and      r8d, r10d
    0x141584503: 0f 86 d4 53 43 00                jbe      0x1419b98dd
    0x141584509: 48 8d 6d 01                      lea      rbp, [rbp + 1]
    0x14158450d: 49 f7 d2                         not      r10
    0x141584510: 0f 88 f4 cd 11 00                js       0x1416a130a
    0x141584516: 59                               pop      rcx
    0x141584517: e8 e2 66 3f 00                   call     0x14197abfe
    0x14158451c: 49 f7 d0                         not      r8
    0x14158451f: 40 80 f6 36                      xor      sil, 0x36
    0x141584523: 0f 85 a8 20 bf ff                jne      0x1411765d1
    0x141584529: 53                               push     rbx
    0x14158452a: 48 bb b6 b8 09 11 0a e1 97 b2    movabs   rbx, 0xb297e10a1109b8b6
    0x141584534: e8 b3 30 0b 00                   call     0x1416375ec
    0x141584539: 48 81 44 24 00 f8 f6 b6 be       add      qword ptr [rsp], -0x41490908
    0x141584542: 66 f7 44 24 30 2e e0             test     word ptr [rsp + 0x30], 0xe02e
    0x141584549: 48 8b 6c 24 28                   mov      rbp, qword ptr [rsp + 0x28]
    0x14158454e: ba b6 82 80 6e                   mov      edx, 0x6e8082b6
    0x141584553: f6 94 14 7a 7d 7f 91             not      byte ptr [rsp + rdx - 0x6e808286]
    0x14158455a: e8 0c 9f 24 00                   call     0x1417ce46b
    0x14158455f: 48 c7 44 24 00 56 93 be 8e       mov      qword ptr [rsp], 0xffffffff8ebe9356
    0x141584568: e8 dd b6 94 00                   call     0x141ecfc4a
    0x14158456d: 41 53                            push     r11
    0x14158456f: 48 8b 54 24 38                   mov      rdx, qword ptr [rsp + 0x38]
    0x141584574: 48 8b 12                         mov      rdx, qword ptr [rdx]
    0x141584577: 48 89 7c 24 38                   mov      qword ptr [rsp + 0x38], rdi
    0x14158457c: 4c 8b 44 24 38                   mov      r8, qword ptr [rsp + 0x38]
    0x141584581: 41 51                            push     r9
    0x141584583: 49 bb 3b 1c 30 2c b4 ff 8a 13    movabs   r11, 0x138affb42c301c3b
    0x14158458d: 48 8d 92 9b f6 15 b4             lea      rdx, [rdx - 0x4bea0965]
    0x141584594: 66 45 85 d9                      test     r9w, r11w
    0x141584598: 4e 8d 1c c5 a6 5a 02 c6          lea      r11, [r8*8 - 0x39fda55a]
    0x1415845a0: 0f 84 43 ae 05 00                je       0x1415df3e9
    0x1415845a6: 66 44 33 64 24 03                xor      r12w, word ptr [rsp + 3]
    0x1415845ac: 66 41 f7 d9                      neg      r9w
    0x1415845b0: 66 45 33 c8                      xor      r9w, r8w
    0x1415845b4: 41 57                            push     r15
    0x1415845b6: 4c 8b 7c 24 48                   mov      r15, qword ptr [rsp + 0x48]
    0x1415845bb: 48 87 54 24 78                   xchg     qword ptr [rsp + 0x78], rdx
    0x1415845c0: 4c 8b 4c 24 30                   mov      r9, qword ptr [rsp + 0x30]
    0x1415845c5: 49 c1 ec 63                      shr      r12, 0x63
    0x1415845c9: 66 44 33 64 24 0e                xor      r12w, word ptr [rsp + 0xe]
    0x1415845cf: e8 09 53 06 00                   call     0x1415e98dd
    0x1415845d4: 44 00 74 24 20                   add      byte ptr [rsp + 0x20], r14b
    0x1415845d9: 4c 8b d9                         mov      r11, rcx
    0x1415845dc: 41 c1 e6 5b                      shl      r14d, 0x5b
    0x1415845e0: 41 50                            push     r8
    0x1415845e2: 49 8b eb                         mov      rbp, r11
    0x1415845e5: 66 44 0f b6 5c 24 2c             movzx    r11w, byte ptr [rsp + 0x2c]
    0x1415845ec: 48 87 74 24 58                   xchg     qword ptr [rsp + 0x58], rsi
    0x1415845f1: 48 8b 6c 24 10                   mov      rbp, qword ptr [rsp + 0x10]
    0x1415845f6: 0f 48 4c 24 29                   cmovs    ecx, dword ptr [rsp + 0x29]
    0x1415845fb: 0f 98 44 24 40                   sets     byte ptr [rsp + 0x40]
    0x141584600: 4d 0b f6                         or       r14, r14
    0x141584603: 4c 63 9c 0c fb d9 a6 ff          movsxd   r11, dword ptr [rsp + rcx - 0x592605]
    0x14158460b: 4a f7 94 1c 4f d2 d9 a6          not      qword ptr [rsp + r11 - 0x59262db1]
    0x141584613: 4c 8b 5c 24 18                   mov      r11, qword ptr [rsp + 0x18]
    0x141584618: 0f 85 43 d0 2e 00                jne      0x141871661
    0x14158461e: 3a ce                            cmp      cl, dh
    0x141584620: 50                               push     rax
    0x141584621: cf                               iretd
    0x141584622: fb                               sti
    0x141584623: 7f 00                            jg       0x141584625
    0x141584625: 00 0f                            add      byte ptr [rdi], cl
    0x141584627: 80 08 f1                         or       byte ptr [rax], 0xf1

### call_1419060e7 0x1419060e7–0x1419070e7（4096 字节）
解码指令数 32，覆盖 127 字节；direct edges=5，RIP refs=2。
    0x1419060e7: e8 ce e6 fd ff                   call     0x1418e47ba
    0x1419060ec: 41 56                            push     r14
    0x1419060ee: 49 be a6 60 8d 84 a3 67 8b 91    movabs   r14, 0x918b67a3848d60a6
    0x1419060f8: 0f 87 07 00 00 00                ja       0x141906105
    0x1419060fe: b1 0c                            mov      cl, 0xc
    0x141906100: 48 8b 4c 24 10                   mov      rcx, qword ptr [rsp + 0x10]
    0x141906105: 48 c7 44 24 10 91 ec 51 7c       mov      qword ptr [rsp + 0x10], 0x7c51ec91
    0x14190610e: 4c 8b 74 24 00                   mov      r14, qword ptr [rsp]
    0x141906113: e8 cb 1b ea fe                   call     0x1407a7ce3
    0x141906118: 50                               push     rax
    0x141906119: e8 88 85 88 ff                   call     0x14118e6a6
    0x14190611e: e8 b4 9f 02 00                   call     0x1419300d7
    0x141906123: 1c 4c                            sbb      al, 0x4c
    0x141906125: d9 71 09                         fnstenv  [rcx + 9]
    0x141906128: 85 25 41 ff 72 09                test     dword ptr [rip + 0x972ff41], esp
    0x14190612e: 25 ad a1 ff 72                   and      eax, 0x72ffa1ad
    0x141906133: 09 c5                            or       ebp, eax
    0x141906135: 35 09 ff 72 09                   xor      eax, 0x972ff09
    0x14190613a: 6d                               insd     dword ptr [rdi], dx
    0x14190613b: b5 d9                            mov      ch, 0xd9
    0x14190613d: ff 72 09                         push     qword ptr [rdx + 9]
    0x141906140: bd c5 3c c2 87                   mov      ebp, 0x87c23cc5
    0x141906145: f6 6c 1b 13                      imul     byte ptr [rbx + rbx + 0x13]
    0x141906149: 39 7d 7e                         cmp      dword ptr [rbp + 0x7e], edi
    0x14190614c: 09 f1                            or       ecx, esi
    0x14190614e: 21 15 01 8d f6 71                and      dword ptr [rip + 0x71f68d01], edx
    0x141906154: 56                               push     rsi
    0x141906155: e4 3d                            in       al, 0x3d
    0x141906157: e4 80                            in       al, 0x80
    0x141906159: c5 3b 5e 8d 45 9d ac 33          vdivsd   xmm9, xmm8, qword ptr [rbp + 0x33ac9d45]
    0x141906161: a4                               movsb    byte ptr [rdi], byte ptr [rsi]
    0x141906162: 65 08 66 b5                      or       byte ptr gs:[rsi - 0x4b], ah

### call_14171631b 0x14171631b–0x14171731b（4096 字节）
解码指令数 29，覆盖 152 字节；direct edges=5，RIP refs=0。
    0x14171631b: 48 81 44 24 00 97 29 c5 fe       add      qword ptr [rsp], -0x13ad669
    0x141716324: 48 f7 5c 24 18                   neg      qword ptr [rsp + 0x18]
    0x141716329: 0f 9c 44 24 18                   setl     byte ptr [rsp + 0x18]
    0x14171632e: 55                               push     rbp
    0x14171632f: 66 44 21 64 24 20                and      word ptr [rsp + 0x20], r12w
    0x141716335: 4f 8d a4 24 0c 91 1e 6d          lea      r12, [r12 + r12 + 0x6d1e910c]
    0x14171633d: 49 81 ed 31 71 aa b7             sub      r13, -0x48558ecf
    0x141716344: 0f 82 fd 47 fe ff                jb       0x1416fab47
    0x14171634a: 9c                               pushfq
    0x14171634b: 48 bb b2 ee ac ac 37 42 3e 86    movabs   rbx, 0x863e4237acaceeb2
    0x141716355: 41 56                            push     r14
    0x141716357: 48 89 74 24 38                   mov      qword ptr [rsp + 0x38], rsi
    0x14171635c: 85 da                            test     edx, ebx
    0x14171635e: 49 be 2c 8b 3e 05 1f f3 8b 77    movabs   r14, 0x778bf31f053e8b2c
    0x141716368: 41 51                            push     r9
    0x14171636a: e8 14 2e a7 ff                   call     0x141189183
    0x14171636f: 48 89 6c 24 30                   mov      qword ptr [rsp + 0x30], rbp
    0x141716374: 48 81 44 24 48 8c 1f 23 00       add      qword ptr [rsp + 0x48], 0x231f8c
    0x14171637d: 41 56                            push     r14
    0x14171637f: 44 3a 7c 24 3d                   cmp      r15b, byte ptr [rsp + 0x3d]
    0x141716384: 48 bf 98 37 11 cd 91 16 36 00    movabs   rdi, 0x361691cd113798
    0x14171638e: 4c 8b 74 24 38                   mov      r14, qword ptr [rsp + 0x38]
    0x141716393: 0f 88 18 fd e8 ff                js       0x1415a60b1
    0x141716399: 5d                               pop      rbp
    0x14171639a: 9c                               pushfq
    0x14171639b: e8 38 b6 de ff                   call     0x1415019d8
    0x1417163a0: 42 c0 a4 2c 40 26 ff ff 38       shl      byte ptr [rsp + r13 - 0xd9c0], 0x38
    0x1417163a9: e8 8d 02 08 00                   call     0x14179663b
    0x1417163ae: e8 74 0c d7 ff                   call     0x141487027

### call_141a93e50 0x141a93e50–0x141a93f11（193 字节）
解码指令数 35，覆盖 193 字节；direct edges=6，RIP refs=0。
    0x141a93e50: 41 56                            push     r14
    0x141a93e52: 80 c1 08                         add      cl, 8
    0x141a93e55: 48 8b 4c 24 18                   mov      rcx, qword ptr [rsp + 0x18]
    0x141a93e5a: 48 8b 09                         mov      rcx, qword ptr [rcx]
    0x141a93e5d: 49 be 33 d2 09 73 80 25 ad 29    movabs   r14, 0x29ad25807309d233
    0x141a93e67: 49 81 f6 aa 02 11 9f             xor      r14, 0xffffffff9f1102aa
    0x141a93e6e: 41 80 ee 88                      sub      r14b, 0x88
    0x141a93e72: 0f 8c 20 cc c2 ff                jl       0x1416c0a98
    0x141a93e78: 0f 80 d5 95 fc ff                jo       0x141a5d453
    0x141a93e7e: 66 41 c1 ee d9                   shr      r14w, 0xd9
    0x141a93e83: 41 81 e6 28 6b 85 23             and      r14d, 0x23856b28
    0x141a93e8a: 4e 89 b4 74 18 00 00 c0          mov      qword ptr [rsp + r14*2 - 0x3fffffe8], r14
    0x141a93e92: 4a 8d 8c 31 1b 1e 34 ef          lea      rcx, [rcx + r14 - 0x10cbe1e5]
    0x141a93e9a: 66 41 be 3e af                   mov      r14w, 0xaf3e
    0x141a93e9f: 66 46 03 b4 74 9d a1 fe bf       add      r14w, word ptr [rsp + r14*2 - 0x40015e63]
    0x141a93ea8: 4a 81 84 34 ca 50 ff df e6 84 8a be add      qword ptr [rsp + r14 - 0x2000af36], -0x41757b1a
    0x141a93eb4: 46 08 b4 74 9c a1 fe bf          or       byte ptr [rsp + r14*2 - 0x40015e64], r14b
    0x141a93ebc: 4a 87 8c 34 ea 50 ff df          xchg     qword ptr [rsp + r14 - 0x2000af16], rcx
    0x141a93ec4: 4e 8b b4 74 84 a1 fe bf          mov      r14, qword ptr [rsp + r14*2 - 0x40015e7c]
    0x141a93ecc: 0f 81 d1 4b c2 ff                jno      0x1416b8aa3
    0x141a93ed2: 55                               push     rbp
    0x141a93ed3: e8 ac e4 e7 ff                   call     0x141912384
    0x141a93ed8: 41 f7 d6                         not      r14d
    0x141a93edb: 4e 89 b4 34 98 7d 08 bf          mov      qword ptr [rsp + r14 - 0x40f78268], r14
    0x141a93ee3: e8 9b 84 6f ff                   call     0x14118c383
    0x141a93ee8: e8 a7 2f a7 ff                   call     0x141506e94
    0x141a93eed: e8 c5 58 ae ff                   call     0x1415797b7
    0x141a93ef2: e8 f2 11 e8 ff                   call     0x1419150e9
    0x141a93ef7: 4c 8b 74 24 50                   mov      r14, qword ptr [rsp + 0x50]
    0x141a93efc: ff 74 24 70                      push     qword ptr [rsp + 0x70]
    0x141a93f00: 9d                               popfq
    0x141a93f01: 4c 8b 6c 24 58                   mov      r13, qword ptr [rsp + 0x58]
    0x141a93f06: 4c 8b 54 24 48                   mov      r10, qword ptr [rsp + 0x48]
    0x141a93f0b: 48 8d 64 24 78                   lea      rsp, [rsp + 0x78]
    0x141a93f10: c3                               ret

## 当前仍未闭合的量

- RC00 调用者传入的 0x10c 字节缓冲区，在完整运行时函数链中的读写位置和返回契约。
- RC03 decode_failed 使用的返回值、marker 和输出/副作用。
- 运行时函数链是否继续进入驱动或仅在用户态完成变换。
- 最终本地结果的文件、注册表、设备或其他副作用。

因此 C81 将状态从“缺少完整 .Sq> 字节”推进为“完整页面已取得，可进行离线调用图和数据流追踪”，但不宣称核心解码已经完成。

## 可复核材料

- 原始范围：artifacts/captures/stream_SQSCAN_20260921A/sq_runtime_range.bin
- 页清单：artifacts/captures/stream_SQSCAN_20260921A/sq_runtime_pages.jsonl
- 采集日志：artifacts/captures/stream_SQSCAN_20260921A/scan.log
- 生成器：<HOST_PATH>/vmctl/scan_sq_runtime_range.ps1
- 分析器：<HOST_PATH>/vmctl/analyze_sq_runtime_range.py
