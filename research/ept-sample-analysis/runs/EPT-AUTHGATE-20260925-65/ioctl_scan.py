import struct
b = open('captured/captured/HpDrvoznHrSvUEBlJRFiHf0.sys.bin', 'rb').read()
# .text raw 0x400-0xe00, .rdata 0xe00-0x1200, .data 0x1200-0x1400, PAGE 0x1600-0x1a00, INIT 0x1a00-0x2000
text = b[0x400:0xe00]
# IOCTL = CTL_CODE(DeviceType, Function, Method, Access) = (Dev<<16)|(Func<<2)|Method|Access
# scan for immediate compares/moves with 0x2220xx-0x22xxxx patterns
import re
print('=== candidate IOCTL immediates in .text/.rdata/PAGE/INIT ===')
for name, blob in [('.text', b[0x400:0xe00]), ('.rdata', b[0xe00:0x1200]), ('.data', b[0x1200:0x1400]), ('PAGE', b[0x1600:0x1a00]), ('INIT', b[0x1a00:0x2000])]:
    for m in re.finditer(rb'\x00\x00\x22[\x20-\x7f]', blob):
        v = struct.unpack_from('<I', blob, m.start())[0]
        print('  %s @0x%x: 0x%08x  dev=0x%x func=0x%x method=%d access=%d' % (name, m.start(), v, (v>>16)&0xffff, (v>>2)&0xfff, v&3, (v>>14)&3))
    for m in re.finditer(rb'\x00\x00\x22\x00', blob):
        v = struct.unpack_from('<I', blob, m.start())[0]
        if (v >> 16) & 0xffff == 0x22:
            pass
# broader: any dword with high word 0x0022
print('=== all dwords with high16==0x0022 ===')
for name, blob, base in [('.text', b[0x400:0xe00], 0x140001000), ('.rdata', b[0xe00:0x1200], 0x140002000), ('.data', b[0x1200:0x1400], 0x140003000), ('PAGE', b[0x1600:0x1a00], 0x140005000), ('INIT', b[0x1a00:0x2000], 0x140006000)]:
    for off in range(0, len(blob)-3):
        v = struct.unpack_from('<I', blob, off)[0]
        if (v >> 16) & 0xffff == 0x22 and v > 0x220000:
            print('  %s va=0x%x: 0x%08x dev=0x%x func=0x%x method=%d access=%d' % (name, base+off, v, (v>>16)&0xffff, (v>>2)&0xfff, v&3, (v>>14)&3))
# dump .rdata as hex-ish (unicode strings there)
print('=== .rdata bytes ===')
rd = b[0xe00:0x1200]
import binascii
print(binascii.hexlify(rd[:0x120]).decode())
