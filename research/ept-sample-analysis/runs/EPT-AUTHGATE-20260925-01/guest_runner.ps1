[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunId,[int]$DeadlineSeconds=45)
$ErrorActionPreference='Continue'
$root=Join-Path 'C:\ept_obs\spool' $RunId
$cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
$target='C:\ept_core\Hardware.exe'
$cmd=Join-Path $root 'auth_gate.cdb'
$out=Join-Path $root 'cdb.stdout.txt'
$err=Join-Path $root 'cdb.stderr.txt'
New-Item -ItemType Directory -Force -Path $root | Out-Null
$pre=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match '^(Hardware|EPT.*|cdb|windbg)$'} | Select-Object Id,ProcessName)
$start=[DateTime]::UtcNow.ToString('o')
$p=Start-Process -FilePath $cdb -ArgumentList @('-o','-cf',$cmd,$target,'-n','0','-m','1') -WorkingDirectory $root -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
$ended=$p.WaitForExit($DeadlineSeconds*1000)
if(-not $ended){try{$p.Kill()}catch{};try{$p.WaitForExit()}catch{}}
$post=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match '^(Hardware|EPT.*|cdb|windbg)$'} | Select-Object Id,ProcessName)
$summary=[ordered]@{run_id=$RunId;evidence_scope='real_sample_guest_run_predecode_auth_gate_bypass';sample_launch_requested=$true;network_request_sent=$false;real_card_present=$false;response_injection=$false;target_path=$target;started_utc=$start;ended_utc=[DateTime]::UtcNow.ToString('o');deadline_seconds=$DeadlineSeconds;deadline_reached=(-not $ended);cdb_exit_code=if($ended){$p.ExitCode}else{'TIMEOUT_KILLED'};pre_relevant_processes=$pre;post_relevant_processes=$post;patched_points=@('FUN_1407a3080 runtime return -> 1','main authorization-controlled branch at 0x1407a6a6a -> fall-through');target_native_return='NOT_OBSERVED';target_caller_diff_bytes='NOT_OBSERVED';post_decode_behavior='NOT_OBSERVED'}
$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $root 'summary.json') -Encoding UTF8
[IO.File]::WriteAllText((Join-Path $root 'done.json'),($summary|ConvertTo-Json -Depth 8),[Text.Encoding]::UTF8)
