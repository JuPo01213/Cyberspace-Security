$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  "spool_dirs=" + ((Get-ChildItem 'C:\ept_obs\spool' -Directory -ErrorAction SilentlyContinue | ForEach-Object {$_.Name}) -join ';')
  "spool75_exists=" + (Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-75')
  if(Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-75'){ (Get-ChildItem 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-75').Name -join ';' }
 }
 Remove-PSSession $s
} catch { "PSD_FAIL: $_" }
