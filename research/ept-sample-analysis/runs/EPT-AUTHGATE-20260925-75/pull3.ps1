$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 $txt=Invoke-Command -Session $s -ScriptBlock { Get-Content 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-75\protocol.ndjson' -Raw }
 "len=" + $txt.Length
 [System.IO.File]::WriteAllText('<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260925-75\protocol.ndjson',$txt)
 Remove-PSSession $s
} catch { "PSD_FAIL: $_" }
