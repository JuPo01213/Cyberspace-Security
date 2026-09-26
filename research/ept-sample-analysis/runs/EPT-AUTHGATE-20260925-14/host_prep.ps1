[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[string]$RunId='EPT-AUTHGATE-20260925-14')
$ErrorActionPreference='Stop'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=ConvertTo-SecureString $pw -AsPlainText -Force
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
try {
 Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)if(Test-Path -LiteralPath $r){Remove-Item -LiteralPath $r -Recurse -Force};New-Item -ItemType Directory -Force -Path $r|Out-Null;Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb|windbg)'}|Stop-Process -Force -ErrorAction SilentlyContinue}
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'auth_release_stage_log.cdb') -Destination (Join-Path $guestRoot 'auth_release_stage_log.cdb') -Force
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'guest_launch.ps1') -Destination (Join-Path $guestRoot 'guest_launch.ps1') -Force
 $taskName='EPT-'+$RunId
 Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId,$taskName -ScriptBlock {param($r,$id,$task)$a=New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+(Join-Path $r 'guest_launch.ps1')+'" -RunId "'+$id+'"') -WorkingDirectory $r;$t=New-ScheduledTaskTrigger -Once -At ((Get-Date).AddSeconds(2));$pr=New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest;$se=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 15);Register-ScheduledTask -TaskName $task -Action $a -Trigger $t -Principal $pr -Settings $se -Force|Out-Null;Start-ScheduledTask -TaskName $task}
 Start-Sleep -Seconds 30
 Invoke-Command -Session $s -ScriptBlock {"--- events ---";$r="C:\ept_obs\spool\EPT-AUTHGATE-20260925-14";if(Test-Path ($r+'\events.ndjson')){Get-Content ($r+'\events.ndjson')};"--- procs ---";Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb)'}|Select-Object Id,ProcessName,@{n='CPU';e={$_.CPU}}|Format-Table -AutoSize|Out-String -Width 120}
 Write-Host 'PREP_DONE'
} finally {Remove-PSSession $s -ErrorAction SilentlyContinue;$sec.Dispose()}
