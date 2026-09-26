[CmdletBinding()]
param(
    [string]$VmName = '<OTHER_VM_LABEL>',
    [string]$ShareName = 'HexPatch',
    [string]$RunId = '',
    [switch]$EnsureScaffold
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RunId)) {
    $RunId = 'CHANNEL-PREFLIGHT-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
}
if ($RunId -notmatch '^[A-Za-z0-9._-]{1,64}$') { throw 'RunId contains unsupported characters.' }
$vbox = Join-Path $env:ProgramFiles (Join-Path 'Oracle' (Join-Path 'VirtualBox' 'VBoxManage.exe'))
if (-not (Test-Path -LiteralPath $vbox)) { throw 'VBoxManage.exe was not found.' }

$hostShare = Join-Path ([System.IO.Path]::GetPathRoot($PSScriptRoot)) 'HexPatch'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$authoritativeSampleDirectory = Join-Path $projectRoot 'sample'
function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Path)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        return [System.BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-', '')
    } finally {
        $stream.Dispose()
        $algorithm.Dispose()
    }
}
$authoritativeSampleCandidates = @()
if (Test-Path -LiteralPath $authoritativeSampleDirectory) {
    $authoritativeSampleCandidates = @(Get-ChildItem -LiteralPath $authoritativeSampleDirectory -Filter 'EPT*.exe' -File)
}
$authoritativeSamplePath = $null
$authoritativeSampleState = 'MISSING'
$authoritativeSampleSha256 = $null
if ($authoritativeSampleCandidates.Count -eq 1) {
    $authoritativeSamplePath = $authoritativeSampleCandidates[0].FullName
    $authoritativeSampleState = 'HASHED'
    $authoritativeSampleSha256 = Get-Sha256Hex -Path $authoritativeSamplePath
} elseif ($authoritativeSampleCandidates.Count -gt 1) {
    $authoritativeSampleState = 'AMBIGUOUS'
}
$authoritativeSamplePresent = ($authoritativeSampleState -eq 'HASHED')
$hostMarkerPath = Join-Path $hostShare (Join-Path 'probe' 'host_to_guest.txt')
$hostMarkerWritten = $false
if ($EnsureScaffold) {
    foreach ($relative in @('probe', 'spool', 'tools', (Join-Path 'transfer' 'in'), (Join-Path 'transfer' 'out'))) {
        New-Item -ItemType Directory -Force -Path (Join-Path $hostShare $relative) | Out-Null
    }
    $markerContent = 'run_id=' + $RunId + [Environment]::NewLine +
        'direction=host-to-guest' + [Environment]::NewLine +
        'expected_ack=spool/' + $RunId + '.guest.json' + [Environment]::NewLine
    [System.IO.File]::WriteAllText($hostMarkerPath, $markerContent, [System.Text.UTF8Encoding]::new($false))
    $hostMarkerWritten = $true
}

$output = & $vbox showvminfo $VmName --machinereadable 2>&1
if ($LASTEXITCODE -ne 0) { throw "showvminfo failed for $VmName." }
$humanOutput = & $vbox showvminfo $VmName 2>&1
if ($LASTEXITCODE -ne 0) { throw "human showvminfo failed for $VmName." }
$sampleShareLine = @($humanOutput | Where-Object { ([string]$_) -match "Name: 'EPTSample'" }) | Select-Object -First 1
$sampleShareConfigured = ($null -ne $sampleShareLine)
$sampleShareReadonly = [bool]($sampleShareLine -and ([string]$sampleShareLine -match '(?i)readonly'))
$sampleShareAutomount = [bool]($sampleShareLine -and ([string]$sampleShareLine -match '(?i)auto-mount'))
$info = @{}
foreach ($line in $output) {
    $pair = ([string]$line) -split '=', 2
    if ($pair.Count -eq 2) { $info[$pair[0]] = $pair[1].Trim('"') }
}

$slash = [string][char]92
$sampleShareHostPath = $null
for ($index = 1; $index -le 8; $index++) {
    if ($info["SharedFolderNameTransientMapping$index"] -eq 'EPTSample') {
        $sampleShareHostPath = $info["SharedFolderPathTransientMapping$index"].Replace(($slash + $slash), $slash)
        break
    }
}

$sharePath = $null
for ($index = 1; $index -le 8; $index++) {
    if ($info["SharedFolderNameMachineMapping$index"] -eq $ShareName) {
        $sharePath = $info["SharedFolderPathMachineMapping$index"].Replace(($slash + $slash), $slash)
        break
    }
}

