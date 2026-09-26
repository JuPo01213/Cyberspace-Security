import struct, os, hashlib, json, sys

DUMP = r"<HOST_PATH>\EPT\runs\EPT-INJECT-20260925-23\harvest\mem_parent.dmp"
OUTDIR = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01"
IMGBASE = 0x140000000
IMGSIZE = 0x3f83000

data = open(DUMP, 'rb').read()
sig, ver, nstreams, dirrva = struct.unpack_from('<IIII', data, 0)
if sig != 0x504D444D:
    print("BAD_SIGNATURE", hex(sig)); sys.exit(1)
streams = []
for i in range(nstreams):
    st, ds, rva = struct.unpack_from('<III', data, dirrva + i * 12)
    streams.append((st, ds, rva))
print("streams:", [(s[0], s[1]) for s in streams])

mem = [s for s in streams if s[0] == 9]
if not mem:
    print("NO_MEMORY64_LIST"); sys.exit(1)
ds, rva = mem[0][1], mem[0][2]
nranges, baserva = struct.unpack_from('<QQ', data, rva)
print("nranges:", nranges, "baserva:", hex(baserva))

ranges = []
cursor = baserva
for i in range(nranges):
    start, size = struct.unpack_from('<QQ', data, rva + 16 + i * 16)
    ranges.append((start, size, cursor))
    cursor += size

img = bytearray(IMGSIZE)
present = 0
hits = 0
for start, size, off in ranges:
    if start + size <= IMGBASE or start >= IMGBASE + IMGSIZE:
        continue
    hits += 1
    lo = max(start, IMGBASE)
    hi = min(start + size, IMGBASE + IMGSIZE)
    n = hi - lo
    src = off + (lo - start)
    img[lo - IMGBASE: hi - IMGBASE] = data[src: src + n]
    present += n

out = os.path.join(OUTDIR, "image_140000000.bin")
open(out, 'wb').write(img)
print("ranges_overlapping_image:", hits)
print("image_bytes_present:", present, "of", IMGSIZE, "= %.2f%%" % (100.0 * present / IMGSIZE))
print("image_sha256:", hashlib.sha256(bytes(img)).hexdigest().upper())
print("wrote:", out)

probe = {
  "0x1416F98F0": 0x1416F98F0,
  "0x14166F7B6": 0x14166F7B6,
  "0x14251699c": 0x14251699c,
  "0x1403b3d30": 0x1403b3d30,
}
for name, va in probe.items():
    o = va - IMGBASE
    if 0 <= o < IMGSIZE:
        chunk = bytes(img[o: o + 16])
        print(name, "->", chunk.hex(), "all_zero" if chunk == b"\x00"*16 else "")

json.dump({"nranges": nranges, "image_bytes_present": present, "image_size": IMGSIZE},
          open(os.path.join(OUTDIR, "image_extract_meta.json"), "w"), indent=2)
