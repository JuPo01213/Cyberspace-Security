import re, struct, sys, collections

BASE = 0x140000000
path = r'<HOST_PATH>\EPT\runs\EPT-INJECT-20260925-15\harvest\mem_140000000_1000000.bin'
data = open(path, 'rb').read()
print('dump bytes', hex(len(data)))

targets = {
    'StoredAuthorizationUsable@0x140f9252d': 0x140f9252d,
    'skip_driver_load@0x140f93624': 0x140f93624,
    'StoredVerify.begin@0x140f92508': 0x140f92508,
}
# also accept any address inside the string table region
def is_target(a):
    if 0x140f90000 <= a <= 0x140f95000:
        return True
    return any(abs(a - t) < 0x400 for t in targets.values())

hits = collections.defaultdict(list)
b = data
n = len(b)
# 1) lea r64, [rip+d]  : REX(0x48..0x4F) 8D modrm(mod=00,rm=101) disp32
for i in range(0, n - 7):
    if 0x48 <= b[i] <= 0x4F and b[i+1] == 0x8D and (b[i+2] & 0xC7) == 0x05:
        disp = struct.unpack_from('<i', b, i+3)[0]
        tgt = BASE + i + 7 + disp
        if is_target(tgt):
            hits[tgt].append((BASE + i, 'lea', disp))
# 2) mov r64, imm64 : REX.W(0x48..0x4B with B8..BF) -> 48 B8..BF
for i in range(0, n - 10):
    if b[i] in (0x48, 0x49, 0x4A, 0x4B) and 0xB8 <= b[i+1] <= 0xBF:
        imm = struct.unpack_from('<Q', b, i+2)[0]
        if is_target(imm):
            hits[imm].append((BASE + i, 'movabs', imm))

if not hits:
    print('NO xref found (lea/movabs)')
for t in sorted(hits):
    print('\n=== target 0x%x : %d refs' % (t, len(hits[t])))
    for a, k, d in hits[t][:40]:
        off = a - BASE
        raw = b[off:off+12].hex()
        print('  0x%x  %-6s disp=%s  bytes=%s' % (a, k, hex(d & 0xFFFFFFFFFFFFFFFF), raw))

# string table sanity
for name, t in targets.items():
    off = t - BASE
    print('\n%s -> %r' % (name, b[off:off+40]))

# keyword strings
print('\n=== keyword strings ===')
pat = re.compile(rb'[\x20-\x7e]{6,}')
kws = [b'http', b'license', b'auth', b'card', b'driver', b'verif', b'server', b'activ', b'HWID', b'HP_', b'WKS', b'token', b'key']
seen = set()
for m in pat.finditer(b):
    s = m.group()
    low = s.lower()
    if any(k.lower() in low for k in kws):
        if s in seen:
            continue
        seen.add(s)
        print('0x%x  %s' % (BASE + m.start(), s.decode('ascii', 'replace')[:120]))
    if len(seen) > 400:
        break
