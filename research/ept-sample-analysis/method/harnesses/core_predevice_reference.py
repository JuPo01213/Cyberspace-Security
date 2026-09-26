"""Readable reference implementation of the recovered genB pre-device stages.

This file is deliberately narrower than ``core_predevice_harness.py``.  It is
an arithmetic transcription of the recovered x64 instructions at
0x14078ce60, the embedded helper at 0x14078cd70, and 0x14078d900.  It does
not start the sample, load authorization state, open a device, or perform I/O.

The implementation is a research reference, not a claim that these stages are
the final business decoder.  Their business direction (encode/decode) and the
post-DeviceIoControl result remain unresolved.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
from pathlib import Path


MASK32 = 0xFFFFFFFF
INPUT_BYTES = 0x10C
STATE_BYTES = 0x10
HASH_ROUNDS = 0x43

MIX_A = 0x7FEB352D
MIX_B = 0x846CA68B
FNV_PRIME = 0x01000193


def u32(value: int) -> int:
    return value & MASK32


def mix_full(value: int) -> int:
    """The repeated x ^= x>>16, multiply, x ^= x>>15, multiply, x ^= x>>16."""

    # Every caller reaches this sequence through a 32-bit x86 register.  The
    # explicit truncation is important when a preceding ADD overflowed.
    value = u32(value)
    value = u32(value ^ (value >> 16))
    value = u32(value * MIX_A)
    value = u32(value ^ (value >> 15))
    value = u32(value * MIX_B)
    return u32(value ^ (value >> 16))


def mix_without_final_xor(value: int) -> int:
    """The state-builder variant that stops after the second multiply."""

    value = u32(value)
    value = u32(value ^ (value >> 16))
    value = u32(value * MIX_A)
    value = u32(value ^ (value >> 15))
    return u32(value * MIX_B)


def rol32(value: int, count: int) -> int:
    count &= 31
    value = u32(value)
    if count == 0:
        return value
    return u32((value << count) | (value >> (32 - count)))


def pack_words(words: list[int]) -> bytes:
    return struct.pack("<" + "I" * len(words), *(u32(word) for word in words))


def local_transform(payload: bytes, globals_: dict[str, int]) -> bytes:
    """Transcribe 0x14078ce60: a 0x10c-byte in-place XOR transform."""

    if len(payload) != INPUT_BYTES:
        raise ValueError(f"payload must be exactly {INPUT_BYTES} bytes")

    # 0x14078ce65/72/7b: g350 ^ g340 ^ g344 ^ 0xc3d2e1f0
    state = mix_full(
        globals_["g350"]
        ^ globals_["g340"]
        ^ globals_["g344"]
        ^ 0xC3D2E1F0
    )
    table = [globals_["g348"], globals_["g34c"], globals_["g350"], globals_["g354"]]
    output = bytearray(payload)
    for index in range(INPUT_BYTES):
        if (index & 3) == 0:
            # 0x14078ceb9..0x14078cee5; eax is the byte index before its
            # increment at 0x14078cefc.
            state = mix_full(state + table[(index >> 2) & 3] + index)
        output[index] ^= (state >> (8 * (index & 3))) & 0xFF
    return bytes(output)


def local_hash(payload: bytes, globals_: dict[str, int]) -> int:
    """Transcribe 0x14078cd70, including its 67 four-byte rounds."""

    if len(payload) != INPUT_BYTES:
        raise ValueError(f"hash input must be exactly {INPUT_BYTES} bytes")

    # 0x14078cd70/79: g34c ^ g344 ^ 0xb7e1506e, then full mix.
    state = mix_full(globals_["g34c"] ^ globals_["g344"] ^ 0xB7E1506E)
    salt = 0
    for round_index in range(HASH_ROUNDS):
        offset = round_index * 4
        byte0, byte1, byte2, byte3 = payload[offset : offset + 4]
        round_bias = u32(salt + 0x030004B9)

        # The first two bytes are read through [r9-2] and [r9-1].  The
        # pointer is advanced by four before the remaining two reads, so each
        # round consumes exactly payload[offset:offset + 4].
        first = u32((byte0 + salt) ^ state)
        second = u32(byte1 + 0x01000193 + salt)
        state = u32(first * FNV_PRIME)
        second = u32(second ^ (state >> 11) ^ state)
        state = u32(second * FNV_PRIME)

        third = u32(byte2 + 0xFEFFFE6D + round_bias)
        third = u32(third ^ (state >> 11) ^ state)
        state = u32(third * FNV_PRIME)

        fourth = u32(byte3 + round_bias)
        fourth = u32(fourth ^ (state >> 11) ^ state)
        state = u32(fourth * FNV_PRIME)

        # 0x14078cdda increments r10 before byte2/byte3, but r8 retains the
        # pre-increment salt-derived round_bias.
        salt = u32(salt + 0x0400064C)
        state = u32(state ^ (state >> 11))

    return mix_full(state)


def build_state(payload: bytes, globals_: dict[str, int]) -> bytes:
    """Transcribe the four dword stores in 0x14078d900."""

    if len(payload) != INPUT_BYTES:
        raise ValueError(f"state payload must be exactly {INPUT_BYTES} bytes")

    g340 = globals_["g340"]
    g344 = globals_["g344"]
    g348 = globals_["g348"]
    g34c = globals_["g34c"]
    g350 = globals_["g350"]
    g354 = globals_["g354"]
    digest = local_hash(payload, globals_)

    # The assembly uses a rotate synthesized from SHR/SHL/OR.  The shift
    # amount is (x >> 27) + 5, and is in [5, 20].
    seed0 = mix_full(g348 ^ g344 ^ 0x4BCF194A)
    rotate0 = ((seed0 >> 27) & 0xF) + 5
    stage0 = u32(seed0 ^ g344)
    tail0 = mix_without_final_xor(u32(seed0 + 0x7F4A7C15))
    word0 = u32(rol32(stage0, rotate0) ^ tail0 ^ (tail0 >> 16))

    seed1 = mix_full(g34c ^ g344 ^ 0x6BAC2DAC)
    rotate1 = ((seed1 >> 27) & 0xF) + 5
    stage1 = u32(seed1 ^ g340)
    tail1 = mix_without_final_xor(u32(seed1 + 0x7F4A7C15))
    word1 = u32(rol32(stage1, rotate1) ^ tail1 ^ (tail1 >> 16))

    seed2 = mix_full(g350 ^ g344 ^ 0x032B31E2)
    rotate2 = ((seed2 >> 27) & 0xF) + 5
    stage2 = u32(seed2 ^ g344 ^ digest ^ g340 ^ 2)
    tail2 = mix_without_final_xor(u32(seed2 + 0x7F4A7C15))
    word2 = u32(rol32(stage2, rotate2) ^ tail2 ^ (tail2 >> 16))

    accumulator = u32(word2 ^ word1 ^ word0 ^ g344)
    seed3 = mix_full(g354 ^ g344 ^ 0x238A3C50)
    accumulator = u32(accumulator ^ seed3)
    rotate3 = ((seed3 >> 27) & 0xF) + 5
    tail3 = mix_without_final_xor(u32(seed3 + 0x7F4A7C15))
    word3 = u32(rol32(accumulator, rotate3) ^ tail3 ^ (tail3 >> 16))

    return pack_words([word0, word1, word2, word3])


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_u32(value: str) -> int:
    return int(value, 0) & MASK32


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="268-byte input")
    parser.add_argument("--hex", dest="hex_input", help="268-byte input as hex")
    parser.add_argument("--self-test", action="store_true", help="run built-in arithmetic regression vectors")
    parser.add_argument("--out-dir", type=Path)
    parser.add_argument("--g340", default="0x13579bdf", type=parse_u32)
    parser.add_argument("--g344", default="0x2468ace0", type=parse_u32)
    parser.add_argument("--g348", default="0x01020304", type=parse_u32)
    parser.add_argument("--g34c", default="0x11223344", type=parse_u32)
    parser.add_argument("--g350", default="0x55667788", type=parse_u32)
    parser.add_argument("--g354", default="0x99aabbcc", type=parse_u32)
    args = parser.parse_args()
    if args.self_test and (args.input or args.hex_input):
        parser.error("--self-test cannot be combined with --input or --hex")
    if not args.self_test and bool(args.input) == bool(args.hex_input):
        parser.error("provide exactly one of --input or --hex")
    return args


def main() -> int:
    args = parse_args()
    globals_ = {
        name: getattr(args, name)
        for name in ("g340", "g344", "g348", "g34c", "g350", "g354")
    }
    if args.self_test:
        vectors = [
            (
                "zero",
                bytes(INPUT_BYTES),
                "6521b2754d1b897a0cafc70db80cb21ff19fa3730bbff29b0fc3191b4dfd8f0a",
                "0xe77427ce",
                "a47b1c4e030ca1e4388c6826e9dbdf3e",
                "897d70dd4c70bc9081188d4b6d2e2cc910d408f6bfb49e5f4b714c4be5eadc39",
            ),
            (
                "incrementing",
                bytes(range(256)) + bytes(range(12)),
                "34db4e9c15da7f045b57c51b127feed0d2bb1fc49ae68bc86742db78dfce5e6f",
                "0xbeaaacd8",
                "a47b1c4e030ca1e48ba07e9bb12f118c",
                "e0cdb6e91ef7555ea9e6af72df576dd3f7028c49a1301c6cba9cee554b31a7ef",
            ),
        ]
        for label, source, expected_transform, expected_hash, expected_state, expected_request in vectors:
            transformed = local_transform(source, globals_)
            digest = local_hash(transformed, globals_)
            state = build_state(transformed, globals_)
            request = state + transformed
            actual = (sha(transformed), f"0x{digest:08x}", state.hex(), sha(request))
            expected = (expected_transform, expected_hash, expected_state, expected_request)
            if actual != expected:
                raise AssertionError(f"{label} vector mismatch: actual={actual!r} expected={expected!r}")
        print(json.dumps({"status": "self_test_passed", "vectors": [v[0] for v in vectors]}))
        return 0

    if args.input:
        source = args.input.read_bytes()
    else:
        try:
            source = bytes.fromhex(args.hex_input)
        except ValueError as exc:
            raise ValueError("--hex is not valid hexadecimal") from exc
    if len(source) != INPUT_BYTES:
        raise ValueError(f"input must be exactly {INPUT_BYTES} bytes, got {len(source)}")

    transformed = local_transform(source, globals_)
    digest = local_hash(transformed, globals_)
    state = build_state(transformed, globals_)
    request = state + transformed
    report = {
        "status": "completed",
        "semantic_role": "genB_predevice_local_stages_reference",
        "input_bytes": len(source),
        "input_sha256": sha(source),
        "transform_output_sha256": sha(transformed),
        "hash32": f"0x{digest:08x}",
        "state_output_hex": state.hex(),
        "state_output_sha256": sha(state),
        "request_buffer_bytes": len(request),
        "request_buffer_sha256": sha(request),
        "synthetic_globals": {name: f"0x{value:08x}" for name, value in globals_.items()},
        "external_dependencies": [],
        "side_effects": [],
    }
    if args.out_dir:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        (args.out_dir / "transform_output.bin").write_bytes(transformed)
        (args.out_dir / "state_output.bin").write_bytes(state)
        (args.out_dir / "request_buffer.bin").write_bytes(request)
        (args.out_dir / "reference_report.json").write_text(
            json.dumps(report, indent=2) + "\n", encoding="utf-8"
        )
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
