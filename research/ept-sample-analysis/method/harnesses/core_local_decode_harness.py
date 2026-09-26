"""Isolate the recovered user-mode success/decode seam.

The recovered RC03 success path at 0x14078ef42 applies the same
0x14078ce60 transform to the 268-byte payload returned in a validator-accepted
0x11c response buffer, then copies the result to the caller structure at
offset +0x80.  In ``--input`` mode the harness constructs a validator-accepted
response from a known local input; in ``--response`` mode it consumes a
caller-supplied 284-byte response-shaped buffer.  Both modes execute the
native transform at the user-mode success seam and record the second result as
the decoded payload, including the RC06 copy into a modeled caller structure
at offset +0x80.

The ``--input`` path is intentionally a synthetic-response seam.  It does not
claim that the constructed response came from the real driver, and neither
mode opens a device, starts Hardware.exe, loads authorization, or performs
network I/O.
"""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import time
from pathlib import Path

from core_predevice_harness import (
    GLOBAL_BASE,
    GLOBAL_OFFSETS,
    IMAGE_BASE,
    Mapping,
    STATE_BUILDER,
    TEXT_SHA256,
    TEXT_SIZE,
    TRANSFORM,
    VALIDATOR,
    u32,
)


INPUT_BYTES = 0x10C
RESPONSE_BYTES = 0x11C
CALLER_OUTPUT_OFFSET = 0x80
CALLER_STRUCT_BYTES = CALLER_OUTPUT_OFFSET + INPUT_BYTES
EVIDENCE_SCOPE = "caller_injection_harness"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_input(args: argparse.Namespace) -> bytes:
    if args.input:
        data = args.input.read_bytes()
    else:
        try:
            data = bytes.fromhex(args.hex_input)
        except ValueError as exc:
            raise ValueError("--hex is not valid hexadecimal") from exc
    if len(data) != INPUT_BYTES:
        raise ValueError(f"input must be exactly {INPUT_BYTES} bytes, got {len(data)}")
    return data


def load_response(args: argparse.Namespace) -> bytes:
    response = args.response.read_bytes()
    if len(response) != RESPONSE_BYTES:
        raise ValueError(
            f"response must be exactly {RESPONSE_BYTES} bytes, got {len(response)}"
        )
    return response


