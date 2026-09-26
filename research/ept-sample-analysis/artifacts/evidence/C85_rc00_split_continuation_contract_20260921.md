# C85 — RC00 split-continuation and local call contract

This report is offline and read-only. It does not execute Hardware.genB.exe, decode the embedded authorization token, or contact the VM/network.

## Evidence and address model

- text: `<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_text.bin`; bytes=8257536; sha256=`5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757`
- pdata: `<HOST_PATH>\EPT\artifacts\evidence\genB_functions_from_pdata.tsv`; sha256=`698f4bd6f2d1f610026e940c0ea5dff9baeb047437b35d64ec3046a7c024dd31`; text rows=1694; decoded rows=1694; decode failures=0
- mapping: `VA = 0x140000000 + stream_text_offset`; captured range `0x140000000..0x1407e0000` (end exclusive)
- logical communication block examined: `0x14078ece0..0x14078f025`

## `.pdata` split around RC00

- `0x14078ece0..0x14078ed32` size=0x82 unwind=0x140f9626c
- `0x14078ed32..0x14078ed39` size=0x7 unwind=0x140f96284 [RC00_PRE]
- `0x14078ed39..0x14078ee89` size=0x336 unwind=0x140f96298 [RC00]
- `0x14078ee89..0x14078eee6` size=0x93 unwind=0x140f962ac [RC03]

The `0x14078ed32..0x14078ed39` row ends exactly where the `0x14078ed39` row begins. The last predecessor instruction is a three-byte `xor r9d,r9d` ending at `0x14078ed39`; this is a fall-through continuation, not a normal call entry.

### Direct edges and fall-through evidence

- `0x14078ed32` (RC00 continuation predecessor): direct_edges=0; fallthrough_edges=1
  - fall-through from row `0x14078ece0` via instruction `0x14078ed2e` size=0x4
- `0x14078ed39` (RC00 candidate continuation): direct_edges=0; fallthrough_edges=1
  - fall-through from row `0x14078ed32` via instruction `0x14078ed36` size=0x3
- `0x14078ee89` (RC03 validator continuation): direct_edges=0; fallthrough_edges=0
- `0x14078f025` (RC01 invalid-state continuation): direct_edges=3; fallthrough_edges=1
  - `je` at `0x14078ed14` from row `0x14078ece0`
  - `je` at `0x14078ed20` from row `0x14078ece0`
  - `je` at `0x14078ed28` from row `0x14078ece0`
  - fall-through from row `0x14078ef02` via instruction `0x14078f020` size=0x5
- `0x14078ce60` (local 0x10c-byte transform candidate): direct_edges=2; fallthrough_edges=0
  - `call` at `0x14078ee27` from row `0x14078ed39`
  - `call` at `0x14078ef47` from row `0x14078ef02`
- `0x14078d900` (local 16-byte state builder candidate): direct_edges=1; fallthrough_edges=0
  - `call` at `0x14078ee31` from row `0x14078ed39`
- `0x14078db80` (response/marker validator candidate): direct_edges=1; fallthrough_edges=0
  - `call` at `0x14078ee9b` from row `0x14078ee89`
- `0x141757acd` (out-of-capture call target): direct_edges=1; fallthrough_edges=0
  - `call` at `0x14078ee73` from row `0x14078ed39`

## Row-local disassembly (the split must be decoded per row)

### `0x14078ece0..0x14078ed32`
`0x00014078ed10: 48 83 fe ff                  cmp      rsi, -1`
`0x00014078ed14: 0f 84 0b 03 00 00            je       0x14078f025`
`0x00014078ed1a: 48 8b 09                     mov      rcx, qword ptr [rcx]`
`0x00014078ed1d: 48 85 c9                     test     rcx, rcx`
`0x00014078ed20: 0f 84 ff 02 00 00            je       0x14078f025`
`0x00014078ed26: 85 d2                        test     edx, edx`
`0x00014078ed28: 0f 84 f7 02 00 00            je       0x14078f025`
`0x00014078ed2e: 48 8d 41 08                  lea      rax, [rcx + 8]`

