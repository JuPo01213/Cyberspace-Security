[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[string]$RunId='EPT-AUTH-LOCAL-GATE-REV-20260926-02')
$ErrorActionPreference='Stop'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=ConvertTo-SecureString $pw -AsPlainText -Force
$cred=[pscredential]::new('<VM_USER>',$sec)
$m=[Threading.Mutex]::new($false,'Local\EPT_C173_VM_writer');$held=$false;$s=$null
try {
  $held=$m.WaitOne(0);if(-not $held){throw 'VM writer busy'}
  $s=New-PSSession -VMName $VmName -Credential $cred
  $nonce=[guid]::NewGuid().ToString('N')
  $probe=Invoke-Command -Session $s -ArgumentList $guestRoot,$nonce -ScriptBlock {param($r,$n)$ErrorActionPreference='Stop';if(Test-Path $r){throw 'run exists'};New-Item -ItemType Directory -Force -Path $r|Out-Null;[IO.File]::WriteAllText(($r+'\CONTROL_CANARY.txt'),$n,[Text.Encoding]::ASCII);[pscustomobject]@{marker=$n;hash=(Get-FileHash ($r+'\CONTROL_CANARY.txt') -Algorithm SHA256).Hash.ToUpperInvariant()}}
  if($probe.marker -ne $nonce){throw 'control canary mismatch'}
  foreach($n in @('historical_SYS32_Hardware.bin','gate_rev.cdb','gate_rev2.cdb','guest_observe.ps1')){Copy-Item -ToSession $s -LiteralPath (Join-Path $runDir $n) -Destination ($guestRoot+'\'+$n) -Force}
  $hash=Invoke-Command -Session $s -ArgumentList ($guestRoot+'\historical_SYS32_Hardware.bin') -ScriptBlock {param($p)(Get-FileHash $p -Algorithm SHA256).Hash.ToUpperInvariant()}
  if($hash -ne 'E5D72F1C6217F9E4AB492E2A868E88C3A988363A7A09C3BEFE4F9EECA2397E1B'){throw 'input hash mismatch'}
  $task='EPT-'+$RunId
  $started=Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId,$task -ScriptBlock {
    param($r,$id,$task)
    $action=New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+$r+'\guest_observe.ps1" -RunId "'+$id+'" -TaskName "'+$task+'"') -WorkingDirectory $r
    $trigger=New-ScheduledTaskTrigger -Once -At ((Get-Date).AddSeconds(5));$principal=New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest;$settings=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 8)
    Register-ScheduledTask -TaskName $task -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force|Out-Null;Start-ScheduledTask $task;Start-Sleep 2;[string](Get-ScheduledTask $task).State
  }
  [ordered]@{run_id=$RunId;guest_root=$guestRoot;historical_config_sha256=$hash;runner='guest_observe.ps1';task_state=$started;control_nonce=$nonce;network_scope='excluded';code_patches=$false;authorization_state_writes=$false;response_injection=$false}|ConvertTo-Json
}finally{if($s){Remove-PSSession $s};if($held){$m.ReleaseMutex()};$m.Dispose();$sec.Dispose()}
