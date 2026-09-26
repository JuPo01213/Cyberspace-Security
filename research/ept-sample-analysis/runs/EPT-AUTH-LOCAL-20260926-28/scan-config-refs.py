"""Bounded candidate reference scan of a historical dump; run inside Guest only."""
import hashlib
import json
import struct
import sys
from pathlib import Path
import capstone
from capstone import CS_ARCH_X86, CS_MODE_64, Cs
from capstone.x86 import X86_OP_MEM, X86_REG_RIP
from mdmp_read import MiniDump

root=Path(sys.argv[1])
p=Path(sys.argv[2])
expected='ca0ffcec87a8580e9bfdef4daaf90c97fb06a53d597028020fe1ec714830e60d'
assert hashlib.sha256(p.read_bytes()).hexdigest()==expected
m=MiniDump(p)
for start,size,off in m.ranges:
    assert size>=0 and 0<=off<=len(m.blob) and off+size<=len(m.blob)
base=0x140000000
header=m.read(base,0x1000)
assert len(header)==0x1000 and header[:2]==b'MZ'
pe=struct.unpack_from('<I',header,0x3c)[0]
assert header[pe:pe+4]==b'PE\0\0'
assert struct.unpack_from('<Q',header,pe+24+24)[0]==base
size_image=struct.unpack_from('<I',header,pe+24+56)[0]
assert size_image==0x3f83000
cfg=0x141154980
lo=base+0x1000
hi=base+0x7db000
blob=m.read(lo,hi-lo)
assert len(blob)==hi-lo
md=Cs(CS_ARCH_X86,CS_MODE_64);md.detail=True
control_va=0x1407a30b2
hits=[];control=False;candidates=0;decoded=0
# RIP-relative addressing can carry a field access or the base pointer itself.
# Decoding every possible start yields candidates, never a validated CFG.
for off in range(len(blob)-15):
    b=blob[off]
    if not (0x40<=b<=0x4f or b in (0x66,0xf2,0xf3,0x0f,0x8b,0x89,0x8d,0x83,0x80,0xc6,0xc7,0x39,0x3b,0x38,0x3a)):
        continue
    candidates+=1
    ins=next(md.disasm(blob[off:off+15],lo+off,count=1),None)
    if ins is None:
        continue
    decoded+=1
    for op in ins.operands:
        if op.type==X86_OP_MEM and op.mem.base==X86_REG_RIP:
            target=ins.address+ins.size+op.mem.disp
            if cfg<=target<cfg+890:
                item={'address':hex(ins.address),'bytes':ins.bytes.hex(),'instruction':ins.mnemonic+' '+ins.op_str,'target':hex(target),'offset':hex(target-cfg),'operand_access':op.access}
                hits.append(item)
                if ins.address==control_va and target==0x141154ced and ins.bytes.hex()=='833d341c9b0001':control=True
assert control,'Known field-reader control not found by actual traversal'
report={'scope':'offline_historical_dump_candidate_scan','input_sha256':expected,'image_base':hex(base),'size_of_image':hex(size_image),'scan_start':hex(lo),'scan_end_exclusive':hex(hi),'scan_bytes':len(blob),'enumerated_start_positions':len(blob)-15,'prefilter_candidate_positions':candidates,'decoded_positions':decoded,'known_reader_control':control,'hits':hits,'limitations':['Candidate sliding decode may include overlapping or invalid instruction boundaries.','Prefilter excludes other encodings; no whole-program absence claim.','Indirect base-pointer writes are not resolved by this pass.','Only the selected historical .text window is scanned.','Not a runtime trace or authorization success.']}
(root/'config-references.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'status':'CANDIDATE_SCAN_COMPLETE','hits':len(hits),'control':control,'capstone':capstone.__version__}))
