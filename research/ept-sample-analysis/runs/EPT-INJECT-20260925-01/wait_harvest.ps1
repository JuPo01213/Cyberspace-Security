[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260925-01',
    [int]$MaxWaitSeconds = 420
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
    $done = $false
    $waited = 0
    while ($waited -lt $MaxWaitSeconds) {
        $exists = Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock { param($r) Test-Path -LiteralPath (Join-Path $r 'done.json') -PathType Leaf }
        if ($exists) { $done = $true; break }
        Start-Sleep -Seconds 5
        $waited += 5
        if ($waited % 30 -eq 0) { Write-Host "waiting for done.json: ${waited}s" }
    }
    if (-not $done) { throw "done.json not observed within $MaxWaitSeconds s" }
    Write-Host "done.json observed after ${waited}s; settling 8s for file handles"
    Start-Sleep -Seconds 8
    $guestFiles = @(Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock { param($r) if (Test-Path -LiteralPath $r -PathType Container) { @(Get-ChildItem -LiteralPath $r -File -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }) } else { @() } })
    $records = @()
    foreach ($gf in $guestFiles) {
        $leaf = Split-Path -Leaf $gf
        $dest = Join-Path $hostRoot $leaf
        try {
            Copy-Item -FromSession $s -Path $gf -Destination $dest -Force -ErrorAction Stop
            $records += [pscustomobject]@{ guest_path = $gf; host_path = $dest; acquired = $true; length = (Get-Item $dest).Length; sha256 = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash }
        } catch {
            $records += [pscustomobject]@{ guest_path = $gf; host_path = $dest; acquired = $false; error = $_.Exception.Message }
        }
    }
    $records | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $hostRoot 'harvest_manifest.json') -Encoding UTF8
    $records | ConvertTo-Json -Depth 8
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
