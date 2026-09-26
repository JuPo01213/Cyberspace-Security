[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunId)
$ErrorActionPreference='Continue'
$root=Join-Path 'C:\ept_obs\spool' $RunId
New-Item -ItemType Directory -Force -Path $root|Out-Null
$events=Join-Path $root 'events.ndjson'
function Add-Event([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $events -Value ($x|ConvertTo-Json -Compress) -Encoding UTF8}
# NO hosts pinning, NO mock listener, NO winproc, NO watcher pre-start.
# Recipe proven by observe_replica: parent + observer cdb only -> child spawns under <VM_USER> session.
$cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
$target='C:\ept_core\Hardware.exe'
$parent=Start-Process -FilePath $target -WorkingDirectory 'C:\ept_core' -PassThru -WindowStyle Hidden
Add-Event @{type='PARENT_STARTED_NOARGS';pid=[int]$parent.Id}
Start-Sleep -Seconds 2
$obsScript=Join-Path $root 'parent_obs.cdb'
$obsOut=Join-Path $root 'parent_obs.stdout.txt'
$obsErr=Join-Path $root 'parent_obs.stderr.txt'
Set-Content -LiteralPath $obsScript -Value @(
  '.echo PARENT_OBS_ARMED'
  'bu kernelbase!CreateProcessW ".echo CPW; du @rdx; g"'
  'bu kernelbase!CreateProcessA ".echo CPA; da @rdx; g"'
  'bu kernelbase!CreateProcessInternalW ".echo CPIW; du @rdx; g"'
  'g'
) -Encoding ASCII
$obsP=Start-Process -FilePath $cdb -ArgumentList @('-p',[string]$parent.Id,'-cf',$obsScript,'-y','srv*') -WorkingDirectory $root -RedirectStandardOutput $obsOut -RedirectStandardError $obsErr -PassThru -WindowStyle Hidden
Add-Event @{type='PARENT_OBS_ATTACHED';debugger_pid=[int]$obsP.Id}
$child=$null
$deadline=(Get-Date).AddSeconds(110)
while((Get-Date) -lt $deadline -and -not $child){
  $cand=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^EPT_'}|Select-Object -First 2)
  foreach($c in $cand){
    try { $pth=$c.Path } catch { $pth='<noaccess>' }
    Add-Event @{type='EPTCAND';pid=[int]$c.Id;name=$c.ProcessName;path=($pth -replace '\\','/')}
    if($pth -match 'EPT_[0-9A-F]+_[0-9A-F]+\.exe$'){ $child=$c; break }
  }
  if(-not $child){Start-Sleep -Milliseconds 400}
}
if($child){
  Add-Event @{type='CHILD_FOUND';pid=[int]$child.Id;ppid=[int]$parent.Id;path=($child.Path -replace '\\','/')}
  Get-Process -Id $obsP.Id -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  $cmd=Join-Path $root 'auth_stage_force.cdb'
  $out=Join-Path $root 'cdb.stdout.txt'
  $errf=Join-Path $root 'cdb.stderr.txt'
  $dbg=Start-Process -FilePath $cdb -ArgumentList @('-p',[string]$child.Id,'-cf',$cmd) -WorkingDirectory $root -RedirectStandardOutput $out -RedirectStandardError $errf -PassThru -WindowStyle Hidden
  Add-Event @{type='CDB_ATTACHED_CHILD';debugger_pid=[int]$dbg.Id;target_pid=[int]$child.Id}
  # after forcing chain armed, start capture support
  $ms=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'tcp1029.ps1'),'-RunId',$RunId) -WorkingDirectory $root -WindowStyle Hidden -PassThru
  Add-Event @{type='MOCK_LISTENER_STARTED';pid=[int]$ms.Id}
  $watcher=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'watcher.ps1'),'-RunId',$RunId) -WorkingDirectory $root -WindowStyle Hidden -PassThru
  Add-Event @{type='WATCHER_STARTED';pid=[int]$watcher.Id}
} else {
  Add-Event @{type='ATTACH_PARENT_NO_CHILD';parent_alive=([bool](Get-Process -Id $parent.Id -ErrorAction SilentlyContinue))}
  Get-Process -Id $obsP.Id -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Add-Event @{type='LAUNCH_SCRIPT_EXIT'}