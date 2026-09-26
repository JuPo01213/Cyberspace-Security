$ErrorActionPreference = 'Stop'
$pw = (Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec = New-Object System.Security.SecureString
$pw.ToCharArray() | ForEach-Object { $sec.AppendChar($_) }
$sec.MakeReadOnly()
$cred = [pscredential]::new('<VM_USER>', $sec)
$s = New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
  Invoke-Command -Session $s -ArgumentList '2456' -ScriptBlock {
    param($targetPid)
    $cdb = 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
    $out = 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\stack_observe.txt'
    $errf = 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\stack_observe.err'
    $script = 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\observe.cdb'
    Set-Content -LiteralPath $script -Value @(
      '.symfix C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\symcache'
      '.reload'
      '~* k'
      'q'
    ) -Encoding ASCII
    $p = Start-Process -FilePath $cdb -ArgumentList @('-p', $targetPid, '-cf', $script) -RedirectStandardOutput $out -RedirectStandardError $errf -WindowStyle Hidden -Wait -PassThru
    "cdb_exit=" + $p.ExitCode
  }
  Invoke-Command -Session $s -ScriptBlock {
    '=== stack_observe.txt (tail) ==='
    Get-Content 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\stack_observe.txt' -Tail 80 -ErrorAction SilentlyContinue
    '=== err ==='
    Get-Content 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\stack_observe.err' -Tail 10 -ErrorAction SilentlyContinue
  }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }