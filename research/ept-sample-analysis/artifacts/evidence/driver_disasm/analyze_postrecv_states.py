import struct
from capstone import *

tr = open('runs/EPT-AUTHGATE-20260925-79/text_runtime.bin','rb').read()
TRB = 0x140100000
md = Cs(CS_ARCH_X86, CS_MODE_64)

anchors = [0x14017c41a,0x14017c73d,0x14017d211,0x14017d45b,0x14017d75e,0x14017de42,0x14017e062,0x14017e3a9,0x14017e6a3,0x14017e855,0x14017ec5c,0x14017ef30,0x14017f1c6,0x14017f50b,0x14017f963]

def dis(va, n):
    off = va - TRB
    return list(md.disasm(tr[off:off+n*8], va))

for a in anchors[:6]:
    # disassemble 0x60 bytes BEFORE the logger call (the state prep) and 0x40 after
    start = a - 0x60
    print('\n==== state around logger@0x%08x (event from [rsp+0x20]) ====' % a)
    ins_list = dis(start, 40)
    for ins in ins_list:
        # flag interesting ops
        tag = ''
        if ins.mnemonic in ('xor','ror','rol','shl','shr','imul','mul') and ins.op_str.count(',')==1:
            parts = ins.op_str.split(', ')
            if parts[0] != parts[1] or ins.mnemonic=='xor':
                tag = '   ; <<<'
        if 'rbp + 0x3' in ins.op_str or 'rbp + 0x2f' in ins.op_str:
            tag = '   ; frame-buf'
        print('%08x  %-7s %s%s' % (ins.address, ins.mnemonic, ins.op_str, tag))
        if ins.address >= a: break
