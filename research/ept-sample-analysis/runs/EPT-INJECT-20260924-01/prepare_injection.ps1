[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260924-01'
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$runDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot = 'C:\ept_obs\spool\' + $RunId
$hostRunner = Join-Path $runDir 'injected_runner.ps1'
$hostChild = Join-Path $runDir 'child_honest.cdb'
$hostResponse = '<HOST_PATH>/CTF/forge_license_response_284.bin'
$expectedRunnerHash = (Get-FileHash -LiteralPath $hostRunner -Algorithm SHA256).Hash.ToUpperInvariant()
$expectedChildHash = (Get-FileHash -LiteralPath $hostChild -Algorithm SHA256).Hash.ToUpperInvariant()
$expectedResponseHash = (Get-FileHash -LiteralPath $hostResponse -Algorithm SHA256).Hash.ToUpperInvariant()
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId -ScriptBlock {
        param($guestRoot,$RunId)
        if (Test-Path -LiteralPath $guestRoot -PathType Container) {
            $items = @(Get-ChildItem -LiteralPath $guestRoot -Force -ErrorAction SilentlyContinue)
            if ($items.Count -gt 0) { throw "Guest run directory is not empty: $guestRoot" }
        } else { New-Item -ItemType Directory -Force -Path $guestRoot | Out-Null }
        $left = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID|cdb|windbg|ntsd)$' })
        if ($left.Count -gt 0) { throw "Relevant Guest processes remain: $($left.ProcessName -join ',')" }
    }
    Copy-Item -ToSession $s -Path $hostRunner -Destination ($guestRoot + '\injected_runner.ps1') -Force
    Copy-Item -ToSession $s -Path $hostChild -Destination ($guestRoot + '\child_honest.cdb') -Force
    Copy-Item -ToSession $s -Path $hostResponse -Destination ($guestRoot + '\forge_license_response_284.bin') -Force
    $guest = Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId -ScriptBlock {
        param($guestRoot,$RunId)
        $r = Join-Path $guestRoot 'injected_runner.ps1'
        $c = Join-Path $guestRoot 'child_honest.cdb'
        $f = Join-Path $guestRoot 'forge_license_response_284.bin'
        [pscustomobject]@{
            run_id = $RunId
            guest_root = $guestRoot
            runner_sha256 = (Get-FileHash -LiteralPath $r -Algorithm SHA256).Hash.ToUpperInvariant()
            child_cdb_sha256 = (Get-FileHash -LiteralPath $c -Algorithm SHA256).Hash.ToUpperInvariant()
            response_sha256 = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToUpperInvariant()
            runner_bytes = (Get-Item -LiteralPath $r).Length
            child_cdb_bytes = (Get-Item -LiteralPath $c).Length
            response_bytes = (Get-Item -LiteralPath $f).Length
            adapter = @(Get-NetAdapter -ErrorAction SilentlyContinue | Select-Object Name,Status,MacAddress)
            target_present = (Test-Path -LiteralPath 'C:\ept_core\Hardware.exe' -PathType Leaf)
            target_hash = if (Test-Path -LiteralPath 'C:\ept_core\Hardware.exe' -PathType Leaf) { (Get-FileHash -LiteralPath 'C:\ept_core\Hardware.exe' -Algorithm SHA256).Hash.ToUpperInvariant() } else { $null }
        }
    }
    if ($guest.runner_sha256 -ne $expectedRunnerHash) { throw "runner hash mismatch host=$expectedRunnerHash guest=$($guest.runner_sha256)" }
    if ($guest.child_cdb_sha256 -ne $expectedChildHash) { throw "child cdb hash mismatch host=$expectedChildHash guest=$($guest.child_cdb_sha256)" }
    if ($guest.response_sha256 -ne $expectedResponseHash) { throw "response hash mismatch host=$expectedResponseHash guest=$($guest.response_sha256)" }
    $report = [ordered]@{
        run_id = $RunId
        vm_name = $VmName
        guest_root = $guestRoot
        evidence_scope = 'real_sample_guest_run_injected_io'
        response_source = 'forge_license_response_284.bin'
        response_source_scope = 'offline_reference_synthetic_response'
        response_sha256 = $expectedResponseHash
        runner_sha256 = $expectedRunnerHash
        child_cdb_sha256 = $expectedChildHash
        target_sha256 = $guest.target_hash
        target_identity_expected = 'CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7'
        target_identity_match = ($guest.target_hash -eq 'CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7')
        target_present = $guest.target_present
        guest_adapter = $guest.adapter
        prepared_utc = (Get-Date).ToUniversalTime().ToString('o')
    }
    $json = $report | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText((Join-Path $runDir 'prepare_result.json'), $json, [System.Text.UTF8Encoding]::new($false))
    $json
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
