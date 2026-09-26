$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 Copy-Item -ToSession $s -Path '.\canary_H.cdb' -Destination 'C:\ept_obs\' -Force
 Invoke-Command -Session $s -ScriptBlock {
  $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
  $p=Start-Process -FilePath $cdb -ArgumentList @('-cf','C:\ept_obs\canary_H.cdb','cmd.exe','/c','echo X') -WindowStyle Hidden -RedirectStandardOutput 'C:\ept_obs\canary_H.out' -RedirectStandardError 'C:\ept_obs\canary_H.err' -PassThru
  if(-not $p.WaitForExit(60000)){Stop-Process -Id $p.Id -Force}
  Get-Content 'C:\ept_obs\canary_H.out' | Select-String -Pattern 'CANARY_H|KB2_CFW|KB_CFW|H_FORMS|IF_|Couldn.t resolve|Couldn.t' | Select-Object -First 15
 }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
