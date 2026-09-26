[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[string]$RunId='EPT-AUTHGATE-20260925-58')
$ErrorActionPreference='Continue'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
try {
 Invoke-Command -Session $s -ScriptBlock {Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -eq 'cdb'}|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep -Seconds 2}
 Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {param($id)
  $r='C:\ept_obs\spool\'+$id
  $snap=@{utc=[DateTime]::UtcNow.ToString('o')}
  $snap.tasks=@(Get-ScheduledTask -ErrorAction SilentlyContinue|Where-Object {$_.TaskName -like '*Hardware*'}|Select-Object -ExpandProperty TaskName)
  $snap.log_dirs=@();foreach($x in @('C:\Windows\System32\Logs','C:\Windows\System32\HardwareLogs')){if(Test-Path $x){$snap.log_dirs+=$x}}
  $snap.files=@();foreach($x in @('C:\Windows\System32\Hardware.exe','C:\Windows\System32\R3.exe','C:\Windows\System32\R32.dll','C:\Windows\System32\Hardware.ini','C:\Windows\System32\hwid.cmd','C:\Windows\Temp\HardwareTask.xml','C:\Windows\System32\EPT.cmd')){if(Test-Path $x){$snap.files+=$x}}
  $snap.hardware_dir=@();if(Test-Path 'C:\Windows\System32\Hardware'){$snap.hardware_dir=@(Get-ChildItem 'C:\Windows\System32\Hardware' -ErrorAction SilentlyContinue|ForEach-Object {$_.Name+' '+(Get-Item $_.FullName -ErrorAction SilentlyContinue).Length})}
  $snap.services=@(Get-Service -ErrorAction SilentlyContinue|Where-Object {$_.Name -match '(HP|SWTOOLS|Hardware)' -or $_.DisplayName -match '(HP|SWTOOLS|Hardware)'}|ForEach-Object {$_.Name+':'+$_.Status})
  $snap.temp_payloads=@();$t0=(Get-Item 'C:\ept_obs\spool').CreationTime;foreach($f in @(Get-ChildItem 'C:\Windows\Temp' -File -ErrorAction SilentlyContinue|Where-Object {$_.Extension -eq '' -and $_.Length -gt 0 -and $_.Name -notmatch '^EPT_'})){$snap.temp_payloads+=$f.Name+' '+$f.Length;$dest='C:\ept_obs\spool\'+$id+'\payload_'+$f.Name;Copy-Item -LiteralPath $f.FullName -Destination $dest -Force;$snap.temp_payloads+=('SHA256 '+(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash)}
 $snap.svc_paths=@(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue|Where-Object {$_.PathName -match 'Temp|Hardware|EPT|Cheat'}|ForEach-Object {$_.Name+' | '+$_.PathName+' | '+$_.State})
 $snap.drivers=@(Get-ChildItem 'C:\Windows\System32\drivers' -ErrorAction SilentlyContinue|Where-Object {$_.Name -match '^(HP_|SWTOOLS|HpSvc|HpDrv)'}|Select-Object -ExpandProperty Name)
  $snap.procs=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|R3|cdb)'}|ForEach-Object {"$($_.ProcessName):$($_.Id)"})
  $snap|ConvertTo-Json -Depth 6|Set-Content -LiteralPath ($r+'\post_snapshot.json') -Encoding UTF8
  $snap|ConvertTo-Json -Depth 6
 }
 foreach($n in @(Get-ChildItem (Join-Path $guestRoot 'payload_*') -ErrorAction SilentlyContinue|ForEach-Object {$_.Name})+@('auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','cdb.stdout.txt','cdb.stderr.txt','events.ndjson','winproc.ndjson','post_snapshot.json','watcher.csv','parent_cdb.stdout.txt','parent_cdb.stderr.txt')){try{Copy-Item -FromSession $s -LiteralPath (Join-Path $guestRoot $n) -Destination (Join-Path $runDir $n) -Force -ErrorAction Stop}catch{Write-Host ("miss "+$n)}}
 Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {param($id)
  $hosts="$env:SystemRoot\System32\drivers\etc\hosts"
  $keep=@(Get-Content -LiteralPath $hosts -ErrorAction SilentlyContinue|Where-Object {$_ -ne '127.0.0.1 yz.hwid001.com'})
  Set-Content -LiteralPath $hosts -Value $keep -Encoding ASCII -Force
  & ipconfig.exe /flushdns | Out-Null
  Stop-ScheduledTask -TaskName ('EPT-'+$id) -ErrorAction SilentlyContinue
  Unregister-ScheduledTask -TaskName ('EPT-'+$id) -Confirm:$false -ErrorAction SilentlyContinue
  Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb|windbg)'}|Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  "after_cleanup_procs=" + (@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb|windbg)'}).Count)
  "hosts_pin_removed=" + (-not (@(Get-Content -LiteralPath $hosts -ErrorAction SilentlyContinue) -contains '127.0.0.1 yz.hwid001.com'))
 }
 Write-Host 'HARVEST_DONE'
} finally {Remove-PSSession $s -ErrorAction SilentlyContinue;$sec.Dispose()}
