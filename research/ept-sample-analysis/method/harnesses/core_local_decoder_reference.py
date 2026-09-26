"""Pure-Python local decoder reference for the recovered genB user-mode path.

This is the deterministic, offline portion of the recovered pipeline:

    268-byte input
      -> RC00 transform + state builder
      -> 284-byte response-shaped buffer
      -> RC03 validator + marker check
      -> RC06 transform
      -> 268-byte output

``--input`` constructs a synthetic echo response from a known input.  It is
useful for regression and proves the two native transforms cancel.  ``--response``
consumes a caller-supplied 284-byte response-shaped buffer and reports the
observed RC03/RC04/RC06 branch.  Neither mode opens a device, starts the sample,
loads authorization, accesses the network, or decodes the embedded token.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from core_predevice_reference import (
    INPUT_BYTES,
    build_state,
    local_transform,
)
from core_response_validator_reference import (
    RESPONSE_BYTES,
    STATE_BYTES,
    validate_response,
)


DEFAULT_GLOBALS = {
    "g340": 0x13579BDF,
    "g344": 0x2468ACE0,
    "g348": 0x01020304,
    "g34c": 0x11223344,
    "g350": 0x55667788,
    "g354": 0x99AABBCC,
}
EVIDENCE_SCOPE = "offline_reference_synthetic_response"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def make_request(source: bytes, globals_: dict[str, int]) -> bytes:
    """Build the exact 0x11c RC00 request shape from a 0x10c payload."""

    if len(source) != INPUT_BYTES:
        raise ValueError(f"input must be exactly {INPUT_BYTES} bytes")
    transformed = local_transform(source, globals_)
    return build_state(transformed, globals_) + transformed


def decode_response(
    response: bytes, globals_: dict[str, int], source: bytes | None = None
) -> tuple[dict[str, object], bytes]:
    """Run the recovered RC03/RC04/RC06 user-mode response path."""

    if len(response) != RESPONSE_BYTES:
        raise ValueError(f"response must be exactly {RESPONSE_BYTES} bytes")

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

    report: dict[str, object] = {
        "status": "completed",
        "evidence_scope": EVIDENCE_SCOPE,
        "implementation": "pure_python_local_decoder_reference",
        "response_bytes": len(response),
        "response_sha256": sha(response),
        "reference_validator_rax": f"0x{int(accepted):08x}",
        "reference_validator_marker": f"0x{marker:08x}",
        "reference_marker_expected_g340": f"0x{globals_['g340']:08x}",
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
    }
    if source is not None:
        report["input_bytes"] = len(source)
        report["input_sha256"] = sha(source)
    return report, decoded


def read_exact(path: Path, expected: int, label: str) -> bytes:
    data = path.read_bytes()
    if len(data) != expected:
        raise ValueError(f"{label} must be exactly {expected} bytes, got {len(data)}")
    return data


def parse_u32(value: str) -> int:
    return int(value, 0) & 0xFFFFFFFF


def globals_from_args(args: argparse.Namespace) -> dict[str, int]:
    return {name: getattr(args, name) for name in DEFAULT_GLOBALS}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="268-byte local payload")
    parser.add_argument("--hex", dest="hex_input", help="268-byte payload as hex")
    parser.add_argument("--response", type=Path, help="284-byte response-shaped buffer")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--out-dir", type=Path)
    for name, default in DEFAULT_GLOBALS.items():
        parser.add_argument(f"--{name}", default=f"0x{default:08x}", type=parse_u32)
    args = parser.parse_args()
    selected = sum(bool(value) for value in (args.input, args.hex_input, args.response))
    if args.self_test and selected:
        parser.error("--self-test cannot be combined with --input, --hex or --response")
    if not args.self_test and selected != 1:
        parser.error("provide exactly one of --input, --hex or --response, unless using --self-test")
    if args.response and (args.input or args.hex_input):
        parser.error("--response cannot be combined with --input or --hex")
    return args


def run_self_test(globals_: dict[str, int]) -> dict[str, object]:
    vectors = [bytes(INPUT_BYTES), bytes(range(256)) + bytes(range(12))]
    positive = []
    for source in vectors:
        response = make_request(source, globals_)
        report, decoded = decode_response(response, globals_, source)
        if report["reference_rc03_branch"] != "RC06 success" or decoded != source:
            raise AssertionError("local decoder round-trip failed")
        positive.append(report)

    negative_report, _ = decode_response(bytes(RESPONSE_BYTES), globals_)
    if negative_report["reference_rc03_branch"] != "RC03 decode_failed":
        raise AssertionError("zero response did not take RC03 decode_failed")

    mismatch_globals = dict(globals_)
    mismatch_globals["g340"] ^= 1
    mismatch_report, _ = decode_response(make_request(vectors[0], globals_), mismatch_globals)
    if mismatch_report["reference_rc03_branch"] != "RC04 session_mismatch":
        raise AssertionError("stale marker did not take RC04 session_mismatch")

    return {
        "status": "self_test_passed",
        "evidence_scope": EVIDENCE_SCOPE,
        "implementation": "pure_python_local_decoder_reference",
        "positive_vectors": [item["input_sha256"] for item in positive],
        "positive_branches": [item["reference_rc03_branch"] for item in positive],
        "negative_control_branch": negative_report["reference_rc03_branch"],
        "marker_mismatch_control_branch": mismatch_report["reference_rc03_branch"],
    }


def main() -> int:
    args = parse_args()
    globals_ = globals_from_args(args)
    if args.self_test:
        print(json.dumps(run_self_test(globals_), indent=2))
        return 0

    if args.response:
        source = None
        response = read_exact(args.response, RESPONSE_BYTES, "response")
        semantic_role = "genB_user_mode_response_decoder"
        request = None
    else:
        if args.input:
            source = read_exact(args.input, INPUT_BYTES, "input")
        else:
            try:
                source = bytes.fromhex(args.hex_input)
            except ValueError as exc:
                raise ValueError("--hex is not valid hexadecimal") from exc
        if len(source) != INPUT_BYTES:
            raise ValueError(f"input must be exactly {INPUT_BYTES} bytes, got {len(source)}")
        request = make_request(source, globals_)
        response = request
        semantic_role = "genB_user_mode_decode_success_seam_synthetic_echo"

    report, decoded = decode_response(response, globals_, source)
    report["semantic_role"] = semantic_role
    if request is not None:
        report["request_bytes"] = len(request)
        report["request_sha256"] = sha(request)
        report["synthetic_response"] = True
    else:
        report["synthetic_response"] = False

    if args.out_dir:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        if request is not None:
            (args.out_dir / "request.bin").write_bytes(request)
        (args.out_dir / "response.bin").write_bytes(response)
        (args.out_dir / "decoded_output.bin").write_bytes(decoded)
        (args.out_dir / "decode_report.json").write_text(
            json.dumps(report, indent=2) + "\n", encoding="utf-8"
        )
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
