[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunId,[string]$TaskName='')
$ErrorActionPreference='Continue'
$root='C:\ept_obs\spool\'+$RunId
$events=Join-Path $root 'events.ndjson'
$target='C:\ept_core\Hardware.exe'
$cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
$started=(Get-Date).ToUniversalTime();$seq=0
function E([string]$Type,[hashtable]$Fields=@{}){$script:seq++;$r=[ordered]@{seq=$script:seq;utc=(Get-Date).ToUniversalTime().ToString('o');type=$Type};foreach($k in $Fields.Keys){$r[$k]=$Fields[$k]};Add-Content -LiteralPath $events -Value ($r|ConvertTo-Json -Compress -Depth 8) -Encoding UTF8}
function LocalFiles {
  $out=@()
  foreach($p in @('C:\Windows\System32\Hardware\Hardware','C:\Windows\System32\Hardware.ini','C:\Windows\System32\EPT.cmd','C:\Windows\System32\ept.cmd','C:\Windows\System32\R3.exe','C:\Windows\System32\R32.dll')){try{if(Test-Path -LiteralPath $p -PathType Leaf){$i=Get-Item -LiteralPath $p;$out+=[pscustomobject]@{path=$p;length=$i.Length;last_write_utc=$i.LastWriteTimeUtc.ToString('o');sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()}}}catch{}}
  try{foreach($i in @(Get-ChildItem 'C:\Windows\Temp' -Filter 'EPT_*.exe' -Force -ErrorAction SilentlyContinue)){$out+=[pscustomobject]@{path=$i.FullName;length=$i.Length;last_write_utc=$i.LastWriteTimeUtc.ToString('o');sha256=(Get-FileHash -LiteralPath $i.FullName -Algorithm SHA256).Hash.ToUpperInvariant()}}}catch{}
  @($out)
}
E 'RUNNER_READY' @{target=$target;observer='gate_reversal_fatalexit_skip';code_patches=$false;authorization_state_writes=$false;response_injection=$false;network_scope='excluded';gate_reversal='fatal_exit_branch_skip_only'}
try {
  $source=Join-Path $root 'historical_SYS32_Hardware.bin';$dest='C:\Windows\System32\Hardware\Hardware'
  if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw 'historical_config_spool_missing'}
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest)|Out-Null
  Copy-Item -LiteralPath $source -Destination $dest -Force
  $h=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToUpperInvariant()
  E 'HISTORICAL_CONFIG_PLACED' @{path=$dest;sha256=$h;length=(Get-Item $dest).Length;source_scope='historical_forced_run_capture';natural_authorization_proven=$false}
}catch{E 'HISTORICAL_CONFIG_PLACE_FAILED' @{error=$_.Exception.Message}}
try{$cfg='C:\Windows\System32\Hardware\Hardware';$h=(Get-FileHash -LiteralPath $cfg -Algorithm SHA256).Hash.ToUpperInvariant();E 'HISTORICAL_CONFIG_PRESENT' @{path=$cfg;sha256=$h;length=(Get-Item $cfg).Length;source_scope='historical_forced_run_capture';natural_authorization_proven=$false}}catch{E 'HISTORICAL_CONFIG_MISSING' @{}}
$parent=Start-Process -FilePath $target -WorkingDirectory 'C:\ept_core' -PassThru -WindowStyle Hidden
E 'PARENT_STARTED_NOARGS' @{pid=[int]$parent.Id}
$attach=$null
try{$attach=Get-Process -Id $parent.Id -ErrorAction Stop;E 'ATTACH_PARENT_DIRECT' @{pid=[int]$parent.Id;mode='no_child_expected_config_present'}}catch{E 'NO_TARGET' @{}}
if($attach){
  $out=Join-Path $root 'cdb.stdout.txt';$err=Join-Path $root 'cdb.stderr.txt';$cmd=Join-Path $root 'gate_rev2.cdb'
$dbg=Start-Process -FilePath $cdb -ArgumentList @('-p',[string]$attach.Id,'-cf',$cmd) -WorkingDirectory $root -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
E 'CDB_ATTACHED' @{debugger_pid=[int]$dbg.Id;target_pid=[int]$attach.Id;mode='gate_reversal_fatalexit_skip'}
  $deadline=(Get-Date).AddSeconds(300)
  while((Get-Date)-lt$deadline -and -not $dbg.HasExited){try{foreach($f in @(LocalFiles)){E 'LOCAL_FILE_SNAPSHOT' @{file=$f}}}catch{};Start-Sleep -Seconds 2}
  if(-not $dbg.HasExited){E 'CDB_DEADLINE';try{$dbg.Kill()}catch{};try{$dbg.WaitForExit()}catch{}}
  E 'CDB_FINISHED' @{exit_code=$dbg.ExitCode}
}
try{foreach($f in @(LocalFiles)){E 'LOCAL_FILE_FINAL' @{file=$f}}}catch{}
try{if($parent -and -not $parent.HasExited){Stop-Process -Id $parent.Id -Force -ErrorAction SilentlyContinue;E 'PARENT_STOP_REQUESTED' @{pid=[int]$parent.Id}}}catch{}
E 'RUNNER_DONE' @{elapsed_seconds=[math]::Round(((Get-Date).ToUniversalTime()-$started).TotalSeconds,1);target_native_return='NOT_OBSERVED';target_caller_diff_bytes='NOT_OBSERVED';rc06_entry='NOT_OBSERVED';post_decode_behavior='NOT_OBSERVED';gate_reversal_applied='fatal_exit_branch_skip';natural_authorization_proven=$false}
if($TaskName){Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue}
