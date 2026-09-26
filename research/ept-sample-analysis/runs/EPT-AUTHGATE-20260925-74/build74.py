import os, shutil
src = 'EPT-AUTHGATE-20260925-73'
dst = 'EPT-AUTHGATE-20260925-74'
os.makedirs(dst, exist_ok=True)
for f in ['auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','host_prep.ps1','host_harvest.ps1','monitor_run.ps1','HpDrvPre.sys']:
    shutil.copy(os.path.join(src, f), os.path.join(dst, f))
for f in ['host_prep.ps1','host_harvest.ps1','monitor_run.ps1','guest_launch.ps1']:
    p = os.path.join(dst, f)
    t = open(p, encoding='utf-8').read()
    t = t.replace('EPT-AUTHGATE-20260925-73', 'EPT-AUTHGATE-20260925-74')
    open(p, 'w', encoding='utf-8', newline='').write(t)

# replace mock_server with tcp1029 (Phase A: record only, Respond=0)
p = os.path.join(dst, 'guest_launch.ps1')
t = open(p, encoding='utf-8').read()
t = t.replace("'mock_server.ps1'", "'tcp1029.ps1'")
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)

# host_prep: push tcp1029.ps1 instead of mock_server.ps1
p = os.path.join(dst, 'host_prep.ps1')
t = open(p, encoding='utf-8').read()
t = t.replace("'mock_server.ps1'", "'tcp1029.ps1'")
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)

# harvest: pull protocol.ndjson + frame_*.hex
p = os.path.join(dst, 'host_harvest.ps1')
t = open(p, encoding='utf-8').read()
t = t.replace("'requests.ndjson','netstat.txt'", "'requests.ndjson','netstat.txt','protocol.ndjson'")
a = " Write-Host 'HARVEST_DONE'"
add = (" Copy-Item -FromSession $s -Path (Join-Path $guestRoot 'frame_*.hex') -Destination (Join-Path $runDir) -Force -ErrorAction SilentlyContinue\n")
assert a in t
t = t.replace(a, add + a, 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)
print('run74 built (Phase A: record-only)')
