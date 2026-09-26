[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-REAL-20260924-02',
    [string]$TargetHostPath = '<HOST_PATH>/EPT/artifacts/captures/hardware_guest_test.exe',
    [string]$GuestTargetPath = 'C:\ept_core\Hardware.exe'
)

$ErrorActionPreference = 'Stop'
$expectedSha256 = 'CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7'
if (-not (Test-Path -LiteralPath $TargetHostPath -PathType Leaf)) { throw "Host target is missing: $TargetHostPath" }
$hostItem = Get-Item -LiteralPath $TargetHostPath
$hostHash = (Get-FileHash -LiteralPath $TargetHostPath -Algorithm SHA256).Hash.ToUpperInvariant()
if ($hostHash -ne $expectedSha256) { throw "Host target hash mismatch: $hostHash" }

$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$guestRoot = 'C:\ept_obs\spool\' + $RunId
$guestIncoming = $guestRoot + '\target.bin'
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    $state = Invoke-Command -Session $s -ArgumentList $GuestTargetPath,$guestIncoming,$guestRoot -ScriptBlock {
        param($GuestTargetPath,$guestIncoming,$guestRoot)
        [pscustomobject]@{
            target_exists = (Test-Path -LiteralPath $GuestTargetPath -PathType Leaf)
            incoming_exists = (Test-Path -LiteralPath $guestIncoming -PathType Leaf)
            root_exists = (Test-Path -LiteralPath $guestRoot -PathType Container)
            target_hash = if (Test-Path -LiteralPath $GuestTargetPath -PathType Leaf) { (Get-FileHash -LiteralPath $GuestTargetPath -Algorithm SHA256).Hash } else { $null }
        }
    }
    if ($state.incoming_exists) { throw "Guest incoming path is already present; refusing to overwrite: $($state | ConvertTo-Json -Compress)" }
    if ($state.target_exists -and ([string]$state.target_hash).ToUpperInvariant() -ne $expectedSha256) { throw "Guest target hash mismatch: $($state | ConvertTo-Json -Compress)" }
    $reusedExistingTarget = [bool]$state.target_exists
    Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {
        param($guestRoot)
        New-Item -ItemType Directory -Force -Path 'C:\ept_core' | Out-Null
        New-Item -ItemType Directory -Force -Path $guestRoot | Out-Null
        Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID|cdb|windbg|ntsd)$' } | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    if (-not $reusedExistingTarget) {
        Copy-Item -ToSession $s -Path $TargetHostPath -Destination $guestIncoming -Force
        $guestHash = Invoke-Command -Session $s -ArgumentList $guestIncoming -ScriptBlock {
            param($guestIncoming)
            (Get-FileHash -LiteralPath $guestIncoming -Algorithm SHA256).Hash.ToUpperInvariant()
        }
        if ($guestHash -ne $expectedSha256) { throw "Guest incoming hash mismatch: $guestHash" }
        Invoke-Command -Session $s -ArgumentList $guestIncoming,$GuestTargetPath -ScriptBlock {
            param($guestIncoming,$GuestTargetPath)
            Move-Item -LiteralPath $guestIncoming -Destination $GuestTargetPath -Force
        }
    }
    $final = Invoke-Command -Session $s -ArgumentList $GuestTargetPath,$RunId,$reusedExistingTarget -ScriptBlock {
        param($GuestTargetPath,$RunId,$reusedExistingTarget)
        $i = Get-Item -LiteralPath $GuestTargetPath
        [pscustomobject]@{
            run_id = $RunId
            path = $i.FullName
            length = [int64]$i.Length
            sha256 = (Get-FileHash -LiteralPath $GuestTargetPath -Algorithm SHA256).Hash.ToUpperInvariant()
            last_write_utc = $i.LastWriteTimeUtc.ToString('o')
            process_count = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|UVT|Spoof|EPTHWID|cdb|windbg|ntsd)$' }).Count
            guest_free_gb = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
        }
    }
    if ($final.sha256 -ne $expectedSha256 -or [int64]$final.length -ne [int64]$hostItem.Length) { throw "Guest final identity mismatch: $($final | ConvertTo-Json -Compress)" }
    $report = [ordered]@{
        run_id = $RunId
        vm_name = $VmName
        guest_host = $final.PSComputerName
        evidence_scope = 'real_sample_guest_run'
        target_lineage = 'genB_direct_derived_target'
        host_source = $TargetHostPath
        guest_target = $GuestTargetPath
        incoming_guest_path = $guestIncoming
        host_length = [int64]$hostItem.Length
        host_sha256 = $hostHash
        guest_length = [int64]$final.length
        guest_sha256 = [string]$final.sha256
        guest_free_gb = $final.guest_free_gb
        target_processes_before_start = $final.process_count
        reused_existing_target = $reusedExistingTarget
        delivered_utc = (Get-Date).ToUniversalTime().ToString('o')
        input_state = 'synthetic_invalid_card_no_secret'
        launch_gate = 'NATURAL_BASELINE_READY'
    }
    $json = $report | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'delivery.json'), $json, [System.Text.UTF8Encoding]::new($false))
    $json
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
