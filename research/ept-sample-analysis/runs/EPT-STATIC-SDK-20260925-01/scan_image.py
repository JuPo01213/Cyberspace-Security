import re, os, json

IMG = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\image_140000000.bin"
OUTDIR = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01"
BASE = 0x140000000
data = open(IMG, 'rb').read()
print("image_size:", len(data))

needles = [
    b"socket\x00", b"connect\x00", b"send\x00", b"recv\x00", b"closesocket\x00",
    b"WSAStartup\x00", b"WSAGetLastError\x00", b"ws2_32.dll\x00", b"WS2_32.dll\x00",
    b"ws2_32", b"WS2_32", b"WSAStartup", b"gethostbyname\x00", b"select\x00",
    b"ioctlsocket\x00", b"htons\x00", b"inet_addr\x00", b"bind\x00", b"listen\x00",
    b"accept\x00", b"getaddrinfo\x00", b"WSAIoctl\x00", b"shutdown\x00",
    b"yz.hwid001.com", b"kernel32.dll\x00", b"ntdll.dll\x00", b"LoadLibraryA\x00",
    b"GetProcAddress\x00", b"HP_WKS_SWTOOLS_DRIVER", b"\\\\\\\\.\\\\HP_WKS",
]

report = {}
for n in needles:
    offs = []
    start = 0
    while True:
        i = data.find(n, start)
        if i < 0:
            break
        offs.append(i)
        start = i + 1
        if len(offs) > 200:
            break
    report[n.decode('latin1')] = {
        "count": len(offs),
        "vas": [hex(BASE + o) for o in offs[:20]],
    }
    print(repr(n.decode('latin1')), len(offs), [hex(BASE + o) for o in offs[:8]])

json.dump(report, open(os.path.join(OUTDIR, "image_string_scan.json"), "w"), indent=2)

# section table
import struct
pe = data[0x3c:0x40]
e_lfanew = struct.unpack_from('<I', data, 0x3c)[0]
print("e_lfanew", hex(e_lfanew))
nsec = struct.unpack_from('<H', data, e_lfanew + 6)[0]
opt = struct.unpack_from('<H', data, e_lfanew + 20)[0]
print("nsec", nsec, "optsize", hex(opt))
secoff = e_lfanew + 24 + opt
secs = []
for i in range(nsec):
    o = secoff + i * 40
    nm = data[o:o+8].rstrip(b"\x00").decode('latin1')
    vsize, va, rsize, raw = struct.unpack_from('<IIII', data, o + 8)
    secs.append({"name": nm, "va": hex(BASE + va), "vsize": vsize, "vsize_hex": hex(vsize)})
    print(f"  {nm:12s} VA {BASE+va:#x} vsize {vsize:#x}")
json.dump(secs, open(os.path.join(OUTDIR, "image_sections.json"), "w"), indent=2)
