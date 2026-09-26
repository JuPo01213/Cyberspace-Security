$ErrorActionPreference = 'Stop'
$pw = (Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec = New-Object System.Security.SecureString
$pw.ToCharArray() | ForEach-Object { $sec.AppendChar($_) }
$sec.MakeReadOnly()
$cred = [pscredential]::new('<VM_USER>', $sec)
$s = New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
  Invoke-Command -Session $s -ScriptBlock {
    $r = 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-05\observe'
    New-Item -ItemType Directory -Force -Path $r | Out-Null
    $cdb = 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
    $out = Join-Path $r 'cdb.stdout.txt'
    $errf = Join-Path $r 'cdb.stderr.txt'
    $script = Join-Path $r 'observe.cdb'
    Set-Content -LiteralPath $script -Value @(
      '.echo OBS5_START'
      'sxe ld:none'
      'bu kernelbase!CreateProcessW ".echo CPW; du @rdx; g"'
      'bu kernelbase!CreateProcessA ".echo CPA; da @rdx; g"'
      'bu kernelbase!CreateProcessInternalW ".echo CPIW; du @rdx; g"'
      'bu ntdll!NtCreateUserProcess ".echo NCUP; g"'
      'bu kernelbase!ExitProcess ".echo EP; k 4; g"'
      'bu kernel32!ExitProcessImplementation ".echo EPI; k 4; g"'
      'g'
    ) -Encoding ASCII
    $parent = Start-Process -FilePath 'C:\ept_core\Hardware.exe' -WorkingDirectory 'C:\ept_core' -PassThru -WindowStyle Hidden
    "PARENT_PID=" + $parent.Id
    Start-Sleep -Seconds 2
    $dbg = Start-Process -FilePath $cdb -ArgumentList @('-p', [string]$parent.Id, '-cf', $script, '-y', 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-05\observe') -WorkingDirectory $r -RedirectStandardOutput $out -RedirectStandardError $errf -PassThru -WindowStyle Hidden
    "CDB_PID=" + $dbg.Id
    Start-Sleep -Seconds 90
    '--- events ---'
    Get-Content (Join-Path $r 'cdb.stdout.txt') -Tail 40 -ErrorAction SilentlyContinue
    '--- procs ---'
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|cdb)' } | ForEach-Object { "$($_.ProcessName):$($_.Id)" }
  }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }