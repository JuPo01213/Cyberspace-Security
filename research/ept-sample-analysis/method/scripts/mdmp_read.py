#!/usr/bin/env python3
"""Read-only reader for a Windows user-mode minidump (MDMP).

Reads virtual addresses out of the dump without loading the image, so runtime
globals can be inspected offline.
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path


class MiniDump:
    def __init__(self, path: Path):
        self.path = path
        self.blob = path.read_bytes()
        if self.blob[:4] != b"MDMP":
            raise ValueError("not a minidump (no MDMP signature)")
        version, nstreams, dir_rva, _checksum, _ts, flags = struct.unpack_from(
            "<IIIIII", self.blob, 4
        )
        self.version = version
        self.flags = flags
        self.streams: dict[int, list[tuple[int, int]]] = {}
        for i in range(nstreams):
            st, sz, rva = struct.unpack_from("<III", self.blob, dir_rva + i * 12)
            self.streams.setdefault(st, []).append((sz, rva))
        self.ranges: list[tuple[int, int, int]] = []
        if 5 in self.streams:
            _sz, rva = self.streams[5][0]
            n = struct.unpack_from("<I", self.blob, rva)[0]
            for i in range(n):
                start, dsize, drva = struct.unpack_from("<QII", self.blob, rva + 4 + i * 16)
                self.ranges.append((start, dsize, drva))
        if 9 in self.streams:
            _sz, rva = self.streams[9][0]
            nranges, base_rva = struct.unpack_from("<QQ", self.blob, rva)
            off = base_rva
            for i in range(nranges):
                start, dsize = struct.unpack_from("<QQ", self.blob, rva + 16 + i * 16)
                self.ranges.append((start, dsize, off))
                off += dsize
        self.ranges.sort()

    def read(self, va: int, n: int) -> bytes:
        out = bytearray()
        cur = va
        for start, dsize, drva in self.ranges:
            if start <= cur < start + dsize:
                take = min(n - len(out), start + dsize - cur)
                off = drva + (cur - start)
                out += self.blob[off : off + take]
                cur += take
                if len(out) >= n:
                    break
        return bytes(out[:n])

    def describe(self, va: int) -> str:
        for start, dsize, _drva in self.ranges:
            if start <= va < start + dsize:
                return f"range {start:#x}+{dsize:#x} (offset {va - start:#x})"
        return "unmapped"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("dump", type=Path)
    ap.add_argument("vas", nargs="+")
    ap.add_argument("--length", type=int, default=32)
    args = ap.parse_args()
    dump = MiniDump(args.dump)
    print(f"dump            {args.dump}")
    print(f"mapped ranges   {len(dump.ranges)}  bytes={sum(r[1] for r in dump.ranges)}")
    print(f"streams         {sorted(dump.streams)}")
    for token in args.vas:
        va = int(token, 0)
        blob = dump.read(va, args.length)
        print(f"\nVA {va:#x}  [{dump.describe(va)}]")
        print(f"  bytes   {' '.join(f'{b:02x}' for b in blob)}")
        if len(blob) >= 4:
            words = struct.unpack_from("<" + "I" * (len(blob) // 4), blob, 0)
            print(f"  dwords  {[hex(w) for w in words]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