$shareWritable = 'UNKNOWN'
$shareAutoMount = 'UNKNOWN'
$configPath = $info['CfgFile'].Replace(($slash + $slash), $slash)
if (Test-Path -LiteralPath $configPath) {
    [xml]$vmXml = Get-Content -LiteralPath $configPath -Raw
    $shareNode = @($vmXml.SelectNodes("//*[local-name()='SharedFolder']") | Where-Object {
        $_.GetAttribute('name') -eq $ShareName
    }) | Select-Object -First 1
    if ($shareNode) {
        $shareWritable = $shareNode.GetAttribute('writable')
        $shareAutoMount = $shareNode.GetAttribute('autoMount')
    }
}

$sessions = & $vbox guestcontrol $VmName list sessions 2>&1
$sessionExit = $LASTEXITCODE
$sessionText = [string]::Join([Environment]::NewLine, @($sessions))
$sessionState = if ($sessionExit -ne 0) {
    'COMMAND_ERROR'
} elseif ($sessionText -match '(?i)no.*session') {
    'NO_SESSIONS'
} elseif ($sessionText -match '(?i)session') {
    'RESPONDED'
} else {
    'UNKNOWN'
}

$hostTools = foreach ($name in @('cdb.exe', 'windbg.exe', 'rizin.exe', 'python.exe', 'git.exe', '7z.exe')) {
    $tool = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
    [pscustomobject]@{ name = $name; available = ($null -ne $tool); path = $(if ($tool) { $tool.Source } else { $null }) }
}

$guestAckPath = Join-Path $hostShare (Join-Path 'spool' ($RunId + '.guest.json'))
$guestAckPresent = Test-Path -LiteralPath $guestAckPath
$guestAckRunId = $null
$guestToolInventory = 'PENDING_GUEST_ACK'
$guestSamplePath = $null
$guestSampleHashState = 'PENDING_GUEST_ACK'
$guestSampleSha256 = $null
$guestSampleMatchesAuthority = $false
$guestLaunchState = 'PENDING_GUEST_ACK'
$guestLaunchPid = $null
if ($guestAckPresent) {
    try {
        $guestData = [System.IO.File]::ReadAllText($guestAckPath) | ConvertFrom-Json
        $guestAckRunId = $guestData.run_id
        if ($guestAckRunId -eq $RunId) {
            $guestToolInventory = @($guestData.tools)
            $guestSamplePath = $guestData.sample_path
            $guestSampleHashState = $guestData.sample_hash_state
            $guestSampleSha256 = $guestData.sample_sha256
            $guestSampleMatchesAuthority = [bool]($authoritativeSampleSha256 -and $guestSampleSha256 -and $guestSampleSha256 -eq $authoritativeSampleSha256)
            $guestLaunchState = $guestData.ept_launch_state
            $guestLaunchPid = $guestData.ept_launch_pid
        } else {
            $guestToolInventory = 'ACK_RUN_ID_MISMATCH'
        }
    } catch {
        $guestToolInventory = 'ACK_PARSE_ERROR'
    }
}

[pscustomobject]@{
    run_id = $RunId
    captured_utc = [DateTime]::UtcNow.ToString('o')
    vm = $VmName
    state = $info['VMState']
    snapshot = $info['CurrentSnapshotName']
    guest_additions_runlevel = $info['GuestAdditionsRunLevel']
    guestcontrol_list_sessions = $sessionState
    guestcontrol_list_sessions_exit = $sessionExit
    guestcontrol_login = 'NOT_TESTED'
    share_name = $ShareName
    share_host_path = $sharePath
    sample_share_name = 'EPTSample'
    sample_share_host_path = $sampleShareHostPath
    sample_share_configured = $sampleShareConfigured
    sample_share_readonly = $sampleShareReadonly
    sample_share_automount = $sampleShareAutomount
    share_host_path_exists = [bool]($sharePath -and (Test-Path -LiteralPath $sharePath))
    host_marker_written = $hostMarkerWritten
    host_marker_visible = Test-Path -LiteralPath $hostMarkerPath
    guest_ack_path = $guestAckPath
    guest_ack_present = $guestAckPresent
    guest_ack_run_id = $guestAckRunId
    authoritative_sample_path = $authoritativeSamplePath
    authoritative_sample_present = $authoritativeSamplePresent
    authoritative_sample_state = $authoritativeSampleState
    authoritative_sample_sha256 = $authoritativeSampleSha256
    guest_sample_path = $guestSamplePath
    guest_sample_hash_state = $guestSampleHashState
    guest_sample_sha256 = $guestSampleSha256
    guest_sample_matches_authority = $guestSampleMatchesAuthority
    ept_launch_state = $guestLaunchState
    ept_launch_pid = $guestLaunchPid
    share_writable = $shareWritable
    share_automount = $shareAutoMount
    host_tools = @($hostTools)
    guest_tool_inventory = $guestToolInventory
} | ConvertTo-Json -Depth 5
