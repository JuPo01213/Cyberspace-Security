[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[string]$RunId='EPT-AUTHGATE-20260925-01')
$ErrorActionPreference='Stop'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=ConvertTo-SecureString $pw -AsPlainText -Force
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
try {
 Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r) if(Test-Path -LiteralPath $r){$x=@(Get-ChildItem -LiteralPath $r -Force);if($x.Count){throw "Guest run directory not empty: $r"}}else{New-Item -ItemType Directory -Force -Path $r|Out-Null};$p=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT.*|cdb|windbg)$'});if($p.Count){throw 'Relevant Guest process remains'}}
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'auth_gate.cdb') -Destination (Join-Path $guestRoot 'auth_gate.cdb') -Force
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'guest_runner.ps1') -Destination (Join-Path $guestRoot 'guest_runner.ps1') -Force
 Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId -ScriptBlock {param($r,$id)$a=New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+(Join-Path $r 'guest_runner.ps1')+'" -RunId "'+$id+'"') -WorkingDirectory $r;$t=New-ScheduledTaskTrigger -Once -At ((Get-Date).AddSeconds(3));$pr=New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest;$se=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 3);Register-ScheduledTask -TaskName ('EPT-'+$id) -Action $a -Trigger $t -Principal $pr -Settings $se -Force|Out-Null;Start-ScheduledTask -TaskName ('EPT-'+$id)}
 Start-Sleep -Seconds 55
 foreach($n in @('auth_gate.cdb','guest_runner.ps1','cdb.stdout.txt','cdb.stderr.txt','summary.json','done.json')){try{Copy-Item -FromSession $s -LiteralPath (Join-Path $guestRoot $n) -Destination (Join-Path $runDir $n) -Force}catch{}}
 Invoke-Command -Session $s -ArgumentList ('EPT-'+$RunId),$guestRoot -ScriptBlock {param($task,$r)Stop-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue;Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction SilentlyContinue;Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT.*|cdb|windbg)$'}|Stop-Process -Force -ErrorAction SilentlyContinue}
} finally {Remove-PSSession $s -ErrorAction SilentlyContinue;$sec.Dispose()}
