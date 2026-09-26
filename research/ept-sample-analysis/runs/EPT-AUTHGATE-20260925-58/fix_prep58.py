p = 'host_prep.ps1'
t = open(p, encoding='utf-8').read()
anchor = """ Copy-Item -ToSession $s -Path (Join-Path $runDir 'watcher.ps1') -Destination (Join-Path $guestRoot 'watcher.ps1') -Force"""
assert anchor in t, 'watcher copy anchor missing'
add = anchor + """
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'parent_obs.cdb') -Destination (Join-Path $guestRoot 'parent_obs.cdb') -Force"""
t = t.replace(anchor, add, 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)

p2 = 'host_harvest.ps1'
t2 = open(p2, encoding='utf-8').read()
a2 = "'events.ndjson','winproc.ndjson','post_snapshot.json','watcher.csv'"
assert a2 in t2, 'harvest list anchor missing'
t2 = t2.replace(a2, a2.replace('watcher.csv', "watcher.csv','parent_cdb.stdout.txt','parent_cdb.stderr.txt'"))
open(p2, 'w', encoding='utf-8', newline='\r\n').write(t2)
print('prep+harvest updated')
