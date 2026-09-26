$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 foreach($n in @('recvbuf_at_recv.bin','recvbuf_at_fatal.bin')){
   try{ Copy-Item -FromSession $s -Path ('C:\ept_obs\spool\EPT-AUTHGATE-20260925-80\'+$n) -Destination ('<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260925-80\'+$n) -Force -ErrorAction Stop; "pulled $n" }catch{ "fail $n : $_" }
 }
 Remove-PSSession $s
} catch { "PSD_FAIL: $_" }
