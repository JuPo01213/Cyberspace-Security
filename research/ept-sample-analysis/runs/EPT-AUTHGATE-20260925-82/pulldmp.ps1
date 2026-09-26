$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock { Get-ChildItem 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-82' -Filter '*.dmp' -ErrorAction SilentlyContinue | ForEach-Object {$_.Name+' '+$_.Length} }
 Copy-Item -FromSession $s -Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-82\*.dmp' -Destination '<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260925-82\' -Force -ErrorAction Continue
 Remove-PSSession $s
 'PULL_DONE'
} catch { "PSD_FAIL: $_" }
