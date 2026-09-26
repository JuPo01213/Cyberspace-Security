$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ArgumentList 'EPT-AUTHGATE-20260925-56' -ScriptBlock {param($id)
  $r='C:\ept_obs\spool\'+$id
  "procs=" + (@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb)'}|ForEach-Object {$_.ProcessName+':'+$_.Id}) -join ';')
  $w=Join-Path $r 'watcher.csv'
  if(Test-Path $w){
    $rows=Get-Content $w | Where-Object {$_ -notmatch 'bytes|EXIT'}
    "watcher_rows="+$rows.Count
    "=== distinct files seen ==="
    $rows | ForEach-Object { ($_ -split ',')[2] } | Group-Object | ForEach-Object {$_.Name+' n='+$_.'Count'}
    "=== max bytes per file ==="
    $rows | ForEach-Object {$p=($_ -split ','); [pscustomobject]@{p=$p[2];b=[long]$p[3]}} | Group-Object p | ForEach-Object {$_.Name+' max='+($_.Group.b | Measure-Object -Maximum).Maximum}
    "=== last 6 rows ==="
    $rows | Select-Object -Last 6
  } else { "watcher_missing" }
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
