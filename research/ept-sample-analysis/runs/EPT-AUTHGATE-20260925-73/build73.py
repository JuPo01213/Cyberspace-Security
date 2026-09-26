import os, shutil
src = 'EPT-AUTHGATE-20260925-72'
dst = 'EPT-AUTHGATE-20260925-73'
os.makedirs(dst, exist_ok=True)
for f in ['auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','mock_server.ps1','host_prep.ps1','host_harvest.ps1','monitor_run.ps1','HpDrvPre.sys']:
    shutil.copy(os.path.join(src, f), os.path.join(dst, f))
for f in ['host_prep.ps1','host_harvest.ps1','monitor_run.ps1','guest_launch.ps1']:
    p = os.path.join(dst, f)
    t = open(p, encoding='utf-8').read()
    t = t.replace('EPT-AUTHGATE-20260925-72', 'EPT-AUTHGATE-20260925-73')
    open(p, 'w', encoding='utf-8', newline='').write(t)

# cdb: socket observers
p = os.path.join(dst, 'auth_stage_force.cdb')
t = open(p, encoding='utf-8').read()
t = t.replace('RUN71_', 'RUN73_')
anchor = 'bu kernelbase!DeviceIoControl ".echo DIOC; r rcx; r rdx; r r8; r r9; dd @rsp+20 L4; g"'
add = ('bu ws2_32!connect ".echo CONN; db @rdx L10; g"\n'
       'bu ws2_32!WSAConnect ".echo WSACONN; db @rdx L10; g"\n'
       'bu ws2_32!GetAddrInfoW ".echo GAI; du @rcx; g"\n'
       'bu ws2_32!getaddrinfo ".echo GAI_A; da @rcx; g"\n' + anchor)
assert anchor in t
t = t.replace(anchor, add, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(t)

# watcher: add netstat polling every ~2s
p = os.path.join(dst, 'watcher.ps1')
t = open(p, encoding='utf-8').read()
old = "  Start-Sleep -Milliseconds 500\n}"
assert old in t, 'watcher sleep anchor missing'
new = ('  if(($sw.ElapsedMilliseconds % 2000) -lt 600){\n'
       "    (netstat -n | Select-String '127.0.0.1') | ForEach-Object { Add-Content -LiteralPath (Join-Path $root 'netstat.txt') -Value ($stamp+' '+$_.ToString().Trim()) -Encoding ASCII }\n"
       "  }\n"
       "  Start-Sleep -Milliseconds 500\n}")
t = t.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)
print('run73 built')
