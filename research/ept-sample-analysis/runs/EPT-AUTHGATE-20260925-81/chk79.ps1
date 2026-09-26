$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
foreach($try in 1..10){
 try {
  $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
  Invoke-Command -Session $s -ScriptBlock {
   "uptime_min=" + [math]::Round(((Get-Date)-(Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalMinutes,1)
   "spool79_gone=" + (-not (Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-79'))
   "sha=" + (Get-FileHash 'C:\ept_core\Hardware.exe' -Algorithm SHA256).Hash.Substring(0,12)
  }
  Remove-PSSession $s
  break
 } catch { Start-Sleep -Seconds 8 }
}
