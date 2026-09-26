[CmdletBinding()]
param([string]$RunId='EPT-AUTHGATE-20260926-07')
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
  # synchronous run of guest_launch inside the live session (keeps children alive); may take ~2s only
  # because guest_launch itself forks listener/parent/observer and returns after finding child.
  $rc=Invoke-Command -Session $s -ArgumentList $RunId,$guestRoot -ScriptBlock {param($id,$r)
    Set-ExecutionPolicy -Scope Process Bypass -Force
    & (Join-Path $r 'guest_launch.ps1') -RunId $id
    'GLAUNCH_RETURNED'
  }
  $rc | ForEach-Object { Write-Host $_ }
  Write-Host 'LAUNCH_DONE'
} finally {
  Remove-PSSession $s -ErrorAction SilentlyContinue
  $sec.Dispose()
}