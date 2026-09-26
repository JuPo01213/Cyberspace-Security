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
  "exists=" + (Test-Path 'C:\Windows\System32\drivers\HpDrvTestDrv.sys')
  "create=" + ((& sc.exe create HpDrvTestDrv type= kernel start= demand binPath= HpDrvTestDrv.sys 2>&1) -join ' ')
  "start=" + ((& sc.exe start HpDrvTestDrv 2>&1) -join ' ')
  Start-Sleep -Seconds 2
  "query_state=" + ((& sc.exe query HpDrvTestDrv 2>&1 | Select-String 'STATE') -join ' ')
  $ev = Get-WinEvent -FilterHashtable @{LogName='System';Id=7000} -MaxEvents 1 -ErrorAction SilentlyContinue
  if($ev){ "last_event=" + ($ev.Message -replace "`r`n",' | ').Substring(0,[Math]::Min(200,($ev.Message -replace "`r`n",' | ').Length)) }
  & sc.exe delete HpDrvTestDrv 2>&1 | Out-Null
  Remove-Item 'C:\Windows\System32\drivers\HpDrvTestDrv.sys' -Force -ErrorAction SilentlyContinue
  "cleanup_done"
 }
 Remove-PSSession $s
} catch { "PSD_FAIL: $_" }
