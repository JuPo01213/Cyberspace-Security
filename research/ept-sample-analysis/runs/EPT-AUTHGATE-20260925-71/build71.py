import os, shutil
src = 'EPT-AUTHGATE-20260925-70'
dst = 'EPT-AUTHGATE-20260925-71'
os.makedirs(dst, exist_ok=True)
for f in ['auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','host_prep.ps1','host_harvest.ps1','monitor_run.ps1']:
    shutil.copy(os.path.join(src, f), os.path.join(dst, f))
for f in ['host_prep.ps1','host_harvest.ps1','monitor_run.ps1','guest_launch.ps1']:
    p = os.path.join(dst, f)
    t = open(p, encoding='utf-8').read()
    t = t.replace('EPT-AUTHGATE-20260925-70', 'EPT-AUTHGATE-20260925-71')
    open(p, 'w', encoding='utf-8', newline='').write(t)

# driver binary into run dir as HpDrvPre.sys
shutil.copy('EPT-AUTHGATE-20260925-65/captured/captured/HpDrvoznHrSvUEBlJRFiHf0.sys.bin', os.path.join(dst, 'HpDrvPre.sys'))

# cdb: DeviceIoControl observer (kernelbase layer)
p = os.path.join(dst, 'auth_stage_force.cdb')
t = open(p, encoding='utf-8').read()
t = t.replace('RUN70_', 'RUN71_')
anchor = 'bu kernelbase!ReadFile ".echo RDF; r rcx; r r8; g"'
add = 'bu kernelbase!DeviceIoControl ".echo DIOC; r rcx; r rdx; r r8; r r9; dd @rsp+20 L4; g"\n' + anchor
assert anchor in t
t = t.replace(anchor, add, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(t)

# guest_launch: pre-load driver before starting parent
p = os.path.join(dst, 'guest_launch.ps1')
t = open(p, encoding='utf-8').read()
anchor2 = "& ipconfig.exe /flushdns | Out-Null"
assert anchor2 in t
add2 = anchor2 + """
 Copy-Item (Join-Path $root 'HpDrvPre.sys') 'C:\\Windows\\Temp\\HpDrvPre.sys' -Force
 $c = & sc.exe create HpDrvPre type= kernel start= demand binPath= "\\??\\C:\\Windows\\Temp\\HpDrvPre.sys" 2>&1
 $st = & sc.exe start HpDrvPre 2>&1
 $qd = & sc.exe query HpDrvPre 2>&1 | Select-String 'STATE'
 Add-Event @{type='DRIVER_PRELOADED';create=($c -join ' ');start=($st -join ' ');state=($qd -join ' ')}"""
t = t.replace(anchor2, add2, 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)

# host_prep: push HpDrvPre.sys into spool
p = os.path.join(dst, 'host_prep.ps1')
t = open(p, encoding='utf-8').read()
anchor3 = " Copy-Item -ToSession $s -Path (Join-Path $runDir 'watcher.ps1') -Destination (Join-Path $guestRoot 'watcher.ps1') -Force"
assert anchor3 in t
t = t.replace(anchor3, anchor3 + """
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'HpDrvPre.sys') -Destination (Join-Path $guestRoot 'HpDrvPre.sys') -Force""", 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)
print('run71 built')
