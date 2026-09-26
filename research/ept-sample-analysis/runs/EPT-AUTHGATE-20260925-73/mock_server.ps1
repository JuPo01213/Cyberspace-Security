param([Parameter(Mandatory=$true)][string]$RunId)
$root=Join-Path 'C:\ept_obs\spool' $RunId
$log=Join-Path $root 'requests.ndjson'
function L([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $log -Value ($x|ConvertTo-Json -Compress -Depth 4) -Encoding UTF8}
$netstat=Join-Path $root 'netstat.txt'
$sw=[System.Diagnostics.Stopwatch]::StartNew()
# HttpListener loop (foreground thread) with a timer polling netstat
$listener=new-object System.Net.HttpListener
foreach($pfx in @('http://127.0.0.1:80/','http://127.0.0.1:8080/','http://127.0.0.1:8000/','http://+:8001/')){ try{ $listener.Prefixes.Add($pfx) }catch{} }
try{ $listener.Start() }catch{ L @{type='LISTENER_START_FAIL';err=$_.Exception.Message} }
L @{type='LISTENER_UP'}
$deadline=(Get-Date).AddMinutes(16)
while((Get-Date) -lt $deadline){
  $ctx=$null
  try { $ctx=$listener.GetContext() } catch { break }
  if($ctx){
    $req=$ctx.Request
    $body=''
    try { $rd=New-Object System.IO.StreamReader($req.InputStream); $body=$rd.ReadToEnd() }catch{}
    L @{type='HTTP';method=$req.HttpMethod;url=$req.Url.ToString();ua=$req.UserAgent;bodyLen=$body.Length;bodyPrefix=$body.Substring(0,[Math]::Min(400,$body.Length))}
    $resp=$ctx.Response
    $resp.StatusCode=200
    $resp.ContentType='text/plain'
    $resp.ContentLength64=2
    $out=[System.Text.Encoding]::ASCII.GetBytes('OK')
    $resp.OutputStream.Write($out,0,2)
    $resp.OutputStream.Close()
  }
}
L @{type='LISTENER_EXIT'}
