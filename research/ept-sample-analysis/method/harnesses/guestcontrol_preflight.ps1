[CmdletBinding()]
param(
    [string]$VmName = '<OTHER_VM_LABEL>',
    [string]$RunId = '',
    [string]$GuestScript = '\\VBoxSvr\HexPatch\probe\guest_preflight.ps1',
    [string]$GuestDomain = '',
    [int]$TimeoutMilliseconds = 30000,
    [switch]$Launch
)

$ErrorActionPreference = 'Stop'
if ($TimeoutMilliseconds -lt 1000 -or $TimeoutMilliseconds -gt 120000) {
    throw 'TimeoutMilliseconds must be between 1000 and 120000.'
}

$hostShare = Join-Path ([System.IO.Path]::GetPathRoot($PSScriptRoot)) 'HexPatch'
$markerPath = Join-Path $hostShare (Join-Path 'probe' 'host_to_guest.txt')
if ([string]::IsNullOrWhiteSpace($RunId)) {
    if (-not (Test-Path -LiteralPath $markerPath)) { throw 'Host marker is missing; run target_vm_preflight.ps1 -EnsureScaffold first.' }
    $markerText = [System.IO.File]::ReadAllText($markerPath)
    $markerMatch = [regex]::Match($markerText, '(?m)^run_id=([A-Za-z0-9._-]{1,64})\r?$')
    if (-not $markerMatch.Success) { throw 'Host marker does not contain a valid RunId.' }
    $RunId = $markerMatch.Groups[1].Value
}
if ($RunId -notmatch '^[A-Za-z0-9._-]{1,64}$') { throw 'RunId contains unsupported characters.' }

$ackPath = Join-Path $hostShare (Join-Path 'spool' ($RunId + '.guest.json'))
if (Test-Path -LiteralPath $ackPath) { throw 'ACK already exists for this RunId; create a fresh host marker first.' }

$vbox = Join-Path $env:ProgramFiles (Join-Path 'Oracle' (Join-Path 'VirtualBox' 'VBoxManage.exe'))
if (-not (Test-Path -LiteralPath $vbox)) { throw 'VBoxManage.exe was not found.' }
$guestPowerShell = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$preflightPath = Join-Path $PSScriptRoot 'target_vm_preflight.ps1'
if (-not (Test-Path -LiteralPath $preflightPath)) { throw 'Host preflight script is missing.' }

function ConvertTo-WindowsCommandLineArgument {
    param([Parameter(Mandatory = $true)][string]$Value)
    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') { return $Value }

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append([char]34)
    $slashCount = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq [char]92) {
            $slashCount++
            continue
        }
        if ($character -eq [char]34) {
            for ($index = 0; $index -lt (2 * $slashCount + 1); $index++) { [void]$builder.Append([char]92) }
            [void]$builder.Append([char]34)
        } else {
            for ($index = 0; $index -lt $slashCount; $index++) { [void]$builder.Append([char]92) }
            [void]$builder.Append($character)
        }
        $slashCount = 0
    }
    for ($index = 0; $index -lt (2 * $slashCount); $index++) { [void]$builder.Append([char]92) }
    [void]$builder.Append([char]34)
    return $builder.ToString()
}

$userName = Read-Host -Prompt 'Windows account for <OTHER_VM_LABEL>'
if ([string]::IsNullOrWhiteSpace($userName)) { throw 'Username is empty.' }
$resolvedGuestDomain = $GuestDomain
if ([string]::IsNullOrWhiteSpace($resolvedGuestDomain)) {
    $domainProperty = & $vbox guestproperty get $VmName ('/VirtualBox/GuestInfo/User/' + $userName + '/Domain') 2>$null
    $domainMatch = [regex]::Match(($domainProperty -join ' '), '^Valu<HOST_PATH>\s*(.+?)\s*$')
    if ($domainMatch.Success) { $resolvedGuestDomain = $domainMatch.Groups[1].Value }
}
$passwordSecure = Read-Host -Prompt 'Password (input is hidden)' -AsSecureString
if ($null -eq $passwordSecure) { throw 'Password prompt was cancelled.' }
$credential = [System.Management.Automation.PSCredential]::new($userName, $passwordSecure)
$passwordSecure = $null

