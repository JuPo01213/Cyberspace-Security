param([Parameter(Mandatory=$true)][string]$RunId,[int]$Respond=1)
$root=Join-Path 'C:\ept_obs\spool' $RunId
$log=Join-Path $root 'protocol.ndjson'
function L([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $log -Value ($x|ConvertTo-Json -Compress -Depth 4) -Encoding UTF8}
L @{type='LISTENER_1029_UP';respond=$Respond}
$listener=New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback,1029)
$listener.Start()
$sw=[System.Diagnostics.Stopwatch]::StartNew()
$deadline=(Get-Date).AddMinutes(16)
$connN=0
while((Get-Date) -lt $deadline){
  if(-not $listener.Pending()){ Start-Sleep -Milliseconds 200; continue }
  $client=$listener.AcceptTcpClient()
  $connN++
  $cid=$connN
  $client.ReceiveTimeout=8000
  $stream=$client.GetStream()
  $peer=$client.Client.RemoteEndPoint.ToString()
  L @{type='ACCEPT';cid=$cid;peer=$peer;ms=$sw.ElapsedMilliseconds}
  $buf=New-Object byte[] 65536
  $frame=New-Object System.Collections.Generic.List[byte]
  try {
    while($true){
      try { $n=$stream.Read($buf,0,$buf.Length) } catch { L @{type='READ_TIMEOUT';cid=$cid}; break }
      if($n -le 0){ L @{type='EOF';cid=$cid}; break }
      $chunk=$buf[0..($n-1)]
      $hex=[BitConverter]::ToString($chunk) -replace '-',''
      $ascii=-join($chunk | ForEach-Object { if($_ -ge 0x20 -and $_ -le 0x7e){[char]$_}else{'.'} })
      L @{type='RX';cid=$cid;bytes=$n;ms=$sw.ElapsedMilliseconds;hex=$hex;ascii=$ascii}
      foreach($b in $chunk){ $frame.Add($b) }
      if($Respond -eq 1){
        # Phase B: echo the frame back as a provisional protocol response (injected)
        $stream.Write($chunk,0,$n); $stream.Flush()
        L @{type='TX_ECHO';cid=$cid;bytes=$n}
      } elseif($Respond -eq 2){
        # respond with 4-byte prefix + zero body (generic ack)
        $resp=[byte[]]@(0x00,0x00,0x00,0x00)
        $stream.Write($resp,0,4); $stream.Flush()
        L @{type='TX_ACK0';cid=$cid}
      }
    }
  } catch { L @{type='CONN_ERR';cid=$cid;err=$_.Exception.Message} }
  if($frame.Count -gt 0){
    $hex=[BitConverter]::ToString($frame.ToArray()) -replace '-',''
    Add-Content -LiteralPath (Join-Path $root ('frame_'+$cid+'.hex')) -Value $hex -Encoding ASCII
  }
  $client.Close()
}
$listener.Stop()
L @{type='LISTENER_1029_EXIT';conns=$connN}
