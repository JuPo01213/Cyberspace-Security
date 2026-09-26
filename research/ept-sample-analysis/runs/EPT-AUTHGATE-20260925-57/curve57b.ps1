$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ArgumentList 'EPT-AUTHGATE-20260925-57' -ScriptBlock {param($id)
  $r='C:\ept_obs\spool\'+$id
  $w=Join-Path $r 'watcher.csv'
  $fs=[System.IO.FileStream]::new($w,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
  $sr=[System.IO.StreamReader]::new($fs)
  $all=$sr.ReadToEnd(); $sr.Close(); $fs.Close()
  $rows=@($all -split "`n" | Where-Object {$_ -match ',' -and $_ -notmatch '^ms,'} | ForEach-Object {$_.TrimEnd("`r")})
  "rows="+$rows.Count
  "=== max bytes per file ==="
  $rows | ForEach-Object {$p=($_ -split ','); [pscustomobject]@{p=$p[2];b=[long]$p[3];t=[long]$p[0]}} | Group-Object p | ForEach-Object {$g=$_.Group; $_.Name+' max='+($g.b|Measure-Object -Maximum).Maximum+' first_ms='+($g.t|Measure-Object -Minimum).Minimum+' last_ms='+($g.t|Measure-Object -Maximum).Maximum+' rows='+$g.Count}
  "=== transitions ==="
  $prev=@{}
  foreach($row in $rows){ $p=($row -split ','); $k=$p[2]; $b=[long]$p[3]; if($prev[$k] -ne $b){ $p[0]+' '+$k+' -> '+$b; $prev[$k]=$b } }
 }
 Remove-PSSession $s
} catch { "PS_DIRECT_FAIL: $_" }
