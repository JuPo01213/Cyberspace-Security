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
Add-Event @{type='HOSTS_PINNED';line=$line}
$cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
$target='C:\ept_core\Hardware.exe'
$cmd=Join-Path $root 'auth_release_stage_log.cdb'
$out=Join-Path $root 'cdb.stdout.txt'
$err=Join-Path $root 'cdb.stderr.txt'
$parent=Start-Process -FilePath $target -ArgumentList @('-k','CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','-n','2','-m','1') -WorkingDirectory 'C:\ept_core' -PassThru -WindowStyle Hidden
Add-Event @{type='PARENT_STARTED';pid=[int]$parent.Id}
$child=$null
$deadline=(Get-Date).AddSeconds(25)
while((Get-Date) -lt $deadline -and -not $child){$c=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -like 'EPT_*' -and $_.Path -like 'C:\Windows\Temp\EPT_*.exe'}|Select-Object -First 1);if($c){$child=$c[0]}else{Start-Sleep -Milliseconds 200}}
if($child){
 Add-Event @{type='CHILD_FOUND';pid=[int]$child.Id;ppid=[int]$parent.Id;path=$child.Path}
 $dbg=Start-Process -FilePath $cdb -ArgumentList @('-p',[string]$child.Id,'-cf',$cmd) -WorkingDirectory $root -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
 Add-Event @{type='CDB_ATTACHED';debugger_pid=[int]$dbg.Id;child_pid=[int]$child.Id}
}else{Add-Event @{type='CHILD_NOT_FOUND'}}
Add-Event @{type='LAUNCH_SCRIPT_EXIT'}
