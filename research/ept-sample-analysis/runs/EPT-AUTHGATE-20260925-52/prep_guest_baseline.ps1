[CmdletBinding()]
param([string]$VmName='<VM_LABEL>')
$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
try {
 Invoke-Command -Session $s -ScriptBlock {
  "=== TESTSIGNING ==="
  bcdedit /enum '{current}' | Select-String -Pattern 'testsigning'
  "=== DISABLE UPDATE SERVICES ==="
  foreach($sv in @('wuauserv','UsoSvc','DoSvc','BITS')){
    $cfg = & sc.exe config $sv start= disabled 2>&1
    $stp = & sc.exe stop $sv 2>&1
    "svc=$sv config=[$cfg] stop=[$stp]"
  }
  "=== START TYPES AFTER ==="
  foreach($sv in @('wuauserv','UsoSvc','DoSvc','BITS','WaaSMedicSvc')){
    $q = & sc.exe qc $sv 2>&1 | Select-String 'START_TYPE'
    "svc=$sv $($q)"
  }
  "=== PENDING REBOOT CHECK ==="
  $p1 = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
  $p2 = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
  "cbs_pending=$p1 wu_pending=$p2"
  "=== SAMPLE LINEAGE ==="
  $sp='C:\ept_core\Hardware.exe'
  if(Test-Path $sp){ "sample_present=True sha256="+(Get-FileHash $sp -Algorithm SHA256).Hash } else { "sample_present=FALSE" }
  "=== BASELINE CLEANLINESS ==="
  $procs=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb|windbg)'})
  "sample_procs="+$procs.Count
  $hosts="$env:SystemRoot\System32\drivers\etc\hosts"
  "hosts_pinned="+(@($hosts | ForEach-Object { [bool](Select-String -LiteralPath $_ -Pattern 'yz\.hwid001\.com' -ErrorAction SilentlyContinue) }) -contains $true)
  $t=@(Get-ScheduledTask -ErrorAction SilentlyContinue|Where-Object {$_.TaskName -like 'EPT-*' -or $_.TaskName -like '*Hardware*'})
  "leftover_tasks="+($t.TaskName -join ',')
  $svc=@(Get-Service -ErrorAction SilentlyContinue|Where-Object {$_.Name -match '(HP|SWTOOLS|Hardware)'})
  "leftover_services="+($svc.Name -join ',')
  $pl=@(Get-ChildItem 'C:\Windows\Temp' -File -ErrorAction SilentlyContinue|Where-Object {$_.Extension -eq '' -and $_.Length -gt 0 -and $_.Name -notmatch '^EPT_'})
  "leftover_payloads="+($pl.Name -join ',')
  "=== UPTIME ==="
  $os=Get-CimInstance Win32_OperatingSystem
  "last_boot="+$os.LastBootUpTime.ToString('o')+" uptime_min="+[math]::Round(((Get-Date)-$os.LastBootUpTime).TotalMinutes,1)
  "BASELINE_CHECK_DONE"
 }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
