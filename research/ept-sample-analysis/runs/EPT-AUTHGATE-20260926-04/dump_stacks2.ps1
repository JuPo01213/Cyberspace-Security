$ErrorActionPreference = 'Stop'
$pw = (Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec = New-Object System.Security.SecureString
$pw.ToCharArray() | ForEach-Object { $sec.AppendChar($_) }
$sec.MakeReadOnly()
$cred = [pscredential]::new('<VM_USER>', $sec)
$s = New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
  $procs = Invoke-Command -Session $s -ScriptBlock {
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|cdb)' } | ForEach-Object { "$($_.ProcessName):$($_.Id) start=$($_.StartTime.ToString('HH:mm:ss'))" }
  }
  "ALIVE_PROCS=" + ($procs -join ' | ')
  $target = $null
  foreach ($l in $procs) { if ($l -match '^Hardware:(\d+)') { $target = $Matches[1]; break } }
  if ($target) {
    Invoke-Command -Session $s -ArgumentList $target -ScriptBlock {
      param($targetPid)
      $cdb = 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
      $out = 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\stacks2.txt'
      $errf = 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\stacks2.err'
      $script = 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\observe2.cdb'
      Set-Content -LiteralPath $script -Value @(
        '!sym noisy'
        '~* kp'
        'r'
        'q'
      ) -Encoding ASCII
      $p = Start-Process -FilePath $cdb -ArgumentList @('-p', $targetPid, '-cf', $script, '-y', 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\symcache;srv*') -RedirectStandardOutput $out -RedirectStandardError $errf -WindowStyle Hidden -Wait -PassThru
      "cdb_exit=" + $p.ExitCode
    }
    Invoke-Command -Session $s -ScriptBlock {
      '=== stacks2.txt tail ==='
      Get-Content 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-04\stacks2.txt' -Tail 90 -ErrorAction SilentlyContinue
    }
  } else {
    'NO_HARDWARE_TARGET_ALIVE'
  }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }