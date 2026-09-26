$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 $f='C:\ept_obs\spool\EPT-AUTHGATE-20260925-82\child_full.dmp dd @rsp L1'
 "exists=" + (Test-Path -LiteralPath $f) + " size=" + (Get-Item -LiteralPath $f -ErrorAction SilentlyContinue).Length
 Copy-Item -FromSession $s -LiteralPath $f -Destination '<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260925-82\child_full_recv2.dmp' -Force
 "PULL_DONE"
 Remove-PSSession $s
} catch { "PSD_FAIL: $_" }
