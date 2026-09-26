import os, struct, json

IMG = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\image_140000000.bin"
OUTDIR = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01"
BASE = 0x140000000
data = open(IMG, 'rb').read()

def ctx(va, before=48, after=96):
    o = va - BASE
    seg = data[max(0,o-before): o+after]
    txt = "".join(chr(c) if 32 <= c < 127 else "." for c in seg)
    print(hex(va), "|", txt)
    return txt

print("=== contexts ===")
for va in (0x1407dccfe, 0x14252c850, 0x14234b0a2, 0x14251699c):
    ctx(va)

print()
print("=== cloud / plugin strings ===")
needles = [
    b"SP_CloudComputing_Callback", b"CloudComputing", b"cloudcomputing",
    b"CloudComputing.dll", b"SP_Cloud", b".dll", b"LoadLibrary",
    b"SP_Cloud_Beat", b"GetLastestVersionInfo", b"GetNotice",
    b"SP_Verify_CardLogin", b"SP_Verify_Init", b"SP_Verify_IsLogin",
    b"SP_Verify_GetServerOption", b"StoredVerify.SetHost",
    b"StoredAuthorizationUsable", b"skip_driver_load",
]
rep = {}
for n in needles:
    offs = []
    s = 0
    while True:
        i = data.find(n, s)
        if i < 0: break
        offs.append(BASE + i)
        s = i + 1
        if len(offs) > 400: break
    rep[n.decode('latin1')] = {"count": len(offs), "vas": [hex(x) for x in offs[:16]]}
    print(f"{n.decode('latin1'):32s} count={len(offs):5d} first={[hex(x) for x in offs[:6]]}")

print()
print("=== .dll name candidates (printable, around SP_Cloud) ===")
import re
hits = {}
for m in re.finditer(rb"[\x20-\x7e]{4,40}\.dll", data):
    s = m.group().decode('latin1')
    if any(k in s.lower() for k in ("cloud", "verif", "hwid", "ept", "hard", "sp_", "sdk", "auth", "lic")):
        hits.setdefault(s, []).append(BASE + m.start())
for k, v in sorted(hits.items()):
    print(f"  {k:44s} {len(v)} {[hex(x) for x in v[:5]]}")

json.dump({"cloud_strings": rep, "dll_candidates": {k: [hex(x) for x in v] for k, v in hits.items()}},
          open(os.path.join(OUTDIR, "cloud_plugin_strings.json"), "w"), indent=2)
