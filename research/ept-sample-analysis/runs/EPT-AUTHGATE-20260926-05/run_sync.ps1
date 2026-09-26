[CmdletBinding()]
param([string]$RunId='EPT-AUTHGATE-20260926-05')
$ErrorActionPreference='Continue'
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
  # run guest_launch synchronously inside session; it must not return until LAUNCH_SCRIPT_EXIT logged
  $rc=Invoke-Command -Session $s -ArgumentList $RunId,$guestRoot -ScriptBlock {param($id,$r)
    & (Join-Path $r 'guest_launch.ps1') -RunId $id
    'GLAUNCH_RETURNED'
  }
  $rc | ForEach-Object { Write-Host $_ }
  Write-Host 'SYNC_LAUNCH_DONE'
} finally {
  Remove-PSSession $s -ErrorAction SilentlyContinue
  $sec.Dispose()
}