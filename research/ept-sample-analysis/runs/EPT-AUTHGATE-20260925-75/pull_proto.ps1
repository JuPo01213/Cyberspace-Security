$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 $fs=[System.IO.File]::Open('C:\ept_obs\spool\EPT-AUTHGATE-20260925-75\protocol.ndjson',[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
 $sr=New-Object System.IO.StreamReader($fs)
 $all=$sr.ReadToEnd()
 $sr.Close(); $fs.Close()
 [System.IO.File]::WriteAllText('<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260925-75\protocol.ndjson',$all)
 "pulled_bytes="+$all.Length
 Remove-PSSession $s
} catch { "PSD_FAIL: $_" }
