"""Scan protected image references and locate known local configuration copies."""
import hashlib,json,struct,sys,time
from pathlib import Path
from capstone import Cs,CS_ARCH_X86,CS_MODE_64
from capstone.x86 import X86_OP_MEM,X86_REG_RIP
from mdmp_read import MiniDump
root=Path(sys.argv[1]); dump=Path(sys.argv[2]); started=time.monotonic()
m=MiniDump(dump)
assert hashlib.sha256(m.blob).hexdigest()=='ca0ffcec87a8580e9bfdef4daaf90c97fb06a53d597028020fe1ec714830e60d'
base=0x140000000;cfg=0x141154980
h=m.read(base,4096);pe=struct.unpack_from('<I',h,0x3c)[0]
assert h[:2]==b'MZ' and h[pe:pe+4]==b'PE\0\0'
assert struct.unpack_from('<Q',h,pe+48)[0]==base
ns=struct.unpack_from('<H',h,pe+6)[0];osz=struct.unpack_from('<H',h,pe+20)[0]
sections=[]
for i in range(ns):
 p=pe+24+osz+i*40
 name=h[p:p+8].rstrip(b'\0').decode('ascii','replace');vs,rva=struct.unpack_from('<II',h,p+8);flags=struct.unpack_from('<I',h,p+36)[0]
 sections.append({'name':name,'start':base+rva,'size':vs,'flags':flags})
md=Cs(CS_ARCH_X86,CS_MODE_64);md.detail=True
hits=[];windows=[];canary=False
for sec in sections:
 if not sec['flags']&0x20000000:continue
 lo=sec['start'];size=sec['size']
 if lo==base+0x1000:continue
 blob=m.read(lo,size)
 if len(blob)!=size:windows.append({**sec,'status':'incomplete','read_bytes':len(blob)});continue
 candidates=0
 # Confirm signed disp32 plausibility before expensive decode, without assuming
 # instruction boundaries; all returned entries remain candidates.
 for off in range(len(blob)-15):
  b=blob[off]
  if b not in (0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4a,0x4b,0x4c,0x4d,0x4e,0x4f,0x66,0xf2,0xf3,0x0f,0x8b,0x89,0x8d,0x83,0x80,0xc6,0xc7,0x39,0x3b,0x38,0x3a):continue
  possible=False
  for dpos in (2,3,4,5):
   target0=lo+off+dpos+4+struct.unpack_from('<i',blob,off+dpos)[0]
   if cfg-8<=target0<cfg+898:possible=True;break
  if not possible:continue
  candidates+=1
  ins=next(md.disasm(blob[off:off+15],lo+off,count=1),None)
  if not ins:continue
  for op in ins.operands:
   if op.type==X86_OP_MEM and op.mem.base==X86_REG_RIP:
    target=ins.address+ins.size+op.mem.disp
    if cfg<=target<cfg+890:hits.append({'address':hex(ins.address),'bytes':ins.bytes.hex(),'instruction':ins.mnemonic+' '+ins.op_str,'target':hex(target),'offset':hex(target-cfg),'access':op.access})
 windows.append({**sec,'status':'scanned','read_bytes':len(blob),'prefilter_candidates':candidates})
 print('WINDOW_COMPLETE',sec['name'],len(hits),flush=True)
 if time.monotonic()-started>150:raise TimeoutError('Bounded pass exceeded 150 seconds')
needle=b'1234567890\0'; copies=[]
for start,size,off in m.ranges:
 assert off+size<=len(m.blob)
 chunk=m.blob[off:off+size];pos=0
 while True:
  pos=chunk.find(needle,pos)
  if pos<0:break
  va=start+pos;cb=va-0x167;data=m.read(cb,890)
  if len(data)==890:
   fs=[struct.unpack_from('<I',data,x)[0] for x in (0x365,0x369,0x36d,0x371,0x376)]
   if fs[2:4]==[1,1]:copies.append({'input_va':hex(va),'candidate_base':hex(cb),'fields':fs,'sha256':hashlib.sha256(data).hexdigest()})
  pos+=1
r={'evidence_scope':'offline_protected_reference_and_copy_candidates','dump_sha256':hashlib.sha256(m.blob).hexdigest(),'windows':windows,'references':hits,'placeholder_config_candidates':copies,'elapsed_sec':time.monotonic()-started,'limits':['Historical captured bytes only; not runtime reachability.','Instruction encodings prefiltered and candidate alignment not certified.','Literal input search only finds known placeholder, not all configuration instances.','No authorization success inferred.']}
(root/'protected-references.json').write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8')
print('PROTECTED_SCAN_COMPLETE',len(hits),len(copies),flush=True)
