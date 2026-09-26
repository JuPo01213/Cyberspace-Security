[CmdletBinding()]
param(
    [string]$VmName='<VM_LABEL>',
    [string]$RunId='EPT-AUTH-LOCAL-STORED-CONFIG-20260926-01',
    [int]$DeadlineSeconds=180
)
$ErrorActionPreference='Stop'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=ConvertTo-SecureString $pw -AsPlainText -Force
$cred=[pscredential]::new('<VM_USER>',$sec)
$mutex=[Threading.Mutex]::new($false,'Local\EPT_C173_VM_writer')
$held=$false;$s=$null
try {
    $held=$mutex.WaitOne(0)
    if(-not $held){throw 'VM writer busy'}
    $s=New-PSSession -VMName $VmName -Credential $cred
    $nonce=[guid]::NewGuid().ToString('N')
    $probe=Invoke-Command -Session $s -ArgumentList $guestRoot,$nonce -ScriptBlock {
        param($root,$n)
        $ErrorActionPreference='Stop'
        if(Test-Path -LiteralPath $root){throw "Guest run directory exists: $root"}
        New-Item -ItemType Directory -Path $root|Out-Null
        [IO.File]::WriteAllText(($root+'\CONTROL_CANARY.txt'),$n,[Text.Encoding]::ASCII)
        [pscustomobject]@{marker=('CTRL_'+$n);hash=(Get-FileHash -LiteralPath ($root+'\CONTROL_CANARY.txt') -Algorithm SHA256).Hash.ToUpperInvariant()}
    }
    if($probe.marker -ne ('CTRL_'+$nonce)){throw 'control canary mismatch'}
    Copy-Item -ToSession $s -LiteralPath (Join-Path $runDir 'local_runner.ps1') -Destination ($guestRoot+'\local_runner.ps1') -Force
    Copy-Item -ToSession $s -LiteralPath (Join-Path $runDir 'historical_SYS32_Hardware.bin') -Destination ($guestRoot+'\historical_SYS32_Hardware.bin') -Force
    $hostHash=(Get-FileHash -LiteralPath (Join-Path $runDir 'local_runner.ps1') -Algorithm SHA256).Hash.ToUpperInvariant()
    $guestHash=Invoke-Command -Session $s -ArgumentList ($guestRoot+'\local_runner.ps1') -ScriptBlock {param($p)(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()}
    $inputHash=Invoke-Command -Session $s -ArgumentList ($guestRoot+'\historical_SYS32_Hardware.bin') -ScriptBlock {param($p)(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()}
    if($hostHash -ne $guestHash){throw "runner hash mismatch: host=$hostHash guest=$guestHash"}
    if($inputHash -ne 'E5D72F1C6217F9E4AB492E2A868E88C3A988363A7A09C3BEFE4F9EECA2397E1B'){throw "historical config hash mismatch: $inputHash"}
    $taskName='EPT-'+$RunId
    $started=Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId,$DeadlineSeconds,$taskName -ScriptBlock {
        param($root,$id,$deadline,$task)
        $ErrorActionPreference='Stop'
        $action=New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+$root+'\local_runner.ps1" -RunId "'+$id+'" -DeadlineSeconds '+$deadline+' -HistoricalConfigPath "C:\Windows\System32\Hardware\Hardware" -TaskName "'+$task+'"') -WorkingDirectory $root
        $trigger=New-ScheduledTaskTrigger -Once -At ((Get-Date).AddSeconds(5))
        $principal=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        $settings=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 8) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName $task -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force|Out-Null
        Start-ScheduledTask -TaskName $task
        Start-Sleep -Seconds 2
        $t=Get-ScheduledTask -TaskName $task -ErrorAction Stop
        [pscustomobject]@{run_id=$id;task_name=$task;state=[string]$t.State;guest_root=$root;runner_sha256=(Get-FileHash -LiteralPath ($root+'\local_runner.ps1') -Algorithm SHA256).Hash.ToUpperInvariant();historical_config_sha256=(Get-FileHash -LiteralPath ($root+'\historical_SYS32_Hardware.bin') -Algorithm SHA256).Hash.ToUpperInvariant();started_utc=(Get-Date).ToUniversalTime().ToString('o')}
    }
    $launch=[ordered]@{run_id=$RunId;vm=$VmName;guest_root=$guestRoot;target='C:\ept_core\Hardware.exe';target_sha256='CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7';baseline='C173-gen1-ready2';observation_mode='natural';evidence_scope='real_sample_guest_run';network_scope='excluded';debugger='none';memory_writes='none';input_state='HISTORICAL_STORED_CONFIG_CONSUMER';historical_config_source='EPT-AUTHGATE-20260925-65 forced-run capture';historical_config_sha256='E5D72F1C6217F9E4AB492E2A868E88C3A988363A7A09C3BEFE4F9EECA2397E1B';natural_authorization_proven='false';control_nonce=$nonce;runner_sha256=$hostHash;task=$started;dispatched_utc=(Get-Date).ToUniversalTime().ToString('o')}
    $launch|ConvertTo-Json -Depth 12|Set-Content -LiteralPath (Join-Path $runDir 'launch.json') -Encoding UTF8
    $launch|ConvertTo-Json -Depth 12
} finally {
    if($s){Remove-PSSession $s -ErrorAction SilentlyContinue}
    if($held){$mutex.ReleaseMutex()}
    $mutex.Dispose();$sec.Dispose()
}
