[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunId)
$ErrorActionPreference='Continue'
$root=Join-Path 'C:\ept_obs\spool' $RunId
New-Item -ItemType Directory -Force -Path $root|Out-Null
$events=Join-Path $root 'events.ndjson'
function Add-Event([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $events -Value ($x|ConvertTo-Json -Compress) -Encoding UTF8}
$hosts="$env:SystemRoot\System32\drivers\etc\hosts"
$line='127.0.0.1 yz.hwid001.com'
$txt=@(Get-Content -LiteralPath $hosts -ErrorAction SilentlyContinue)
if($txt -notcontains $line){Add-Content -LiteralPath $hosts -Value $line -Encoding ASCII}
& ipconfig.exe /flushdns | Out-Null
$ms=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'tcp1029.ps1'),'-RunId',$RunId) -WorkingDirectory $root -WindowStyle Hidden -PassThru
Add-Event @{type='MOCK_LISTENER_STARTED';pid=[int]$ms.Id}
Add-Event @{type='HOSTS_PINNED';line=$line}
$target='C:\ept_core\Hardware.exe'
$parent=Start-Process -FilePath $target -WorkingDirectory 'C:\ept_core' -PassThru -WindowStyle Hidden
Add-Event @{type='PARENT_STARTED_NOARGS';pid=[int]$parent.Id}
#
# BROAD child discovery: sample may drop child under %TEMP% (Windows\Temp or LocalAppData\Temp)
# depending on launching context. Match ANY EPT_*.exe process, record its path.
#
$child=$null
$deadline=(Get-Date).AddSeconds(90)
while((Get-Date) -lt $deadline -and -not $child){
  $cand=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^EPT_'}|Select-Object -First 3)
  foreach($c in $cand){
    Add-Event @{type='EPTCAND';pid=[int]$c.Id;name=$c.ProcessName;path=($c.Path -replace '\\','/')}
    if($c.Path -match 'EPT_[0-9A-F]+_[0-9A-F]+\.exe$'){ $child=$c; break }
  }
  if(-not $child){Start-Sleep -Milliseconds 400}
}
if($child){
  Add-Event @{type='CHILD_FOUND';pid=[int]$child.Id;ppid=[int]$parent.Id;path=($child.Path -replace '\\','/')}
  $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
  $cmd=Join-Path $root 'auth_stage_force.cdb'
  $out=Join-Path $root 'cdb.stdout.txt'
  $errf=Join-Path $root 'cdb.stderr.txt'
  $dbg=Start-Process -FilePath $cdb -ArgumentList @('-p',[string]$child.Id,'-cf',$cmd) -WorkingDirectory $root -RedirectStandardOutput $out -RedirectStandardError $errf -PassThru -WindowStyle Hidden
  Add-Event @{type='CDB_ATTACHED_CHILD';debugger_pid=[int]$dbg.Id;target_pid=[int]$child.Id}
  $helper=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'winproc.ps1'),'-TargetPid',[string]$child.Id,'-RunId',$RunId) -WorkingDirectory $root -WindowStyle Hidden -PassThru
  Add-Event @{type='WINPROC_HELPER_STARTED';pid=[int]$helper.Id}
  Start-Sleep -Seconds 2
  $watcher=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'watcher.ps1'),'-RunId',$RunId) -WorkingDirectory $root -WindowStyle Hidden -PassThru
  Add-Event @{type='WATCHER_STARTED';pid=[int]$watcher.Id}
} else {
  $still=@(Get-Process -Id $parent.Id -ErrorAction SilentlyContinue)
  if($still.Count -gt 0){
    Add-Event @{type='ATTACH_PARENT_NO_CHILD';pid=[int]$parent.Id}
  } else {
    Add-Event @{type='NO_TARGET'}
  }
}
Add-Event @{type='LAUNCH_SCRIPT_EXIT'}