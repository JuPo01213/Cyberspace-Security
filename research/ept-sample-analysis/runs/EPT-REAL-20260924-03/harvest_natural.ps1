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
$guestRoot = 'C:\ept_obs\spool\' + $RunId
$hostRoot = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'harvest'
New-Item -ItemType Directory -Force -Path $hostRoot | Out-Null
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    $guestFiles = @(Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {
        param($guestRoot)
        if (-not (Test-Path -LiteralPath $guestRoot -PathType Container)) { return @() }
        @(Get-ChildItem -LiteralPath $guestRoot -File -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    })
    $records = @()
    foreach ($gf in $guestFiles) {
        $leaf = Split-Path -Leaf $gf
        $dest = Join-Path $hostRoot $leaf
        try {
            Copy-Item -FromSession $s -Path $gf -Destination $dest -Force -ErrorAction Stop
            $h = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
            $records += [pscustomobject]@{ guest_path = $gf; host_path = $dest; acquired = $true; length = (Get-Item $dest).Length; sha256 = $h }
        } catch {
            $records += [pscustomobject]@{ guest_path = $gf; host_path = $dest; acquired = $false; error = $_.Exception.Message }
        }
    }
    $recordPath = Join-Path $hostRoot 'harvest_manifest.json'
    $records | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $recordPath -Encoding UTF8
    $records | ConvertTo-Json -Depth 8
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
