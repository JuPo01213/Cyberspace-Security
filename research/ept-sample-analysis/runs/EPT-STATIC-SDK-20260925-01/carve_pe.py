import struct, json, os

IMG = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\image_140000000.bin"
OUTDIR = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01"
BASE = 0x140000000
data = open(IMG, 'rb').read()
n = len(data)
print("image_size", n)

cands = []
i = 0
while True:
    i = data.find(b"MZ", i)
    if i < 0:
        break
    try:
        if i + 0x40 > n:
            break
        elfa = struct.unpack_from('<I', data, i + 0x3c)[0]
        if 0x40 <= elfa < 0x1000 and i + elfa + 0x100 <= n and data[i+elfa:i+elfa+4] == b"PE\x00\x00":
            machine, nsec = struct.unpack_from('<HH', data, i + elfa + 4)
            ts = struct.unpack_from('<I', data, i + elfa + 8)[0]
            optsize = struct.unpack_from('<H', data, i + elfa + 20)[0]
            magic = struct.unpack_from('<H', data, i + elfa + 24)[0]
            szimg = struct.unpack_from('<I', data, i + elfa + 24 + 56)[0]
            entry = struct.unpack_from('<I', data, i + elfa + 24 + 16)[0]
            cands.append({
                "va": hex(BASE + i),
                "offset": hex(i),
                "machine": hex(machine),
                "nsec": nsec,
                "timestamp": hex(ts),
                "optsize": hex(optsize),
                "magic": hex(magic),
                "size_of_image": hex(szimg),
                "entry_rva": hex(entry),
            })
    except Exception as e:
        pass
    i += 1

print("embedded PE candidates:", len(cands))
for c in cands:
    print(" ", c)
json.dump(cands, open(os.path.join(OUTDIR, "embedded_pe_candidates.json"), "w"), indent=2)

# which section holds WS2_32.dll
for needle in (b"WS2_32.dll", b"LoadLibraryA", b"GetProcAddress"):
    j = data.find(needle)
    print(needle, "at", hex(BASE + j), "offset", hex(j))

# section ranges from image_sections.json
secs = json.load(open(os.path.join(OUTDIR, "image_sections.json")))
print("sections:", [(s["name"], s["va"], s["vsize_hex"]) for s in secs])
