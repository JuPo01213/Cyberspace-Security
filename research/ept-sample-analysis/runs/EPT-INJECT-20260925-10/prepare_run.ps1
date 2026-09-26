[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260924-03'
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$runDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot = 'C:\ept_obs\spool\' + $RunId
$hostRunner = Join-Path $runDir 'cdb_launch_runner.ps1'
$hostChild = Join-Path $runDir 'child.cdb'
$hostLate = Join-Path $runDir 'late.cdb'
$hostResponse = '<HOST_PATH>/CTF/forge_license_response_284.bin'
$expectedRunnerHash = (Get-FileHash -LiteralPath $hostRunner -Algorithm SHA256).Hash.ToUpperInvariant()
$expectedChildHash = (Get-FileHash -LiteralPath $hostChild -Algorithm SHA256).Hash.ToUpperInvariant()
$expectedLateHash = (Get-FileHash -LiteralPath $hostLate -Algorithm SHA256).Hash.ToUpperInvariant()
$expectedResponseHash = (Get-FileHash -LiteralPath $hostResponse -Algorithm SHA256).Hash.ToUpperInvariant()
$expectedTargetHash = 'CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7'
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {
        param($guestRoot)
        if (Test-Path -LiteralPath $guestRoot -PathType Container) {
            $items = @(Get-ChildItem -LiteralPath $guestRoot -Force -ErrorAction SilentlyContinue)
            if ($items.Count -gt 0) { throw "Guest run directory is not empty: $guestRoot" }
        } else { New-Item -ItemType Directory -Force -Path $guestRoot | Out-Null }
        $left = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID|cdb|windbg|ntsd)$' })
        if ($left.Count -gt 0) { throw "Relevant Guest processes remain: $($left.ProcessName -join ',')" }
    }
    Copy-Item -ToSession $s -Path $hostRunner -Destination ($guestRoot + '\cdb_launch_runner.ps1') -Force
    Copy-Item -ToSession $s -Path $hostChild -Destination ($guestRoot + '\child.cdb') -Force
    Copy-Item -ToSession $s -Path $hostLate -Destination ($guestRoot + '\late.cdb') -Force
    Copy-Item -ToSession $s -Path $hostResponse -Destination ($guestRoot + '\forge_license_response_284.bin') -Force
    $guest = Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId -ScriptBlock {
        param($guestRoot,$RunId)
        $r = Join-Path $guestRoot 'cdb_launch_runner.ps1'
        $c = Join-Path $guestRoot 'child.cdb'
        $l = Join-Path $guestRoot 'late.cdb'
        $f = Join-Path $guestRoot 'forge_license_response_284.bin'
        $target = 'C:\ept_core\Hardware.exe'
        [pscustomobject]@{
            run_id = $RunId
            guest_root = $guestRoot
            runner_sha256 = (Get-FileHash -LiteralPath $r -Algorithm SHA256).Hash.ToUpperInvariant()
            child_cdb_sha256 = (Get-FileHash -LiteralPath $c -Algorithm SHA256).Hash.ToUpperInvariant()
            late_cdb_sha256 = (Get-FileHash -LiteralPath $l -Algorithm SHA256).Hash.ToUpperInvariant()
            response_sha256 = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToUpperInvariant()
            runner_bytes = (Get-Item -LiteralPath $r).Length
            child_cdb_bytes = (Get-Item -LiteralPath $c).Length
            late_cdb_bytes = (Get-Item -LiteralPath $l).Length
            response_bytes = (Get-Item -LiteralPath $f).Length
            adapter = @(Get-NetAdapter -ErrorAction SilentlyContinue | Select-Object Name,Status,MacAddress)
            target_present = (Test-Path -LiteralPath $target -PathType Leaf)
            target_hash = if (Test-Path -LiteralPath $target -PathType Leaf) { (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToUpperInvariant() } else { $null }
            target_length = if (Test-Path -LiteralPath $target -PathType Leaf) { [int64](Get-Item -LiteralPath $target).Length } else { $null }
        }
    }
    if ($guest.runner_sha256 -ne $expectedRunnerHash) { throw "runner hash mismatch host=$expectedRunnerHash guest=$($guest.runner_sha256)" }
    if ($guest.child_cdb_sha256 -ne $expectedChildHash) { throw "child cdb hash mismatch host=$expectedChildHash guest=$($guest.child_cdb_sha256)" }
    if ($guest.late_cdb_sha256 -ne $expectedLateHash) { throw "late cdb hash mismatch host=$expectedLateHash guest=$($guest.late_cdb_sha256)" }
    if ($guest.response_sha256 -ne $expectedResponseHash) { throw "response hash mismatch host=$expectedResponseHash guest=$($guest.response_sha256)" }
    if (-not $guest.target_present -or $guest.target_hash -ne $expectedTargetHash) { throw "target identity mismatch expected=$expectedTargetHash actual=$($guest.target_hash)" }
    $report = [ordered]@{
        run_id = $RunId
        vm_name = $VmName
        guest_root = $guestRoot
        evidence_scope = 'real_sample_guest_run_injected_io'
        process_model = 'debugger_launch'
        response_source = 'forge_license_response_284.bin'
        response_source_scope = 'offline_reference_synthetic_response'
        response_sha256 = $expectedResponseHash
        runner_sha256 = $expectedRunnerHash
        child_cdb_sha256 = $expectedChildHash
        late_cdb_sha256 = $expectedLateHash
        target_sha256 = $guest.target_hash
        target_length = $guest.target_length
        target_identity_expected = $expectedTargetHash
        target_identity_match = ($guest.target_hash -eq $expectedTargetHash)
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
