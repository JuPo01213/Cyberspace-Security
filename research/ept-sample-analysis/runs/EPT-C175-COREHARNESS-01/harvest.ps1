# Host Authority harvest for EPT-C175-COREHARNESS-01
# Pull Guest spool/output artifacts to Host evidence dir; record Host-side sha256.
$ErrorActionPreference = "Stop"

$pwPath = "<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt"
$pw = (Get-Content $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("<VM_USER>", $sec)
$vm = "<VM_LABEL>"

$hostRaw = "<HOST_PATH>/EPT/artifacts/evidence/C175_coreharness/raw"
New-Item -ItemType Directory -Force -Path $hostRaw | Out-Null

$s = New-PSSession -VMName $vm -Credential $cred
try {
    $guestFiles = @(
        "C:\ept_obs\spool\run_meta.json",
        "C:\ept_obs\spool\done.json",
        "C:\ept_obs\out\decode_report.json",
        "C:\ept_obs\out\caller_structure_after_decode.bin",
        "C:\ept_obs\out\decoded_output.bin",
        "C:\ept_obs\out\response_before_decode.bin",
        "C:\ept_obs\out\stdout.txt",
        "C:\ept_obs\out\stderr.txt",
        "C:\ept_obs\out_response\decode_report.json",
        "C:\ept_obs\out_response\caller_structure_after_decode.bin",
        "C:\ept_obs\out_response\decoded_output.bin",
        "C:\ept_obs\out_response\response_before_decode.bin",
        "C:\ept_obs\out_response\stdout.txt",
        "C:\ept_obs\out_response\stderr.txt",
        "C:\ept_obs\out_selftest\stdout.txt",
        "C:\ept_obs\out_selftest\stderr.txt"
    )
    $manifest = @()
    foreach ($gf in $guestFiles) {
        $leaf = Split-Path $gf -Leaf
        # build a unique host name preserving which mode it came from
        if ($gf -like "*\out_response\*") { $name = "response__$leaf" }
        elseif ($gf -like "*\out_selftest\*") { $name = "selftest__$leaf" }
        elseif ($gf -like "*\out\*") { $name = "input__$leaf" }
        else { $name = $leaf }
        $dest = Join-Path $hostRaw $name
        if (Test-Path "Microsoft.PowerShell.Core\FileSystem::$gf") { } # noop
        try {
            Copy-Item -FromSession $s -Path $gf -Destination $dest -Force -ErrorAction Stop
            $ok = $true
        } catch {
            $ok = $false
        }
        if ($ok -and (Test-Path $dest)) {
            $h = (Get-FileHash $dest -Algorithm SHA256).Hash
            $manifest += @{ guest_path=$gf; host_path=$dest; sha256=$h; acquired=$true }
        } else {
            $manifest += @{ guest_path=$gf; host_path=$dest; sha256=$null; acquired=$false }
        }
    }
    $manifest | ConvertTo-Json -Depth 4 | Out-File -FilePath "<HOST_PATH>/EPT/artifacts/evidence/C175_coreharness/raw/harvest_manifest.json" -Encoding utf8
    Write-Output ($manifest | ConvertTo-Json -Depth 4 -Compress)
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
}
