param([string]$SnapshotName='C173-gen1-ready2')
$ErrorActionPreference='Stop'
Write-Host "STOP_VM"
Stop-VM -Name <VM_LABEL> -Force
Start-Sleep -Seconds 3
Write-Host "RESTORE_CHECKPOINT $SnapshotName"
Restore-VMCheckpoint -Name $SnapshotName -VMName <VM_LABEL> -Confirm:$false
Write-Host "START_VM"
Start-VM -Name <VM_LABEL>
Write-Host "WAIT_PS_DIRECT"
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$ok=$false
foreach($i in 1..24){
  Start-Sleep -Seconds 5
  try {
    $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
    $r=Invoke-Command -Session $s -ScriptBlock {
      $sp='C:\ept_core\Hardware.exe'
      "sha=" + $(if(Test-Path $sp){(Get-FileHash $sp -Algorithm SHA256).Hash.Substring(0,12)}else{'MISSING'})
      "testsign=" + (((bcdedit /enum '{current}') | Where-Object {$_ -match 'testsigning|测试签名'}) -join '')
      "sym_dir_present=" + (Test-Path 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\sym')
      "uptime_min=" + [math]::Round(((Get-Date)-(Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalMinutes,1)
    }
    Remove-PSSession $s
    Write-Host $r
    if($r -match 'sha=CFA6998ECC2F'){ $ok=$true; break }
  } catch { Write-Host ("retry "+$i) }
}
if($ok){ Write-Host 'RESTORE_VERIFIED' } else { Write-Host 'RESTORE_VERIFY_FAILED' }
