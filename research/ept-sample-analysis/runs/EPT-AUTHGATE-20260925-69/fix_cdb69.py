import os, shutil
src = 'EPT-AUTHGATE-20260925-65'
dst = 'EPT-AUTHGATE-20260925-69'
os.makedirs(dst, exist_ok=True)
for f in ['auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','host_prep.ps1','host_harvest.ps1','monitor_run.ps1']:
    shutil.copy(os.path.join(src, f), os.path.join(dst, f))
for f in ['host_prep.ps1','host_harvest.ps1','monitor_run.ps1','guest_launch.ps1']:
    p = os.path.join(dst, f)
    t = open(p, encoding='utf-8').read()
    t = t.replace('EPT-AUTHGATE-20260925-65', 'EPT-AUTHGATE-20260925-69')
    open(p, 'w', encoding='utf-8', newline='').write(t)
# extend FATAL_THUNK action: runtime disasm + region dump before synthetic return
p = os.path.join(dst, 'auth_stage_force.cdb')
t = open(p, encoding='utf-8').read()
old = '".echo FATAL_THUNK; k L12; dd @rsp L4;'
new = '".echo FATAL_THUNK; k L12; dd @rsp L4; u 0x1407aa580 L28; u 0x1407aa694 L12; writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-69/fatal_region.bin 1407aa000 L3000;'
assert old in t
t = t.replace(old, new, 1)
t = t.replace('RUN65_', 'RUN69_')
open(p, 'w', encoding='utf-8', newline='\n').write(t)
# harvest: pull fatal_region.bin
p2 = os.path.join(dst, 'host_harvest.ps1')
t2 = open(p2, encoding='utf-8').read()
t2 = t2.replace("'parent_cdb.stdout.txt','parent_cdb.stderr.txt'", "'parent_cdb.stdout.txt','parent_cdb.stderr.txt','fatal_region.bin'")
open(p2, 'w', encoding='utf-8', newline='\r\n').write(t2)
print('run69 built, fatal dump wired:', 'fatal_region.bin' in t2)