def run_one(
    args: argparse.Namespace,
    source: bytes | None,
    response_input: bytes | None,
) -> tuple[dict[str, object], bytes, bytes, bytes]:
    if (source is None) == (response_input is None):
        raise ValueError("provide exactly one of source or response_input")
    caller_structure = bytearray(CALLER_STRUCT_BYTES)
    if source is not None:
        caller_structure[:INPUT_BYTES] = source
    caller_structure_before = bytes(caller_structure)
    start = time.perf_counter()
    text = args.text.read_bytes()
    if len(text) != TEXT_SIZE or sha(text) != TEXT_SHA256:
        raise ValueError("--text is not the verified genB recovered .text capture")
    files = [
        (IMAGE_BASE, args.text),
        (0x1407DB000, args.rdatafront),
        (0x140E00000, args.data_region),
        (0x140F80000, args.rdata),
    ]
    for _, path in files:
        if not path.is_file():
            raise FileNotFoundError(path)

    with Mapping(files):
        for name, offset in GLOBAL_OFFSETS.items():
            ctypes.c_uint32.from_address(GLOBAL_BASE + offset).value = getattr(args, name)

        transform = ctypes.CFUNCTYPE(None, ctypes.c_void_p)(TRANSFORM)
        state_builder = ctypes.CFUNCTYPE(None, ctypes.c_void_p)(STATE_BUILDER)
        validator = ctypes.CFUNCTYPE(ctypes.c_uint32, ctypes.c_void_p, ctypes.c_void_p)(VALIDATOR)

        if source is not None:
            # First transform: exactly the request-side operation at RC00.
            request_payload = (ctypes.c_ubyte * INPUT_BYTES).from_buffer_copy(source)
            transform(ctypes.addressof(request_payload))
            encrypted_payload = bytes(request_payload)

            # Build the same 0x11c shape that the RC00 path sends.  C92/C99
            # show that this shape is accepted by the recovered RC03 validator
            # when it is used as a synthetic response.
            response = (ctypes.c_ubyte * RESPONSE_BYTES)()
            ctypes.memmove(
                ctypes.addressof(response) + 0x10, encrypted_payload, INPUT_BYTES
            )
            state_builder(ctypes.addressof(response))
            synthetic_response = True
        else:
            response = (ctypes.c_ubyte * RESPONSE_BYTES).from_buffer_copy(response_input)
            encrypted_payload = bytes(response)[0x10:]
            synthetic_response = False
        response_before_decode = bytes(response)

        marker = ctypes.c_uint32(0)
        valid = int(validator(ctypes.addressof(response), ctypes.addressof(marker)))
        marker_matches = None
        if not valid:
            # RC03's false branch logs decode_failed and does not execute the
            # second transform.
            rc03_branch = "RC03 decode_failed"
            decoded = b""
        else:
            marker_matches = marker.value == args.g340
            if not marker_matches:
                # RC03 accepts the response shape but diverts to RC04 before
                # the +0x80 output copy when the response marker is stale.
                rc03_branch = "RC04 session_mismatch"
                decoded = b""
            else:
                # Second transform: the RC03-success local user-mode operation
                # at 0x14078ef42, applied before the +0x80 copy.
                rc03_branch = "RC06 success"
                decoded_payload = (ctypes.c_ubyte * INPUT_BYTES).from_buffer(
                    response, 0x10
                )
                transform(ctypes.addressof(decoded_payload))
                decoded = bytes(decoded_payload)
    if decoded:
        caller_structure[CALLER_OUTPUT_OFFSET : CALLER_OUTPUT_OFFSET + INPUT_BYTES] = decoded
    caller_structure_after = bytes(caller_structure)

    completed_ms = round((time.perf_counter() - start) * 1000, 3)
    caller_diff_bytes = sum(
        before != after
        for before, after in zip(caller_structure_before, caller_structure_after)
    )
    report = {
        "status": "completed",
        "evidence_scope": EVIDENCE_SCOPE,
        "semantic_role": (
            "genB_user_mode_decode_success_seam"
            if synthetic_response
            else "genB_user_mode_response_decoder"
        ),
        "synthetic_response": synthetic_response,
        "response_bytes": len(response_before_decode),
        "response_before_decode_sha256": sha(response_before_decode),
        "harness_validator_rax": f"0x{valid:08x}",
        "harness_validator_marker": f"0x{marker.value:08x}",
        "harness_validator_accepted": bool(valid),
        "harness_marker_matches_g340": marker_matches,
        "harness_rc03_branch": rc03_branch,
        "harness_decoded_output_bytes": len(decoded),
        "harness_decoded_output_sha256": sha(decoded) if decoded else None,
        "harness_decoded_matches_input": (
            None if source is None or not decoded else decoded == source
        ),
        "encrypted_payload_sha256": sha(encrypted_payload),
        "harness_caller_structure_bytes": len(caller_structure_after),
        "harness_caller_output_offset": f"0x{CALLER_OUTPUT_OFFSET:x}",
        "harness_caller_output_sha256": sha(decoded) if decoded else None,
        "harness_caller_output_written": bool(decoded),
        "harness_caller_diff_bytes": caller_diff_bytes,
        "synthetic_globals": {
            name: f"0x{getattr(args, name):08x}" for name in GLOBAL_OFFSETS
        },
        "external_dependencies": [],
        "side_effects": (
            [f"caller_structure+0x{CALLER_OUTPUT_OFFSET:x}[0x{INPUT_BYTES:x}]"]
            if decoded
            else []
        ),
        "external_side_effects": [],
        "elapsed_ms": completed_ms,
    }
    if source is not None:
        report["input_bytes"] = len(source)
        report["input_sha256"] = sha(source)
    else:
        report["response_input_sha256"] = sha(response_input)
    return report, response_before_decode, decoded, caller_structure_after


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--text", required=True, type=Path)
    parser.add_argument("--input", type=Path, help="268-byte known local input")
    parser.add_argument("--hex", dest="hex_input", help="268-byte input as hex")
    parser.add_argument("--response", type=Path, help="284-byte validator-accepted response buffer")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--out-dir", type=Path)
    parser.add_argument(
        "--rdatafront",
        type=Path,
        default=Path(r"<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_rdatafront.bin"),
    )
    parser.add_argument(
        "--data-region",
        type=Path,
        default=Path(r"<HOST_PATH>\EPT\artifacts\captures\RG2_region_0x140e00000.bin"),
    )
    parser.add_argument(
        "--rdata",
        type=Path,
        default=Path(r"<HOST_PATH>\EPT\artifacts\captures\stream_C6\stream_rdata.bin"),
    )
    parser.add_argument("--g340", default="0x13579bdf", type=u32)
    parser.add_argument("--g344", default="0x2468ace0", type=u32)
    parser.add_argument("--g348", default="0x01020304", type=u32)
    parser.add_argument("--g34c", default="0x11223344", type=u32)
    parser.add_argument("--g350", default="0x55667788", type=u32)
    parser.add_argument("--g354", default="0x99aabbcc", type=u32)
    args = parser.parse_args()
    selected = [bool(args.input), bool(args.hex_input), bool(args.response)]
    if args.self_test and any(selected):
        parser.error("--self-test cannot be combined with --input, --hex or --response")
    if not args.self_test and sum(selected) != 1:
        parser.error("provide exactly one of --input, --hex or --response, unless using --self-test")
    if args.response and (args.input or args.hex_input):
        parser.error("--response cannot be combined with --input or --hex")
    return args


