import os, shutil, re
src = 'EPT-AUTHGATE-20260925-80'
dst = 'EPT-AUTHGATE-20260925-81'
os.makedirs(dst, exist_ok=True)
for f in ['auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','tcp1029.ps1','HpDrvPre.sys','host_prep.ps1','host_harvest.ps1','monitor_run.ps1']:
    shutil.copy(os.path.join(src, f), os.path.join(dst, f))
for f in ['host_prep.ps1','host_harvest.ps1','monitor_run.ps1','guest_launch.ps1']:
    p = os.path.join(dst, f)
    t = open(p, encoding='utf-8').read()
    t = t.replace('EPT-AUTHGATE-20260925-80', 'EPT-AUTHGATE-20260925-81')
    open(p, 'w', encoding='utf-8', newline='').write(t)

p = os.path.join(dst, 'auth_stage_force.cdb')
t = open(p, encoding='utf-8').read()

# 1) recv#2: targeted heap dumps
old = ".writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-81/recvbuf_at_recv.bin @rdx L67;"
new = (".writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-81/recvbuf_at_recv.bin @rdx L67;"
       " .writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-81/heap_low_recv.bin 1e0000 L20000;"
       " .writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-81/heap_mid_recv.bin 4c00000 L100000;")
assert old in t, 'recv heap dump anchor missing'
t = t.replace(old, new, 1)

# 2) WriteFile action: time-series buffer snapshot via j-form
m = re.search(r'bu kernel32!WriteFile "([^"]*)"', t)
act = m.group(1)
new_act = act[:-1] + " j (@$t10 != 0) 'db @$t10 L67; da @$t10 L67; g' 'g'\""
t = t.replace(m.group(0), 'bu kernel32!WriteFile "' + new_act, 1)

# 3) Sleep action: snapshot
m2 = re.search(r'bu kernelbase!Sleep "([^"]*)"', t)
sl = m2.group(1)
new_sl = sl[:-1] + " j (@$t10 != 0) 'db @$t10 L67; g' 'g'\""
t = t.replace(m2.group(0), 'bu kernelbase!Sleep "' + new_sl, 1)

open(p, 'w', encoding='utf-8', newline='\n').write(t)
print('run81 built: heap dumps + time-series snapshots')
