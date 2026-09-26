"""Verify exact facts in a harvested debugger listing; never open sample bytes."""
import hashlib
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent
listing = root / 'offline.stdout.txt'
text = listing.read_text(encoding='utf-8-sig')
rows = {}
for line in text.splitlines():
    match = re.match(r'^([0-9a-f]{8}`[0-9a-f]{8})\s+([0-9a-f]+)\s+(.+)$', line, re.I)
    if match:
        address = int(match[1].replace('`', ''), 16)
        rows.setdefault(address, set()).add((match[2].lower(), match[3]))
expected = {
    0x1407a4441: '4181f87a030000',
    0x1407a4448: '0f84ba010000',
    0x1407a4608: '488d0d71039b00',
    0x1407a460f: '488d5570',
    0x1407a4613: 'b806000000',
    0x1407a4656: '488d8980000000',
    0x1407a4665: '488d9280000000',
    0x1407a466c: '4883e801',
    0x1407a4670: '75ae',
    0x1407a46a8: '488b4270',
    0x1407a46b0: '0fb74278',
    0x1407a46b4: '66894178',
}
for address, raw in expected.items():
    matches = rows.get(address, set())
    assert len(matches) == 1, (hex(address), matches)
    assert next(iter(matches))[0] == raw, hex(address)
assert re.search(r'^LOCAL_CONFIG_FOLLOWUP_END\s*$', text, re.M)
base = 0x141154980
length = 6 * 0x80 + 0x70 + 8 + 2
assert length == 0x37a
fields = [
    (0x141154ae7, 1, 'nonzero first byte; also passed by address to CardLogin candidate'),
    (0x141154ce9, 4, 'nonzero field; semantic type unresolved'),
    (0x141154ced, 4, 'compared with 1'),
    (0x141154cf1, 4, 'compared with 1'),
    (0x141154cf6, 4, 'mode candidate; compared with 2 in save-entry listing'),
]
for address, width, _ in fields:
    assert 0 <= address-base and address-base+width <= length
report = {
    'evidence_scope': 'offline_historical_dump_listing_verification',
    'input_dump_sha256': 'CA0FFCEC87A8580E9BFDEF4DAAF90C97FB06A53D597028020FE1EC714830E60D',
    'listing_sha256': hashlib.sha256(listing.read_bytes()).hexdigest().upper(),
    'verified_instruction_count': len(expected),
    'configuration_base': hex(base),
    'plaintext_length_bytes': length,
    'copy_extent_exclusive': hex(base+length),
    'fields': [{'va': hex(a), 'offset': hex(a-base), 'width': w, 'meaning_boundary': m} for a,w,m in fields],
    'sample_launched': False,
    'validation_result_modified': False,
    'authorization_status': 'AUTH_GATE_UNRESOLVED',
    'limitations': [
        'Historical snapshot, not an execution trace of the listed path.',
        'No proof of a valid license or natural state production.',
        'Protected crypto-wrapper API targets remain unresolved.',
        'Exact byte assertions do not validate control flow outside the selected blocks.',
    ],
}
(root / 'listing-facts.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
