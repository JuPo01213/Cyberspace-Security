import re, struct, json, os

IMG = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\image_140000000.bin"
OUT = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\setup_refs.json"
BASE = 0x140000000
data = open(IMG, 'rb').read()
n = len(data)

# 1) dump printable strings in the Setup stage-name region
lo, hi = 0x140f92d80, 0x140f93400
region = data[lo - BASE: hi - BASE]
print("=== strings in Setup region ===")
outs = []
for m in re.finditer(rb"[\x20-\x7e]{6,}", region):
    va = BASE + (lo - BASE) + m.start()
    s = m.group().decode('latin1')
    outs.append((va, s))
    print(f"  {va:#x}  {s}")
json.dump([{"va": hex(v), "s": s} for v, s in outs], open(OUT, "w"), indent=2)

# 2) scan RIP-relative LEA/MOV references to any of those strings
targets = {v for v, _ in outs}
pat = re.compile(rb"[\x48\x4c][\x8d\x8b][\x05\x0d\x15\x1d\x25\x2d\x35\x3d]")
refs = {}
cnt = 0
for m in pat.finditer(data):
    i = m.start()
    if i + 7 > n:
        continue
    disp = struct.unpack_from('<i', data, i + 3)[0]
    tgt = (BASE + i) + 7 + disp
    cnt += 1
    if tgt in targets:
        refs.setdefault(hex(tgt), []).append(hex(BASE + i))
print()
print("scan candidates:", cnt)
print("=== refs to Setup strings ===")
for k, v in sorted(refs.items()):
    s = dict((hex(a), b) for a, b in outs).get(k, '?')
    print(f"  {k} <- {v}  ({s})")
json.dump(refs, open(r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\setup_string_refs.json", "w"), indent=2)
