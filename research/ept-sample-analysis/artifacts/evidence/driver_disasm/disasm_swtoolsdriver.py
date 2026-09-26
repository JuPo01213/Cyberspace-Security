import struct
from capstone import *

p = 'runs/EPT-AUTHGATE-20260925-65/captured/captured/HpDrvoznHrSvUEBlJRFiHf0.sys.bin'
b = open(p, 'rb').read()
base = 0x140000000

# --- parse imports (ntoskrnl.exe / HAL.dll / WDFLDR.SYS) to build IAT map ---
# Find import directory from optional header (data directory index 1)
e = struct.unpack_from('<I', b, 0x3c)[0]
opt = e + 24
magic = struct.unpack_from('<H', b, opt)[0]
ddoff = opt + (0x70 if magic == 0x20b else 0x60)
imp_rva, imp_sz = struct.unpack_from('<II', b, ddoff + 8)

secs = []
nsec = struct.unpack_from('<H', b, e+6)[0]
optsz = struct.unpack_from('<H', b, e+20)[0]
sec0 = opt + optsz
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

iat = {}  # va -> name
if imp_rva:
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
                iat[base + (oft or fthunk) + k*8] = fname
            k += 1
        off += 20

md = Cs(CS_ARCH_X86, CS_MODE_64)
md.detail = False

def dis(name, va_raw, raw_start, raw_end):
    print('\n' + '='*20 + ' ' + name + ' ' + '='*20)
    code = b[raw_start:raw_end]
    for ins in md.disasm(code, base + va_raw):
        extra = ''
        # annotate call/jmp to import thunks [rip+X] reading IAT
        if ins.mnemonic in ('call','jmp') and 'rip' in ins.op_str:
            try:
                tgt = int(ins.op_str.split('rip ')[-1].strip('[]+- '), 16) if False else None
            except Exception: pass
        for va, fn in iat.items():
            if hex(va)[2:] in ins.op_str.replace('`','') or ('0x%x' % va) in ins.op_str:
                extra = '  ; ' + fn
        print('%012x  %-8s %-40s%s' % (ins.address, ins.mnemonic, ins.op_str, extra))

dis('INIT (DriverEntry)', 0x6000, 0x1a00, 0x2000)
dis('PAGE', 0x5000, 0x1600, 0x1a00)
dis('.text', 0x1000, 0x400, 0xe00)
