[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RunId,
    [string]$TargetPath = 'C:\ept_core\Hardware.exe',
    [int]$DeadlineSeconds = 90,
    [int]$PollIntervalSeconds = 1,
    [string]$TaskName = ''
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$root = Join-Path 'C:\ept_obs\spool' $RunId
$eventsPath = Join-Path $root 'events.ndjson'
$heartbeatPath = Join-Path $root 'heartbeat.json'
$phasePath = Join-Path $root 'phase.json'
$prePath = Join-Path $root 'pre.json'
$postPath = Join-Path $root 'post.json'
$donePath = Join-Path $root 'done.json'
$stdoutPath = Join-Path $root 'target.stdout.txt'
$stderrPath = Join-Path $root 'target.stderr.txt'
$networkPath = Join-Path $root 'network.ndjson'
$seq = 0
$startedUtc = (Get-Date).ToUniversalTime()
$runnerProcessId = [int]$PID
$rootPid = $null
$lastProcessDetails = @{}
$errors = New-Object System.Collections.Generic.List[string]

New-Item -ItemType Directory -Force -Path $root | Out-Null

function Write-AtomicText {
    param([string]$Path, [string]$Text)
    $tmp = "$Path.tmp.$runnerProcessId"
    [System.IO.File]::WriteAllText($tmp, $Text, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Write-AtomicJson {
    param([string]$Path, $Object)
    Write-AtomicText $Path ($Object | ConvertTo-Json -Depth 14)
}

function Add-Event {
    param([string]$Type, [hashtable]$Fields = @{})
    $script:seq++
    $record = [ordered]@{ seq = $script:seq; utc = (Get-Date).ToUniversalTime().ToString('o'); type = $Type }
    foreach ($key in $Fields.Keys) { $record[$key] = $Fields[$key] }
    Add-Content -LiteralPath $eventsPath -Value ($record | ConvertTo-Json -Compress -Depth 10) -Encoding UTF8
}

function Set-Phase {
    param([string]$Name, [hashtable]$Fields = @{})
    $record = [ordered]@{ run_id = $RunId; phase = $Name; utc = (Get-Date).ToUniversalTime().ToString('o') }
    foreach ($key in $Fields.Keys) { $record[$key] = $Fields[$key] }
    Write-AtomicJson $phasePath $record
    Add-Event 'PHASE' @{ phase = $Name }
}

function Get-StartUtc {
    param($Process)
    try { return $Process.StartTime.ToUniversalTime().ToString('o') } catch { return $null }
}

function Get-ProcessDetails {
    param([switch]$IncludeCommandLine)
    $items = @()
    foreach ($p in @(Get-Process -ErrorAction SilentlyContinue)) {
        $path = $null
        try { $path = $p.Path } catch {}
        $item = [ordered]@{
            pid = [int]$p.Id
            name = [string]$p.ProcessName
            path = $path
            start_utc = Get-StartUtc $p
            ppid = $null
            command_line = $null
        }
        if ($IncludeCommandLine -or -not $lastProcessDetails.ContainsKey([int]$p.Id)) {
            try {
                $w = Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction SilentlyContinue
                if ($w) {
                    $item.ppid = [int]$w.ParentProcessId
                    if ($IncludeCommandLine -and $w.CommandLine) {
                        $item.command_line = ([string]$w.CommandLine -replace '(?i)(-k\s+)([^\s]+)', '$1[REDACTED]')
                    }
                }
            } catch {}
        } elseif ($lastProcessDetails.ContainsKey([int]$p.Id)) {
            $item.ppid = $lastProcessDetails[[int]$p.Id].ppid
        }
        $items += [pscustomobject]$item
    }
    return @($items)
}

function Get-FileRecord {
    param([string]$Path, [switch]$Hash)
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
        $i = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        $sha = $null
        if ($Hash -and $i.Length -le 67108864) { try { $sha = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash } catch {} }
        return [pscustomobject]@{
            path = $i.FullName
            length = [int64]$i.Length
            last_write_utc = $i.LastWriteTimeUtc.ToString('o')
            sha256 = $sha
            attributes = [string]$i.Attributes
        }
    } catch { return $null }
}

function Get-InterestingFiles {
    param([switch]$Hash)
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($p in @('C:\ept_core\Hardware.exe','C:\Windows\System32\Hardware.exe','C:\Windows\System32\Hardware','C:\Windows\System32\EPT_HWID.exe','C:\Windows\System32\EPTHWID.exe','C:\Windows\SysWOW64\SpooferSoftware.exe','C:\Windows\SysWOW64\EPTHWID.exe','C:\Windows\SysWOW64\JW.txt','C:\Windows\SysWOW64\EPTHWID.txt','C:\Windows\System32\EPT.cmd','C:\Windows\System32\ept.cmd','C:\Windows\System32\hwid.cmd','C:\Windows\System32\Hardware.ini')) {
        [void]$paths.Add($p)
    }
    foreach ($dir in @('<HOST_PATH>\Users\<USER>\AppData\Local\Temp','C:\Windows\Temp')) {
        try { foreach ($i in @(Get-ChildItem -LiteralPath $dir -Filter 'EPT_*.exe' -Force -ErrorAction SilentlyContinue)) { [void]$paths.Add($i.FullName) } } catch {}
    }
    try { foreach ($i in @(Get-ChildItem -LiteralPath 'C:\ept_core' -Force -ErrorAction SilentlyContinue)) { [void]$paths.Add($i.FullName) } } catch {}
    try {
        foreach ($i in @(Get-ChildItem -LiteralPath 'C:\Windows\System32' -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(Hardware|EPT|EPTHWID|Spoof|JW|.*\.cmd$|.*\.csv$)' })) { [void]$paths.Add($i.FullName) }
    } catch {}
    try {
        foreach ($i in @(Get-ChildItem -LiteralPath 'C:\Windows\System32\drivers' -Filter '*.sys' -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)(hp|ept|swtools|hardware)' })) { [void]$paths.Add($i.FullName) }
    } catch {}
    $records = @()
    foreach ($p in ($paths | Select-Object -Unique)) {
        $r = Get-FileRecord $p -Hash:$Hash
        if ($null -ne $r) { $records += $r }
    }
    return @($records | Sort-Object path)
}

function Get-RegistrySnapshot {
    $out = [ordered]@{}
    foreach ($key in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce')) {
        try {
            $p = Get-ItemProperty -LiteralPath $key -ErrorAction Stop
            $vals = [ordered]@{}
            foreach ($prop in $p.PSObject.Properties) { if ($prop.Name -notmatch '^PS') { $vals[$prop.Name] = [string]$prop.Value } }
            $out[$key] = $vals
        } catch { $out[$key] = $null }
    }
    return $out
}

function Get-ServiceSnapshot {
    try { return @(Get-CimInstance Win32_Service -ErrorAction Stop | Select-Object Name,DisplayName,State,StartMode,StartName,PathName) } catch { return @() }
}

function Get-TaskSnapshot {
    try { return @(Get-ScheduledTask -ErrorAction Stop | Select-Object TaskPath,TaskName,State) } catch { return @() }
}

function Get-NetworkSnapshot {
    try {
        return @(Get-NetTCPConnection -ErrorAction Stop | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess)
    } catch {
        try { return @(netstat.exe -ano 2>$null) } catch { return @() }
    }
}

function Get-State {
    param([switch]$HashFiles, [switch]$FullProcesses)
    $proc = Get-ProcessDetails -IncludeCommandLine:$FullProcesses
    $files = Get-InterestingFiles -Hash:$HashFiles
    return [ordered]@{
        run_id = $RunId
        utc = (Get-Date).ToUniversalTime().ToString('o')
        target_path = $TargetPath
        target_pid = $rootPid
        processes = $proc
        files = $files
        registry = Get-RegistrySnapshot
        services = Get-ServiceSnapshot
        scheduled_tasks = Get-TaskSnapshot
        network = Get-NetworkSnapshot
    }
}

function Add-NewProcessEvents {
    param([object[]]$Processes)
    foreach ($p in @($Processes)) {
        $processId = [int]$p.pid
        if (-not $lastProcessDetails.ContainsKey($processId)) {
            $lastProcessDetails[$processId] = $p
            Add-Event 'PROCESS_SEEN' @{ pid = $p.pid; ppid = $p.ppid; name = $p.name; path = $p.path; start_utc = $p.start_utc; command_line = $p.command_line }
        } else {
            $lastProcessDetails[$processId] = $p
        }
    }
}

function Stop-TargetTree {
    $candidate = @($lastProcessDetails.Values | Where-Object { $_.pid -ne $runnerProcessId })
    $ids = New-Object System.Collections.Generic.HashSet[int]
    if ($rootPid) { [void]$ids.Add([int]$rootPid) }
    $changed = $true
    while ($changed) {
        $changed = $false
        foreach ($p in $candidate) {
            if ($p.ppid -and $ids.Contains([int]$p.ppid) -and -not $ids.Contains([int]$p.pid)) { [void]$ids.Add([int]$p.pid); $changed = $true }
        }
    }
    foreach ($id in @($ids | Sort-Object -Descending)) {
        try { Stop-Process -Id $id -Force -ErrorAction SilentlyContinue; Add-Event 'PROCESS_STOP_REQUESTED' @{ pid = $id } } catch {}
    }
}

Set-Phase 'RUNNER_READY' @{ target_path = $TargetPath; deadline_seconds = $DeadlineSeconds; mode = 'NATURAL_NO_DEBUGGER' }
Add-Event 'RUNNER_READY' @{ target_path = $TargetPath; input_state = 'synthetic_invalid_card_no_secret' }

$pre = Get-State -HashFiles -FullProcesses
Write-AtomicJson $prePath $pre
Add-NewProcessEvents @($pre.processes)

$syntheticCard = 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
$argList = @('-k', $syntheticCard, '-n', '2', '-m', '1')
$targetStdout = $stdoutPath
$targetStderr = $stderrPath

try {
    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) { throw "target_missing:$TargetPath" }
    Set-Phase 'TARGET_STARTING' @{ target_path = $TargetPath; input_state = 'synthetic_invalid_card_no_secret'; card_value = 'NOT_STORED'; card_length = $syntheticCard.Length; args = @('-k','[REDACTED]','-n','2','-m','1') }
    $proc = Start-Process -FilePath $TargetPath -ArgumentList $argList -WorkingDirectory 'C:\ept_core' -RedirectStandardOutput $targetStdout -RedirectStandardError $targetStderr -PassThru -WindowStyle Hidden
    $rootPid = [int]$proc.Id
    Add-Event 'TARGET_STARTED' @{ pid = $rootPid; ppid = $runnerProcessId; input_state = 'synthetic_invalid_card_no_secret'; args = @('-k','[REDACTED]','-n','2','-m','1') }
    Set-Phase 'RUNNING' @{ target_pid = $rootPid }
} catch {
    $errors.Add($_.Exception.Message)
    Add-Event 'TARGET_START_FAILED' @{ error = $_.Exception.Message }
    Set-Phase 'TARGET_START_FAILED' @{ error = $_.Exception.Message }
}

$lastHeartbeat = Get-Date
$lastFilePoll = Get-Date
$deadline = (Get-Date).AddSeconds($DeadlineSeconds)
while ((Get-Date) -lt $deadline) {
    try {
        $current = Get-ProcessDetails
        Add-NewProcessEvents $current
        if ($rootPid) {
            $rootAlive = $false
            foreach ($p in $current) { if ([int]$p.pid -eq [int]$rootPid) { $rootAlive = $true; break } }
        } else { $rootAlive = $false }
        if (((Get-Date) - $lastFilePoll).TotalSeconds -ge 2) {
            $files = Get-InterestingFiles
            Add-Event 'FILE_SNAPSHOT' @{ count = @($files).Count; files = $files }
            $net = Get-NetworkSnapshot
            Add-Content -LiteralPath $networkPath -Value (($net | ConvertTo-Json -Compress -Depth 8)) -Encoding UTF8
            $lastFilePoll = Get-Date
        }
        if (((Get-Date) - $lastHeartbeat).TotalSeconds -ge 5) {
            $hb = [ordered]@{
                run_id = $RunId
                utc = (Get-Date).ToUniversalTime().ToString('o')
                phase = 'RUNNING'
                elapsed_seconds = [math]::Round(((Get-Date) - $startedUtc).TotalSeconds, 1)
                target_pid = $rootPid
                target_alive = $rootAlive
                process_count = @($current).Count
                observed_process_count = $lastProcessDetails.Count
                file_count = @(Get-InterestingFiles).Count
            }
            Write-AtomicJson $heartbeatPath $hb
            $lastHeartbeat = Get-Date
        }
    } catch { $errors.Add($_.Exception.Message) }
    Start-Sleep -Seconds $PollIntervalSeconds
}

Add-Event 'DEADLINE_REACHED' @{ deadline_seconds = $DeadlineSeconds }
Set-Phase 'CLEANUP' @{ target_pid = $rootPid }
Stop-TargetTree
Start-Sleep -Seconds 2

try {
    $post = Get-State -HashFiles -FullProcesses
    Write-AtomicJson $postPath $post
    $preFiles = @($pre.files)
    $postFiles = @($post.files)
    $preMap = @{}
    foreach ($f in $preFiles) { $preMap[[string]$f.path] = $f }
    $postMap = @{}
    foreach ($f in $postFiles) { $postMap[[string]$f.path] = $f }
    $fileChanges = @()
    foreach ($path in @($preMap.Keys + $postMap.Keys | Select-Object -Unique | Sort-Object)) {
        $before = $preMap[$path]
        $after = $postMap[$path]
        if ($null -eq $before -or $null -eq $after -or ($before.length -ne $after.length) -or ($before.sha256 -and $after.sha256 -and $before.sha256 -ne $after.sha256) -or ($before.last_write_utc -ne $after.last_write_utc)) {
            $fileChanges += [pscustomobject]@{ path = $path; before = $before; after = $after }
        }
    }
    Write-AtomicJson (Join-Path $root 'file_changes.json') $fileChanges
    $done = [ordered]@{
        run_id = $RunId
        status = 'NATURAL_BASELINE_COMPLETE'
        mode = 'real_sample_guest_run'
        evidence_scope = 'real_sample_guest_run'
        completed_utc = (Get-Date).ToUniversalTime().ToString('o')
        target_path = $TargetPath
        target_pid = $rootPid
        target_native_return = 'NOT_OBSERVED'
        target_caller_diff_bytes = 'NOT_OBSERVED'
        rc06_entry = 'NOT_OBSERVED'
        rc06_return = 'NOT_OBSERVED'
        post_decode_behavior = 'NOT_OBSERVED'
        input_state = 'synthetic_invalid_card_no_secret'
        deadline_seconds = $DeadlineSeconds
        errors = @($errors)
    }
    Write-AtomicJson $donePath $done
    Set-Phase 'DONE' @{ status = $done.status }
} catch {
    $errors.Add($_.Exception.Message)
    $done = [ordered]@{ run_id = $RunId; status = 'RUNNER_FINALIZE_FAILED'; completed_utc = (Get-Date).ToUniversalTime().ToString('o'); errors = @($errors) }
    Write-AtomicJson $donePath $done
    Set-Phase 'RUNNER_FINALIZE_FAILED' @{ error = $_.Exception.Message }
}

if ($TaskName) { try { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue } catch {} }
