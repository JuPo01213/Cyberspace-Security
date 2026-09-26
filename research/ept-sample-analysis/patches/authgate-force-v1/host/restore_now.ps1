$ErrorActionPreference = 'Continue'
Write-Host 'STEP1_STOP'
Stop-VM -Name <VM_LABEL> -Force
Start-Sleep -Seconds 4
Write-Host 'STEP2_RESTORE'
Restore-VMCheckpoint -Name C173-gen1-ready2 -VMName <VM_LABEL> -Confirm:$false
Write-Host 'STEP3_START'
Start-VM -Name <VM_LABEL>
Write-Host 'STEP4_WAIT'
$pw = (Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec = New-Object System.Security.SecureString
$pw.ToCharArray() | ForEach-Object { $sec.AppendChar($_) }
$sec.MakeReadOnly()
$cred = [pscredential]::new('<VM_USER>', $sec)
$ok = $false
foreach ($i in 1..20) {
    Start-Sleep -Seconds 6
    try {
        $s = New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
        $r = Invoke-Command -Session $s -ScriptBlock {
            "sha=" + (Get-FileHash 'C:\ept_core\Hardware.exe' -Algorithm SHA256).Hash.Substring(0,12)
            "spool79_gone=" + (-not (Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-79'))
            "spool81_gone=" + (-not (Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-81'))
        }
        Remove-PSSession $s
        Write-Host $r
        if ($r -match 'sha=CFA6998ECC2F' -and $r -match 'spool81_gone=True') { $ok = $true; break }
    } catch { Write-Host ('retry ' + $i) }
}
if ($ok) { Write-Host 'RESTORE_VERIFIED' } else { Write-Host 'RESTORE_FAILED' }