def main() -> int:
    args = parse_args()
    if args.self_test:
        vectors = [bytes(INPUT_BYTES), bytes(range(256)) + bytes(range(12))]
        positive_runs = [run_one(args, source, None) for source in vectors]
        reports = [item[0] for item in positive_runs]
        if not all(
            report["harness_rc03_branch"] == "RC06 success"
            and report["harness_decoded_matches_input"]
            for report in reports
        ):
            raise AssertionError("native double-transform did not recover the input")
        negative_report = run_one(args, None, bytes(RESPONSE_BYTES))[0]
        if negative_report["harness_rc03_branch"] != "RC03 decode_failed":
            raise AssertionError("all-zero response did not take RC03 decode_failed")
        mismatch_args = argparse.Namespace(**vars(args))
        mismatch_args.g340 = args.g340 ^ 1
        mismatch_report = run_one(
            mismatch_args, None, positive_runs[0][1]
        )[0]
        if mismatch_report["harness_rc03_branch"] != "RC04 session_mismatch":
            raise AssertionError("stale marker did not take RC04 session_mismatch")
        result: dict[str, object] = {
            "status": "self_test_passed",
            "vectors": [report["input_sha256"] for report in reports],
            "evidence_scope": EVIDENCE_SCOPE,
            "harness_validator_rax": [report["harness_validator_rax"] for report in reports],
            "harness_decoded_matches_input": [report["harness_decoded_matches_input"] for report in reports],
            "harness_negative_control_branch": negative_report["harness_rc03_branch"],
            "harness_marker_mismatch_control_branch": mismatch_report["harness_rc03_branch"],
        }
        print(json.dumps(result, indent=2))
        return 0

    if args.response:
        source = None
        response_input = load_response(args)
    else:
        source = load_input(args)
        response_input = None
    report, response_before_decode, decoded, caller_structure_after = run_one(
        args, source, response_input
    )
    if args.out_dir:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        (args.out_dir / "response_before_decode.bin").write_bytes(response_before_decode)
        (args.out_dir / "decoded_output.bin").write_bytes(decoded)
        (args.out_dir / "caller_structure_after_decode.bin").write_bytes(
            caller_structure_after
        )
        (args.out_dir / "decode_report.json").write_text(
            json.dumps(report, indent=2) + "\n", encoding="utf-8"
        )
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
