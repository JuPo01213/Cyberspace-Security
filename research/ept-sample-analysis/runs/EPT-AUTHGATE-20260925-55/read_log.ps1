$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  "=== sizes ==="
  foreach($p in @('C:\Windows\System32\Hardware.exe','C:\Windows\System32\Hardware.ini','C:\Windows\System32\Hardware\Hardware','C:\Windows\System32\EPT.cmd')){
    if(Test-Path $p){ $i=Get-Item $p; $p+' | '+$i.Length+' | '+$i.LastWriteTime.ToString('MM-dd HH:mm:ss') }
  }
  "=== LOG CONTENT (Hardware\Hardware) ==="
  if(Test-Path 'C:\Windows\System32\Hardware\Hardware'){ [System.IO.File]::ReadAllText('C:\Windows\System32\Hardware\Hardware',[System.Text.Encoding]::GetEncoding(936)) }
  "=== Hardware.ini ==="
  if(Test-Path 'C:\Windows\System32\Hardware.ini'){ [System.IO.File]::ReadAllText('C:\Windows\System32\Hardware.ini',[System.Text.Encoding]::GetEncoding(936)) }
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
