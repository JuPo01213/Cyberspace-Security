# block_ept_network.ps1
# Block EPT Hardware.exe update/C2 traffic.
# Endpoint: yz.hwid001.com:1029 (custom TCP protocol).
# Run elevated: .\block_ept_network.ps1 ; use -Undo to revert.
[CmdletBinding()]
param([switch]$Undo)

$ErrorActionPreference = 'Continue'
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$entries = @(
    '0.0.0.0 yz.hwid001.com',
    '0.0.0.0 hwid001.com',
    '0.0.0.0 www.hwid001.com'
)
$ruleName = 'BLOCK_EPT_Hardware_C2_1029'
$fw       = 'netsh.exe'

function Set-Hosts {
    param([switch]$Remove)
    $txt = Get-Content -LiteralPath $hostsPath -ErrorAction SilentlyContinue
    $out = @()
    $changed = $false
    foreach ($line in $txt) {
        if ($entries -contains $line.Trim()) {
            if ($Remove) { $changed = $true; continue } else { $out += $line; continue }
        }
        $out += $line
    }
    if (-not $Remove) {
        foreach ($e in $entries) { if ($out -notcontains $e) { $out += $e; $changed = $true } }
    }
    if ($changed) { Set-Content -LiteralPath $hostsPath -Value $out -Encoding ASCII -Force }
    $changed
}

function Flush-DnsCache {
    & ipconfig.exe /flushdns >$null 2>&1
}

if ($Undo) {
    $r = Set-Hosts -Remove
    & $fw advfirewall firewall delete rule name=$ruleName >$null 2>&1
    Flush-DnsCache
    Write-Host "[*] Removed hosts entries and firewall rule; flushed DNS cache"
} else {
    $h = Set-Hosts
    # Make the rule idempotent so repeated preparations do not accumulate stale entries.
    & $fw advfirewall firewall delete rule name=$ruleName >$null 2>&1
    & $fw advfirewall firewall add rule name=$ruleName dir=out action=block protocol=TCP remoteport=1029 profile=any >$null 2>&1
    # The lab DNS capture returned this TEST-NET address; block it as a direct-IP fallback.
    & $fw advfirewall firewall add rule name=$ruleName dir=out action=block protocol=TCP remoteaddress=198.18.2.159 profile=any >$null 2>&1
    Flush-DnsCache
    Write-Host "[*] hosts changed: $h ; firewall rule '$ruleName' blocks TCP/1029 and 198.18.2.159; flushed DNS cache"
    Write-Host "[!] In an isolated VM, keeping the adapter Disconnected is the safest block"
}
Write-Host "[*] C2 endpoint: yz.hwid001.com:1029 (custom TCP, not HTTP)"
