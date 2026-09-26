[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunId,[int]$ChildWaitSeconds=20,[int]$DebuggerWaitSeconds=30)
$ErrorActionPreference='Continue'
$root=Join-Path 'C:\ept_obs\spool' $RunId
$cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
$target='C:\ept_core\Hardware.exe'
$cmd=Join-Path $root 'auth_gate_attach.cdb'
$out=Join-Path $root 'cdb.stdout.txt'
$err=Join-Path $root 'cdb.stderr.txt'
$events=Join-Path $root 'events.ndjson'
New-Item -ItemType Directory -Force -Path $root|Out-Null
function Add-Event([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $events -Value ($x|ConvertTo-Json -Compress) -Encoding UTF8}
$start=[DateTime]::UtcNow.ToString('o')
$parent=Start-Process -FilePath $target -ArgumentList @('-k','CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','-n','2','-m','1') -WorkingDirectory 'C:\ept_core' -PassThru -WindowStyle Hidden
Add-Event @{type='NATURAL_PARENT_STARTED';pid=[int]$parent.Id;command='Hardware.exe -k <format-test> -n 2 -m 1'}
$child=$null
$deadline=(Get-Date).AddSeconds($ChildWaitSeconds)
while((Get-Date) -lt $deadline -and -not $child){$child=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -like 'EPT_*' -and $_.Path -and $_.Path -like 'C:\Windows\Temp\EPT_*.exe'}|Select-Object -First 1);if(-not $child){Start-Sleep -Milliseconds 250}}
if($child){$child=$child[0];Add-Event @{type='NATURAL_CHILD_FOUND';pid=[int]$child.Id;ppid=[int]$parent.Id;path=$child.Path};$p=Start-Process -FilePath $cdb -ArgumentList @('-p',[string]$child.Id,'-cf',$cmd) -WorkingDirectory $root -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden;$debugEnded=$p.WaitForExit($DebuggerWaitSeconds*1000);if(-not $debugEnded){try{$p.Kill()}catch{};try{$p.WaitForExit()}catch{}};Add-Event @{type='CDB_ATTACH_FINISHED';pid=[int]$child.Id;debugger_pid=[int]$p.Id;debugger_wait_expired=(-not $debugEnded)}}else{Add-Event @{type='NATURAL_CHILD_NOT_FOUND';wait_seconds=$ChildWaitSeconds};$debugEnded=$false}
$childAlive=$false;if($child){$childAlive=[bool](Get-Process -Id $child.Id -ErrorAction SilentlyContinue)}
$parentAlive=[bool](Get-Process -Id $parent.Id -ErrorAction SilentlyContinue)
$stdout='';if(Test-Path -LiteralPath $out){$stdout=Get-Content -LiteralPath $out -Raw}
$patched=($stdout -match 'AUTH_GATE_AND_MAIN_BRANCH_PATCHED')
$summary=[ordered]@{run_id=$RunId;evidence_scope='real_sample_guest_run_predecode_auth_gate_attach';sample_launch_requested=$true;network_request_sent=$false;real_card_present=$false;response_injection=$false;target_path=$target;launch_mode='natural_parent_then_cdb_attach_to_natural_child';command_line='Hardware.exe -k <format-test> -n 2 -m 1';started_utc=$start;ended_utc=[DateTime]::UtcNow.ToString('o');child_found=[bool]$child;child_pid=if($child){[int]$child.Id}else{$null};parent_pid=[int]$parent.Id;debugger_attached=[bool]$child;debugger_wait_expired=if($child){(-not $debugEnded)}else{$false};temporary_patch_points_executed=if($patched){@('FUN_1407a3080 runtime return -> 1','main authorization-controlled branch at 0x1407a6a6a -> fall-through')}else{@()};target_process_alive_after_attach=$childAlive;parent_alive_after_attach=$parentAlive;target_native_return='NOT_OBSERVED';target_caller_diff_bytes='NOT_OBSERVED';post_decode_behavior='NOT_OBSERVED';observation_state=if($patched){'NATURAL_CHILD_ATTACHED_PATCHED_POINTS_ARMED'}elseif($child){'NATURAL_CHILD_FOUND_ATTACH_UNCONFIRMED'}else{'NATURAL_CHILD_NOT_FOUND'}}
$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $root 'summary.json') -Encoding UTF8
[IO.File]::WriteAllText((Join-Path $root 'done.json'),($summary|ConvertTo-Json -Depth 8),[Text.Encoding]::UTF8)
try{Get-Process -Id $child.Id -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue}catch{};try{Get-Process -Id $parent.Id -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue}catch{}
