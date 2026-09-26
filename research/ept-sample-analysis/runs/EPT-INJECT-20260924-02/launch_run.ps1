[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260924-02',
    [int]$DeadlineSeconds = 180
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$guestRoot = 'C:\ept_obs\spool\' + $RunId
$taskName = 'EPT-' + $RunId
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    $result = Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId,$DeadlineSeconds,$taskName -ScriptBlock {
        param($guestRoot,$RunId,$DeadlineSeconds,$taskName)
        $scriptPath = Join-Path $guestRoot 'cdb_launch_runner.ps1'
        $actionArgs = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $scriptPath + '" -RunId "' + $RunId + '" -DeadlineSeconds ' + $DeadlineSeconds + ' -TaskName "' + $taskName + '"'
        $taskAction = New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument $actionArgs -WorkingDirectory $guestRoot
        $taskTrigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddSeconds(5))
        $taskPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        $taskSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings -Force | Out-Null
        Start-ScheduledTask -TaskName $taskName
        Start-Sleep -Seconds 2
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        [pscustomobject]@{ run_id=$RunId; task_name=$taskName; state=[string]$task.State; guest_root=$guestRoot; started_utc=(Get-Date).ToUniversalTime().ToString('o') }
    }
    $json = $result | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'launch_result.json'), $json, [System.Text.UTF8Encoding]::new($false))
    $json
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; if ($sec) { $sec.Dispose() } }
