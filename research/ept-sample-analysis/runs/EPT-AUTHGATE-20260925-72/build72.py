import os, shutil
src = 'EPT-AUTHGATE-20260925-71'
dst = 'EPT-AUTHGATE-20260925-72'
os.makedirs(dst, exist_ok=True)
for f in ['auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','host_prep.ps1','host_harvest.ps1','monitor_run.ps1','HpDrvPre.sys']:
    shutil.copy(os.path.join(src, f), os.path.join(dst, f))
for f in ['host_prep.ps1','host_harvest.ps1','monitor_run.ps1','guest_launch.ps1']:
    p = os.path.join(dst, f)
    t = open(p, encoding='utf-8').read()
    t = t.replace('EPT-AUTHGATE-20260925-71', 'EPT-AUTHGATE-20260925-72')
    open(p, 'w', encoding='utf-8', newline='').write(t)

# mock listener (guest, SYSTEM context via task)
mock = r'''param([Parameter(Mandatory=$true)][string]$RunId)
$root=Join-Path 'C:\ept_obs\spool' $RunId
$log=Join-Path $root 'requests.ndjson'
function L([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $log -Value ($x|ConvertTo-Json -Compress -Depth 4) -Encoding UTF8}
$netstat=Join-Path $root 'netstat.txt'
$sw=[System.Diagnostics.Stopwatch]::StartNew()
# HttpListener loop (foreground thread) with a timer polling netstat
$listener=new-object System.Net.HttpListener
foreach($pfx in @('http://127.0.0.1:80/','http://127.0.0.1:8080/','http://127.0.0.1:8000/','http://+:8001/')){ try{ $listener.Prefixes.Add($pfx) }catch{} }
try{ $listener.Start() }catch{ L @{type='LISTENER_START_FAIL';err=$_.Exception.Message} }
L @{type='LISTENER_UP'}
$deadline=(Get-Date).AddMinutes(16)
while((Get-Date) -lt $deadline){
  $ctx=$null
  try { $ctx=$listener.GetContext() } catch { break }
  if($ctx){
    $req=$ctx.Request
    $body=''
    try { $rd=New-Object System.IO.StreamReader($req.InputStream); $body=$rd.ReadToEnd() }catch{}
    L @{type='HTTP';method=$req.HttpMethod;url=$req.Url.ToString();ua=$req.UserAgent;bodyLen=$body.Length;bodyPrefix=$body.Substring(0,[Math]::Min(400,$body.Length))}
    $resp=$ctx.Response
    $resp.StatusCode=200
    $resp.ContentType='text/plain'
    $resp.ContentLength64=2
    $out=[System.Text.Encoding]::ASCII.GetBytes('OK')
    $resp.OutputStream.Write($out,0,2)
    $resp.OutputStream.Close()
  }
}
L @{type='LISTENER_EXIT'}
'''
open(os.path.join(dst,'mock_server.ps1'),'w',encoding='utf-8-sig',newline='\r\n').write(mock)

# guest_launch: start mock listener before parent
p = os.path.join(dst,'guest_launch.ps1')
t = open(p, encoding='utf-8').read()
a = " Add-Event @{type='DRIVER_PRELOADED';create=($c -join ' ');start=($st -join ' ');state=($qd -join ' ')}"
assert a in t
t = t.replace(a, a + """
 $ms=Start-Process -FilePath 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'mock_server.ps1'),'-RunId',$RunId) -WorkingDirectory $root -WindowStyle Hidden -PassThru
 Add-Event @{type='MOCK_LISTENER_STARTED';pid=[int]$ms.Id}""", 1)
open(p,'w',encoding='utf-8',newline='\r\n').write(t)

# host_prep: push mock_server.ps1
p = os.path.join(dst,'host_prep.ps1')
t = open(p, encoding='utf-8').read()
a2 = " Copy-Item -ToSession $s -Path (Join-Path $runDir 'HpDrvPre.sys') -Destination (Join-Path $guestRoot 'HpDrvPre.sys') -Force"
assert a2 in t
t = t.replace(a2, a2 + """
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'mock_server.ps1') -Destination (Join-Path $guestRoot 'mock_server.ps1') -Force""", 1)
open(p,'w',encoding='utf-8',newline='\r\n').write(t)

# harvest: pull requests.ndjson + netstat.txt
p = os.path.join(dst,'host_harvest.ps1')
t = open(p, encoding='utf-8').read()
t = t.replace("'fatal_region.bin'", "'fatal_region.bin','requests.ndjson','netstat.txt'")
open(p,'w',encoding='utf-8',newline='\r\n').write(t)
print('run72 built')
