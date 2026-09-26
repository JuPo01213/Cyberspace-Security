[CmdletBinding()]
param([string]$RunId='EPT-AUTHGATE-20260926-15')
$ErrorActionPreference='Continue'
# ============ HOST SIDE: restore ============
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
Write-Host 'STEP1_STOP'
Stop-VM -Name <VM_LABEL> -Force
Start-Sleep -Seconds 4
Write-Host 'STEP2_RESTORE'
Restore-VMCheckpoint -Name C173-gen1-ready2 -VMName <VM_LABEL> -Confirm:$false
Write-Host 'STEP3_START'
Start-VM -Name <VM_LABEL>
Write-Host 'STEP4_WAIT'
$ok=$false
foreach($i in 1..20){
  Start-Sleep -Seconds 6
  try {
    $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
    $r=Invoke-Command -Session $s -ScriptBlock {
      "sha=" + (Get-FileHash 'C:\ept_core\Hardware.exe' -Algorithm SHA256).Hash.Substring(0,12)
      "spool81_gone=" + (-not (Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-81'))
    }
    Remove-PSSession $s
    Write-Host $r
    if($r -match 'sha=CFA6998ECC2F' -and $r -match 'spool81_gone=True'){ $ok=$true; break }
  } catch { Write-Host ('retry '+$i) }
}
if(-not $ok){ Write-Host 'RESTORE_FAILED'; exit 1 }
Write-Host 'RESTORE_VERIFIED'
# ============ GUEST SIDE: push + unpinned observe + on-child force attach ============
$localDir='<HOST_PATH>\EPT\runs\'+$RunId
$guestRoot='C:\ept_obs\spool\'+$RunId
$s=New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
  Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {param($id)
    Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb|windbg)'}|Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $guestRoot='C:\ept_obs\spool\'+$id
    if(Test-Path -LiteralPath $guestRoot){Remove-Item -LiteralPath $guestRoot -Recurse -Force -ErrorAction SilentlyContinue}
    New-Item -ItemType Directory -Force -Path $guestRoot|Out-Null
    $sym='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\sym'
    if(Test-Path -LiteralPath $sym){Rename-Item -LiteralPath $sym ($sym+'_off'+(Get-Date -Format 'HHmmss')) -Force -ErrorAction SilentlyContinue}
    Write-Host 'GUEST_CLEANED'
  }
  foreach($f in @('guest_launch.ps1','auth_stage_force.cdb','canary_syntax.cdb','winproc.ps1','watcher.ps1','tcp1029.ps1','HpDrvPre.sys')){
    if(Test-Path (Join-Path $localDir $f)){ Copy-Item -ToSession $s -Path (Join-Path $localDir $f) -Destination (Join-Path $guestRoot $f) -Force }
  }
  Write-Host 'FILES_PUSHED'
  $rc=Invoke-Command -Session $s -ArgumentList $RunId,$guestRoot -ScriptBlock {param($id,$r)
    Set-ExecutionPolicy -Scope Process Bypass -Force
    & (Join-Path $r 'guest_launch.ps1') -RunId $id
    'GLAUNCH_RETURNED'
  }
  $rc | ForEach-Object { Write-Host $_ }
} finally {
  Remove-PSSession $s -ErrorAction SilentlyContinue
  $sec.Dispose()
}
Write-Host 'ALL_DONE'