### `0x14078ed32..0x14078ed39`
`0x00014078ed32: 49 89 5b 10                  mov      qword ptr [r11 + 0x10], rbx`
`0x00014078ed36: 45 33 c9                     xor      r9d, r9d`

### `0x14078ed39..0x14078ee89`
`0x00014078ed39: 49 89 6b 18                  mov      qword ptr [r11 + 0x18], rbp`
`0x00014078ed3d: 8b 2d 25 d6 9c 00            mov      ebp, dword ptr [rip + 0x9cd625]  ; rip_ref=0x14115c368 [rg2 +0x35c368, non-printable/requires data interpretation]`
`0x00014078ed43: 48 85 c0                     test     rax, rax`
`0x00014078ed46: 74 39                        je       0x14078ed81`
`0x00014078ed48: 80 38 00                     cmp      byte ptr [rax], 0`
`0x00014078ed4b: 74 34                        je       0x14078ed81`
`0x00014078ed4d: 80 78 01 00                  cmp      byte ptr [rax + 1], 0`
`0x00014078ed51: 74 2b                        je       0x14078ed7e`
`0x00014078ed53: 80 78 02 00                  cmp      byte ptr [rax + 2], 0`
`0x00014078ed57: 74 1f                        je       0x14078ed78`
`0x00014078ed59: 80 78 03 00                  cmp      byte ptr [rax + 3], 0`
`0x00014078ed5d: 74 13                        je       0x14078ed72`
`0x00014078ed5f: 48 83 c0 04                  add      rax, 4`
`0x00014078ed63: 41 83 c1 04                  add      r9d, 4`
`0x00014078ed67: 41 81 f9 00 01 00 00         cmp      r9d, 0x100`
`0x00014078ed6e: 72 d8                        jb       0x14078ed48`
`0x00014078ed70: eb 0f                        jmp      0x14078ed81  ; direct_target=0x14078ed81`
`0x00014078ed72: 41 83 c1 03                  add      r9d, 3`
`0x00014078ed76: eb 09                        jmp      0x14078ed81  ; direct_target=0x14078ed81`
`0x00014078ed78: 41 83 c1 02                  add      r9d, 2`
`0x00014078ed7c: eb 03                        jmp      0x14078ed81  ; direct_target=0x14078ed81`
`0x00014078ed7e: 41 ff c1                     inc      r9d`
`0x00014078ed81: 44 0f be 81 08 01 00 00      movsx    r8d, byte ptr [rcx + 0x108]`
`0x00014078ed89: 48 8d 3d 60 d6 9c 00         lea      rdi, [rip + 0x9cd660]  ; rip_ref=0x14115c3f0 [rg2 +0x35c3f0, non-printable/requires data interpretation]`
`0x00014078ed90: 89 54 24 30                  mov      dword ptr [rsp + 0x30], edx`
`0x00014078ed94: 8b 51 04                     mov      edx, dword ptr [rcx + 4]`
`0x00014078ed97: 48 8d 0d 12 ea 7f 00         lea      rcx, [rip + 0x7fea12]  ; rip_ref=0x140f8d7b0 [rg2 ASCII 'RC00 send mode=%lu serialMode=%d diskLen=%lu comm=%s ioctlRun=0x%08lX session=0x%08lX']`
`0x00014078ed9e: 89 6c 24 28                  mov      dword ptr [rsp + 0x28], ebp`
`0x00014078eda2: 48 89 7c 24 20               mov      qword ptr [rsp + 0x20], rdi`
`0x00014078eda7: e8 b4 df ff ff               call     0x14078cd60  ; direct_target=0x14078cd60`
`0x00014078edac: 49 8b 0e                     mov      rcx, qword ptr [r14]`
`0x00014078edaf: 48 8d 54 24 60               lea      rdx, [rsp + 0x60]`
`0x00014078edb4: 0f 57 c0                     xorps    xmm0, xmm0`
`0x00014078edb7: bb 02 00 00 00               mov      ebx, 2`
`0x00014078edbc: 0f 11 44 24 50               movups   xmmword ptr [rsp + 0x50], xmm0`
`0x00014078edc1: 8b c3                        mov      eax, ebx`
`0x00014078edc3: 48 8d 92 80 00 00 00         lea      rdx, [rdx + 0x80]`
`0x00014078edca: 0f 10 01                     movups   xmm0, xmmword ptr [rcx]`
`0x00014078edcd: 48 8d 89 80 00 00 00         lea      rcx, [rcx + 0x80]`
`0x00014078edd4: 0f 11 42 80                  movups   xmmword ptr [rdx - 0x80], xmm0`
`0x00014078edd8: 0f 10 49 90                  movups   xmm1, xmmword ptr [rcx - 0x70]`
`0x00014078eddc: 0f 11 4a 90                  movups   xmmword ptr [rdx - 0x70], xmm1`
`0x00014078ede0: 0f 10 41 a0                  movups   xmm0, xmmword ptr [rcx - 0x60]`
`0x00014078ede4: 0f 11 42 a0                  movups   xmmword ptr [rdx - 0x60], xmm0`
`0x00014078ede8: 0f 10 49 b0                  movups   xmm1, xmmword ptr [rcx - 0x50]`
`0x00014078edec: 0f 11 4a b0                  movups   xmmword ptr [rdx - 0x50], xmm1`
`0x00014078edf0: 0f 10 41 c0                  movups   xmm0, xmmword ptr [rcx - 0x40]`
`0x00014078edf4: 0f 11 42 c0                  movups   xmmword ptr [rdx - 0x40], xmm0`
`0x00014078edf8: 0f 10 49 d0                  movups   xmm1, xmmword ptr [rcx - 0x30]`
`0x00014078edfc: 0f 11 4a d0                  movups   xmmword ptr [rdx - 0x30], xmm1`
`0x00014078ee00: 0f 10 41 e0                  movups   xmm0, xmmword ptr [rcx - 0x20]`
`0x00014078ee04: 0f 11 42 e0                  movups   xmmword ptr [rdx - 0x20], xmm0`
`0x00014078ee08: 0f 10 49 f0                  movups   xmm1, xmmword ptr [rcx - 0x10]`
`0x00014078ee0c: 0f 11 4a f0                  movups   xmmword ptr [rdx - 0x10], xmm1`
`0x00014078ee10: 48 83 e8 01                  sub      rax, 1`
`0x00014078ee14: 75 ad                        jne      0x14078edc3`
`0x00014078ee16: 48 8b 01                     mov      rax, qword ptr [rcx]`
`0x00014078ee19: 48 89 02                     mov      qword ptr [rdx], rax`
`0x00014078ee1c: 8b 41 08                     mov      eax, dword ptr [rcx + 8]`
`0x00014078ee1f: 48 8d 4c 24 60               lea      rcx, [rsp + 0x60]`
`0x00014078ee24: 89 42 08                     mov      dword ptr [rdx + 8], eax`
`0x00014078ee27: e8 34 e0 ff ff               call     0x14078ce60  ; direct_target=0x14078ce60`
`0x00014078ee2c: 48 8d 4c 24 50               lea      rcx, [rsp + 0x50]`
`0x00014078ee31: e8 ca ea ff ff               call     0x14078d900  ; direct_target=0x14078d900`
`0x00014078ee36: 48 c7 44 24 38 00 00 00 00   mov      qword ptr [rsp + 0x38], 0`
`0x00014078ee3f: 48 8d 44 24 40               lea      rax, [rsp + 0x40]`
`0x00014078ee44: 48 89 44 24 30               mov      qword ptr [rsp + 0x30], rax`
`0x00014078ee49: 4c 8d 44 24 50               lea      r8, [rsp + 0x50]`
`0x00014078ee4e: 48 8d 44 24 50               lea      rax, [rsp + 0x50]`
`0x00014078ee53: c7 44 24 28 1c 01 00 00      mov      dword ptr [rsp + 0x28], 0x11c`
`0x00014078ee5b: 41 b9 1c 01 00 00            mov      r9d, 0x11c`
`0x00014078ee61: 48 89 44 24 20               mov      qword ptr [rsp + 0x20], rax`
`0x00014078ee66: 8b d5                        mov      edx, ebp`
`0x00014078ee68: c7 44 24 40 00 00 00 00      mov      dword ptr [rsp + 0x40], 0`
`0x00014078ee70: 48 8b ce                     mov      rcx, rsi`
`0x00014078ee73: e8 55 8c fc 00               call     0x141757acd  ; direct_target=0x141757acd`
`0x00014078ee78: 00 48 8b                     add      byte ptr [rax - 0x75], cl`
`0x00014078ee7b: ac                           lodsb    al, byte ptr [rsi]`
`0x00014078ee7c: 24 b0                        and      al, 0xb0`
`0x00014078ee7e: 01 00                        add      dword ptr [rax], eax`
`0x00014078ee80: 00 85 c0 0f 84 60            add      byte ptr [rbp + 0x60840fc0], al`
`0x00014078ee86: 01 00                        add      dword ptr [rax], eax`

