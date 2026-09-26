"""Read only configuration-global facts from one historical minidump."""
import hashlib,json,sys
from pathlib import Path
from mdmp_read import MiniDump
root=Path(sys.argv[1]);dump=Path(sys.argv[2]);expected='ca0ffcec87a8580e9bfdef4daaf90c97fb06a53d597028020fe1ec714830e60d'
raw=dump.read_bytes();assert hashlib.sha256(raw).hexdigest()==expected
m=MiniDump(dump);base=0x141154980;n=890
b=m.read(base,n)
parts={}
for va,width in ((0x141154980,890),(0x141154ae7,1),(0x141154ce9,4),(0x141154ced,4),(0x141154cf1,4),(0x141154cf6,4),(0x141154cfa,1)):
 x=m.read(va,width);parts[hex(va)]={'requested':width,'read':len(x),'mapped':len(x)==width,'sha256':hashlib.sha256(x).hexdigest(),'all_zero':bool(x) and not any(x),'values':list(x) if width<=4 else None}
report={'scope':'offline_historical_minidump_configuration_global','dump_sha256':expected,'va_base':hex(base),'requested_bytes':n,'read_bytes':len(b),'mapped':len(b)==n,'sha256':hashlib.sha256(b).hexdigest(),'all_zero':bool(b) and not any(b),'field_reads':parts,'ranges':len(m.ranges),'limitations':['Historical snapshot only; no runtime reachability.','A zero or unmapped global is not authorization failure.','No raw license material emitted.','No sample execution or validation modification.']}
(root/'config-global-facts.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps(report,indent=2))
