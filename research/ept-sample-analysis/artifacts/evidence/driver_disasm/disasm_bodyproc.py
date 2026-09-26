import struct
from capstone import *

p = 'runs/EPT-AUTHGATE-20260925-65/captured/captured/SYS32_Hardware.exe.bin'
b = open(p, 'rb').read()
base = 0x140000000
# PE sections for VA->offset
e = struct.unpack_from('<I', b, 0x3c)[0]
nsec = struct.unpack_from('<H', b, e+6)[0]
optsz = struct.unpack_from('<H', b, e+20)[0]
opt = e + 24
sec0 = opt + optsz
secs = []
for i in range(nsec):
    o = sec0 + i*40
    name = b[o:o+8].rstrip(b'\0').decode('ascii','replace')
    vsz, va, rsz, ra = struct.unpack_from('<IIII', b, o+8)
    secs.append((name, va, vsz, ra, rsz))
def va2off(va):
    rva = va - base
    for name, sva, vsz, ra, rsz in secs:
        if sva <= rva < sva + max(vsz, rsz):
            return ra + (rva - sva)
    return None

md = Cs(CS_ARCH_X86, CS_MODE_64)
C104_HELPERS = {0x14078ce60:'C104_local_transform(0x14078ce60)', 0x14078cd70:'C104_local_hash(0x14078cd70)', 0x14078d900:'C104_request_write(0x14078d900)'}

def show(va, count, label):
    print('\n==== %s (0x%x) ====' % (label, va))
    off = va2off(va)
    code = b[off:off+count*8]
    for ins in md.disasm(code, va):
        note = ''
        if ins.mnemonic in ('call','jmp') and ins.op_str.startswith('0x'):
            t = int(ins.op_str,16)
            if t in C104_HELPERS: note = '   ; <<< ' + C104_HELPERS[t]
        print('%08x  %-7s %s%s' % (ins.address, ins.mnemonic, ins.op_str, note))
        count -= 1
        if count <= 0: break

show(0x140141fef, 60, 'body-processing continuation (after RECV#2)')
