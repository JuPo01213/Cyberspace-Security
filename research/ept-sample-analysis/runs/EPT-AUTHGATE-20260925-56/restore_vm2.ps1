param([string]$SnapshotName='C173-gen1-ready2')
$ErrorActionPreference='Continue'
Stop-VM -Name <VM_LABEL> -Force
Start-Sleep -Seconds 3
Restore-VMCheckpoint -Name $SnapshotName -VMName <VM_LABEL> -Confirm:$false
Write-Host "RESTORE_DONE $SnapshotName"
Start-VM -Name <VM_LABEL>
Write-Host "START_DONE"
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
      "sha=" + (Get-FileHash 'C:\ept_core\Hardware.exe' -Algorithm SHA256).Hash.Substring(0,12)
      "run55_spool_gone=" + (-not (Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-55'))
      "ini_mtime=" + (Get-Item 'C:\Windows\System32\Hardware.ini' -ErrorAction SilentlyContinue).LastWriteTime.ToString('MM-dd HH:mm:ss')
      "procs=" + (@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb)'}).Count)
    }
    Remove-PSSession $s
    Write-Host $r
    if($r -match 'sha=CFA6998ECC2F' -and $r -match 'run55_spool_gone=True'){ $ok=$true; break }
  } catch { Write-Host ("retry "+$i) }
}
if($ok){ Write-Host 'RESTORE_VERIFIED' } else { Write-Host 'RESTORE_VERIFY_FAILED' }
