[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunId)
$ErrorActionPreference='Continue'
$root=Join-Path 'C:\ept_obs\spool' $RunId
New-Item -ItemType Directory -Force -Path $root|Out-Null
$events=Join-Path $root 'events.ndjson'
function Add-Event([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $events -Value ($x|ConvertTo-Json -Compress) -Encoding UTF8}
$hosts=Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$line='127.0.0.1 yz.hwid001.com'
$txt=@(Get-Content -LiteralPath $hosts -ErrorAction SilentlyContinue)
if($txt -notcontains $line){Add-Content -LiteralPath $hosts -Value $line -Encoding ASCII}
& ipconfig.exe /flushdns | Out-Null
Add-Event @{type='HOSTS_PINNED';line=$line}
# driver preload: the sample's device session (comm_init -> g340) needs \Device\HP_WKS_SWTOOLS_DRIVER online
Copy-Item (Join-Path $root 'HpDrvPre.sys') (Join-Path $env:SystemRoot 'Temp\HpDrvPre.sys') -Force
$c = & sc.exe create HpDrvPre type= kernel start= demand binPath= "\??\C:\Windows\Temp\HpDrvPre.sys" 2>&1
$st = & sc.exe start HpDrvPre 2>&1
$qd = & sc.exe query HpDrvPre 2>&1 | Select-String 'STATE'
Add-Event @{type='DRIVER_PRELOADED';create=($c -join ' ');start=($st -join ' ');state=($qd -join ' ')}
$ms=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'tcp1029.ps1'),'-RunId',$RunId,'-Respond','0') -WorkingDirectory $root -WindowStyle Hidden -PassThru
Add-Event @{type='MOCK_LISTENER_STARTED';pid=[int]$ms.Id}
$cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
$symLocal=Join-Path (Split-Path -Parent $cdb) 'sym'
$target='C:\ept_core\Hardware.exe'
$cmd=Join-Path $root 'auth_stage_force.cdb'
$out=Join-Path $root 'cdb.stdout.txt'
$err=Join-Path $root 'cdb.stderr.txt'
# NATURAL invocation: the sample's own Python wrapper calls
#   Hardware.exe -k <cardKey> -n <codeType static=0/dynamic=2> -m <mode1..3>
$cardKey='1234567890'
$parent=Start-Process -FilePath $target -ArgumentList @('-k',$cardKey,'-n','2','-m','1') -WorkingDirectory 'C:\ept_core' -PassThru -WindowStyle Hidden
Add-Event @{type='PARENT_STARTED_NATURAL_ARGS';pid=[int]$parent.Id;argv=('-k '+$cardKey+' -n 2 -m 1')}
$child=$null
$deadline=(Get-Date).AddSeconds(25)
while((Get-Date) -lt $deadline -and -not $child){$c=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -like 'EPT_*'}|Select-Object -First 1);if($c){$child=$c[0]}else{Start-Sleep -Milliseconds 200}}
$attach=$null
if($child){
  $attach=$child
  Add-Event @{type='CHILD_FOUND';pid=[int]$child.Id;ppid=[int]$parent.Id;path=$child.Path}
} else {
  $still=@(Get-Process -Id $parent.Id -ErrorAction SilentlyContinue)
  if($still.Count -gt 0){ $attach=$still[0]; Add-Event @{type='ATTACH_PARENT_NO_CHILD';pid=[int]$parent.Id} }
  else { Add-Event @{type='NO_TARGET'} }
}
if($attach){
 $env:_NT_SYMBOL_PATH=$symLocal
 $dbg=Start-Process -FilePath $cdb -ArgumentList @('-p',[string]$attach.Id,'-cf',$cmd) -WorkingDirectory $root -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
 Add-Event @{type='CDB_ATTACHED';debugger_pid=[int]$dbg.Id;target_pid=[int]$attach.Id}
 $helper=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'winproc.ps1'),'-TargetPid',[string]$attach.Id,'-RunId',$RunId) -WorkingDirectory $root -WindowStyle Hidden -PassThru
 Add-Event @{type='WINPROC_HELPER_STARTED';pid=[int]$helper.Id}
 $watcher=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'watcher.ps1'),'-RunId',$RunId) -WorkingDirectory $root -WindowStyle Hidden -PassThru
 Add-Event @{type='WATCHER_STARTED';pid=[int]$watcher.Id}
}
Add-Event @{type='LAUNCH_SCRIPT_EXIT'}
