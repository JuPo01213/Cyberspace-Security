$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  "=== MpComputerStatus ==="
  try { $st=Get-MpComputerStatus -ErrorAction Stop; "AMRunning="+$st.AMServiceEnabled+" RealTime="+$st.RealTimeProtectionEnabled+" BehaviorMon="+$st.BehaviorMonitorEnabled+" AVSignature="+$st.AntivirusSignatureVersion } catch { "Get-MpComputerStatus FAIL: $_" }
  "=== MpThreatDetection ==="
  try { Get-MpThreatDetection -ErrorAction Stop | Select-Object -First 8 | ForEach-Object {$_.InitialDetectionTime.ToString('MM-dd HH:mm:ss')+' '+($_.Resources -join ';')} } catch { "Get-MpThreatDetection FAIL: $_" }
  "=== Defender EventLog 1116/1117 ==="
  Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Defender/Operational';Id=1116,1117} -MaxEvents 8 -ErrorAction SilentlyContinue | ForEach-Object {$_.TimeCreated.ToString('MM-dd HH:mm:ss')+' id='+$_.Id+' '+(($_.Message -split "`n" | Select-String 'Name:|Path:') -join ' | ').Substring(0,[Math]::Min(180,($_.Message -split "`n" | Select-String 'Name:|Path:') -join ' | ').Length)}
  "=== service state ==="
  (Get-Service WinDefend -ErrorAction SilentlyContinue).Status
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
