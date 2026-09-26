import os, shutil
src = 'EPT-AUTHGATE-20260925-81'
dst = 'EPT-AUTHGATE-20260925-82'
os.makedirs(dst, exist_ok=True)
for f in ['auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','tcp1029.ps1','HpDrvPre.sys','host_prep.ps1','host_harvest.ps1','monitor_run.ps1']:
    shutil.copy(os.path.join(src, f), os.path.join(dst, f))
for f in ['host_prep.ps1','host_harvest.ps1','monitor_run.ps1','guest_launch.ps1']:
    p = os.path.join(dst, f)
    t = open(p, encoding='utf-8').read()
    t = t.replace('EPT-AUTHGATE-20260925-81', 'EPT-AUTHGATE-20260925-82')
    open(p, 'w', encoding='utf-8', newline='').write(t)

p = os.path.join(dst, 'auth_stage_force.cdb')
t = open(p, encoding='utf-8').read()
# add full-image dump at recv#2 (66MB)
anchor = '.writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-82/recvbuf_at_recv.bin @rdx L67;'
assert anchor in t
t = t.replace(anchor, anchor + ' .writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-82/full_image_runtime.bin 140000000 L3f83000;', 1)
open(p, 'w', encoding='utf-8', newline='\n').write(t)

p = os.path.join(dst, 'host_harvest.ps1')
t = open(p, encoding='utf-8').read()
old = "'logstrings.bin')"
assert old in t
t = t.replace(old, "'logstrings.bin','full_image_runtime.bin')")
open(p, 'w', encoding='utf-8', newline='').write(t)
print('run82 built (full image dump)')
