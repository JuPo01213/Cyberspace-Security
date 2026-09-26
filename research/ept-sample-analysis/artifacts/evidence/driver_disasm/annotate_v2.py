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
LOGGER = 0x1405d5f80
handlers = json.load(open('runs/EPT-AUTHGATE-20260925-82/handler_enum.json'))

def analyze(va, depth, seen, out_events, out_calls):
    if depth > 1 or va in seen or not mapped(va, 0x40): return
    seen.add(va)
    code = read(va, 0x600)
    ins_list = list(md.disasm(code, va))
    if len(ins_list) < 8: return
    call_site_imm = None
    for j, ins in enumerate(ins_list):
        if ins.mnemonic == 'mov' and 'dword ptr [' in ins.op_str:
            mm = re.fullmatch(r'dword ptr \[[^\]]+\], (0x[0-9a-f]{3,4})', ins.op_str)
            if mm: call_site_imm = int(mm.group(1), 16)  # last imm before next call
        if ins.mnemonic == 'call':
            if ins.op_str.startswith('0x'):
                t = int(ins.op_str, 16)
                if t == LOGGER:
                    out_events.append((ins.address, call_site_imm))
                elif depth == 0:
                    out_calls.append(t)
            elif '0x1405d5f80' in ins.op_str or '1405d5f80' in ins.op_str:
                out_events.append((ins.address, call_site_imm))

report = []
for idx_s, h_s, nins, xorflag in handlers:
    idx = int(idx_s); h = int(h_s, 16)
    events = []; calls = []
    analyze(h, 0, set(), events, calls)
    # depth-1: recurse into called functions (one level)
    sub_events = []
    sub_xor = []
    for c in calls[:8]:
        if not mapped(c, 0x40): continue
        sub_code = read(c, 0x500)
        sub_ins = list(md.disasm(sub_code, c))
        imm = None
        s_xor = 0
        for ins in sub_ins:
            if ins.mnemonic == 'mov' and 'dword ptr [' in ins.op_str:
                mm = re.fullmatch(r'dword ptr \[[^\]]+\], (0x[0-9a-f]{3,4})', ins.op_str)
                if mm: imm = int(mm.group(1), 16)
            if ins.mnemonic in ('xor','ror','rol') and ('byte ptr' in ins.op_str or 'word ptr' in ins.op_str):
                s_xor += 1
        if imm: sub_events.append(imm)
        if s_xor: sub_xor.append((hex(c), s_xor))
    report.append({'idx': idx, 'handler': hex(h), 'events': [ (hex(a) if isinstance(a,int) else str(a), hex(e) if e else None) for a, e in events[:3] ],
                   'calls': [hex(c) for c in calls[:5]], 'sub_events': [hex(e) for e in sub_events[:4]],
                   'sub_xor': sub_xor[:4]})

json.dump(report, open('runs/EPT-AUTHGATE-20260925-82/handler_annotations2.json','w'), indent=1)
n_ev = sum(1 for r in report if r['events'])
n_sub = sum(1 for r in report if r['sub_events'])
n_x = sum(1 for r in report if r['sub_xor'])
print('handlers:', len(report), '| with logger events:', n_ev, '| with sub events:', n_sub, '| with sub xor:', n_x)
# show the recv-adjacent handlers (idx 4,5,6) and any with sub_xor
for r in report:
    if r['idx'] in (4,5,6) or r['sub_xor']:
        print(json.dumps(r))
