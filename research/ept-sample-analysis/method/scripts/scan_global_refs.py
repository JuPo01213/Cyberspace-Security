#!/usr/bin/env python3
"""Disassemble a runtime .text dump with capstone and report RIP-relative
references to a VA window, separating reads from writes.

Used to locate every producer/consumer of the EPT session-key block
0x14115c340..0x14115c358 in the runtime (decoded) code image.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from capstone import CS_ARCH_X86, CS_MODE_64, Cs
from capstone.x86 import X86_OP_MEM, X86_REG_RIP

WRITE_MNEMONICS = {
    "mov", "movups", "movaps", "movdqu", "movdqa", "movd", "movq", "movsd",
    "movss", "vmovups", "vmovdqu", "vmovaps", "lea_placeholder",
}
# mnemonic -> destination operand index (0) writes; capstone gives operands
# with the destination first for x86.
STORE_PREFIXES = ("mov", "stos", "xchg", "add", "sub", "xor", "or", "and", "inc", "dec", "not", "neg")


def is_write(insn) -> bool:
    if not insn.operands:
        return False
    dst = insn.operands[0]
    if dst.type != X86_OP_MEM:
        return False
    mnemonic = insn.mnemonic
    if mnemonic.startswith("cmp") or mnemonic.startswith("test") or mnemonic in {"mov", "movzx", "movsx", "movsxd"}:
        pass
    return mnemonic.startswith(STORE_PREFIXES)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("dump", type=Path)
    ap.add_argument("--base", default="0x140100000")
    ap.add_argument("--lo", default="0x14115c340")
    ap.add_argument("--hi", default="0x14115c358")
    ap.add_argument("--entry", default=None, help="only disassemble from this VA")
    ap.add_argument("--stop", default=None, help="stop at this VA")
    ap.add_argument("--context", type=int, default=0, help="instructions of context around each hit")
    args = ap.parse_args()

    blob = args.dump.read_bytes()
    base = int(args.base, 0)
    lo, hi = int(args.lo, 0), int(args.hi, 0)
    entry = int(args.entry, 0) if args.entry else base
    stop = int(args.stop, 0) if args.stop else base + len(blob)

    md = Cs(CS_ARCH_X86, CS_MODE_64)
    md.detail = True

    text = blob[entry - base : stop - base]
    insns = list(md.disasm(text, entry))
    print(f"dump      {args.dump}  ({len(blob)} bytes at {base:#x})")
    print(f"window    {entry:#x}..{entry + len(text):#x}  decoded {len(insns)} instructions")
    print(f"watching  {lo:#x}..{hi:#x}")
    hits = []
    for index, insn in enumerate(insns):
        for op_index, op in enumerate(insn.operands):
            if op.type != X86_OP_MEM:
                continue
            if op.mem.base == X86_REG_RIP:
                target = insn.address + insn.size + op.mem.disp
            elif op.mem.base == 0 and op.mem.index == 0:
                target = op.mem.disp
            else:
                continue
            if lo <= target < hi:
                # a memory operand writes only when it is the destination
                writes = is_write(insn) and op_index == 0
                hits.append((index, insn, target, writes))
    print(f"hits      {len(hits)}")
    for index, insn, target, write in hits:
        tag = "WRITE" if write else "read "
        print(f"  {insn.address:#014x} {tag} -> {target:#x}   {insn.mnemonic} {insn.op_str}")
    if args.context:
        print("\n=== context ===")
        shown = set()
        for index, _insn, _t, _w in hits:
            for j in range(max(0, index - args.context), min(len(insns), index + args.context + 1)):
                if j in shown:
                    continue
                shown.add(j)
                insn = insns[j]
                mark = ">>" if (j, insn, None, None)[0] == index else "  "
                print(f"{mark} {insn.address:#014x}  {insn.mnemonic:<10} {insn.op_str}")
            print("   ---")
    return 0


if __name__ == "__main__":
    sys.exit(main())
