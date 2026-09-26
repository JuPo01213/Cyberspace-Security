import struct, collections

BASE = 0x140000000
data = open(r'<HOST_PATH>\EPT\runs\EPT-INJECT-20260925-15\harvest\mem_140000000_1000000.bin', 'rb').read()

targets = {
    0x140f9252d: 'StoredAuthorizationUsable',
    0x140f93624: 'skip_driver_load_because...',
    0x140f92508: 'StoredVerify.begin',
    0x140f92520: 'StoredVerify.StoredAuthorizationUsable',
    0x140f92640: 'StoredVerify.SP_...',
    0x140f92880: 'StoredVerify.all...',
}
hits = collections.defaultdict(list)
b = data
n = len(b)
for i in range(0, n - 7):
    if 0x48 <= b[i] <= 0x4F and b[i+1] == 0x8D and (b[i+2] & 0xC7) == 0x05:
        disp = struct.unpack_from('<i', b, i+3)[0]
        tgt = BASE + i + 7 + disp
        for t in targets:
            if 0 <= tgt - t <= 0x80:
                hits[t].append(BASE + i)
for i in range(0, n - 10):
    if b[i] in (0x48, 0x49, 0x4A, 0x4B) and 0xB8 <= b[i+1] <= 0xBF:
        imm = struct.unpack_from('<Q', b, i+2)[0]
        for t in targets:
            if 0 <= imm - t <= 0x80:
                hits[t].append(BASE + i)

for t in sorted(targets):
    lst = sorted(set(hits.get(t, [])))
    print('0x%x  %-45s refs=%d' % (t, targets[t], len(lst)))
    for a in lst[:12]:
        print('      code 0x%x' % a)
