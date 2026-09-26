import struct
from capstone import *

p = 'runs/EPT-AUTHGATE-20260925-65/captured/captured/HpDrvoznHrSvUEBlJRFiHf0.sys.bin'
b = open(p, 'rb').read()
base = 0x140000000

e = struct.unpack_from('<I', b, 0x3c)[0]
opt = e + 24
magic = struct.unpack_from('<H', b, opt)[0]
ddoff = opt + (0x70 if magic == 0x20b else 0x60)
imp_rva = struct.unpack_from('<I', b, ddoff + 8)[0]
nsec = struct.unpack_from('<H', b, e+6)[0]
optsz = struct.unpack_from('<H', b, e+20)[0]
sec0 = opt + optsz
secs = []
for i in range(nsec):
    o = sec0 + i*40
    name = b[o:o+8].rstrip(b'\0').decode('ascii','replace')
    vsz, va, rsz, ra = struct.unpack_from('<IIII', b, o+8)
    secs.append((name, va, vsz, ra, rsz))
def rva2off(rva):
    for name, va, vsz, ra, rsz in secs:
        if va <= rva < va + max(vsz, rsz):
            return ra + (rva - va)
    return None
iat = {}
off = rva2off(imp_rva)
while True:
    oft, tstamp, fwd, name_rva, fthunk = struct.unpack_from('<IIIII', b, off)
    if name_rva == 0: break
    noff = rva2off(name_rva)
    dll = b[noff:b.index(b'\0', noff)].decode('ascii','replace')
    t_off = rva2off(oft or fthunk)
    k = 0
    while True:
        v = struct.unpack_from('<Q', b, t_off + k*8)[0]
        if v == 0: break
        if not (v & (1 << 63)):
            hoff = rva2off(v & 0xffffffff)
            fname = b[hoff+2:b.index(b'\0', hoff+2)].decode('ascii','replace')
            iat[base + (oft or fthunk) + k*8] = dll + '!' + fname
        k += 1
    off += 20

md = Cs(CS_ARCH_X86, CS_MODE_64)
def show(lo, hi, label):
    print('\n==== %s (0x%x-0x%x) ====' % (label, lo, hi))
    start_off = rva2off(lo - base)
    code = b[start_off:start_off + (hi - lo)]
    for ins in md.disasm(code, lo):
        extra = ''
        if 'rip' in ins.op_str:
            # compute rip-relative target
            try:
                import re as _re
                m = _re.search(r'rip ([+-]) (0x[0-9a-f]+)', ins.op_str)
                if m:
                    d = int(m.group(2), 16) * (1 if m.group(1) == '+' else -1)
                    tgt = ins.address + ins.size + d
                    extra = '  ; ->0x%x' % tgt
                    if tgt in iat: extra += ' ' + iat[tgt]
            except Exception:
                pass
        if ins.mnemonic in ('call', 'jmp') and ins.op_str.startswith('0x'):
            t2 = int(ins.op_str, 16)
            if t2 in iat: extra = '  ; ' + iat[t2]
        print('%012x  %-7s %-38s%s' % (ins.address, ins.mnemonic, ins.op_str, extra))

# handlers
show(0x140001314, 0x1400013a8, 'handler_A (0x9c4060c4/0x9c4060d8/range)')
show(0x140001364, 0x1400013a8, 'handler_B (0x9c40a1xx range)')
show(0x1400013a8, 0x1400014b4, 'handler_C (0x9c406104)')
show(0x1400014b4, 0x140001504, 'handler_D (0x9c402084)')
show(0x140001504, 0x14000159c, 'handler_E (0x9c402088/208c)')
show(0x14000159c, 0x1400016ec, 'handler_F (0x9c406144)')
show(0x1400016ec, 0x14000173c, 'handler_G (0x9c40610c)')
show(0x14000173c, 0x1400018c7, 'handler_H (0x9c40610c target... actually 0x9c40610c)')
