import os, shutil
src = 'EPT-AUTHGATE-20260925-69'
dst = 'EPT-AUTHGATE-20260925-70'
os.makedirs(dst, exist_ok=True)
for f in ['auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','host_prep.ps1','host_harvest.ps1','monitor_run.ps1']:
    shutil.copy(os.path.join(src, f), os.path.join(dst, f))
for f in ['host_prep.ps1','host_harvest.ps1','monitor_run.ps1','guest_launch.ps1']:
    p = os.path.join(dst, f)
    t = open(p, encoding='utf-8').read()
    t = t.replace('EPT-AUTHGATE-20260925-69', 'EPT-AUTHGATE-20260925-70')
    open(p, 'w', encoding='utf-8', newline='').write(t)
p = os.path.join(dst, 'auth_stage_force.cdb')
t = open(p, encoding='utf-8').read()
old = 'writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-69/fatal_region.bin 1407aa000 L3000;'
new = 'da 140f8e308 L30; du 140f8e308 L20; da 140f92ed0 L20; .writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-70/fatal_region.bin 1407aa000 L3000;'
assert old in t
t = t.replace(old, new, 1)
t = t.replace('RUN69_', 'RUN70_')
open(p, 'w', encoding='utf-8', newline='\n').write(t)
print('run70 built: string dump + fixed .writemem')
