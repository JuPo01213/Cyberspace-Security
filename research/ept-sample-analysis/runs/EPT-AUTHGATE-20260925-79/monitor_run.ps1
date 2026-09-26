param([string]$RunId='EPT-AUTHGATE-20260925-79')
$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
 Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {param($id)
  $r='C:\ept_obs\spool\'+$id
  $o=Join-Path $r 'cdb.stdout.txt'
  "cdb_stdout_bytes=" + $(if(Test-Path $o){(Get-Item $o).Length}else{'MISSING'})
  "pl=" + (@(Get-ChildItem 'C:\Windows\Temp' -File -ErrorAction SilentlyContinue|Where-Object {$_.Extension -eq '' -and $_.Name -notmatch '^EPT_'}|ForEach-Object {$_.Name+':'+$_.Length}) -join ';')
  "procs=" + (@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|R3|cdb)' }|ForEach-Object {$_.ProcessName+':'+$_.Id}) -join ';')
  "wp=" + $(if(Test-Path (Join-Path $r 'winproc.ndjson')){(Get-Content (Join-Path $r 'winproc.ndjson')|Select-Object -Last 3) -join ' | '}else{'none'})
  $svc=@(Get-Service -ErrorAction SilentlyContinue|Where-Object {$_.Name -match '(HP|SWTOOLS|HpSvc|Hardware)' -and $_.Name -ne 'shpamsvc'}|ForEach-Object {$_.Name+':'+$_.Status})
  "svc=" + ($svc -join ';')
 }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
