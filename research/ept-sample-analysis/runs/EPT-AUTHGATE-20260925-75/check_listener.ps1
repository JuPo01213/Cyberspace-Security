$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  "ps_listeners=" + (@(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object {$_.CommandLine -match 'tcp1029'} | ForEach-Object {$_.ProcessId}) -join ';')
  "netstat_1029=" + ((netstat -an | Select-String ':1029') -join ' ; ')
  $r='C:\ept_obs\spool\EPT-AUTHGATE-20260925-75'
  "proto_size=" + (Get-Item ($r+'\protocol.ndjson') -ErrorAction SilentlyContinue).Length
  "spool_files:" 
  Get-ChildItem $r -ErrorAction SilentlyContinue | ForEach-Object {$_.Name+' '+$_.Length}
  "tcp1029_head:"
  Get-Content ($r+'\tcp1029.ps1') -TotalCount 4 -ErrorAction SilentlyContinue
 }
 Remove-PSSession $s
} catch { "PSD_FAIL: $_" }
