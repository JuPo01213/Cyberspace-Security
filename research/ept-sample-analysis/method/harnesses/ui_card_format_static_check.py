#!/usr/bin/env python3
"""Read-only C122 verifier for the PyInstaller UI card-format boundary."""

from __future__ import annotations

import hashlib
import marshal
import re
import struct
import sys
import types
from pathlib import Path

ROOT = Path("<HOST_PATH>")
CLEAN = ROOT / "unpack/ept_clean.exe"
SAMPLE = ROOT / "sample/EPT专业游戏维修工具箱V5.1.exe"
PYZ = ROOT / "sample/EPT专业游戏维修工具箱V5.1.exe_extracted/PYZ.pyz"
MAIN = ROOT / "sample/EPT专业游戏维修工具箱V5.1.exe_extracted/main.pyc"

EXPECTED_CLEAN_SHA256 = "5d3e30e28162276a99af87f9b625e2763354c2598bbb97ebf94f2ba980d77cb3"
EXPECTED_PYZ_SHA256 = "14875591998f8c07b82f24c5c76f6eda8be40df720f925e88592fad0ab9dd89f"
EXPECTED_MAIN_SHA256 = "de746c511178b8748a265a9c56e4c7a21e9703c1ce89dea2609b1ba6be33e274"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def find_on_confirm(root: types.CodeType) -> types.CodeType:
    found: list[types.CodeType] = []

    def walk(code: types.CodeType, path: str) -> None:
        name = f"{path}.{code.co_name}" if path else code.co_name
        if name.endswith(".SplashScreen._on_confirm"):
            found.append(code)
        for item in code.co_consts:
            if isinstance(item, types.CodeType):
                walk(item, name)

    walk(root, "")
    if len(found) != 1:
        raise AssertionError(f"expected one _on_confirm, found {len(found)}")
    return found[0]


def verify_archive() -> tuple[int, int, str]:
    data = SAMPLE.read_bytes()
    cookie = data.rfind(b"MEI\x0c\x0b\x0a\x0b\x0e")
    if cookie < 0:
        raise AssertionError("PyInstaller cookie not found")
    magic, package_len, toc_offset, toc_len, pyver, _dll = struct.unpack_from(
        ">8sIIII64s", data, cookie
    )
    if magic != b"MEI\x0c\x0b\x0a\x0b\x0e" or pyver != 313:
        raise AssertionError("unexpected PyInstaller cookie")
    base = len(data) - package_len
    cursor = base + toc_offset
    end = cursor + toc_len
    pyz = None
    while cursor < end:
        entry_size = struct.unpack_from(">i", data, cursor)[0]
        raw = data[cursor + 4 : cursor + entry_size]
        entry_offset, entry_len, _unc_len, flag = struct.unpack_from(">iiiB", raw, 0)
        name = raw[14:].split(b"\0", 1)[0].decode("utf-8", "replace")
        if name == "PYZ.pyz":
            pyz = (base + entry_offset, entry_len, flag)
            break
        cursor += entry_size
    if pyz is None:
        raise AssertionError("PYZ.pyz TOC entry not found")
    absolute_offset, length, flag = pyz
    archive_slice = data[absolute_offset : absolute_offset + length]
    if flag != 0 or len(archive_slice) != PYZ.stat().st_size:
        raise AssertionError("PYZ archive slice metadata mismatch")
    digest = hashlib.sha256(archive_slice).hexdigest()
    if digest != sha256(PYZ) or digest != EXPECTED_PYZ_SHA256:
        raise AssertionError("PYZ archive slice hash mismatch")
    return absolute_offset, length, digest


def main() -> int:
    if sys.version_info[:2] != (3, 13):
        raise SystemExit("Run with CPython 3.13.x to match the sample bytecode.")
    if sha256(CLEAN) != EXPECTED_CLEAN_SHA256:
        raise AssertionError("ept_clean.exe hash mismatch")
    if sha256(PYZ) != EXPECTED_PYZ_SHA256:
        raise AssertionError("extracted PYZ hash mismatch")
    if sha256(MAIN) != EXPECTED_MAIN_SHA256:
        raise AssertionError("main.pyc hash mismatch")

    pyz_offset, pyz_length, pyz_digest = verify_archive()
    root = marshal.loads(MAIN.read_bytes()[16:])
    code = find_on_confirm(root)
    assert code.co_firstlineno == 2961
    assert len(code.co_code) == 1154
    assert code.co_consts[11] == "^[a-zA-Z0-9]{31,36}$"
    assert code.co_consts[13] == "^(C|E(?!PT))"
    for offset in (454, 476, 518, 538, 762, 782, 982, 984, 1016, 1020, 1044):
        assert offset < len(code.co_code), offset

    format_re = re.compile(code.co_consts[11])
    prefix_re = re.compile(code.co_consts[13])

    def accepts(value: str) -> bool:
        key = value.strip()
        return bool(key and format_re.match(key) and prefix_re.match(key))

    assert accepts("C" + "A" * 30)
    assert accepts("C" + "A" * 35)
    assert accepts("E" + "A" * 30)
    assert not accepts("A" * 31)
    assert not accepts("C" + "A" * 29)
    assert not accepts("C" + "A" * 36)
    assert not accepts("EPT" + "A" * 28)
    assert not accepts("C" + "A" * 29 + "!")

    print("C122 read-only verification: PASS")
    print(f"ept_clean_sha256={sha256(CLEAN)}")
    print(f"pyz_offset=0x{pyz_offset:x} pyz_length={pyz_length} pyz_sha256={pyz_digest}")
    print(f"main_code=<module>.SplashScreen._on_confirm firstlineno={code.co_firstlineno} code_len={len(code.co_code)}")
    print("ui_format=31..36 ASCII alphanumeric; prefix=C or E except EPT")
    print("external_authorization=not tested")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
