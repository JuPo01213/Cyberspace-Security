import re
IMG = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\image_140000000.bin"
BASE = 0x140000000
data = open(IMG,"rb").read()
def clean(x):
    if isinstance(x, bytes): return x.decode("latin1")
    return x
print("=== ASCII paths ===")
seen = set()
for m in re.finditer(rb"[A-Za-z]:\\[\x20-\x7e]{2,120}", data):
    va = BASE + m.start()
    if m.group() in seen: continue
    seen.add(m.group())
    print(f"  A {va:#x}  {clean(m.group())}")
    if len(seen) > 60: break
print()
print("=== UTF16LE paths ===")
seen2 = set()
for m in re.finditer(rb"(?:[A-Za-z]\x00:\x00\\\x00)(?:[\x20-\x7e]\x00){2,120}", data):
    va = BASE + m.start()
    s = m.group().decode("utf-16le","replace")
    if s in seen2: continue
    seen2.add(s)
    print(f"  U {va:#x}  {s}")
    if len(seen2) > 60: break
print()
print("=== registry-ish strings ===")
seen3 = set()
for m in re.finditer(rb"(?:SOFTWARE|SYSTEM|Software)[\\][\x20-\x7e]{4,90}", data):
    va = BASE + m.start()
    if m.group() in seen3: continue
    seen3.add(m.group())
    print(f"  R {va:#x}  {clean(m.group())}")
    if len(seen3) > 40: break
