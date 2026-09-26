p = 'host_prep.ps1'
lines = open(p, 'rb').read().split(b'\r\n')
if len(lines) < 5:
    lines = open(p, 'rb').read().split(b'\n')
block = (
    b" Write-Host 'WATCHTEST_BEGIN'\r\n"
    b" Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {param($id)\r\n"
    b"  $r='C:\\ept_obs\\spool\\'+$id\r\n"
    b"  $p=Start-Process -FilePath 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',($r+'\\watcher.ps1'),'-RunId',$id) -WindowStyle Hidden -PassThru\r\n"
    b"  Start-Sleep -Seconds 4\r\n"
    b"  if($p -and -not $p.HasExited){ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }\r\n"
    b"  Write-Host ('WATCHTEST_CSV='+((Test-Path ($r+'\\watcher.csv'))))\r\n"
    b"  if(-not (Test-Path ($r+'\\watcher.csv'))){ throw 'WATCHER_CSV_MISSING' }\r\n"
    b" }\r\n"
    b" Write-Host 'WATCHTEST_END'\r\n"
)
anchor = b" Write-Host 'CANARY_PASS'"
found = False
out = []
for l in lines:
    out.append(l)
    if anchor in l and not found:
        out.append(block)
        found = True
if not found:
    raise SystemExit('CANARY_PASS anchor not found')
open(p, 'wb').write(b'\r\n'.join(out))
print('watchtest inserted after CANARY_PASS:', found)
