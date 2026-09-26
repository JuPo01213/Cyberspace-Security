#!/usr/bin/env python3
"""Read-only PE RVA inspector: map virtual addresses to file offsets and dump bytes.

Used to check whether the EPT target's session-key globals (0x14115c340..0x14115c354)
are backed by static file data or only exist at runtime.
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path


def parse_sections(data: bytes) -> tuple[int, list[tuple[str, int, int, int, int]]]:
    if data[:2] != b"MZ":
        raise ValueError("not a PE file (no MZ)")
    e_lfanew = struct.unpack_from("<I", data, 0x3C)[0]
    if data[e_lfanew : e_lfanew + 4] != b"PE\0\0":
        raise ValueError("not a PE file (no PE signature)")
    coff = e_lfanew + 4
    _machine, n_sections = struct.unpack_from("<HH", data, coff)
    size_opt = struct.unpack_from("<H", data, coff + 16)[0]
    opt = coff + 20
    magic = struct.unpack_from("<H", data, opt)[0]
    if magic == 0x20B:
        image_base = struct.unpack_from("<Q", data, opt + 24)[0]
    elif magic == 0x10B:
        image_base = struct.unpack_from("<I", data, opt + 28)[0]
    else:
        raise ValueError(f"unknown optional header magic {magic:#x}")
    size_of_image = struct.unpack_from("<I", data, opt + 56)[0]
    section_table = opt + size_opt
    sections = []
    for i in range(n_sections):
        off = section_table + i * 40
        name = data[off : off + 8].rstrip(b"\0").decode("ascii", "replace")
        v_size, v_addr, raw_size, raw_ptr = struct.unpack_from("<IIII", data, off + 8)
        sections.append((name, v_addr, v_size, raw_ptr, raw_size))
    return image_base, sections, size_of_image


def find_section(
    sections: list[tuple[str, int, int, int, int]], rva: int
) -> tuple[str, int, int, int, int] | None:
    for sec in sections:
        name, v_addr, v_size, raw_ptr, raw_size = sec
        span = max(v_size, raw_size)
        if v_addr <= rva < v_addr + span:
            return sec
    return None


def read_rva(data: bytes, sections, image_base: int, va: int, length: int) -> tuple[bytes, dict]:
    rva = va - image_base
    sec = find_section(sections, rva)
    if sec is None:
        raise ValueError(f"VA {va:#x} (RVA {rva:#x}) is not inside any section")
    name, v_addr, v_size, raw_ptr, raw_size = sec
    inner = rva - v_addr
    info = {
        "section": name,
        "rva": rva,
        "section_va": v_addr,
        "section_vsize": v_size,
        "section_raw_size": raw_size,
        "within_raw": inner + length <= raw_size,
    }
    if inner >= raw_size:
        zeros = b"\0" * length
        info["bytes_are_file_backed"] = False
        return zeros, info
    chunk = data[raw_ptr + inner : raw_ptr + inner + length]
    info["bytes_are_file_backed"] = len(chunk) == length
    return chunk.ljust(length, b"\0"), info


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("image", type=Path)
    ap.add_argument("vas", nargs="+", help="virtual addresses, e.g. 0x14115c340")
    ap.add_argument("--length", type=int, default=0x20)
    args = ap.parse_args()
    data = args.image.read_bytes()
    image_base, sections, size_of_image = parse_sections(data)
    print(f"file            {args.image}")
    print(f"size            {len(data)}")
    print(f"image_base      {image_base:#x}")
    print(f"size_of_image   {size_of_image:#x}")
    print(f"sections        {len(sections)}")
    for name, v_addr, v_size, raw_ptr, raw_size in sections:
        print(f"  {name:<10} VA {image_base + v_addr:#012x} vsize {v_size:#09x} raw {raw_ptr:#09x}+{raw_size:#09x}")
    for token in args.vas:
        va = int(token, 0)
        blob, info = read_rva(data, sections, image_base, va, args.length)
        hexs = " ".join(f"{b:02x}" for b in blob)
        words = struct.unpack_from("<" + "I" * (len(blob) // 4), blob, 0)
        print(f"\nVA {va:#x}")
        print(f"  section={info['section']} rva={info['rva']:#x} within_raw={info['within_raw']} file_backed={info['bytes_are_file_backed']}")
        print(f"  bytes   {hexs}")
        print(f"  dwords  {[hex(w) for w in words]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
