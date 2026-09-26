$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  $p1='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\sym'
  "testpath_sym=" + (Test-Path -LiteralPath $p1)
  "testpath_sym_plain=" + (Test-Path $p1)
  "gci=" + ((Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64' -Directory -ErrorAction SilentlyContinue | Where-Object {$_.Name -like 'sym*'} | ForEach-Object {$_.Name}) -join ';')
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
