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
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {
        param($RunId)
        $before = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID|cdb|windbg|ntsd)$' } | Select-Object Id,ProcessName,Path)
        foreach ($p in $before) { try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {} }
        Start-Sleep -Seconds 2
        $after = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID|cdb|windbg|ntsd)$' } | Select-Object Id,ProcessName,Path)
        [pscustomobject]@{ run_id=$RunId; before=$before; after=$after }
    } | ConvertTo-Json -Depth 8
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; if ($sec) { $sec.Dispose() } }
