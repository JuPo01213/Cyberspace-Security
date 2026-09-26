"""Run the recovered genB user-mode pre-device stages without the outer tool.

This is intentionally a research harness, not a decoder claim.  It maps the
captured genB .text and the minimum captured data regions at their preferred
addresses, then calls only the recovered local transform, state builder, and
RC03 validator.  It never starts Hardware.exe, loads authorization state, or
performs I/O.
"""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import os
import struct
import time
from pathlib import Path


IMAGE_BASE = 0x140000000
TEXT_SHA256 = "5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757"
TEXT_SIZE = 0x7E0000
TRANSFORM = 0x14078CE60
STATE_BUILDER = 0x14078D900
VALIDATOR = 0x14078DB80
GLOBAL_BASE = 0x14115C340
GLOBAL_OFFSETS = {
    "g340": 0x00,
    "g344": 0x04,
    "g348": 0x08,
    "g34c": 0x0C,
    "g350": 0x10,
    "g354": 0x14,
}
REGION_SIZE = 0x02000000
EVIDENCE_SCOPE = "host_mapped_code_runner"

MEM_COMMIT = 0x1000
MEM_RESERVE = 0x2000
MEM_RELEASE = 0x8000
PAGE_EXECUTE_READWRITE = 0x40


class Mapping:
    def __init__(self, files: list[tuple[int, Path]]) -> None:
        if os.name != "nt":
            raise RuntimeError("this harness requires Windows ctypes execution")
        self.kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        self.kernel32.VirtualAlloc.restype = ctypes.c_void_p
        self.kernel32.VirtualAlloc.argtypes = [
            ctypes.c_void_p,
            ctypes.c_size_t,
            ctypes.c_uint32,
            ctypes.c_uint32,
        ]
        self.kernel32.VirtualFree.restype = ctypes.c_int
        self.kernel32.VirtualFree.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint32]
        self.address = int(
            self.kernel32.VirtualAlloc(
                ctypes.c_void_p(IMAGE_BASE),
                REGION_SIZE,
                MEM_COMMIT | MEM_RESERVE,
                PAGE_EXECUTE_READWRITE,
            )
            or 0
        )
        if self.address != IMAGE_BASE:
            if self.address:
                self.kernel32.VirtualFree(ctypes.c_void_p(self.address), 0, MEM_RELEASE)
            raise RuntimeError(f"preferred image base unavailable: got 0x{self.address:x}")
        for va, path in files:
            data = path.read_bytes()
            if va < IMAGE_BASE or va + len(data) > IMAGE_BASE + REGION_SIZE:
                self.close()
                raise ValueError(f"region outside mapping: {path} at 0x{va:x}")
            ctypes.memmove(ctypes.c_void_p(va), data, len(data))

    def close(self) -> None:
        if getattr(self, "address", 0):
            self.kernel32.VirtualFree(ctypes.c_void_p(self.address), 0, MEM_RELEASE)
            self.address = 0

    def __enter__(self) -> "Mapping":
        return self

    def __exit__(self, *_: object) -> None:
        self.close()


def u32(value: str) -> int:
    return int(value, 0) & 0xFFFFFFFF


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--text", required=True, type=Path)
    parser.add_argument("--input", type=Path, help="268-byte pre-transform input")
    parser.add_argument("--hex", dest="hex_input", help="268-byte input as hex")
    parser.add_argument("--self-test", action="store_true", help="run the all-zero negative validator case")
    parser.add_argument("--out-dir", type=Path)
    parser.add_argument("--rdatafront", type=Path, default=Path(r"<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_rdatafront.bin"))
    parser.add_argument("--data-region", type=Path, default=Path(r"<HOST_PATH>\EPT\artifacts\captures\RG2_region_0x140e00000.bin"))
    parser.add_argument("--rdata", type=Path, default=Path(r"<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_rdata.bin"))
    parser.add_argument("--g340", default="0x13579bdf", type=u32)
    parser.add_argument("--g344", default="0x2468ace0", type=u32)
    parser.add_argument("--g348", default="0x01020304", type=u32)
    parser.add_argument("--g34c", default="0x11223344", type=u32)
    parser.add_argument("--g350", default="0x55667788", type=u32)
    parser.add_argument("--g354", default="0x99aabbcc", type=u32)
    args = parser.parse_args()
    if args.self_test:
        if args.input or args.hex_input:
            parser.error("--self-test cannot be combined with --input or --hex")
    elif bool(args.input) == bool(args.hex_input):
        parser.error("provide exactly one of --input or --hex, unless using --self-test")
    return args


