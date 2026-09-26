$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Copy-Item -ToSession $s -Path '<HOST_PATH>/EPT/runs/EPT-AUTHGATE-20260925-65/captured/captured/HpDrvoznHrSvUEBlJRFiHf0.sys.bin' -Destination 'C:\ept_obs\spool\HpDrvTestDrv.sys' -Force
 Invoke-Command -Session $s -ScriptBlock {
  Copy-Item 'C:\ept_obs\spool\HpDrvTestDrv.sys' 'C:\Windows\Temp\HpDrvTestDrv.sys' -Force
  "exists=" + (Test-Path 'C:\Windows\Temp\HpDrvTestDrv.sys') + " size=" + (Get-Item 'C:\Windows\Temp\HpDrvTestDrv.sys' -ErrorAction SilentlyContinue).Length
  "create=" + ((& sc.exe create HpDrvTestDrv type= kernel start= demand binPath= "\??\C:\Windows\Temp\HpDrvTestDrv.sys" 2>&1) -join ' ')
  "start=" + ((& sc.exe start HpDrvTestDrv 2>&1) -join ' ')
  Start-Sleep -Seconds 2
  "query_state=" + ((& sc.exe query HpDrvTestDrv 2>&1 | Select-String 'STATE') -join ' ')
  $ev = Get-WinEvent -FilterHashtable @{LogName='System';Id=7000,219} -MaxEvents 2 -ErrorAction SilentlyContinue | Select-Object -First 2
  foreach($x in $ev){ "evt: " + (($x.Message -replace "`r`n",' | ').Substring(0,[Math]::Min(180,($x.Message -replace "`r`n",' | ').Length))) }
  & sc.exe delete HpDrvTestDrv 2>&1 | Out-Null
  Remove-Item 'C:\Windows\Temp\HpDrvTestDrv.sys' -Force -ErrorAction SilentlyContinue
  "cleanup_done"
 }
 Remove-PSSession $s
} catch { "PSD_FAIL: $_" }
