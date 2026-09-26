param([Parameter(Mandatory=$true)][string]$RunId)
$root=Join-Path 'C:\ept_obs\spool' $RunId
$cap=Join-Path $root 'captured'
New-Item -ItemType Directory -Force -Path $cap | Out-Null
$csv=Join-Path $root 'watcher.csv'
'ms,epoch,path,bytes' | Set-Content -LiteralPath $csv -Encoding ASCII
$seen=@{}
$pending=@{}
$sw=[System.Diagnostics.Stopwatch]::StartNew()
$deadline=(Get-Date).AddMinutes(18)
while((Get-Date) -lt $deadline){
  $stamp="$($sw.ElapsedMilliseconds)"
  foreach($f in @(Get-ChildItem 'C:\Windows\Temp' -File -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -notmatch '^(EPT_|TS_)'})){
    Add-Content -LiteralPath $csv -Value ($stamp+','+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()+','+$f.Name+','+$f.Length) -Encoding ASCII
    $dest=Join-Path $cap ($f.Name+'.bin')
    $okc=Test-Path -LiteralPath $dest
    if($f.Length -gt 0 -and -not $okc){
      try {
        $fs=[System.IO.File]::Open($f.FullName,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
        $buf=New-Object byte[] $fs.Length
        [void]$fs.Read($buf,0,$fs.Length)
        $fs.Close()
        [System.IO.File]::WriteAllBytes($dest,$buf)
        Add-Content -LiteralPath $csv -Value ($stamp+','+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()+',CAPTURED_'+$f.Name+','+$f.Length) -Encoding ASCII
      } catch {
        Add-Content -LiteralPath $csv -Value ($stamp+','+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()+',CAPFAIL_'+$f.Name+','+$_.Exception.Message.GetHashCode()) -Encoding ASCII
      }
    }
  }
  foreach($p in @('C:\Windows\System32\Hardware','C:\Windows\System32\Hardware.exe','C:\Windows\System32\Hardware.ini')){
    if(Test-Path $p){ $i=Get-Item $p -Force; Add-Content -LiteralPath $csv -Value ($stamp+','+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()+','+('SYS32_'+$i.Name)+','+$i.Length) -Encoding ASCII
      $d2=Join-Path $cap ('SYS32_'+$i.Name+'.bin')
      $need=$false
      if(-not (Test-Path -LiteralPath $d2)){ $need=$true } else { if((Get-Item $d2 -Force).Length -ne $i.Length){ $need=$true } }
      if($need){ Copy-Item -LiteralPath $p -Destination $d2 -Force -ErrorAction SilentlyContinue }
    }
  }
  Start-Sleep -Milliseconds 500
}
Add-Content -LiteralPath $csv -Value "WATCHER_EXIT" -Encoding ASCII
