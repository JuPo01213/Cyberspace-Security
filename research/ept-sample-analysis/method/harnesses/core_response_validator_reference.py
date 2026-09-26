"""Pure-Python reference for the recovered genB response validator.

The native validator at 0x14078db80 performs three checks over a 0x11c-byte
response-shaped buffer:

* a state word at +0x00;
* a marker derived from the state word at +0x04;
* the 268-byte payload digest and the state word at +0x0c.

This module transcribes those checks without mapping the executable, starting
Hardware.exe, opening a device, loading authorization, or performing network
I/O.  It is a reference model for the native harness, not evidence that a
response came from the real driver.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import time
from pathlib import Path

from core_predevice_reference import (
    INPUT_BYTES,
    local_hash,
    local_transform,
    mix_full,
    mix_without_final_xor,
    rol32,
    u32,
)


RESPONSE_BYTES = 0x11C
STATE_BYTES = 0x10
EVIDENCE_SCOPE = "offline_reference_synthetic_response"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def word(data: bytes, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def validate_response(
    response: bytes, globals_: dict[str, int]
) -> tuple[bool, int]:
    """Return ``(validator_accepted, marker_out)`` for one response buffer."""

    if len(response) != RESPONSE_BYTES:
        raise ValueError(f"response must be exactly {RESPONSE_BYTES} bytes")

    g340 = globals_["g340"]
    g344 = globals_["g344"]
    g348 = globals_["g348"]
    g34c = globals_["g34c"]
    g350 = globals_["g350"]
    g354 = globals_["g354"]
    d0, d1, d2, d3 = struct.unpack_from("<4I", response, 0)

    # 0x14078db91..0x14078dc31: first state-word check.
    seed0 = mix_full(g348 ^ g344 ^ 0x4BCF194A)
    rotate0 = ((seed0 >> 27) & 0xF) + 5
    tail0 = mix_without_final_xor(u32(seed0 + 0x7F4A7C15))
    check0 = u32(
        rol32(u32((tail0 >> 16) ^ d0 ^ tail0), 32 - rotate0) ^ seed0
    )
    if check0 != g344:
        return False, 0

    # 0x14078dc37..0x14078dce9: marker-producing state-word check.
    seed1 = mix_full(g34c ^ g344 ^ 0x6BAC2DAC)
    rotate1 = ((seed1 >> 27) & 0xF) + 5
    tail1 = mix_without_final_xor(u32(seed1 + 0x7F4A7C15))
    marker = u32(
        rol32(u32((tail1 >> 16) ^ d1 ^ tail1), 32 - rotate1) ^ seed1
    )

    # 0x14078dcec..0x14078ddf1: payload digest/state-word check.
    seed2 = mix_full(g350 ^ g344 ^ 0x032B31E2)
    rotate2 = ((seed2 >> 27) & 0xF) + 5
    tail2 = mix_without_final_xor(u32(seed2 + 0x7F4A7C15))
    check2_left = u32(
        rol32(u32((tail2 >> 16) ^ d2 ^ tail2), 32 - rotate2) ^ seed2
    )
    digest = local_hash(response[STATE_BYTES:], globals_)
    check2_right = u32(digest ^ marker ^ g344 ^ 2)
    if check2_left != check2_right:
        return False, marker

    # 0x14078dd35..0x14078de2d: final state-word check.
    seed3 = mix_full(g354 ^ g344 ^ 0x238A3C50)
    rotate3 = ((seed3 >> 27) & 0xF) + 5
    tail3 = mix_without_final_xor(u32(seed3 + 0x7F4A7C15))
    check3_left = u32(
        rol32(u32((tail3 >> 16) ^ d3 ^ tail3), 32 - rotate3) ^ seed3
    )
    check3_right = u32(d0 ^ d1 ^ d2 ^ g344)
    return check3_left == check3_right, marker


def make_synthetic_response(payload: bytes, globals_: dict[str, int]) -> bytes:
    if len(payload) != INPUT_BYTES:
        raise ValueError(f"payload must be exactly {INPUT_BYTES} bytes")
    encrypted = local_transform(payload, globals_)
    # The four-word state formula is the readable transcription of
    # 0x14078d900, kept in the pre-device reference module.
    from core_predevice_reference import build_state

    return build_state(encrypted, globals_) + encrypted


def globals_from_args(args: argparse.Namespace) -> dict[str, int]:
    return {
        name: getattr(args, name)
        for name in ("g340", "g344", "g348", "g34c", "g350", "g354")
    }


def run_one(
    response: bytes, globals_: dict[str, int], source: bytes | None = None
) -> dict[str, object]:
    started = time.perf_counter()
    accepted, marker = validate_response(response, globals_)
    marker_matches = accepted and marker == globals_["g340"]
    if not accepted:
        branch = "RC03 decode_failed"
        decoded = b""
    elif not marker_matches:
        branch = "RC04 session_mismatch"
        decoded = b""
    else:
        branch = "RC06 success"
        decoded = local_transform(response[STATE_BYTES:], globals_)
    elapsed_ms = round((time.perf_counter() - started) * 1000, 3)
    report: dict[str, object] = {
        "status": "completed",
        "evidence_scope": EVIDENCE_SCOPE,
        "implementation": "pure_python_reference",
        "response_bytes": len(response),
        "response_sha256": sha(response),
        "reference_validator_rax": f"0x{int(accepted):08x}",
        "reference_validator_marker": f"0x{marker:08x}",
        "reference_marker_matches_g340": marker_matches if accepted else None,
        "reference_rc03_branch": branch,
        "reference_decoded_output_bytes": len(decoded),
        "reference_decoded_output_sha256": sha(decoded) if decoded else None,
        "reference_decoded_matches_input": (
            decoded == source if source is not None and decoded else None
        ),
        "synthetic_globals": {
            name: f"0x{value:08x}" for name, value in globals_.items()
        },
        "external_dependencies": [],
        "side_effects": [],
        "elapsed_ms": elapsed_ms,
    }
    if source is not None:
        report["input_bytes"] = len(source)
        report["input_sha256"] = sha(source)
    return report


def parse_u32(value: str) -> int:
    return int(value, 0) & 0xFFFFFFFF


def load_exact(path: Path, expected: int, label: str) -> bytes:
    data = path.read_bytes()
    if len(data) != expected:
        raise ValueError(f"{label} must be exactly {expected} bytes, got {len(data)}")
    return data


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="268-byte local payload")
    parser.add_argument("--response", type=Path, help="284-byte response buffer")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--out-dir", type=Path)
    for name, default in {
        "g340": "0x13579bdf",
        "g344": "0x2468ace0",
        "g348": "0x01020304",
        "g34c": "0x11223344",
        "g350": "0x55667788",
        "g354": "0x99aabbcc",
    }.items():
        parser.add_argument(f"--{name}", default=default, type=parse_u32)
    args = parser.parse_args()
    selected = sum(bool(value) for value in (args.input, args.response))
    if args.self_test and selected:
        parser.error("--self-test cannot be combined with --input or --response")
    if not args.self_test and selected != 1:
        parser.error("provide exactly one of --input or --response, unless using --self-test")
    return args


def main() -> int:
    args = parse_args()
    globals_ = globals_from_args(args)
    if args.self_test:
        vectors = [bytes(INPUT_BYTES), bytes(range(256)) + bytes(range(12))]
        positives = []
        for source in vectors:
            response = make_synthetic_response(source, globals_)
            positives.append(run_one(response, globals_, source))
        negative = run_one(bytes(RESPONSE_BYTES), globals_)
        mismatch_globals = dict(globals_)
        mismatch_globals["g340"] ^= 1
        mismatch_response = make_synthetic_response(vectors[0], globals_)
        mismatch = run_one(mismatch_response, mismatch_globals)
        if not all(
            item["reference_rc03_branch"] == "RC06 success"
            and item["reference_decoded_matches_input"]
            for item in positives
        ):
            raise AssertionError("reference validator positive vector failed")
        if negative["reference_rc03_branch"] != "RC03 decode_failed":
            raise AssertionError("reference validator negative vector failed")
        if mismatch["reference_rc03_branch"] != "RC04 session_mismatch":
            raise AssertionError("reference marker mismatch vector failed")
        print(
            json.dumps(
                {
                    "status": "self_test_passed",
                    "positive_vectors": [item["input_sha256"] for item in positives],
                    "evidence_scope": EVIDENCE_SCOPE,
                    "negative_control_branch": negative["reference_rc03_branch"],
                    "marker_mismatch_control_branch": mismatch["reference_rc03_branch"],
                },
                indent=2,
            )
        )
        return 0

    if args.input:
        source = load_exact(args.input, INPUT_BYTES, "input")
        response = make_synthetic_response(source, globals_)
    else:
        source = None
        response = load_exact(args.response, RESPONSE_BYTES, "response")
    report = run_one(response, globals_, source)
    if args.out_dir:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        (args.out_dir / "response_before_decode.bin").write_bytes(response)
        if report["reference_rc03_branch"] == "RC06 success":
            (args.out_dir / "decoded_output.bin").write_bytes(
                local_transform(response[STATE_BYTES:], globals_)
            )
        (args.out_dir / "validator_reference_report.json").write_text(
            json.dumps(report, indent=2) + "\n", encoding="utf-8"
        )
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
