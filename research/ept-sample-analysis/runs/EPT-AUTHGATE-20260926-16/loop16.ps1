[CmdletBinding()]
param([int]$Attempts=4,[string]$RunId='EPT-AUTHGATE-20260926-16')
$ErrorActionPreference='Continue'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$positive=@('KEY_DERIVER_DONE','RC00_CALLSITE','RC03_VALIDATOR_CALLSITE','GAI','CONN','KB_CFW','MSGBOXA_SKIPPED','MSGBOXW_SKIPPED','DIOC')
for($a=1;$a -le $Attempts;$a++){
  Write-Host ('=== ATTEMPT '+$a+' ===')
  $s=New-PSSession -VMName '<VM_LABEL>' -Credential $cred -ErrorAction SilentlyContinue
  if($s){
    Invoke-Command -Session $s -ScriptBlock { Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match '^(cdb|Hardware|EPT_)'} | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2 }
    Remove-PSSession $s
  }
  & (Join-Path $runDir 'host_prep.ps1') -RunId $RunId 2>&1 | Select-String -Pattern 'CANARY_PASS|PREFLIGHT|TASK_STARTED|PREP_DONE|DRIVER_PRELOADED|CHILD_FOUND|CDB_ATTACHED' | ForEach-Object { Write-Host ('  '+$_.Line) }
  # wait for natural end (cdb exit) up to 6 minutes
  for($i=1;$i -le 24;$i++){
    Start-Sleep -Seconds 15
    $s=New-PSSession -VMName '<VM_LABEL>' -Credential $cred -ErrorAction SilentlyContinue
    if(-not $s){ continue }
    $st=Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock { param($id)
      $r='C:\ept_obs\spool\'+$id
      $cdb=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -eq 'cdb'}).Count
      $tgt=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_)'}).Count
      $p=$r+'\cdb.stdout.txt'
      $len=0; $txt=''
      if(Test-Path $p){ $fs=[IO.File]::Open($p,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite); $len=$fs.Length; if($len -lt 4000000){ $buf=New-Object byte[] $len; [void]$fs.Read($buf,0,$len); $txt=[Text.Encoding]::UTF8.GetString($buf) }; $fs.Close() }
      @{cdb=$cdb;tgt=$tgt;len=$len;txt=$txt} }
    Remove-PSSession $s
    Write-Host ('  poll'+$i+' cdb='+$st.cdb+' tgt='+$st.tgt+' log='+$st.len)
    if($st.cdb -eq 0 -and $i -gt 2){ break }
  }
  # copy back this attempt's log
  $s=New-PSSession -VMName '<VM_LABEL>' -Credential $cred -ErrorAction SilentlyContinue
  if($s){
    foreach($n in @('cdb.stdout.txt','protocol.ndjson','winproc.ndjson','events.ndjson')){
      try { Copy-Item -FromSession $s -LiteralPath ('C:\ept_obs\spool\'+$RunId+'\'+$n) -Destination (Join-Path $runDir ('att'+$a+'_'+$n)) -Force -ErrorAction Stop } catch { }
    }
    Remove-PSSession $s
  }
  $txt=''
  $f=Join-Path $runDir ('att'+$a+'_cdb.stdout.txt')
  if(Test-Path $f){ $txt=Get-Content -LiteralPath $f -Raw }
  $hit=@()
  foreach($m in $positive){ if(($txt -split "`n" | Where-Object {$_.Trim() -eq $m}).Count -gt 0){ $hit += $m } }
  Write-Host ('  attempt '+$a+' positives: '+(($hit -join ',')+' (none)').Split("`n")[0])
  if($hit.Count -gt 0){ Write-Host ('POSITIVE_ATTEMPT='+$a+' markers='+($hit -join ',')); break }
}
Write-Host 'LOOP16_DONE'
