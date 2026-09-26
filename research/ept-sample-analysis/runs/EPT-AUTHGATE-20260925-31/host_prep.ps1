[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[string]$RunId='EPT-AUTHGATE-20260925-31')
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
 Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)if(Test-Path -LiteralPath $r){Remove-Item -LiteralPath $r -Recurse -Force};New-Item -ItemType Directory -Force -Path $r|Out-Null;Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb|windbg)'}|Stop-Process -Force -ErrorAction SilentlyContinue}
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'auth_stage_force.cdb') -Destination (Join-Path $guestRoot 'auth_stage_force.cdb') -Force
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'canary_syntax.cdb') -Destination (Join-Path $guestRoot 'canary_syntax.cdb') -Force
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'guest_launch.ps1') -Destination (Join-Path $guestRoot 'guest_launch.ps1') -Force
 Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)
  $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
  $out=Join-Path $r 'canary.stdout.txt'
  $errf=Join-Path $r 'canary.stderr.txt'
  $p=Start-Process -FilePath $cdb -ArgumentList @('-cf',(Join-Path $r 'canary_syntax.cdb'),'cmd.exe','/c','echo CANARY_ECHO_OK') -WorkingDirectory $r -RedirectStandardOutput $out -RedirectStandardError $errf -PassThru -WindowStyle Hidden
  if(-not $p.WaitForExit(60000)){Write-Host 'CANARY_TIMEOUT';Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue}
 }
 Copy-Item -FromSession $s -LiteralPath (Join-Path $guestRoot 'canary.stdout.txt') -Destination (Join-Path $runDir 'canary.stdout.txt') -Force
 $can=Get-Content -LiteralPath (Join-Path $runDir 'canary.stdout.txt') -Raw -ErrorAction SilentlyContinue
 Write-Host '--- CANARY OUTPUT ---'
 Write-Host $can
 $need=@('CANARY_BEGIN','COND_TRUE_WORKS','COND_NEG_WORKS','SIGN_TEST_TRUE','CANARY_ARMED','CANARY_ECHO_OK','CANARY_STOP')
 $missing=@($need|Where-Object {$can -notmatch [regex]::Escape($_)})
 if($can -match 'Syntax error'){throw 'canary reports cdb syntax error'}
 if($missing.Count -gt 0){throw ('canary missing markers: '+($missing -join ','))}
 Write-Host 'CANARY_PASS'
 $taskName='EPT-'+$RunId
 Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId,$taskName -ScriptBlock {param($r,$id,$task)$a=New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+(Join-Path $r 'guest_launch.ps1')+'" -RunId "'+$id+'"') -WorkingDirectory $r;$t=New-ScheduledTaskTrigger -Once -At ((Get-Date).AddSeconds(2));$pr=New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest;$se=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 15);Register-ScheduledTask -TaskName $task -Action $a -Trigger $t -Principal $pr -Settings $se -Force|Out-Null;Start-ScheduledTask -TaskName $task}
 Write-Host 'TASK_STARTED'
 Start-Sleep -Seconds 30
 Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {param($id)"--- events ---";$r="C:\ept_obs\spool\"+$id;if(Test-Path ($r+'\events.ndjson')){Get-Content ($r+'\events.ndjson')};$o=$r+'\cdb.stdout.txt';if(Test-Path $o){(Get-Item $o).Length}}
 Write-Host 'PREP_DONE'
} finally {Remove-PSSession $s -ErrorAction SilentlyContinue;$sec.Dispose()}
