[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[string]$RunId='EPT-AUTHGATE-20260926-16')
$ErrorActionPreference='Stop'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
$nonce='CN-'+[guid]::NewGuid().ToString('N').Substring(0,12)
try {
 $echo=Invoke-Command -Session $s -ArgumentList $nonce -ScriptBlock {param($n) "CTRL_CANARY_OK $n $env:COMPUTERNAME $env:USERNAME"}
 Write-Host ("CTRL_CANARY: "+$echo)
 if($echo -notmatch [regex]::Escape($nonce)){throw 'control canary nonce mismatch'}
 Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -match 'watcher\.ps1|tcp1029\.ps1'} | ForEach-Object {Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue};Start-Sleep -Seconds 1;if(Test-Path -LiteralPath $r){Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue};New-Item -ItemType Directory -Force -Path $r|Out-Null;Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb|windbg)'}|Stop-Process -Force -ErrorAction SilentlyContinue}
 Invoke-Command -Session $s -ScriptBlock {
  $sym='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\sym'
  if(-not (Test-Path -LiteralPath $sym)){ New-Item -ItemType Directory -Force -Path $sym | Out-Null }
  $npdb=@(Get-ChildItem -LiteralPath $sym -Filter '*.pdb' -File -ErrorAction SilentlyContinue).Count
  Write-Host ('SYM_CACHE_KEPT pdbs='+$npdb)
  $left=@(Get-ChildItem 'C:\Windows\Temp' -File -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -notmatch '^(EPT_|TS_)'})
  foreach($f in $left){ Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue }
  Write-Host ('TEMP_CLEANED count='+$left.Count)
 }
 foreach($n in @('auth_stage_force.cdb','canary_syntax.cdb','preflight_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','tcp1029.ps1','HpDrvPre.sys')){
   Copy-Item -ToSession $s -Path (Join-Path $runDir $n) -Destination (Join-Path $guestRoot $n) -Force
 }
 $lg=(Get-FileHash (Join-Path $runDir 'auth_stage_force.cdb') -Algorithm MD5).Hash
 $gg=Invoke-Command -Session $s -ScriptBlock {param($p)(Get-FileHash $p -Algorithm MD5).Hash} -ArgumentList (Join-Path $guestRoot 'auth_stage_force.cdb')
 if($lg -ne $gg){throw 'CDB_COPY_HASH_MISMATCH'}
 Write-Host 'CDB_COPY_VERIFIED'
 Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)
  $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
  $out=Join-Path $r 'canary.stdout.txt'
  $errf=Join-Path $r 'canary.stderr.txt'
  $p=Start-Process -FilePath $cdb -ArgumentList @('-cf',(Join-Path $r 'canary_syntax.cdb'),'cmd.exe','/c','echo CANARY_ECHO_OK') -WorkingDirectory $r -RedirectStandardOutput $out -RedirectStandardError $errf -PassThru -WindowStyle Hidden
  if(-not $p.WaitForExit(60000)){Write-Host 'CANARY_TIMEOUT';Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue}
 }
 Copy-Item -FromSession $s -LiteralPath (Join-Path $guestRoot 'canary.stdout.txt') -Destination (Join-Path $runDir 'canary.stdout.txt') -Force
 $can=Get-Content -LiteralPath (Join-Path $runDir 'canary.stdout.txt') -Raw -ErrorAction SilentlyContinue
 $need=@('CANARY_BEGIN','COND_TRUE_WORKS','COND_NEG_WORKS','SIGN_TEST_TRUE','CANARY_ARMED','CANARY_ECHO_OK','CANARY_STOP')
 $missing=@($need|Where-Object {$can -notmatch [regex]::Escape($_)})
 if($can -match 'Syntax error'){throw 'canary reports cdb syntax error'}
 if($missing.Count -gt 0){throw ('canary missing markers: '+($missing -join ','))}
 Write-Host 'CANARY_PASS'
 Write-Host 'PREFLIGHT_BEGIN'
 Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)
  $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
  $out=Join-Path $r 'preflight.stdout.txt'
  $errf=Join-Path $r 'preflight.stderr.txt'
  $p=Start-Process -FilePath $cdb -ArgumentList @('-cf',(Join-Path $r 'preflight_syntax.cdb'),'cmd.exe','/c','echo PREFLIGHT_ECHO_OK') -WorkingDirectory $r -RedirectStandardOutput $out -RedirectStandardError $errf -PassThru -WindowStyle Hidden
  if(-not $p.WaitForExit(150000)){Write-Host 'PREFLIGHT_TIMEOUT';Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue}
 }
 Copy-Item -FromSession $s -LiteralPath (Join-Path $guestRoot 'preflight.stdout.txt') -Destination (Join-Path $runDir 'preflight.stdout.txt') -Force
 $pf=Get-Content -LiteralPath (Join-Path $runDir 'preflight.stdout.txt') -Raw -ErrorAction SilentlyContinue
 $bad=@()
 if($pf -match 'Syntax error'){ $bad += 'syntax_error' }
 foreach($m in @('PF_BEGIN','PF_ARMED')){
   if($pf -notmatch [regex]::Escape($m)){ $bad += ('missing_'+$m) }
 }
 if($bad.Count -gt 0){ throw ('preflight failed: '+($bad -join ',')) }
 Write-Host 'PREFLIGHT_PASS'
 Write-Host 'PREFLIGHT_END'
 Write-Host 'WATCHTEST_BEGIN'
 Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {param($id)
  $r='C:\ept_obs\spool\'+$id
  $p=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',($r+'\watcher.ps1'),'-RunId',$id) -WindowStyle Hidden -PassThru
  Start-Sleep -Seconds 4
  if($p -and -not $p.HasExited){ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
  Write-Host ('WATCHTEST_CSV='+((Test-Path ($r+'\watcher.csv'))))
  if(-not (Test-Path ($r+'\watcher.csv'))){ throw 'WATCHER_CSV_MISSING' }
 }
 Write-Host 'WATCHTEST_END'
 $taskName='EPT-'+$RunId
 Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId,$taskName -ScriptBlock {param($r,$id,$task)$a=New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+(Join-Path $r 'guest_launch.ps1')+'" -RunId "'+$id+'"') -WorkingDirectory $r;$t=New-ScheduledTaskTrigger -Once -At ((Get-Date).AddSeconds(2));$pr=New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest;$se=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 15);Register-ScheduledTask -TaskName $task -Action $a -Trigger $t -Principal $pr -Settings $se -Force|Out-Null;Start-ScheduledTask -TaskName $task}
 Write-Host 'TASK_STARTED'
 Start-Sleep -Seconds 30
 Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {param($id)"--- events ---";$r="C:\ept_obs\spool\"+$id;if(Test-Path ($r+'\events.ndjson')){Get-Content ($r+'\events.ndjson')};$o=$r+'\cdb.stdout.txt';if(Test-Path $o){(Get-Item $o).Length}}
 Write-Host 'PREP_DONE'
} finally {Remove-PSSession $s -ErrorAction SilentlyContinue;$sec.Dispose()}
