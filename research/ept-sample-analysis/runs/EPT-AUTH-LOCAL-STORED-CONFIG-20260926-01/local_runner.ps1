[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RunId,
    [string]$TargetPath='C:\ept_core\Hardware.exe',
    [int]$DeadlineSeconds=180,
    [int]$PollIntervalSeconds=1,
    [string]$TaskName='',
    [string]$HistoricalConfigPath='C:\Windows\System32\Hardware\Hardware'
)

$ErrorActionPreference='Continue'
$ProgressPreference='SilentlyContinue'
$root=Join-Path 'C:\ept_obs\spool' $RunId
$eventsPath=Join-Path $root 'events.ndjson'
$phasePath=Join-Path $root 'phase.json'
$prePath=Join-Path $root 'pre.json'
$postPath=Join-Path $root 'post.json'
$donePath=Join-Path $root 'done.json'
$stdoutPath=Join-Path $root 'target.stdout.txt'
$stderrPath=Join-Path $root 'target.stderr.txt'
$runnerProcessId=[int]$PID
$rootPid=$null
$seq=0
$startedUtc=(Get-Date).ToUniversalTime()
$lastProcessDetails=@{}
$errors=New-Object System.Collections.Generic.List[string]

New-Item -ItemType Directory -Force -Path $root | Out-Null

