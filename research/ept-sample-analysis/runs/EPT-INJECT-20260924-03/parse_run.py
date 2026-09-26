import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
HARVEST = ROOT / 'harvest'
DERIVED = ROOT / 'derived'
DERIVED.mkdir(exist_ok=True)

log_path = HARVEST / 'cdb.stdout.txt'
if not log_path.exists():
    log_path = HARVEST / 'cdb.log'
text = log_path.read_text(encoding='utf-8', errors='replace') if log_path.exists() else ''
lines = text.splitlines()
markers = [
    'INJ2_PARENT_READY', 'INJ2_CHILD_ATTACHED', 'INJ2_CHILD_BPS_ARMING',
    'INJ2_CHILD_BPS_ARMED', 'INJ2_DEVICE_CALLSITE', 'INJ2_DEVICE_ENTRY',
    'INJ2_DEVICEIO_ENTRY', 'INJ2_DEVICE_RETURN', 'INJ2_RC03_ENTRY',
    'INJ2_MARKER_CHECK', 'INJ2_RC06_ENTRY', 'INJ2_RC06_AFTER_TRANSFORM',
    'INJ2_CALLER_AFTER_COPY', 'INJ2_NATIVE_RETURN_PRE', 'INJ2_NATIVE_RETURN',
    'INJ2_AV',
]
marker_hits = {}
for marker in markers:
    marker_hits[marker] = [i + 1 for i, line in enumerate(lines) if line.strip() == f'[{marker}]']

# A marker may also appear in command echo. Only an independent full-line marker is counted.
def register_value_after(marker):
    hits = marker_hits.get(marker, [])
    for line_no in hits:
        for line in lines[line_no:line_no + 25]:
            m = re.search(r'\b(?:e|r)?ax\s*=\s*([0-9a-fA-F`]+)', line)
            if m:
                raw = m.group(1).replace('`', '')
                try:
                    return int(raw, 16), line_no
                except ValueError:
                    pass
    return None, None

native_return, native_return_marker_line = register_value_after('INJ2_NATIVE_RETURN')

def read_bytes(name):
    p = HARVEST / name
    return p.read_bytes() if p.exists() else None

caller_before = read_bytes('caller_before.bin')
caller_after = read_bytes('caller_after.bin')
response_before = read_bytes('response_before_inject.bin')
response_after = read_bytes('response_after_inject.bin')
forge = read_bytes('forge_license_response_284.bin')

def diff_count(a, b):
    if a is None or b is None:
        return None
    n = min(len(a), len(b))
    return sum(x != y for x, y in zip(a[:n], b[:n])) + abs(len(a) - len(b))

caller_diff = diff_count(caller_before, caller_after)
response_diff = diff_count(response_before, response_after)
response_matches_fixture = response_after == forge if response_after is not None and forge is not None else None

# Extract independent marker lines with a small surrounding excerpt for audit.
marker_excerpt = {}
for marker, hits in marker_hits.items():
    marker_excerpt[marker] = []
    for line_no in hits:
        lo = max(0, line_no - 1)
        hi = min(len(lines), line_no + 8)
        marker_excerpt[marker].append({'line': line_no, 'excerpt': lines[lo:hi]})

result = {
    'run_id': 'EPT-INJECT-20260924-03',
    'evidence_scope': 'real_sample_guest_run_injected_io',
    'process_model': 'debugger_launch',
    'log_path': str(log_path),
    'log_present': log_path.exists(),
    'marker_hits': marker_hits,
    'marker_excerpt': marker_excerpt,
    'target_native_return': native_return if native_return is not None else 'NOT_OBSERVED',
    'native_return_marker_line': native_return_marker_line,
    'target_caller_diff_bytes': caller_diff if caller_diff is not None else 'NOT_OBSERVED',
    'caller_before_bytes': len(caller_before) if caller_before is not None else None,
    'caller_after_bytes': len(caller_after) if caller_after is not None else None,
    'response_before_bytes': len(response_before) if response_before is not None else None,
    'response_after_bytes': len(response_after) if response_after is not None else None,
    'response_diff_bytes': response_diff if response_diff is not None else 'NOT_OBSERVED',
    'response_after_matches_fixture': response_matches_fixture,
    'response_source_scope': 'offline_reference_synthetic_response',
    'rc06_entry': bool(marker_hits.get('INJ2_RC06_ENTRY')),
    'rc06_return': bool(marker_hits.get('INJ2_NATIVE_RETURN')),
    'post_decode_observation': 'REQUIRES_PROCESS_FILE_REGISTRY_NETWORK_CORRELATION',
}
(DERIVED / 'target_seam.json').write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding='utf-8')
print(json.dumps(result, indent=2, ensure_ascii=False))
