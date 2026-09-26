$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
foreach($i in 1..30){
  Start-Sleep -Seconds 30
  try {
    $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
    $procs=Invoke-Command -Session $s -ScriptBlock {
      @(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb)'}).Count
    }
    Remove-PSSession $s
    Write-Host ("poll"+$i+" procs="+$procs)
    if($procs -eq 0){ break }
  } catch { }
}
Write-Host 'WAIT_DONE'
