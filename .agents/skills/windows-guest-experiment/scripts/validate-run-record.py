#!/usr/bin/env python3
import json, sys
from pathlib import Path

ALLOWED_STATUS={"CREATED","RUNNING","FINISHED"}
ALLOWED_OUTCOMES={None,"POSITIVE","NEGATIVE","INCONCLUSIVE","INVALID_INSTRUMENT","INFRA_FAILURE"}

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

for k in ("schema_version","run_id","goal_ref","subject","status","outcome"):
    if k not in d:
        fail(f"missing field: {k}")

if d["schema_version"] != 3:
    fail("schema_version must be 3")
if not isinstance(d["run_id"],str) or not d["run_id"].strip():
    fail("run_id must be non-empty")
if not isinstance(d["goal_ref"],str) or not d["goal_ref"].strip():
    fail("goal_ref must be non-empty")
if not isinstance(d["subject"],str) or not d["subject"].strip():
    fail("subject must be non-empty")
if d["status"] not in ALLOWED_STATUS:
    fail("invalid status")
if d["outcome"] not in ALLOWED_OUTCOMES:
    fail("invalid outcome")
if d["status"] == "FINISHED" and d["outcome"] is None:
    fail("FINISHED run requires outcome")
if "interventions" in d and (not isinstance(d["interventions"],list) or not all(isinstance(x,str) and x.strip() for x in d["interventions"])):
    fail("interventions must be a list of non-empty strings")

print("OK")
