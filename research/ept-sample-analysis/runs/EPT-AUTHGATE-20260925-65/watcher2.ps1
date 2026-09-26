param([Parameter(Mandatory=$true)][string]$RunId)
$root=Join-Path 'C:\ept_obs\spool' $RunId
$cap=Join-Path $root 'captured'
New-Item -ItemType Directory -Force -Path $cap | Out-Null
$csv=Join-Path $root 'watcher.csv'
'ms,epoch,path,bytes' | Set-Content -LiteralPath $csv -Encoding ASCII
$seen=@{}
$sw=[System.Diagnostics.Stopwatch]::StartNew()
$deadline=(Get-Date).AddMinutes(18)
while((Get-Date) -lt $deadline){
  $stamp="$($sw.ElapsedMilliseconds)"
  foreach($f in @(Get-ChildItem 'C:\Windows\Temp' -File -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -notmatch '^(EPT_|TS_)'})){
    Add-Content -LiteralPath $csv -Value ($stamp+','+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()+','+$f.Name+','+$f.Length) -Encoding ASCII
    if($f.Length -gt 0 -and -not $seen.ContainsKey($f.Name)){
      $seen[$f.Name]=$f.Length
      $dest=Join-Path $cap ($f.Name+'.bin')
      Copy-Item -LiteralPath $f.FullName -Destination $dest -Force -ErrorAction SilentlyContinue
      Add-Content -LiteralPath $csv -Value ($stamp+','+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()+',CAPTURED_'+$f.Name+','+$f.Length) -Encoding ASCII
    }
  }
  foreach($p in @('C:\Windows\System32\Hardware','C:\Windows\System32\Hardware.exe','C:\Windows\System32\Hardware.ini')){
    if(Test-Path $p){ $i=Get-Item $p -Force; Add-Content -LiteralPath $csv -Value ($stamp+','+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()+','+('SYS32_'+$i.Name)+','+$i.Length) -Encoding ASCII
      if(-not $seen.ContainsKey('SYS32_'+$i.Name) -or $seen['SYS32_'+$i.Name] -ne $i.Length){ $seen['SYS32_'+$i.Name]=$i.Length; Copy-Item -LiteralPath $p -Destination (Join-Path $cap ('SYS32_'+$i.Name+'.bin')) -Force -ErrorAction SilentlyContinue }
    }
  }
  Start-Sleep -Milliseconds 500
}
Add-Content -LiteralPath $csv -Value "WATCHER_EXIT" -Encoding ASCII
