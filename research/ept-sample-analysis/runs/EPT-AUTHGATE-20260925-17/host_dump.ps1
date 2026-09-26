[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[string]$RunId='EPT-AUTHGATE-20260925-17')
$ErrorActionPreference='Continue'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=ConvertTo-SecureString $pw -AsPlainText -Force
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
try {
  Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {
    param($r)
    $out=Join-Path $r 'cdb.stdout.txt'
    $last=-1
    for($i=0;$i -lt 8;$i++){
      $len=0; if(Test-Path $out){$len=(Get-Item $out).Length}
      if($len -eq $last -and $len -gt 0){ 'stdout_stable_at=' + $len; break }
      $last=$len; Start-Sleep -Seconds 5
    }
    $ch=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -like 'EPT_*'})
    'child=' + (($ch|ForEach-Object{$_.Id}) -join ',')
    if($ch.Count -eq 0){ 'NO_CHILD'; return }
    $pid2=$ch[0].Id
    $dmp=Join-Path $r 'child_full.dmp'
    $a=@('C:\Windows\System32\comsvcs.dll,MiniDump',[string]$pid2,$dmp,'full')
    'args=' + ($a -join '|')
    $p=Start-Process -FilePath 'C:\Windows\System32\rundll32.exe' -ArgumentList $a -PassThru -WindowStyle Hidden
    if(-not $p.WaitForExit(60000)){ $p.Kill(); 'minidump_timeout' } else { 'minidump_rc=' + $p.ExitCode }
    if(Test-Path $dmp){
      'dump_bytes=' + (Get-Item $dmp).Length
      $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
      $an=Join-Path $r 'dump_analysis.txt'
      $er=Join-Path $r 'dump_analysis.err'
      Start-Process -FilePath $cdb -ArgumentList @('-z',$dmp,'-cf',(Join-Path $r 'dump_analyze.cdb')) -WorkingDirectory $r -RedirectStandardOutput $an -RedirectStandardError $er -WindowStyle Hidden -Wait | Out-Null
      if(Test-Path $an){ 'analysis_bytes=' + (Get-Item $an).Length } else { 'analysis_missing' }
    } else { 'dump_missing' }
    Get-Process -Name cdb -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    'procs_after=' + (@(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb)'}).Count)
  }
  foreach($n in @('dump_analysis.txt','dump_analysis.err','cdb.stdout.txt','events.ndjson')){ try{ Copy-Item -FromSession $s -LiteralPath (Join-Path $guestRoot $n) -Destination (Join-Path $runDir $n) -Force -ErrorAction Stop; Write-Host ('got '+$n) }catch{ Write-Host ('miss '+$n) } }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
