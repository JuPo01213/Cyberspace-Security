[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-REAL-20260924-02'
)

$ErrorActionPreference = 'Stop'
$hostScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'natural_runner.ps1'
$hostHash = (Get-FileHash -LiteralPath $hostScript -Algorithm SHA256).Hash.ToUpperInvariant()
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$root = 'C:\ept_obs\spool\' + $RunId
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    $r = Invoke-Command -Session $s -ArgumentList $root,$RunId,$hostHash -ScriptBlock {
        param($root,$RunId,$hostHash)
        $taskName = 'EPT-' + $RunId
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        $runner = Join-Path $root 'natural_runner.ps1'
        $guestHash = if (Test-Path -LiteralPath $runner -PathType Leaf) { (Get-FileHash -LiteralPath $runner -Algorithm SHA256).Hash.ToUpperInvariant() } else { $null }
        $done = $null
        if (Test-Path -LiteralPath (Join-Path $root 'done.json')) { $done = Get-Content -LiteralPath (Join-Path $root 'done.json') -Raw | ConvertFrom-Json }
        $phase = Get-Content -LiteralPath (Join-Path $root 'phase.json') -Raw | ConvertFrom-Json
        [pscustomobject]@{
            run_id = $RunId
            guest_host = $env:COMPUTERNAME
            host_script_sha256 = $hostHash
            guest_script_sha256 = $guestHash
            script_match = ($hostHash -eq $guestHash)
            scheduled_task = if ($task) { [pscustomobject]@{ name=$task.TaskName; state=[string]$task.State } } else { $null }
            phase = $phase
            done = $done
            target_processes = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID)$' } | Select-Object Id,ProcessName,Path)
            utc = (Get-Date).ToUniversalTime().ToString('o')
        }
    }
    $json = $r | ConvertTo-Json -Depth 12
    [System.IO.File]::WriteAllText((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'resolve.json'), $json, [System.Text.UTF8Encoding]::new($false))
    $json
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
