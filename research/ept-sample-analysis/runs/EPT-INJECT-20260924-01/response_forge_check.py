from pathlib import Path
import hashlib
import json
import sys
sys.path.insert(0, str(Path('<HOST_PATH>/EPT/method/harnesses')))
from core_response_validator_reference import globals_from_args, validate_response

response = Path('<HOST_PATH>/CTF/forge_license_response_284.bin').read_bytes()
g = {
    'g340': 0x13579bdf,
    'g344': 0x2468ace0,
    'g348': 0x01020304,
    'g34c': 0x11223344,
    'g350': 0x55667788,
    'g354': 0x99aabbcc,
}
accepted, marker = validate_response(response, g)
result = {
    'response_bytes': len(response),
    'response_sha256': hashlib.sha256(response).hexdigest(),
    'reference_validator_accepted': accepted,
    'reference_validator_marker': f'0x{marker:08x}',
    'reference_marker_matches_g340': marker == g['g340'],
    'evidence_scope': 'offline_reference_synthetic_response',
}
print(json.dumps(result, indent=2))
if not accepted or marker != g['g340']:
    raise SystemExit(1)
