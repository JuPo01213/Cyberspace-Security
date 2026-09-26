
$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString; $pw.ToCharArray()|ForEach-Object{$sec.AppendChar($_)}; $sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName '<VM_LABEL>' -Credential $cred
try {
 $runDir='<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260926-16'
 Invoke-Command -Session $s -ScriptBlock {param($r) if(-not (Test-Path $r)){New-Item -ItemType Directory -Force -Path $r|Out-Null} } -ArgumentList 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-16'
 Copy-Item -ToSession $s -Path (Join-Path $runDir 'pf2_syntax.cdb') -Destination 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-16\pf2_syntax.cdb' -Force
 Invoke-Command -Session $s -ScriptBlock {
  $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
  $r='C:\ept_obs\spool\EPT-AUTHGATE-20260926-16'
  $sw=[System.Diagnostics.Stopwatch]::StartNew()
  $p=Start-Process -FilePath $cdb -ArgumentList @('-cf',($r+'\pf2_syntax.cdb'),'cmd.exe','/c','echo PF_ECHO_OK') -WorkingDirectory $r -RedirectStandardOutput ($r+'\pf2.stdout.txt') -RedirectStandardError ($r+'\pf2.stderr.txt') -PassThru -WindowStyle Hidden
  $done=$p.WaitForExit(120000)
  if(-not $done){ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
  Write-Host ('pf2_elapsed_ms=' + $sw.ElapsedMilliseconds + ' exited=' + $done)
 }
 Copy-Item -FromSession $s -LiteralPath 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-16\pf2.stdout.txt' -Destination (Join-Path $runDir 'pf2.stdout.txt') -Force
 Write-Host 'PF2_DONE'
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
