[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260924-01'
)

$ErrorActionPreference = 'Continue'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$root = 'C:\ept_obs\spool\' + $RunId
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    Invoke-Command -Session $s -ArgumentList $root -ScriptBlock {
        param($root)
        $files = @(Get-ChildItem -LiteralPath $root -File -Force -ErrorAction SilentlyContinue | Select-Object Name,Length,LastWriteTimeUtc)
        $phase = if (Test-Path -LiteralPath (Join-Path $root 'phase.json')) { Get-Content -LiteralPath (Join-Path $root 'phase.json') -Raw } else { $null }
        $done = if (Test-Path -LiteralPath (Join-Path $root 'done.json')) { Get-Content -LiteralPath (Join-Path $root 'done.json') -Raw } else { $null }
        $procs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID|cdb|windbg|ntsd)$' } | Select-Object Id,ProcessName,Path)
        [pscustomobject]@{ root=$root; files=$files; phase=$phase; done=$done; processes=$procs }
    } | ConvertTo-Json -Depth 14
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; if ($sec) { $sec.Dispose() } }
