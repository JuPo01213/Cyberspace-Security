import re, struct
IMG = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\image_140000000.bin"
BASE = 0x140000000
data = open(IMG,"rb").read()
pats = [b"Config", b"config", b".dat", b".cfg", b".ini", b"Software", b"SOFTWARE", b"CurrentVersion", b"Hwid", b"HWID", b"hwid", b"Stored", b"SaveConfig", b"LoadConfig", b"EPT.dat", b"Hardware.dat"]
hits = {}
for p in pats:
    out = []
    for m in re.finditer(re.escape(p), data):
        va = BASE + m.start()
        s = data[max(0,m.start()-48):m.start()+64]
        txt = re.sub(rb"[^\x20-\x7e]", b".", s).decode("latin1")
        out.append((va, txt))
        if len(out) >= 12: break
    hits[p.decode()] = out
for k, v in hits.items():
    print("=== " + k + " (" + str(len(v)) + ") ===")
    for va, txt in v:
        print(f"  {va:#x}  {txt}")
print()
print("=== UTF-16LE targeted ===")
for p in [b"Config", b".dat", b".ini", b"Software\\", b"Hardware"]:
    u = p.decode().encode("utf-16le")
    n = 0
    for m in re.finditer(re.escape(u), data):
        va = BASE + m.start()
        s = data[max(0,m.start()-48):m.start()+72]
        txt = s.decode("utf-16le", "replace")
        txt = re.sub(r"[^\x20-\x7e]", ".", txt)
        print(f"  [{p.decode()}] {va:#x}  {txt}")
        n += 1
        if n >= 8: break
