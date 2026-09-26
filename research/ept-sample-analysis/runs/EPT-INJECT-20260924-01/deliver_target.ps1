[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260924-01',
    [string]$TargetHostPath = '<HOST_PATH>/EPT/artifacts/captures/hardware_guest_test.exe',
    [string]$GuestTargetPath = 'C:\ept_core\Hardware.exe'
)

$ErrorActionPreference = 'Stop'
$expectedSha256 = 'CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7'
$hostItem = Get-Item -LiteralPath $TargetHostPath -ErrorAction Stop
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
        }
    }
    if ($state.target_exists -or $state.incoming_exists) { throw "Guest target/incoming path already exists: $($state | ConvertTo-Json -Compress)" }
    Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {
        param($guestRoot)
        New-Item -ItemType Directory -Force -Path 'C:\ept_core' | Out-Null
        New-Item -ItemType Directory -Force -Path $guestRoot | Out-Null
    }
    Copy-Item -ToSession $s -Path $TargetHostPath -Destination $guestIncoming -Force
    $guestHash = Invoke-Command -Session $s -ArgumentList $guestIncoming -ScriptBlock { param($p) (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant() }
    if ($guestHash -ne $expectedSha256) { throw "Guest incoming hash mismatch: $guestHash" }
    Invoke-Command -Session $s -ArgumentList $guestIncoming,$GuestTargetPath -ScriptBlock { param($src,$dst) Move-Item -LiteralPath $src -Destination $dst -Force }
    $final = Invoke-Command -Session $s -ArgumentList $GuestTargetPath -ScriptBlock {
        param($p)
        $i = Get-Item -LiteralPath $p
        [pscustomobject]@{ path=$i.FullName; length=[int64]$i.Length; sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant(); last_write_utc=$i.LastWriteTimeUtc.ToString('o') }
    }
    if ($final.sha256 -ne $expectedSha256 -or [int64]$final.length -ne [int64]$hostItem.Length) { throw "Guest final identity mismatch: $($final | ConvertTo-Json -Compress)" }
    $report = [ordered]@{ run_id=$RunId; vm_name=$VmName; evidence_scope='real_sample_guest_run_injected_io'; target_lineage='genB_direct_derived_target'; host_source=$TargetHostPath; guest_target=$GuestTargetPath; host_length=[int64]$hostItem.Length; host_sha256=$hostHash; guest_length=[int64]$final.length; guest_sha256=[string]$final.sha256; delivered_utc=(Get-Date).ToUniversalTime().ToString('o'); launch_gate='INJECTION_READY' }
    $json = $report | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'delivery_result.json'), $json, [System.Text.UTF8Encoding]::new($false))
    $json
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; if ($sec) { $sec.Dispose() } }
