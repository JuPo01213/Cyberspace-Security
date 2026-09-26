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
$child=$null
$deadline=(Get-Date).AddSeconds(90)
while((Get-Date) -lt $deadline -and -not $child){$c=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -like 'EPT_*' -and $_.Path -like 'C:\Windows\Temp\EPT_*.exe'}|Select-Object -First 1);if($c){$child=$c[0]};if(-not $child){Start-Sleep -Milliseconds 300}}
if($child){Add-Event @{type='CHILD_FOUND';pid=[int]$child.Id;ppid=[int]$parent.Id;path=$child.Path}}else{Add-Event @{type='NO_CHILD_NO_CDB';parent_alive=([bool](Get-Process -Id $parent.Id -ErrorAction SilentlyContinue))}}
Add-Event @{type='RUN_OBSERVATION_WINDOW';deadline_sec=90}
Start-Sleep -Seconds 30
Add-Event @{type='OBSERVATION_END';parent_alive=([bool](Get-Process -Id $parent.Id -ErrorAction SilentlyContinue));child_alive=([bool]($child -and (Get-Process -Id $child.Id -ErrorAction SilentlyContinue)))}
