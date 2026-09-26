import struct
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
LOGGER = 0x1405d5f80
base_ptr = struct.unpack('<Q', read(0x140FA18F0, 8))[0]
print('base_ptr = 0x%x' % base_ptr)

results = []
for idx in range(0, 0x100):
    entry = (base_ptr + idx*8 + 0x577a9250) & 0xFFFFFFFFFFFFFFFF
    if not mapped(entry, 8): continue
    v = struct.unpack('<Q', read(entry, 8))[0]
    h = (v + 0x51ea58a4) & 0xFFFFFFFFFFFFFFFF
    if not mapped(h, 0x40): continue
    code = read(h, 0x400)
    # find logger calls + their stack immediates; find xor byte loops
    ins_list = list(md.disasm(code, h))
    if len(ins_list) < 10: continue
    log_imms = []
    has_xor_byte = False
    buf_refs = 0
    call_targets = []
    for ins in ins_list:
        if ins.mnemonic == 'xor' and 'byte' in ins.op_str: has_xor_byte = True
        if '0x1e0004' in ins.op_str or '0x1e0000' in ins.op_str: buf_refs += 1
    results.append((idx, h, len(ins_list), has_xor_byte))

mapped_n = len(results)
print('mapped handlers for idx 0-0xFF:', mapped_n)
import json
json.dump([(i, hex(h), n, x) for i,h,n,x in results], open('runs/EPT-AUTHGATE-20260925-82/handler_enum.json','w'), indent=1)
print('sample:', [(i,hex(h)) for i,h,n,x in results[:8]])