function Write-AtomicText([string]$Path,[string]$Text) {
    $tmp="$Path.tmp.$runnerProcessId"
    [IO.File]::WriteAllText($tmp,$Text,[Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function Write-AtomicJson([string]$Path,$Object) {
    Write-AtomicText $Path ($Object|ConvertTo-Json -Depth 16)
}
function Add-Event([string]$Type,[hashtable]$Fields=@{}) {
    $script:seq++
    $r=[ordered]@{seq=$script:seq;utc=(Get-Date).ToUniversalTime().ToString('o');type=$Type}
    foreach($k in $Fields.Keys){$r[$k]=$Fields[$k]}
    Add-Content -LiteralPath $eventsPath -Value ($r|ConvertTo-Json -Compress -Depth 12) -Encoding UTF8
}
function Set-Phase([string]$Name,[hashtable]$Fields=@{}) {
    $r=[ordered]@{run_id=$RunId;phase=$Name;utc=(Get-Date).ToUniversalTime().ToString('o')}
    foreach($k in $Fields.Keys){$r[$k]=$Fields[$k]}
    Write-AtomicJson $phasePath $r
    Add-Event 'PHASE' @{phase=$Name}
}
try {
    $source=Join-Path $root 'historical_SYS32_Hardware.bin'
    if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw "historical_config_missing:$source"}
    $parent=Split-Path -Parent $HistoricalConfigPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    Copy-Item -LiteralPath $source -Destination $HistoricalConfigPath -Force
    $h=(Get-FileHash -LiteralPath $HistoricalConfigPath -Algorithm SHA256).Hash.ToUpperInvariant()
    Add-Event 'HISTORICAL_CONFIG_PLACED' @{path=$HistoricalConfigPath;sha256=$h;source_scope='historical_forced_run_capture';natural_authorization_proven=$false}
} catch { $errors.Add($_.Exception.Message); Add-Event 'HISTORICAL_CONFIG_PLACE_FAILED' @{error=$_.Exception.Message} }
function Get-StartUtc($Process) { try{return $Process.StartTime.ToUniversalTime().ToString('o')}catch{return $null} }
function Get-ProcessDetails([switch]$IncludeCommandLine) {
    $items=@()
    foreach($p in @(Get-Process -ErrorAction SilentlyContinue)) {
        $path=$null;try{$path=$p.Path}catch{}
        $item=[ordered]@{pid=[int]$p.Id;name=[string]$p.ProcessName;path=$path;start_utc=(Get-StartUtc $p);ppid=$null;command_line=$null}
        if($IncludeCommandLine -or -not $lastProcessDetails.ContainsKey([int]$p.Id)) {
            try {
                $w=Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction SilentlyContinue
                if($w){$item.ppid=[int]$w.ParentProcessId;if($IncludeCommandLine -and $w.CommandLine){$item.command_line=[string]$w.CommandLine}}
            }catch{}
        } elseif($lastProcessDetails.ContainsKey([int]$p.Id)) {$item.ppid=$lastProcessDetails[[int]$p.Id].ppid}
        $items+=[pscustomobject]$item
    }
    @($items)
}
function Get-FileRecord([string]$Path,[switch]$Hash) {
    try {
        if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return $null}
        $i=Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        $sha=$null;if($Hash -and $i.Length -le 67108864){try{$sha=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}catch{}}
        [pscustomobject]@{path=$i.FullName;length=[int64]$i.Length;last_write_utc=$i.LastWriteTimeUtc.ToString('o');sha256=$sha;attributes=[string]$i.Attributes}
    }catch{$null}
}
function Get-InterestingFiles([switch]$Hash) {
    $paths=New-Object System.Collections.Generic.List[string]
    foreach($p in @(
        'C:\ept_core\Hardware.exe','C:\Windows\System32\Hardware.exe','C:\Windows\System32\Hardware',
        'C:\Windows\System32\Hardware\Hardware','C:\Windows\System32\Hardware.ini','C:\Windows\System32\EPT.cmd',
        'C:\Windows\System32\ept.cmd','C:\Windows\System32\hwid.cmd','C:\Windows\System32\R3.exe',
        'C:\Windows\System32\R32.dll','C:\Windows\Temp\HardwareTask.xml','C:\Windows\System32\EPT_runtime_hash.csv')){[void]$paths.Add($p)}
    foreach($dir in @('C:\Windows\Temp','<HOST_PATH>\Users\<USER>\AppData\Local\Temp')){try{foreach($i in @(Get-ChildItem -LiteralPath $dir -Filter 'EPT_*.exe' -Force -ErrorAction SilentlyContinue)){[void]$paths.Add($i.FullName)}}catch{}}
    foreach($dir in @('C:\Windows\System32\Logs','C:\Windows\System32\HardwareLogs')){try{if(Test-Path -LiteralPath $dir){foreach($i in @(Get-ChildItem -LiteralPath $dir -File -Force -ErrorAction SilentlyContinue)){[void]$paths.Add($i.FullName)}}}catch{}}
    try{foreach($i in @(Get-ChildItem -LiteralPath 'C:\Windows\System32\drivers' -Filter '*.sys' -Force -ErrorAction SilentlyContinue|Where-Object{$_.Name -match '(?i)(hp|ept|swtools|hardware)'})){[void]$paths.Add($i.FullName)}}catch{}
    $records=@();foreach($p in ($paths|Select-Object -Unique)){$r=Get-FileRecord $p -Hash:$Hash;if($null-ne$r){$records+=$r}}
    @($records|Sort-Object path)
}
function Get-RegistrySnapshot {
    $out=[ordered]@{}
    foreach($key in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce')){
        try{$p=Get-ItemProperty -LiteralPath $key -ErrorAction Stop;$vals=[ordered]@{};foreach($prop in $p.PSObject.Properties){if($prop.Name -notmatch '^PS'){$vals[$prop.Name]=[string]$prop.Value}};$out[$key]=$vals}catch{$out[$key]=$null}
    }
    $out
}
function Get-ServiceSnapshot {try{@(Get-CimInstance Win32_Service -ErrorAction Stop|Where-Object{$_.Name -match '(?i)(hp|swtools|hardware|ept)' -or $_.DisplayName -match '(?i)(hp|swtools|hardware|ept)'}|Select-Object Name,DisplayName,State,StartMode,StartName,PathName)}catch{@()}}
function Get-TaskSnapshot {try{@(Get-ScheduledTask -ErrorAction Stop|Where-Object{$_.TaskName -match '(?i)(hardware|ept|detect|remediate)'-or $_.TaskPath -match '(?i)(hardware|ept)'}|Select-Object TaskPath,TaskName,State)}catch{@()}}
function Get-State([switch]$HashFiles,[switch]$FullProcesses) {
    [ordered]@{run_id=$RunId;utc=(Get-Date).ToUniversalTime().ToString('o');target_path=$TargetPath;target_pid=$rootPid;processes=(Get-ProcessDetails -IncludeCommandLine:$FullProcesses);files=(Get-InterestingFiles -Hash:$HashFiles);registry=Get-RegistrySnapshot;services=Get-ServiceSnapshot;scheduled_tasks=Get-TaskSnapshot}
}
function Add-NewProcessEvents([object[]]$Processes) {
    foreach($p in @($Processes)){$id=[int]$p.pid;if(-not $lastProcessDetails.ContainsKey($id)){$lastProcessDetails[$id]=$p;Add-Event 'PROCESS_SEEN' @{pid=$p.pid;ppid=$p.ppid;name=$p.name;path=$p.path;start_utc=$p.start_utc;command_line=$p.command_line}}else{$lastProcessDetails[$id]=$p}}
}
function Stop-TargetTree {
    $candidate=@($lastProcessDetails.Values|Where-Object{$_.pid-ne$runnerProcessId})
    $ids=New-Object 'System.Collections.Generic.HashSet[int]';if($rootPid){[void]$ids.Add([int]$rootPid)}
    $changed=$true;while($changed){$changed=$false;foreach($p in $candidate){if($p.ppid -and $ids.Contains([int]$p.ppid)-and -not $ids.Contains([int]$p.pid)){[void]$ids.Add([int]$p.pid);$changed=$true}}}
    foreach($id in @($ids|Sort-Object -Descending)){try{Stop-Process -Id $id -Force -ErrorAction SilentlyContinue;Add-Event 'PROCESS_STOP_REQUESTED' @{pid=$id}}catch{}}
}

Set-Phase 'RUNNER_READY' @{target_path=$TargetPath;deadline_seconds=$DeadlineSeconds;mode='NATURAL_NO_DEBUGGER_NO_NETWORK_OBSERVER';input_state='HISTORICAL_STORED_CONFIG_CONSUMER';historical_config=$HistoricalConfigPath}
Add-Event 'RUNNER_READY' @{target_path=$TargetPath;input_state='HISTORICAL_STORED_CONFIG_CONSUMER';historical_config=$HistoricalConfigPath;network_observer='DISABLED';debugger='NONE';memory_writes='NONE'}
$pre=Get-State -HashFiles -FullProcesses
Write-AtomicJson $prePath $pre
Add-NewProcessEvents @($pre.processes)
try {
    if(-not(Test-Path -LiteralPath $TargetPath -PathType Leaf)){throw "target_missing:$TargetPath"}
    Set-Phase 'TARGET_STARTING' @{target_path=$TargetPath;input_state='NO_ARGUMENTS';args=@()}
    $proc=Start-Process -FilePath $TargetPath -WorkingDirectory 'C:\ept_core' -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -WindowStyle Hidden
    $rootPid=[int]$proc.Id
    Add-Event 'TARGET_STARTED' @{pid=$rootPid;ppid=$runnerProcessId;input_state='NO_ARGUMENTS';args=@()}
    Set-Phase 'RUNNING' @{target_pid=$rootPid}
}catch{$errors.Add($_.Exception.Message);Add-Event 'TARGET_START_FAILED' @{error=$_.Exception.Message};Set-Phase 'TARGET_START_FAILED' @{error=$_.Exception.Message}}
$lastHeartbeat=Get-Date;$lastFilePoll=Get-Date;$deadline=(Get-Date).AddSeconds($DeadlineSeconds)
while((Get-Date)-lt$deadline){
    try {
        $current=Get-ProcessDetails;Add-NewProcessEvents $current
        $alive=$false;if($rootPid){foreach($p in $current){if([int]$p.pid -eq $rootPid){$alive=$true;break}}}
        if(((Get-Date)-$lastFilePoll).TotalSeconds -ge 2){$files=Get-InterestingFiles;Add-Event 'LOCAL_FILE_SNAPSHOT' @{count=@($files).Count;files=$files};$lastFilePoll=Get-Date}
        if(((Get-Date)-$lastHeartbeat).TotalSeconds -ge 5){Write-AtomicJson (Join-Path $root 'heartbeat.json') ([ordered]@{run_id=$RunId;utc=(Get-Date).ToUniversalTime().ToString('o');phase='RUNNING';elapsed_seconds=[math]::Round(((Get-Date)-$startedUtc).TotalSeconds,1);target_pid=$rootPid;target_alive=$alive;process_count=@($current).Count;observed_process_count=$lastProcessDetails.Count;file_count=@(Get-InterestingFiles).Count});$lastHeartbeat=Get-Date}
    }catch{$errors.Add($_.Exception.Message)}
    Start-Sleep -Seconds $PollIntervalSeconds
}
Add-Event 'DEADLINE_REACHED' @{deadline_seconds=$DeadlineSeconds}
Set-Phase 'CLEANUP' @{target_pid=$rootPid}
Stop-TargetTree
Start-Sleep -Seconds 2
try {
    $post=Get-State -HashFiles -FullProcesses;Write-AtomicJson $postPath $post
    $preMap=@{};foreach($f in @($pre.files)){$preMap[[string]$f.path]=$f};$postMap=@{};foreach($f in @($post.files)){$postMap[[string]$f.path]=$f}
    $changes=@();foreach($path in @($preMap.Keys+$postMap.Keys|Select-Object -Unique|Sort-Object)){$before=$preMap[$path];$after=$postMap[$path];if($null-eq$before-or$null-eq$after-or$before.length-ne$after.length-or($before.sha256-and$after.sha256-and$before.sha256-ne$after.sha256)-or$before.last_write_utc-ne$after.last_write_utc){$changes+=[pscustomobject]@{path=$path;before=$before;after=$after}}}
    Write-AtomicJson (Join-Path $root 'file_changes.json') $changes
    $done=[ordered]@{run_id=$RunId;status='NATURAL_STORED_CONFIG_CONSUMER_COMPLETE';mode='real_sample_guest_run';evidence_scope='real_sample_guest_run';completed_utc=(Get-Date).ToUniversalTime().ToString('o');target_path=$TargetPath;target_pid=$rootPid;target_native_return='NOT_OBSERVED';target_caller_diff_bytes='NOT_OBSERVED';rc06_entry='NOT_OBSERVED';rc06_return='NOT_OBSERVED';post_decode_behavior='NOT_OBSERVED';authorization_state='NOT_PROVEN_HISTORICAL_CONFIG';input_state='HISTORICAL_STORED_CONFIG_CONSUMER';historical_config=$HistoricalConfigPath;network_observer='DISABLED';debugger='NONE';memory_writes='NONE';deadline_seconds=$DeadlineSeconds;errors=@($errors)}
    Write-AtomicJson $donePath $done;Set-Phase 'DONE' @{status=$done.status}
}catch{$errors.Add($_.Exception.Message);$done=[ordered]@{run_id=$RunId;status='RUNNER_FINALIZE_FAILED';completed_utc=(Get-Date).ToUniversalTime().ToString('o');errors=@($errors)};Write-AtomicJson $donePath $done;Set-Phase 'RUNNER_FINALIZE_FAILED' @{error=$_.Exception.Message}}
if($TaskName){try{Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue}catch{}}
