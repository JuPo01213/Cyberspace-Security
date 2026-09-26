[CmdletBinding()]
param(
    [switch]$IncludeIdentifiers
)

$ErrorActionPreference = "SilentlyContinue"

function Test-Command {
    param([Parameter(Mandatory=$true)][string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        return [pscustomobject]@{ available = $false; source = $null }
    }
    return [pscustomobject]@{ available = $true; source = $cmd.Source }
}

function Test-Parameter {
    param(
        [Parameter(Mandatory=$true)][string]$Command,
        [Parameter(Mandatory=$true)][string]$Parameter
    )
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if ($null -eq $cmd) { return $false }
    return $cmd.Parameters.ContainsKey($Parameter)
}

$isElevated = $false
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {}

$hyperV = Test-Command "Get-VM"
$vbox = Test-Command "VBoxManage.exe"
if (-not $vbox.available) {
    $candidate = Join-Path $env:ProgramFiles "Oracle\VirtualBox\VBoxManage.exe"
    if (Test-Path $candidate) {
        $vbox = [pscustomobject]@{ available = $true; source = $candidate }
    }
}

$ssh = Test-Command "ssh.exe"
$scp = Test-Command "scp.exe"
$cdb = Test-Command "cdb.exe"

if (-not $cdb.available -and $env:ProgramFiles) {
    $roots = @()
    $pf86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    if ($pf86) { $roots += $pf86 }
    $roots += $env:ProgramFiles
    foreach ($root in $roots) {
        foreach ($arch in @("x64","x86")) {
            $candidate = Join-Path $root "Windows Kits\10\Debuggers\$arch\cdb.exe"
            if (Test-Path $candidate) {
                $cdb = [pscustomobject]@{ available = $true; source = $candidate }
                break
            }
        }
        if ($cdb.available) { break }
    }
}

$vmSummary = $null
$vmIdentifiers = $null
if ($hyperV.available) {
    $vms = @(Get-VM)
    $vmSummary = [ordered]@{
        count = $vms.Count
        running = @($vms | Where-Object State -eq "Running").Count
        off = @($vms | Where-Object State -eq "Off").Count
        saved = @($vms | Where-Object State -eq "Saved").Count
        other = @($vms | Where-Object { $_.State -notin @("Running","Off","Saved") }).Count
    }
    if ($IncludeIdentifiers) {
        $vmIdentifiers = @($vms | Select-Object Name, State, Generation)
    }
}

$vboxVersion = $null
if ($vbox.available) {
    try { $vboxVersion = (& $vbox.source --version 2>$null | Select-Object -First 1) } catch {}
}

$result = [ordered]@{
    schema = "wge-preflight-v2"
    note = "Read-only capability discovery. Do not commit raw output containing identifiers."
    host = [ordered]@{
        powershell = $PSVersionTable.PSVersion.ToString()
        windows = [bool]$IsWindows
        elevated = $isElevated
    }
    hyperv = [ordered]@{
        available = $hyperV.available
        powershell_direct_invoke = (Test-Parameter "Invoke-Command" "VMName")
        powershell_direct_session = (Test-Parameter "New-PSSession" "VMName")
        vm_summary = $vmSummary
    }
    virtualbox = [ordered]@{
        available = $vbox.available
        version = $vboxVersion
    }
    ssh = [ordered]@{
        available = $ssh.available
        scp_available = $scp.available
    }
    host_cdb = [ordered]@{
        available = $cdb.available
        note = "Host capability only. Guest debugger capability is not probed by this read-only Host preflight."
    }
    guest_debugger = [ordered]@{
        state = "UNKNOWN_NOT_PROBED"
    }
}

if ($IncludeIdentifiers) {
    $result.hyperv.vm_identifiers = $vmIdentifiers
    $result.virtualbox.executable = $vbox.source
    $result.ssh.executable = $ssh.source
    $result.ssh.scp_executable = $scp.source
    $result.host_cdb.executable = $cdb.source
}

$result | ConvertTo-Json -Depth 6