$privateDirectory = Join-Path $env:TEMP ('vboxgc-' + [Guid]::NewGuid().ToString('N'))
$passwordFile = Join-Path $privateDirectory 'password.txt'
$process = $null
$plainPassword = $null
try {
    $currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
    $directorySecurity = New-Object System.Security.AccessControl.DirectorySecurity
    $directorySecurity.SetAccessRuleProtection($true, $false)
    $directorySecurity.SetOwner($currentSid)
    $accessRule = [System.Security.AccessControl.FileSystemAccessRule]::new(
        $currentSid,
        [System.Security.AccessControl.FileSystemRights]::FullControl,
        ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit),
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $directorySecurity.AddAccessRule($accessRule)
    [void][System.IO.Directory]::CreateDirectory($privateDirectory, $directorySecurity)

    $plainPassword = [System.Net.NetworkCredential]::new('', $credential.Password).Password
    [System.IO.File]::WriteAllText($passwordFile, $plainPassword, [System.Text.UTF8Encoding]::new($false))

    $nativeArguments = @(
        'guestcontrol', $VmName, 'run',
        ('--exe=' + $guestPowerShell),
        ('--username=' + $credential.UserName),
        ('--passwordfile=' + $passwordFile),
        ('--timeout=' + $TimeoutMilliseconds),
        '--wait-stdout', '--wait-stderr'
    )
    if (-not [string]::IsNullOrWhiteSpace($resolvedGuestDomain)) {
        $nativeArguments += ('--domain=' + $resolvedGuestDomain)
    }
    $nativeArguments += @(
        '--',
        '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
        '-File', $GuestScript, '-RunId', $RunId
    )
    if ($Launch) { $nativeArguments += '-Launch' }
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $vbox
    $startInfo.Arguments = (($nativeArguments | ForEach-Object { ConvertTo-WindowsCommandLineArgument ([string]$_) }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw 'VBoxManage process did not start.' }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutMilliseconds + 10000)) {
        $process.Kill()
        throw 'GuestControl wrapper exceeded its host timeout.'
    }
    $process.WaitForExit()
    $guestStdout = $stdoutTask.GetAwaiter().GetResult()
    $guestStderr = $stderrTask.GetAwaiter().GetResult()
    $guestExitCode = $process.ExitCode
    if ($guestExitCode -ne 0) {
        $detail = ($guestStderr -replace '[\r\n]+', ' ').Trim()
        if ($detail.Length -gt 500) { $detail = $detail.Substring(0, 500) }
        throw ('GuestControl returned exit code ' + $guestExitCode + ': ' + $detail)
    }

    $hostReportText = & $preflightPath -RunId $RunId
    $hostReport = $hostReportText | ConvertFrom-Json
    if (-not $hostReport.guest_ack_present -or $hostReport.guest_ack_run_id -ne $RunId) {
        throw 'GuestControl completed, but the matching share ACK is missing.'
    }
    if (-not $hostReport.authoritative_sample_present -or -not $hostReport.guest_sample_matches_authority) {
        throw 'Guest sample hash does not match the authoritative host sample; EPT launch is held.'
    }
    $authoritativeDirectory = Split-Path -Parent ([string]$hostReport.authoritative_sample_path)
    if (-not $hostReport.sample_share_configured -or -not $hostReport.sample_share_readonly -or -not $hostReport.sample_share_automount -or $hostReport.sample_share_host_path -ne $authoritativeDirectory) {
        throw 'EPTSample is not the expected read-only authoritative sample share; EPT launch is held.'
    }
    if ($Launch -and $hostReport.ept_launch_state -ne 'STARTED') {
        throw ('EPT launch did not start: ' + [string]$hostReport.ept_launch_state)
    }

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $evidenceDirectory = Join-Path $projectRoot (Join-Path 'artifacts' 'evidence')
    $evidencePath = Join-Path $evidenceDirectory ('guestcontrol_preflight_' + $RunId + '.json')
    if (Test-Path -LiteralPath $evidencePath) { throw 'Evidence path already exists; preserve it and use a fresh RunId.' }
    [System.IO.File]::WriteAllText($evidencePath, ($hostReport | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))

    $resultStatus = if ($Launch) { 'EPT_LAUNCH_STARTED' } else { 'GUEST_PREFLIGHT_OK' }
    [pscustomobject]@{
        status = $resultStatus
        run_id = $RunId
        guest_ack_path = $hostReport.guest_ack_path
        evidence_path = $evidencePath
        authoritative_sample_sha256 = $hostReport.authoritative_sample_sha256
        guest_sample_sha256 = $hostReport.guest_sample_sha256
        guest_sample_matches_authority = $hostReport.guest_sample_matches_authority
        ept_launch_state = $hostReport.ept_launch_state
        ept_launch_pid = $hostReport.ept_launch_pid
        guest_tool_inventory = $hostReport.guest_tool_inventory
    } | ConvertTo-Json -Depth 8
} finally {
    $plainPassword = $null
    if ($credential -and $credential.Password) { $credential.Password.Dispose() }
    if ($process) { $process.Dispose() }
    if (Test-Path -LiteralPath $privateDirectory) {
        Remove-Item -LiteralPath $privateDirectory -Force -Recurse -ErrorAction SilentlyContinue
    }
}