### `0x14078ee89..0x14078eee6`
`0x00014078ee89: 48 8d 54 24 44               lea      rdx, [rsp + 0x44]`
`0x00014078ee8e: c7 44 24 44 00 00 00 00      mov      dword ptr [rsp + 0x44], 0`
`0x00014078ee96: 48 8d 4c 24 50               lea      rcx, [rsp + 0x50]`
`0x00014078ee9b: e8 e0 ec ff ff               call     0x14078db80  ; direct_target=0x14078db80`
`0x00014078eea0: 85 c0                        test     eax, eax`
`0x00014078eea2: 75 5e                        jne      0x14078ef02`

## Recovered local data-flow contract

The following facts are tied to the row-local instructions above; names such as `source` and `state` describe storage roles, not recovered semantic names.

- The logical block first checks `rsi`, dereferences `rcx` once, and forms `rax = rcx + 8` before the split at `0x14078ed39`. Therefore `0x14078ed39` consumes live state produced before its `.pdata` row: at minimum `r11`, `rbp`, and `rax`; the continuation later also consumes `rcx`, `r14`, `rsi`, and the argument registers used for logging/call setup.
- At `0x14078edac`, the code loads `source = qword ptr [r14]` and sets `destination = rsp + 0x60`. Two iterations copy `0x100` bytes with `movups`, followed by `8 + 4` bytes; the prepared local buffer is therefore exactly `0x10c` bytes.
- At `0x14078ee1f` the continuation passes `RCX = rsp + 0x60` to `0x14078ce60`. The captured function body writes through that pointer in place for `0x10c` iterations and returns; this proves a local in-place transform stage, but not whether it is the final decode direction.
- `rsp + 0x50` is zeroed for `0x10` bytes before the call at `0x14078ee31`, which passes that address to `0x14078d900`. The captured body of `0x14078d900` writes four dwords at offsets `0,4,8,c`; this is a local 16-byte state-building stage, not an observed output file or decoded payload.
- Immediately before `0x14078ee73`, the call contract is: `RCX = RSI`, `RDX = EBP`, `R8 = RSP+0x50`, `R9 = 0x11c`, stack `[rsp+0x20] = RSP+0x50`, `[rsp+0x28] = 0x11c`, `[rsp+0x30] = RSP+0x40`, `[rsp+0x38] = 0`, and `[rsp+0x40] = 0`. The target `0x141757acd` is outside the recovered plaintext `.text`; its user/driver/network meaning remains unresolved here and is outside the local-only core.
- The row beginning at `0x14078ee89` passes `rsp + 0x50` into `0x14078db80`; that function returns a boolean-style value and is followed by the `RC03 decode_failed` logging branch. This is a response/marker validation path, not proof of a standalone decoder output.

## Bounded conclusion

- CONFIRMED: `0x14078ed39` is a split continuation, not a safe standalone harness entry.
- CONFIRMED: the candidate local stages prepare and transform a `0x10c`-byte stack buffer and build a 16-byte state block before the out-of-capture call.
- NOT CONFIRMED: the final local decode algorithm, output semantics, or a driver-free end-to-end result.
- NOT JUSTIFIED: another direct call to `0x14078ed39`, `main`, or a generic long VM wait. A useful dynamic run must arm the logical predecessor/continuation with a valid caller context and observe the local buffer before/after `0x14078ce60` or the actual post-target return boundary.
- Status: `INCOMPLETE / CONTINUATION_CONTEXT_CLOSED_ONLY`.
