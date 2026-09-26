import hashlib,json,sys
from pathlib import Path
from mdmp_read import MiniDump
root=Path(sys.argv[1]);rows=[]
for item in map(Path,sys.argv[2:]):
 raw=item.read_bytes(); h=hashlib.sha256(raw).hexdigest().upper(); m=MiniDump(item)
 row={'path':str(item),'sha256':h,'ranges':len(m.ranges),'bytes':sum(x[1] for x in m.ranges)}
 for va,width in ((0x141154980,890),(0x141154ae7,1),(0x141154ce9,4),(0x141154ced,4),(0x141154cf1,4),(0x141154cf6,4)):
  b=m.read(va,width);row[hex(va)]={'read':len(b),'mapped':len(b)==width,'all_zero':bool(b) and not any(b),'bytes':b.hex() if width<=4 else None}
 rows.append(row)
(root/'global-comparison.json').write_text(json.dumps({'scope':'offline_historical_dump_comparison','dumps':rows,'authorization_proven':False,'sample_executed':False},indent=2)+'\n',encoding='utf-8')
print(json.dumps(rows,indent=2))
