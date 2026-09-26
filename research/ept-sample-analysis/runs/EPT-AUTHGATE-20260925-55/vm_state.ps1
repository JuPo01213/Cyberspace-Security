$ErrorActionPreference='Continue'
Get-VM -Name <VM_LABEL> | Select-Object Name,State,Uptime | Format-Table -AutoSize | Out-String
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  "sha="+(Get-FileHash 'C:\ept_core\Hardware.exe' -Algorithm SHA256).Hash.Substring(0,12)
  "testsign="+(((bcdedit /enum '{current}') | Where-Object {$_ -match 'testsigning|测试签名'}) -join '')
  "procs="+(@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb)'})).Count
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
