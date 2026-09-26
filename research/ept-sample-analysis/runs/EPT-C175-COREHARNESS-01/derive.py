#!/usr/bin/env python3
# Host-side derivation & cross-checks for EPT-C175-COREHARNESS-01
import json, hashlib, os

RAW = "<HOST_PATH>/EPT/artifacts/evidence/C175_coreharness/raw"
CAP = "<HOST_PATH>/EPT/artifacts/captures/stream_C6"
FORGE = "<HOST_PATH>/CTF"

def sha(b): return hashlib.sha256(b).hexdigest()


def normalize_harness_report(report):
    """Normalize legacy C175 JSON without relabeling it as target evidence."""
    if "evidence_scope" in report:
        if report["evidence_scope"] != "caller_injection_harness":
            raise ValueError(f"unexpected evidence_scope: {report['evidence_scope']}")
        return report, False
    # C175 raw files were produced before the namespace migration. Keep them
    # immutable, but expose only scoped names in this derivation.
    mapping = {
        "harness_rc03_branch": "rc03_branch",
        "harness_validator_rax": "validator_rax",
        "harness_validator_accepted": "validator_accepted",
        "harness_marker_matches_g340": "marker_matches_g340",
        "harness_decoded_output_bytes": "decoded_output_bytes",
        "harness_caller_output_written": "caller_output_written",
        "harness_caller_diff_bytes": None,
        "harness_caller_output_offset": "caller_output_offset",
        "harness_decoded_output_sha256": "decoded_output_sha256",
        "harness_caller_output_sha256": "caller_output_sha256",
    }
    normalized = {"evidence_scope": "caller_injection_harness"}
    for scoped, legacy in mapping.items():
        if legacy is not None:
            normalized[scoped] = report[legacy]
    normalized["harness_caller_diff_bytes"] = None
    return normalized, True


meta = json.load(open(f"{RAW}/run_meta.json"))
m = meta["modes"]

print("=== SELF-TEST ===")
print("  exit:", m["self_test"]["exit_code"], "| pid:", m["self_test"]["pid"], "| ppid:", m["self_test"]["ppid"])
print("  stdout:", m["self_test"]["stdout"].splitlines()[0], "...")

for label in ("input_268","response_284"):
    r, legacy_report = normalize_harness_report(m[label]["report"])
    print(f"\n=== {label} ===")
    print("  pid:", m[label]["pid"], "| ppid:", m[label]["ppid"], "| ppid_live:", m[label].get("ppid_live"),
          "| exit:", m[label]["exit_code"])
    scope = r.get("evidence_scope", "UNKNOWN_SCOPE")
    print("  evidence_scope:", scope, "| legacy_raw_report:", legacy_report)
    print("  harness_rc03_branch:", r["harness_rc03_branch"])
    print("  harness_validator_rax:", r["harness_validator_rax"], "| harness_validator_accepted:", r["harness_validator_accepted"],
          "| harness_marker_matches_g340:", r["harness_marker_matches_g340"])
    print("  harness_decoded_output_bytes:", r["harness_decoded_output_bytes"],
          "| harness_caller_output_written:", r["harness_caller_output_written"],
          "| harness_caller_output_offset:", r["harness_caller_output_offset"])
    print("  harness_caller_diff_bytes:", r["harness_caller_diff_bytes"], "(derived below from immutable artifact)")
    print("  harness_decoded_output_sha256:", r["harness_decoded_output_sha256"])
    print("  harness_caller_output_sha256 :", r["harness_caller_output_sha256"])

print("\n=== target-level fields (same real sample Guest run) ===")
print("  target_native_return: NOT_COLLECTED")
print("  target_caller_diff_bytes: NOT_COLLECTED")
print("  post_decode_behavior: NOT_OBSERVED")

# Cross-check: input_268 decoded == forge_caller_input_268.bin
forge_in = open(f"{FORGE}/forge_caller_input_268.bin","rb").read()
decoded = open(f"{RAW}/input__decoded_output.bin","rb").read()
print("\n=== ROUND-TRIP (input_268 mode) ===")
print("  forge_caller_input_268.bin len:", len(forge_in), "sha256:", sha(forge_in))
print("  decoded_output.bin        len:", len(decoded),       "sha256:", sha(decoded))
print("  MATCH:", sha(forge_in)==sha(decoded) and bytes(decoded)==forge_in)

# response_284 decode should also equal forge_caller_input_268.bin
dec_resp = open(f"{RAW}/response__decoded_output.bin","rb").read()
print("\n=== RESPONSE->INPUT pairing ===")
print("  response_284 decoded sha256:", sha(dec_resp))
print("  equals forge_caller_input_268.bin:", sha(dec_resp)==sha(forge_in))

# caller +0x80 before/after diff (input_268 mode)
# This is a harness-local diff only; it must not be emitted as target_caller_diff_bytes.
INPUT_BYTES = 0x10C
CALLER_STRUCT = 0x80 + INPUT_BYTES  # 396
before = bytearray(CALLER_STRUCT)
before[:INPUT_BYTES] = forge_in[:INPUT_BYTES]  # harness places source at [0:0x10C]
after = open(f"{RAW}/input__caller_structure_after_decode.bin","rb").read()
assert len(after)==CALLER_STRUCT, f"after len {len(after)} != {CALLER_STRUCT}"
changed = [i for i in range(CALLER_STRUCT) if before[i]!=after[i]]
print("\n=== harness caller_structure +0x80 before/after diff (input_268) ===")
print("  evidence_scope: caller_injection_harness")
print("  harness_caller_diff_bytes:", len(changed))
print("  harness_caller_changed_range:", f"0x{changed[0]:x}-0x{changed[-1]:x}" if changed else "NONE")
print("  all in [0x80, 0x80+0x10C)?", all(0x80<=i<0x80+INPUT_BYTES for i in changed))
print("  harness_after_output_equals_decoded:", bytes(after[0x80:0x80+INPUT_BYTES])==decoded)
print("  target_caller_diff_bytes: NOT_COLLECTED")

# evidence-level sha of harvested artifacts
print("\n=== harvested artifact hashes (HOST_VERIFIED) ===")
for f in ["input__decode_report.json","input__caller_structure_after_decode.bin",
          "input__decoded_output.bin","response__decode_report.json",
          "response__decoded_output.bin","run_meta.json","done.json"]:
    p=f"{RAW}/{f}"
    if os.path.exists(p):
        print(f"  {f}: {sha(open(p,'rb').read())[:16]}...")
print("\nALL DERIVATIONS DONE")
