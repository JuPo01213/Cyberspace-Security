import struct, re, hashlib
p = 'captured/captured/HpDrvoznHrSvUEBlJRFiHf0.sys.bin'
b = open(p, 'rb').read()
print('size', len(b), 'sha256', hashlib.sha256(b).hexdigest())
e_lfanew = struct.unpack_from('<I', b, 0x3c)[0]
sig = b[e_lfanew:e_lfanew+4]
print('PE sig:', sig)
machine = struct.unpack_from('<H', b, e_lfanew+4)[0]
nsec = struct.unpack_from('<H', b, e_lfanew+6)[0]
optsz = struct.unpack_from('<H', b, e_lfanew+20)[0]
opt = e_lfanew + 24
magic = struct.unpack_from('<H', b, opt)[0]
print('machine=0x%x nsec=%d optmagic=0x%x' % (machine, nsec, magic))
ep = struct.unpack_from('<I', b, opt+16)[0]
base = struct.unpack_from('<Q', b, opt+24)[0] if magic == 0x20b else struct.unpack_from('<I', b, opt+28)[0]
print('entry_rva=0x%x imagebase=0x%x' % (ep, base))
sec0 = opt + optsz
secs = []
for i in range(nsec):
    o = sec0 + i*40
    name = b[o:o+8].rstrip(b'\0').decode('ascii', 'replace')
    vsz, va, rsz, ra = struct.unpack_from('<IIII', b, o+8)
    chars = struct.unpack_from('<I', b, o+36)[0]
    secs.append((name, va, vsz, ra, rsz, chars))
    print('sec %-8s va=0x%06x vsz=0x%06x raw=0x%06x rsz=0x%06x chars=0x%08x' % (name, va, vsz, ra, rsz, chars))
# imports: parse IDATA roughly — find kernelbase imports via strings of dll names
# strings
print('=== ASCII strings (len>=6, first 60) ===')
ss = re.findall(rb'[\x20-\x7e]{6,}', b)
for s in ss[:60]:
    print('  ', s.decode('ascii'))
print('=== UTF-16 strings ===')
u = re.findall(rb'(?:[\x20-\x7e]\x00){5,}', b)
for s in u[:40]:
    print('  ', s.decode('utf-16le'))
