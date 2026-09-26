$ErrorActionPreference = 'Stop'
$pw = (Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec = New-Object System.Security.SecureString
$pw.ToCharArray() | ForEach-Object { $sec.AppendChar($_) }
$sec.MakeReadOnly()
$cred = [pscredential]::new('<VM_USER>', $sec)
$s = New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
  '=== guest baseline check (post-restore, pre-overwrite) ==='
  Invoke-Command -Session $s -ScriptBlock {
    '--- Hardware.exe hash ---'
    (Get-FileHash 'C:\ept_core\Hardware.exe' -Algorithm SHA256).Hash.Substring(0,16)
    '--- System32 artifacts ---'
    foreach ($x in @('C:\Windows\System32\Hardware.exe','C:\Windows\System32\Hardware.ini','C:\Windows\System32\EPT.cmd','C:\Windows\System32\R3.exe')) {
      if (Test-Path $x) { "$x EXISTS size=" + (Get-Item $x).Length + " mtime=" + (Get-Item $x).LastWriteTime.ToString('MM-dd HH:mm') } else { "$x ABSENT" }
    }
    '--- System32\Hardware dir ---'
    if (Test-Path 'C:\Windows\System32\Hardware') { (Get-ChildItem 'C:\Windows\System32\Hardware' -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }).Count } else { 'NO HARDWARE DIR' }
    '--- Temp EPT_* files ---'
    Get-ChildItem 'C:\Windows\Temp' -Filter 'EPT_*' -ErrorAction SilentlyContinue | ForEach-Object { "$($_.Name) mtime=$($_.LastWriteTime.ToString('MM-dd HH:mm:ss'))" }
    '--- hosts tail ---'
    Get-Content 'C:\Windows\System32\drivers\etc\hosts' -Tail 5
    '--- HpDrv services ---'
    Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'HP|SWTOOLS|Hardware|HpDrv' } | ForEach-Object { "$($_.Name):$($_.Status)" }
    '--- spool dirs ---'
    Get-ChildItem 'C:\ept_obs\spool' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
  }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }