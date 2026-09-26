import struct, re, json
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

md = Cs(CS_ARCH_X86, CS_MODE_64)
LOGGER = 0x1405d5f80
handlers = json.load(open('runs/EPT-AUTHGATE-20260925-82/handler_enum.json'))

report = []
for idx_s, h_s, nins, xorflag in handlers:
    idx = int(idx_s); h = int(h_s, 16)
    code = read(h, 0x600)
    ins_list = list(md.disasm(code, h))
    event_ids = []   # stack immediates near logger calls
    edx_vals = []
    buf_refs = []
    xor_byte_loops = 0
    for j, ins in enumerate(ins_list):
        if ins.mnemonic == 'mov' and ', 0x' in ins.op_str:
            mm = re.fullmatch(r'dword ptr \[[^\]]+\], (0x[0-9a-f]{3,4})', ins.op_str)
            if mm:
                v = int(mm.group(1), 16)
                if 0x100 <= v <= 0xffff: event_ids.append((ins.address, v))
        if ins.mnemonic in ('xor','ror','rol') and 'byte ptr' in ins.op_str:
            xor_byte_loops += 1
        if '0x1e0004' in ins.op_str or '0x1e0000' in ins.op_str or '0x1e1000' in ins.op_str:
            buf_refs.append((ins.address, ins.op_str))
    report.append({'idx': idx, 'handler': hex(h), 'ins': len(ins_list),
                   'events': [(hex(a), hex(v)) for a, v in event_ids[:4]],
                   'xor_bytes': xor_byte_loops, 'buf_refs': buf_refs[:3]})

# summary
with_x = [r for r in report if r['xor_bytes'] > 0]
with_buf = [r for r in report if r['buf_refs']]
print('handlers with xor-byte ops:', len(with_x))
for r in with_x[:10]: print('  idx=%d handler=%s xor_bytes=%d events=%s' % (r['idx'], r['handler'], r['xor_bytes'], r['events'][:2]))
print('handlers with recv-buffer refs:', len(with_buf))
for r in with_buf[:10]: print('  idx=%d handler=%s refs=%s' % (r['idx'], r['handler'], r['buf_refs'][:2]))
json.dump(report, open('runs/EPT-AUTHGATE-20260925-82/handler_annotations.json','w'), indent=1)
print('saved handler_annotations.json')
