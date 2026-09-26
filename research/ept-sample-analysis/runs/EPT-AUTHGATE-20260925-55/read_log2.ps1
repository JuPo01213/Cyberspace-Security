$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  $p='C:\Windows\System32\Hardware'
  $i=Get-Item $p -Force
  "size="+$i.Length+" attrs="+$i.Attributes+" mtime="+$i.LastWriteTime.ToString('MM-dd HH:mm:ss')
  "=== RAW HEX (first 256) ==="
  ($b=[System.IO.File]::ReadAllBytes($p))[0..255] | ForEach-Object {$_.ToString('x2')}
  "=== DECODED GBK ==="
  [System.Text.Encoding]::GetEncoding(936).GetString($b)
  "=== DECODED UTF8 ==="
  [System.Text.Encoding]::UTF8.GetString($b)
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
