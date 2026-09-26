$ErrorActionPreference = 'Stop'
$pw = (Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec = New-Object System.Security.SecureString
$pw.ToCharArray() | ForEach-Object { $sec.AppendChar($_) }
$sec.MakeReadOnly()
$cred = [pscredential]::new('<VM_USER>', $sec)
$s = New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
  Invoke-Command -Session $s -ScriptBlock {
    '=== cleanup ==='
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|cdb)' } | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'tcp1029|watcher|winproc' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 2
    $hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
    'PIN hosts now:'
    $line = '127.0.0.1 yz.hwid001.com'
    $txt = @(Get-Content -LiteralPath $hosts -ErrorAction SilentlyContinue)
    if ($txt -notcontains $line) { Add-Content -LiteralPath $hosts -Value $line -Encoding ASCII }
    & ipconfig.exe /flushdns | Out-Null
    'hosts pinned. launching parent with observer cdb...'
    $r = 'C:\ept_obs\spool\EPT-AUTHGATE-20260926-09\observe'
    New-Item -ItemType Directory -Force -Path $r | Out-Null
    $cdb = 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
    $out = Join-Path $r 'cdb.stdout.txt'
    $errf = Join-Path $r 'cdb.stderr.txt'
    $script = Join-Path $r 'observe.cdb'
    Set-Content -LiteralPath $script -Value @(
      '.echo OBS9_PINNED_START'
      'bu kernelbase!CreateProcessW ".echo CPW; du @rdx; g"'
      'bu kernelbase!CreateProcessA ".echo CPA; da @rdx; g"'
      'bu kernelbase!CreateProcessInternalW ".echo CPIW; du @rdx; g"'
      'g'
    ) -Encoding ASCII
    $parent = Start-Process -FilePath 'C:\ept_core\Hardware.exe' -WorkingDirectory 'C:\ept_core' -PassThru -WindowStyle Hidden
    "PARENT_PID=" + $parent.Id
    Start-Sleep -Seconds 2
    $dbg = Start-Process -FilePath $cdb -ArgumentList @('-p', [string]$parent.Id, '-cf', $script) -WorkingDirectory $r -RedirectStandardOutput $out -RedirectStandardError $errf -PassThru -WindowStyle Hidden
    "CDB_PID=" + $dbg.Id
    Start-Sleep -Seconds 100
    '--- cdb tail ---'
    Get-Content (Join-Path $r 'cdb.stdout.txt') -Tail 50 -ErrorAction SilentlyContinue
    '--- procs ---'
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(Hardware|EPT_|cdb)' } | ForEach-Object { "$($_.ProcessName):$($_.Id)" }
  }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }