[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunId,[int]$ChildWaitSeconds=25,[int]$RunSeconds=180)
$ErrorActionPreference='Continue'
$root=Join-Path 'C:\ept_obs\spool' $RunId
$cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
$target='C:\ept_core\Hardware.exe'
$cmd=Join-Path $root 'auth_data_patch.cdb'
$out=Join-Path $root 'cdb.stdout.txt'
$err=Join-Path $root 'cdb.stderr.txt'
$events=Join-Path $root 'events.ndjson'
New-Item -ItemType Directory -Force -Path $root|Out-Null
function Add-Event([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $events -Value ($x|ConvertTo-Json -Compress) -Encoding UTF8}
function Snap([string]$tag){
  $tasks=@(); try{$tasks=@(Get-ScheduledTask -ErrorAction SilentlyContinue|Where-Object {$_.TaskName -like '*Hardware*'}|Select-Object -ExpandProperty TaskName)}catch{}
  $dirs=@(); foreach($x in @('C:\Windows\System32\Logs','C:\Windows\System32\HardwareLogs')){if(Test-Path -LiteralPath $x){$dirs+=$x}}
  $files=@(); foreach($x in @('C:\Windows\System32\Hardware.exe','C:\Windows\System32\Hardware','C:\Windows\System32\hwid.cmd','C:\Windows\System32\Hardware.ini','C:\Windows\Temp\HardwareTask.xml','C:\Windows\System32\R3.exe','C:\Windows\System32\R32.dll','C:\Windows\System32\EPT.cmd')){if(Test-Path -LiteralPath $x){$files+=$x}}
  $procs=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|R3|cdb|windbg)'}|ForEach-Object {[pscustomobject]@{Id=$_.Id;Name=$_.ProcessName}})
  $drv=@(); try{$drv=@(Get-ChildItem -LiteralPath 'C:\Windows\System32\drivers' -ErrorAction SilentlyContinue|Where-Object {$_.Name -match '^(HP_|SWTOOLS|HpSvc)'}|Select-Object -ExpandProperty Name)}catch{}
  [pscustomobject]@{tag=$tag;utc=[DateTime]::UtcNow.ToString('o');tasks=$tasks;log_dirs=$dirs;files=$files;processes=$procs;drivers=$drv}
}
$snaps=@()
$snaps+=Snap 'pre'
Add-Event @{type='PRE_SNAPSHOT';tasks=$snaps[0].tasks;files=$snaps[0].files;dirs=$snaps[0].log_dirs}
$parent=Start-Process -FilePath $target -ArgumentList @('-k','CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','-n','2','-m','1') -WorkingDirectory 'C:\ept_core' -PassThru -WindowStyle Hidden
Add-Event @{type='NATURAL_PARENT_STARTED';pid=[int]$parent.Id;cmd='Hardware.exe -k <format-test> -n 2 -m 1'}
$child=$null
$deadline=(Get-Date).AddSeconds($ChildWaitSeconds)
while((Get-Date) -lt $deadline -and -not $child){$c=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -like 'EPT_*' -and $_.Path -and $_.Path -like 'C:\Windows\Temp\EPT_*.exe'}|Select-Object -First 1);if($c){$child=$c[0]}else{Start-Sleep -Milliseconds 200}}
$dbg=$null
if($child){
  Add-Event @{type='NATURAL_CHILD_FOUND';pid=[int]$child.Id;ppid=[int]$parent.Id;path=$child.Path}
  $dbg=Start-Process -FilePath $cdb -ArgumentList @('-p',[string]$child.Id,'-cf',$cmd) -WorkingDirectory $root -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
  Add-Event @{type='CDB_ATTACHED';debugger_pid=[int]$dbg.Id;target_pid=[int]$child.Id}
  Start-Sleep -Seconds $RunSeconds
  $snaps+=Snap 'during'
  Add-Event @{type='DURING_SNAPSHOT';tasks=$snaps[1].tasks;files=$snaps[1].files;dirs=$snaps[1].log_dirs}
  try{if(-not $dbg.HasExited){$dbg.Kill();$dbg.WaitForExit(5000)}}catch{}
  Add-Event @{type='CDB_STOPPED';debugger_exit=$true}
} else {
  Add-Event @{type='NATURAL_CHILD_NOT_FOUND';wait=$ChildWaitSeconds}
  $snaps+=Snap 'during'
}
if($child){try{Get-Process -Id $child.Id -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue}catch{}}
Start-Sleep -Seconds 3
$snaps+=Snap 'post'
Add-Event @{type='POST_SNAPSHOT';tasks=$snaps[-1].tasks;files=$snaps[-1].files;dirs=$snaps[-1].log_dirs}
try{Get-Process -Id $parent.Id -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue}catch{}
$stdout=''; if(Test-Path -LiteralPath $out){$stdout=Get-Content -LiteralPath $out -Raw}
$summary=[ordered]@{
 run_id=$RunId
 evidence_scope='real_sample_guest_run_auth_state_data_release'
 sample_launch_requested=$true
 real_card_present=$false
 response_injection=$false
 network_request_sent=$false
 target_path=$target
 launch_mode='natural_parent_then_cdb_attach_data_only_release'
 command_line='Hardware.exe -k <format-test> -n 2 -m 1'
 child_found=[bool]$child
 child_pid=if($child){[int]$child.Id}else{$null}
 parent_pid=[int]$parent.Id
 debugger_attached=[bool]$child
 run_seconds=$RunSeconds
 data_patch_applied=($stdout -match 'AUTH_DATA_PATCH_DONE')
 code_patch_applied=$false
 breakpoints_set=0
 pre=$snaps[0]
 during=$snaps[1]
 post=$snaps[-1]
}
$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $root 'summary.json') -Encoding UTF8
[IO.File]::WriteAllText((Join-Path $root 'done.json'),($summary|ConvertTo-Json -Depth 8),[Text.Encoding]::UTF8)
