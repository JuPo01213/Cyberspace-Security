[CmdletBinding()]
param([string]$RunId='EPT-AUTHGATE-20260926-05')
$ErrorActionPreference='Continue'
$localDir='<HOST_PATH>\EPT\runs\'+$RunId
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
  Write-Host 'CLEAN_START'
  Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {param($id)
    Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb|windbg)'}|Stop-Process -Force -ErrorAction SilentlyContinue
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue|Where-Object {$_.CommandLine -match 'watcher\.ps1|tcp1029\.ps1|winproc\.ps1'}|ForEach-Object {Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}
    Stop-ScheduledTask -TaskName ('EPT-'+$id) -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName ('EPT-'+$id) -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $r='C:\ept_obs\spool\'+$id
    if(Test-Path -LiteralPath $r){Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue}
    New-Item -ItemType Directory -Force -Path $r|Out-Null
    $sym='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\sym'
    if(Test-Path -LiteralPath $sym){Rename-Item -LiteralPath $sym ($sym+'_off'+(Get-Date -Format 'HHmmss')) -Force -ErrorAction SilentlyContinue;Write-Host 'SYM_OFF'}
    Write-Host 'CLEAN_DONE'
  }
  foreach($f in @('guest_launch.ps1','auth_stage_force.cdb','canary_syntax.cdb','winproc.ps1','watcher.ps1','tcp1029.ps1','HpDrvPre.sys')){
    Copy-Item -ToSession $s -Path (Join-Path $localDir $f) -Destination (Join-Path $guestRoot $f) -Force
  }
  Write-Host 'FILES_COPIED'
  $lg=(Get-FileHash (Join-Path $localDir 'auth_stage_force.cdb') -Algorithm MD5).Hash
  $gg=Invoke-Command -Session $s -ScriptBlock {param($p)(Get-FileHash $p -Algorithm MD5).Hash} -ArgumentList (Join-Path $guestRoot 'auth_stage_force.cdb')
  if($lg -ne $gg){throw 'CDB_HASH_MISMATCH'}
  Write-Host 'CDB_HASH_OK'
  # canary: quick parse check
  Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)
    $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
    $out=Join-Path $r 'canary.stdout.txt'
    $errf=Join-Path $r 'canary.stderr.txt'
    $p=Start-Process -FilePath $cdb -ArgumentList @('-cf',(Join-Path $r 'canary_syntax.cdb'),'cmd.exe','/c','echo CANARY_ECHO_OK') -WorkingDirectory $r -RedirectStandardOutput $out -RedirectStandardError $errf -PassThru -WindowStyle Hidden
    if(-not $p.WaitForExit(60000)){Write-Host 'CANARY_TIMEOUT';Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue}
  }
  Copy-Item -FromSession $s -LiteralPath (Join-Path $guestRoot 'canary.stdout.txt') -Destination (Join-Path $localDir 'canary.stdout.txt') -Force
  $can=Get-Content -LiteralPath (Join-Path $localDir 'canary.stdout.txt') -Raw -ErrorAction SilentlyContinue
  if($can -match 'Syntax error'){throw 'canary syntax error'}
  Write-Host 'CANARY_PASS'
  # launch guest_launch in <VM_USER> session (interactive-user context, matches proven child spawn)
  $job=Invoke-Command -Session $s -ArgumentList $RunId,$guestRoot -AsJob -ScriptBlock {param($id,$r)
    Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $r 'guest_launch.ps1'),'-RunId',$id) -WorkingDirectory $r -WindowStyle Hidden
  }
  Write-Host 'LAUNCH_KICKED'
} finally {
  Remove-PSSession $s -ErrorAction SilentlyContinue
  $sec.Dispose()
}