[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-REAL-20260924-03'
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$root = 'C:\ept_obs\spool\' + $RunId
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    $r = Invoke-Command -Session $s -ArgumentList $root,$RunId -ScriptBlock {
        param($root,$RunId)
        $taskName = 'EPT-' + $RunId
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
        $procs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID|powershell|conhost)$' } | ForEach-Object {
            $path = $null
            try { $path = $_.Path } catch {}
            [pscustomobject]@{ pid = $_.Id; name = $_.ProcessName; path = $path; start_utc = try { $_.StartTime.ToUniversalTime().ToString('o') } catch { $null } }
        })
        $files = @(Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue | Select-Object Name,Length,LastWriteTimeUtc,Attributes)
        $phase = $null
        if (Test-Path -LiteralPath ($root + '\phase.json')) { try { $phase = Get-Content -LiteralPath ($root + '\phase.json') -Raw | ConvertFrom-Json } catch {} }
        $done = $null
        if (Test-Path -LiteralPath ($root + '\done.json')) { try { $done = Get-Content -LiteralPath ($root + '\done.json') -Raw | ConvertFrom-Json } catch {} }
        [pscustomobject]@{
            run_id = $RunId
            guest_host = $env:COMPUTERNAME
            utc = (Get-Date).ToUniversalTime().ToString('o')
            task = if ($task) { [pscustomobject]@{ name = $task.TaskName; state = [string]$task.State; last_run = if ($taskInfo) { $taskInfo.LastRunTime.ToString('o') } else { $null }; last_result = if ($taskInfo) { $taskInfo.LastTaskResult } else { $null } } } else { $null }
            processes = $procs
            files = $files
            phase = $phase
            done = $done
        }
    }
    $json = $r | ConvertTo-Json -Depth 12
    [System.IO.File]::WriteAllText((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'status.json'), $json, [System.Text.UTF8Encoding]::new($false))
    $json
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
