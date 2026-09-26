import struct, json, re
from capstone import *

b = open('runs/EPT-AUTHGATE-20260925-82/child_full_recv2.dmp','rb').read()
nstreams = struct.unpack_from('<I', b, 8)[0]
dirrva = struct.unpack_from('<I', b, 12)[0]
streams = {}
for i in range(nstreams):
    st, sz, rva = struct.unpack_from('<III', b, dirrva + i*12)
    streams.setdefault(st, []).append((sz, rva))
ranges = []
sz, rva = streams[9][0]
nranges, base_rva = struct.unpack_from('<QQ', b, rva)
off = base_rva
for i in range(nranges):
    start, dsize = struct.unpack_from('<QQ', b, rva + 16 + i*16)
    ranges.append((start, dsize, off)); off += dsize
ranges.sort()
def read(va, n):
    out = bytearray()
    for start, dsize, drva in ranges:
        if start <= va < start + dsize:
            take = min(n - len(out), start + dsize - va)
            o = drva + (va - start)
            out += b[o:o+take]; va += take
            if len(out) >= n: break
    return bytes(out[:n])
def mapped(va, n=1):
    for start, dsize, drva in ranges:
        if start <= va < start + dsize: return True
    return False

md = Cs(CS_ARCH_X86, CS_MODE_64)
MUTATOR = 0x1405d5f80

# find all callers of the mutator across the WHOLE address space (scan the mapped image region 0x140000000-0x144000000)
# the dmp has the mapped image; scan e8 calls whose target == MUTATOR
sites = []
img_start, img_end = 0x140000000, 0x144000000
# build a quick image-read via ranges: scan ranges overlapping the image
for start, dsize, drva in ranges:
    if not (start < img_end and start + dsize > img_start): continue
    lo = max(start, img_start); hi = min(start + dsize, img_end)
    o = drva + (lo - start)
    seg = b[o:o + (hi - lo)]
    for off in range(len(seg) - 5):
        if seg[off] == 0xE8:
            rel = struct.unpack_from('<i', seg, off + 1)[0]
            tgt = lo + off + 5 + rel
            if tgt == MUTATOR:
                sites.append(lo + off)
print('mutator call sites (whole image):', len(sites))

# for each site: extract (enable_cl, count_edx, index_table_ptr, xor_imm) from preceding code
triples = []
for s in sites:
    code = read(s - 0x80, 0x80)
    ins_list = list(md.disasm(code, s - 0x80))
    # walk forward; capture the last assignments before the call to:
    #   edx (count), r8 (index table ptr), [rsp+X] / stack imm (xor imm), cl (enable)
    edx = r8 = imm = cl = None
    table_global = None
    for ins in ins_list:
        if ins.mnemonic == 'mov':
            mm = re.fullmatch(r'edx, (0x[0-9a-f]+)', ins.op_str)
            if mm: edx = int(mm.group(1), 16)
            mm = re.fullmatch(r'r8, (0x[0-9a-f]+)', ins.op_str)
            if mm: r8 = int(mm.group(1), 16)
            mm = re.fullmatch(r'cl, (0x[0-9a-f]+)', ins.op_str)
            if mm: cl = int(mm.group(1), 16)
        if ins.mnemonic == 'call':
            break
    # resolve r8: it may be loaded from a global: find 'mov r8, qword ptr [rip + ...]' before
    for ins in ins_list:
        if ins.mnemonic == 'mov' and ins.op_str.startswith('r8, qword ptr [rip'):
            m = re.search(r'rip [+-] (0x[0-9a-f]+)', ins.op_str)
            if m:
                d = int(m.group(1), 16)
                # sign
                gaddr = ins.address + ins.size + (d if ins.op_str.split('rip ')[1][0] == '+' else -d)
                if mapped(gaddr, 8):
                    r8v = struct.unpack('<Q', read(gaddr, 8))[0]
                    table_global = (hex(gaddr), hex(r8v))
    triples.append({'site': hex(s), 'edx': hex(edx) if edx else None,
                    'r8': hex(r8) if r8 else None, 'cl': cl,
                    'table_global': table_global})
print('triples extracted:', len(triples))
json.dump(triples, open('runs/EPT-AUTHGATE-20260925-82/mutator_triples.json','w'), indent=1)
# sample
for t3 in triples[:6]: print(t3)
