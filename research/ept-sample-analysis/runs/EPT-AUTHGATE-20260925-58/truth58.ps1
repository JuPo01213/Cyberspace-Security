$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  "run57_spool_gone=" + (-not (Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-57'))
  "NHFT_exists=" + (Test-Path 'C:\Windows\Temp\NHFTwBUmYHlXSsjNJdzXRevJ')
  "ini_mtime=" + (Get-Item 'C:\Windows\System32\Hardware.ini' -ErrorAction SilentlyContinue).LastWriteTime.ToString('MM-dd HH:mm:ss')
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
