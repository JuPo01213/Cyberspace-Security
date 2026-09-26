$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Copy-Item -ToSession $s -Path '.\captured\captured\HpDrvoznHrSvUEBlJRFiHf0.sys.bin' -Destination 'C:\Windows\System32\drivers\HpDrvTestDrv.sys' -Force
 Invoke-Command -Session $s -ScriptBlock {
  "testsign=" + (((bcdedit /enum '{current}') | Where-Object {$_ -match 'testsigning'}) -join '')
  $sig = Get-AuthenticodeSignature 'C:\Windows\System32\drivers\HpDrvTestDrv.sys'
  "sig_status=" + $sig.Status + " signer=" + ($sig.SignerCertificate.Subject -replace '.*CN=([^,]+).*','$1')
  $out = & sc.exe create HpDrvTestDrv type= kernel start= demand binPath= "C:\Windows\System32\drivers\HpDrvTestDrv.sys" 2>&1
  "create=" + ($out -join ' ')
  $out2 = & sc.exe start HpDrvTestDrv 2>&1
  "start=" + ($out2 -join ' ')
  Start-Sleep -Seconds 2
  $q = & sc.exe query HpDrvTestDrv 2>&1
  "query=" + ($q -join ' ')
  $d = Get-WinEvent -FilterHashtable @{LogName='System';Id=7000,7026,219} -MaxEvents 6 -ErrorAction SilentlyContinue | ForEach-Object {$_.Id+' '+($_.Message -split "`n")[0].Substring(0,[Math]::Min(100,($_.Message -split "`n")[0].Length))}
  "events=" + ($d -join ' | ')
  & sc.exe delete HpDrvTestDrv 2>&1 | Out-Null
  Remove-Item 'C:\Windows\System32\drivers\HpDrvTestDrv.sys' -Force -ErrorAction SilentlyContinue
  "cleanup_done"
 }
 Remove-PSSession $s
} catch { "PSD_FAIL: $_" }