def load_input(args: argparse.Namespace) -> bytes:
    if args.self_test:
        return bytes(0x10C)
    if args.input:
        data = args.input.read_bytes()
    else:
        try:
            data = bytes.fromhex(args.hex_input)
        except ValueError as exc:
            raise ValueError("--hex is not valid hexadecimal") from exc
    if len(data) != 0x10C:
        raise ValueError(f"input must be exactly 268 bytes, got {len(data)}")
    return data


def main() -> int:
    args = parse_args()
    text = args.text.read_bytes()
    if len(text) != TEXT_SIZE or sha(text) != TEXT_SHA256:
        raise ValueError("--text is not the verified genB recovered .text capture")
    source = load_input(args)
    files = [
        (IMAGE_BASE, args.text),
        (0x1407DB000, args.rdatafront),
        (0x140E00000, args.data_region),
        (0x140F80000, args.rdata),
    ]
    for _, path in files:
        if not path.is_file():
            raise FileNotFoundError(path)
    start = time.perf_counter()
    with Mapping(files):
        for name, offset in GLOBAL_OFFSETS.items():
            ctypes.c_uint32.from_address(GLOBAL_BASE + offset).value = getattr(args, name)

        transform_type = ctypes.CFUNCTYPE(None, ctypes.c_void_p)
        validator_type = ctypes.CFUNCTYPE(ctypes.c_uint32, ctypes.c_void_p, ctypes.c_void_p)
        transform = transform_type(TRANSFORM)
        state_builder = transform_type(STATE_BUILDER)
        validator = validator_type(VALIDATOR)

        if args.self_test:
            # Negative control used by C92: validator sees an untouched all-zero
            # response-sized buffer, so a fixed-success return is detectable.
            transformed_bytes = b""
            request = (ctypes.c_ubyte * 0x11C)()
            semantic_role = "genB_response_validator_negative_control"
        else:
            transformed = (ctypes.c_ubyte * len(source)).from_buffer_copy(source)
            transform(ctypes.addressof(transformed))
            transformed_bytes = bytes(transformed)
            request = (ctypes.c_ubyte * 0x11C)()
            ctypes.memmove(ctypes.addressof(request) + 0x10, transformed_bytes, len(transformed_bytes))
            state_builder(ctypes.addressof(request))
            semantic_role = "genB_predevice_local_stages"
        request_bytes = bytes(request)

        marker = ctypes.c_uint32(0)
        result = int(validator(ctypes.addressof(request), ctypes.addressof(marker)))
    elapsed_ms = round((time.perf_counter() - start) * 1000, 3)

    report = {
        "status": "completed",
        "evidence_scope": EVIDENCE_SCOPE,
        "semantic_role": semantic_role,
        "text_sha256": sha(text),
        "input_bytes": len(source),
        "input_sha256": sha(source),
        "transform_output_sha256": sha(transformed_bytes),
        "request_buffer_bytes": len(request_bytes),
        "request_buffer_sha256": sha(request_bytes),
        "state_output_hex": request_bytes[:0x10].hex(),
        "harness_validator_rax": f"0x{result:08x}",
        "harness_validator_marker": f"0x{marker.value:08x}",
        "synthetic_globals": {name: f"0x{getattr(args, name):08x}" for name in GLOBAL_OFFSETS},
        "external_dependencies": [],
        "side_effects": [],
        "elapsed_ms": elapsed_ms,
    }
    if args.out_dir:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        (args.out_dir / "transform_output.bin").write_bytes(transformed_bytes)
        (args.out_dir / "request_buffer.bin").write_bytes(request_bytes)
        (args.out_dir / "validator_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
