$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  "=== System32 Hardware* ==="
  Get-ChildItem 'C:\Windows\System32' -Filter 'Hardware*' -Force -ErrorAction SilentlyContinue | ForEach-Object {$_.Name+' '+$_.Length+' '+$_.LastWriteTime.ToString('HH:mm:ss')}
  if(Test-Path 'C:\Windows\System32\Hardware'){ Get-ChildItem 'C:\Windows\System32\Hardware' -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {$_.FullName+' '+$_.Length} | Select-Object -First 15 }
  "=== Temp non-EPT ==="
  Get-ChildItem 'C:\Windows\Temp' -File -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -notmatch '^EPT_'} | ForEach-Object {$_.Name+' '+$_.Length+' '+$_.LastWriteTime.ToString('HH:mm:ss')}
  "=== AntiCheat services ==="
  Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object {$_.Name -match 'AntiCheat'} | ForEach-Object {$_.Name+' | '+$_.State+' | '+$_.StartMode+' | '+$_.PathName}
  "=== svc prefs (registry) ==="
  foreach($n in @('AntiCheatExpert Protection','AntiCheatExpert Service')){ $k='HKLM:\SYSTEM\CurrentControlSet\Services\'+$n; if(Test-Path $k){ $p=(Get-ItemProperty $k); $n+' | ImagePath='+$p.ImagePath+' | Start='+$p.Start } else { $n+' | NO_KEY' } }
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
