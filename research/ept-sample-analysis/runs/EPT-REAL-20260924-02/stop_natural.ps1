[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-REAL-20260924-02'
)

$ErrorActionPreference = 'Continue'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$taskName = 'EPT-' + $RunId
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    $r = Invoke-Command -Session $s -ArgumentList $taskName -ScriptBlock {
        param($taskName)
        $before = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID)$' } | Select-Object Id,ProcessName,Path)
        $stopped = @()
        foreach ($p in $before) {
            try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; $stopped += [int]$p.Id } catch {}
        }
        try { Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue } catch {}
        try { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue } catch {}
        Start-Sleep -Seconds 2
        $after = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID)$' } | Select-Object Id,ProcessName,Path)
        [pscustomobject]@{
            task_name = $taskName
            utc = (Get-Date).ToUniversalTime().ToString('o')
            before = $before
            stopped = $stopped
            after = $after
        }
    }
    $json = $r | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'stop_result.json'), $json, [System.Text.UTF8Encoding]::new($false))
    $json
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
