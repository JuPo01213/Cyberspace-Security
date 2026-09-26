$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
foreach($try in 1..12){
  try {
    $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
    Invoke-Command -Session $s -ScriptBlock {
      "sha=" + (Get-FileHash 'C:\ept_core\Hardware.exe' -Algorithm SHA256).Hash.Substring(0,12)
      "spool57_gone=" + (-not (Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-57'))
      "spool58_gone=" + (-not (Test-Path 'C:\ept_obs\spool\EPT-AUTHGATE-20260925-58'))
      "NHFT_gone=" + (-not (Test-Path 'C:\Windows\Temp\NHFTwBUmYHlXSsjNJdzXRevJ'))
      $ini=Get-Item 'C:\Windows\System32\Hardware.ini' -ErrorAction SilentlyContinue
      "ini_mtime=" + $ini.LastWriteTime.ToString('MM-dd HH:mm:ss')
      "testsign=" + (((bcdedit /enum '{current}') | Where-Object {$_ -match 'testsigning'}) -join '')
    }
    Remove-PSSession $s
    break
  } catch { Start-Sleep -Seconds 8 }
}
