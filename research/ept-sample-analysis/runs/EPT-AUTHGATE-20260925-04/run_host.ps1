[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[string]$RunId='EPT-AUTHGATE-20260925-04')
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
 $started=Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId -ScriptBlock {param($r,$id)$p=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $r 'guest_runner.ps1'),'-RunId',$id) -WorkingDirectory $r -PassThru -WindowStyle Hidden;[pscustomobject]@{pid=[int]$p.Id;started_utc=(Get-Date).ToUniversalTime().ToString('o')}}
 Start-Sleep -Seconds 55
 foreach($n in @('auth_gate.cdb','guest_runner.ps1','cdb.stdout.txt','cdb.stderr.txt','summary.json','done.json')){try{Copy-Item -FromSession $s -LiteralPath (Join-Path $guestRoot $n) -Destination (Join-Path $runDir $n) -Force}catch{}}
 Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)Stop-Process -Id $using:started.pid -Force -ErrorAction SilentlyContinue;Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT.*|cdb|windbg)$'}|Stop-Process -Force -ErrorAction SilentlyContinue}
} finally {Remove-PSSession $s -ErrorAction SilentlyContinue;$sec.Dispose()}
