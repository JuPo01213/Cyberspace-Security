p = 'host_harvest.ps1'
t = open(p, encoding='utf-8').read()
import re
# normalize: find the file list segment and rebuild it cleanly
m = re.search(r"\+@\('auth_stage_force\.cdb'[^)]+\)\)\{try\{Copy-Item -FromSession", t)
assert m, 'list anchor not found'
seg = m.group(0)
clean = "+@('auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','tcp1029.ps1','HpDrvPre.sys','cdb.stdout.txt','cdb.stderr.txt','events.ndjson','winproc.ndjson','post_snapshot.json','watcher.csv','protocol.ndjson','netstat.txt','requests.ndjson','text_runtime.bin')){try{Copy-Item -FromSession"
t = t.replace(seg, clean, 1)
open(p, 'w', encoding='utf-8', newline='').write(t)
print('harvest list rebuilt')
