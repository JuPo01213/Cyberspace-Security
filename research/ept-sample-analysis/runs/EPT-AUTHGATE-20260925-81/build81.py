import os, shutil
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

# 1) recv#2: add targeted heap dumps (low heap around recv buffer + mid heap)
old = ".writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-81/recvbuf_at_recv.bin @rdx L67;"
new = (".writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-81/recvbuf_at_recv.bin @rdx L67;"
       " .writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-81/heap_low_recv.bin 1e0000 L20000;"
       " .writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-81/heap_mid_recv.bin 4c00000 L100000;")
assert old in t, 'recv heap dump anchor missing'
t = t.replace(old, new, 1)

# 2) time-series snapshots: WriteFile and Sleep actions add buffer text dump
old_wf = 'bu kernel32!WriteFile ".echo WFW; r rcx; r r8; db @rdx L8;'
assert old_wf in t
# find the tail of the WriteFile action: ... 'g"'
import re
m = re.search(r'bu kernel32!WriteFile "([^"]*)"', t)
act = m.group(1)
new_act = act.replace("g' 'g'", "g' 'g'")  # unchanged inner
# append before final quote: add db @$t10 + da @$t10 guarded by j ($t10 set marker: just try; errors are non-fatal)
new_act_full = 'bu kernel32!WriteFile ".' + act[1:]
# simpler: replace the action string wholesale at the end
wf_old_full = m.group(0)
wf_new_full = wf_old_full[:-2] + ' .if @$t10 != 0 \\'db @$t10 L67; da @$t10 L67\\' \\'\\'; g"'
# use j-form instead of .if (canary-validated)
wf_new_full = wf_old_full[:-2] + " j (@$t10 != 0) 'db @$t10 L67; da @$t10 L67; g' 'g'\""
t = t.replace(wf_old_full, wf_new_full, 1)

# 3) Sleep action: add snapshot
m2 = re.search(r'bu kernelbase!Sleep "([^"]*)"', t)
sl_old_full = m2.group(0)
sl_new_full = sl_old_full[:-2] + " j (@$t10 != 0) 'db @$t10 L67; g' 'g'\""
t = t.replace(sl_old_full, sl_new_full, 1)

open(p, 'w', encoding='utf-8', newline='\n').write(t)
print('run81 built: heap dumps + time-series snapshots')
