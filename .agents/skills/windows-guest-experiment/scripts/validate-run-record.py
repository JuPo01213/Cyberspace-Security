#!/usr/bin/env python3
import json, sys
from pathlib import Path

ALLOWED_MODES={"natural","attach-after-launch","debugger-launch"}
ALLOWED_OUTCOMES={None,"POSITIVE","NEGATIVE","INCONCLUSIVE","INVALID_INSTRUMENT","INFRA_FAILURE"}
ALLOWED_SCOPES={"TARGET_NATURAL","TARGET_CONTROLLED","TARGET_INJECTED","HARNESS","SYNTHETIC","OFFLINE_REFERENCE"}

def fail(msg):
    print(f"INVALID: {msg}", file=sys.stderr)
    raise SystemExit(1)

if len(sys.argv)!=2:
    fail("usage: validate-run-record.py <run.json>")
p=Path(sys.argv[1])
try:
    d=json.loads(p.read_text(encoding="utf-8"))
except Exception as e:
    fail(f"cannot parse JSON: {e}")

for k in ("schema_version","run_id","objective","acceptance","acceptance_authority","evidence_scope","target","environment","phase","blocked_on","outcome"):
    if k not in d:
        fail(f"missing field: {k}")
if not d["run_id"] or not d["objective"]:
    fail("run_id/objective must be non-empty")
if not isinstance(d["acceptance"],list) or not d["acceptance"]:
    fail("acceptance must be a non-empty list")
if d["environment"].get("observation_mode") not in ALLOWED_MODES:
    fail("invalid observation_mode")
if d["outcome"] not in ALLOWED_OUTCOMES:
    fail("invalid outcome")
if not d["target"].get("sha256"):
    fail("target.sha256 is required")
if not isinstance(d["acceptance_authority"],dict) or not d["acceptance_authority"].get("reference"):
    fail("acceptance_authority.reference is required")
if not isinstance(d["evidence_scope"],dict) or d["evidence_scope"].get("class") not in ALLOWED_SCOPES:
    fail("invalid evidence_scope.class")
print("OK")
