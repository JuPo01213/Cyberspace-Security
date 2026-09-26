import struct
from capstone import *

b = open('runs/EPT-AUTHGATE-20260925-77/text_runtime.bin','rb').read()
DUMP_BASE = 0x140100000
DUMP_END = DUMP_BASE + len(b)
md = Cs(CS_ARCH_X86, CS_MODE_64)

LOGGER = 0x1405d5f80

# 1) find all e8 calls to LOGGER within the dump
sites = []
for off in range(len(b)-5):
    if b[off] == 0xE8:
        rel = struct.unpack_from('<i', b, off+1)[0]
        tgt = DUMP_BASE + off + 5 + rel
        if tgt == LOGGER:
            sites.append(DUMP_BASE + off)
print('logger call sites in dump:', len(sites))

# 2) for each site, disassemble backward-ish window: take 0x40 bytes before the call,
#    decode linearly from a few candidate starts, collect imm32 values (event IDs)
def imms_before(site, window=0x50):
    start_off = site - DUMP_BASE - window
    if start_off < 0: return []
    # try aligning: decode forward from several offsets, keep the decode that reaches the call
    best = []
    for delta in range(0, 0x11):
        so = start_off + delta
        ins_list = []
        ok = True
        addr = DUMP_BASE + so
        o = so
        while o < site - DUMP_BASE:
            try:
                ins = next(md.disasm(b[o:o+16], addr))
            except StopIteration:
                ok = False; break
            ins_list.append(ins)
            o += ins.size
            addr += ins.size
        if ok:
            best = ins_list
            break
    return best

event_map = {}
for s in sites:
    ins_list = imms_before(s)
    ids = []
    for ins in ins_list:
        m = re.search(r'0x[0-9a-f]{3,8}', ins.op_str) if (re := __import__('re')) else None
    import re as _re
    for ins in ins_list:
        for mm in _re.finditer(r'0x([0-9a-f]{3,8})', ins.op_str):
            v = int(mm.group(1), 16)
            if 0x100 <= v <= 0xFFFF and v not in (0x100,):
                ids.append(v)
    region = 'proto' if 0x140130000 <= s < 0x140180000 else 'other'
    event_map.setdefault(region, []).append((s, ids[-4:] if ids else []))

print('=== sites per region ===')
for r, lst in event_map.items():
    print(r, len(lst))
print('\n=== protocol-region sites with candidate event IDs (last 25) ===')
for s, ids in event_map.get('proto', [])[-25:]:
    print('  0x%08x ids=%s' % (s, [hex(x) for x in ids]))

# 3) scan for C104 mix constants (crypto flag) in the dump
print('\n=== mix constant occurrences ===')
for name, const in [('MIX_A 0x7FEB352D', 0x7FEB352D), ('MIX_B 0x846CA68B', 0x846CA68B), ('FNV 0x01000193', 0x01000193)]:
    pat = struct.pack('<I', const)
    offs = [m.start() for m in __import__('re').finditer(__import__('re').escape(pat), b)]
    vas = [DUMP_BASE + o for o in offs if 0x140130000 <= DUMP_BASE + o < 0x140180000]
    print(name, 'total:', len(offs), 'in proto region:', len(vas), ['0x%x'%v for v in vas[:8]])

# 4) dispatch-table constants scan (0x577a9250 / 0x51ea58a4)
print('=== dispatch constants ===')
for name, const in [('0x577a9250', 0x577a9250), ('0x51ea58a4', 0x51ea58a4)]:
    pat = struct.pack('<I', const)
    offs = [m.start() for m in __import__('re').finditer(__import__('re').escape(pat), b)]
    print(name, 'occurrences:', len(offs), ['0x%x'%(DUMP_BASE+o) for o in offs[:6]])
