[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-REAL-20260924-03',
    [int]$DeadlineSeconds = 60
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$vmScript = 'C:\ept_obs\spool\' + $RunId + '\natural_runner.ps1'
$guestRoot = 'C:\ept_obs\spool\' + $RunId
$taskName = 'EPT-' + $RunId
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    $r = Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId,$DeadlineSeconds,$taskName -ScriptBlock {
        param($guestRoot,$RunId,$DeadlineSeconds,$taskName)
        New-Item -ItemType Directory -Force -Path $guestRoot | Out-Null
        $taskAction = New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "C:\ept_obs\spool\' + $RunId + '\natural_runner.ps1" -RunId "' + $RunId + '" -DeadlineSeconds ' + $DeadlineSeconds + ' -TaskName "' + $taskName + '"') -WorkingDirectory $guestRoot
        $taskTrigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddSeconds(15))
        $taskPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        $taskSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings -Force | Out-Null
        Start-ScheduledTask -TaskName $taskName
        Start-Sleep -Seconds 2
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        [pscustomobject]@{ run_id = $RunId; task_name = $taskName; state = [string]$task.State; task_path = $vmScript; guest_root = $guestRoot; started_utc = (Get-Date).ToUniversalTime().ToString('o') }
    }
    $hostResult = $r | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'launch_result.json'), $hostResult, [System.Text.UTF8Encoding]::new($false))
    $hostResult
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
