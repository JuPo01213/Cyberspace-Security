$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ArgumentList 'EPT-AUTHGATE-20260925-65' -ScriptBlock {param($id)
  $c='C:\ept_obs\spool\'+$id+'\captured'
  if(Test-Path $c){ Get-ChildItem $c | ForEach-Object {$_.Name+' '+$_.Length} } else { 'NO_CAP_DIR' }
 }
 Copy-Item -FromSession $s -Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-65\captured\*' -Destination '.\captured\' -Force -ErrorAction Continue
 Remove-PSSession $s
 'PULL_DONE'
} catch { "PSD_FAIL: $_" }
