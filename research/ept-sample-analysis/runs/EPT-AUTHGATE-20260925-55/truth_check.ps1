$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  "run52_spool_exists="+(Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-52')
  "run54_spool_exists="+(Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-54')
  "sym_active="+(Test-Path 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\sym')
  "sym_disabled="+(Test-Path 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\sym_disabled_by_ept')
  "procs=" + (@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb)'}|ForEach-Object {$_.ProcessName+':'+$_.Id}) -join ';')
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
