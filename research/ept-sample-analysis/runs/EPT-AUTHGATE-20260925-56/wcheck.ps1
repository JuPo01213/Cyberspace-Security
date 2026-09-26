$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ArgumentList 'EPT-AUTHGATE-20260925-56' -ScriptBlock {param($id)
  $r='C:\ept_obs\spool\'+$id
  "watcher_ps1_exists="+(Test-Path ($r+'\watcher.ps1'))
  Get-ChildItem $r -ErrorAction SilentlyContinue | ForEach-Object {$_.Name+' '+$_.Length}
  $ev=Join-Path $r 'events.ndjson'
  if(Test-Path $ev){ "=== events ==="; Get-Content $ev | Select-Object -Last 10 }
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
