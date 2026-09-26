[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-REAL-20260924-02'
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$guestRoot = 'C:\ept_obs\spool\' + $RunId
$hostScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'natural_runner.ps1'
$expectedScriptHash = (Get-FileHash -LiteralPath $hostScript -Algorithm SHA256).Hash.ToUpperInvariant()
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {
        param($guestRoot)
        if (Test-Path -LiteralPath $guestRoot -PathType Container) {
            $active = @(Get-ChildItem -LiteralPath $guestRoot -Force -ErrorAction SilentlyContinue)
            if ($active.Count -gt 0) { throw "Guest run directory is not empty: $guestRoot" }
        } else { New-Item -ItemType Directory -Force -Path $guestRoot | Out-Null }
    }
    Copy-Item -ToSession $s -Path $hostScript -Destination ($guestRoot + '\natural_runner.ps1') -Force
    $guestHash = Invoke-Command -Session $s -ArgumentList ($guestRoot + '\natural_runner.ps1') -ScriptBlock {
        param($path)
        (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
    }
    if ($guestHash -ne $expectedScriptHash) { throw "Watcher script hash mismatch: host=$expectedScriptHash guest=$guestHash" }
    $ready = Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId,$expectedScriptHash -ScriptBlock {
        param($guestRoot,$RunId,$expectedScriptHash)
        $o = [ordered]@{
            run_id = $RunId
            guest_host = $env:COMPUTERNAME
            guest_root = $guestRoot
            script_path = $guestRoot + '\natural_runner.ps1'
            script_sha256 = (Get-FileHash -LiteralPath ($guestRoot + '\natural_runner.ps1') -Algorithm SHA256).Hash.ToUpperInvariant()
            expected_script_sha256 = $expectedScriptHash
            ready_utc = (Get-Date).ToUniversalTime().ToString('o')
            writable = $false
        }
        $canary = Join-Path $guestRoot 'RUNNER_READY.canary'
        Set-Content -LiteralPath $canary -Value $RunId -Encoding ASCII
        $o.writable = ((Get-Content -LiteralPath $canary -Raw).Trim() -eq $RunId)
        $o
    }
    $json = $ready | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'watcher_ready.json'), $json, [System.Text.UTF8Encoding]::new($false))
    $json
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
