import re, struct, json
IMG = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\image_140000000.bin"
BASE = 0x140000000
data = open(IMG, "rb").read(); n = len(data)
targets = {
 0x140f92520: "StoredVerify.StoredAuthorizationUsable",
 0x140f92d48: "CliConfigUpdate.StoredAuthorizationUsable",
 0x140f93238: "StoredFlow.StoredAuthorizationUsable",
 0x140f932c0: "StoredFlow.VerifyStoredCardStatusBeforeUse",
 0x140f93350: "RUN dse_read",
 0x140f93420: "Run.StoredAuthorizationUsableBeforeDriver",
 0x140f93470: "RUN comm_init result",
 0x140f93570: "RUN apply soft_success",
 0x140f93620: "Run.skip_driver_load_because_authorization_not_usable",
 0x140f8cba0: "HP_WKS_SWTOOLS_DRIVER.sys helper",
 0x1407ea370: "device path \\\\.\\HP_WKS_SWTOOLS_DRIVER",
 0x140f8d160: "CI00 open_auth begin",
 0x140f8d370: "CI06 scan_existing",
 0x140f8d5a0: "CI16 comm_init new_load_ok",
 0x140f8d7b0: "RC00 send",
 0x140f8d810: "RC02 ioctl_failed",
 0x140f8d870: "RC03 decode_failed",
 0x140f8d8d0: "RC04 session_mismatch",
 0x140f8da70: "HS02 common_mismatch",
 0x140f8e370: "Hardware.ini path",
}
sections = [(".text",0x140001000,0x7d992c),(".rdata",0x1407db000,0x7c2dd0),(".data",0x140f9e000,0x1ce70c),(".pdata",0x14116d000,0x4f80),("_RDATA",0x141172000,0xfc),(".fptable",0x141173000,0x100),(".Sq>",0x141174000,0xee55f0),(".bs]",0x14205a000,0xf88),(".)Bu",0x14205b000,0x1f09b30),(".rsrc",0x143f65000,0x1d445)]
def sec(va):
    for nm,s,sz in sections:
        if s <= va < s+sz: return nm
    return "?"
refs = {}
def add(t, site, form):
    refs.setdefault(t, []).append((site, form))
rx1 = re.compile(rb"[\x8d\x8b\x89\x3b\x39][\x05\x0d\x15\x1d\x25\x2d\x35\x3d]")
for m in rx1.finditer(data):
    i = m.start()
    if i+6 > n: continue
    d = struct.unpack_from("<i", data, i+2)[0]
    t = BASE + i + 6 + d
    if t in targets: add(t, BASE+i, "rip6:"+hex(data[i]))
rx2 = re.compile(rb"[\x48\x49\x4c\x4d][\x8d\x8b\x89\x3b\x39][\x05\x0d\x15\x1d\x25\x2d\x35\x3d]")
for m in rx2.finditer(data):
    i = m.start()
    if i+7 > n: continue
    d = struct.unpack_from("<i", data, i+3)[0]
    t = BASE + i + 7 + d
    if t in targets: add(t, BASE+i, "rip7:"+hex(data[i+1]))
rx3 = re.compile(rb"[\x48\x49][\xb8-\xbf]")
for m in rx3.finditer(data):
    i = m.start()
    if i+10 > n: continue
    for off in (0,):
        v = struct.unpack_from("<Q", data, i+2)[0]
        if v in targets: add(v, BASE+i, "movabs")
for t in sorted(targets):
    sites = refs.get(t, [])
    nm = targets[t]
    if not sites:
        print(f"{t:#x}  {nm}  -> NO_RIP_REL_REF")
    else:
        s2 = ", ".join(f"{a:#x}({sec(a)},{f})" for a,f in sorted(sites))
        print(f"{t:#x}  {nm}  -> {len(sites)} refs: {s2}")
raw = []
for t in sorted(targets):
    b = struct.pack("<Q", t)
    pos = data.find(b)
    hits = 0
    while pos != -1 and hits < 6:
        raw.append((t, BASE+pos, sec(BASE+pos))); hits += 1; pos = data.find(b, pos+1)
print()
print("=== raw 8-byte absolute VA occurrences ===")
if not raw: print("  none")
for t,p,s in raw: print(f"  {t:#x} at {p:#x} ({s})")