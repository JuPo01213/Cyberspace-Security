[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[string]$RunId='EPT-AUTHGATE-20260925-15')
$ErrorActionPreference='Continue'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=ConvertTo-SecureString $pw -AsPlainText -Force
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
try {
  Copy-Item -ToSession $s -Path (Join-Path $runDir 'stack_dump.cdb') -Destination (Join-Path $guestRoot 'stack_dump.cdb') -Force
  Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {
    param($r)
    Get-Process -Name cdb -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 1500
    $ch=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -like 'EPT_*'})
    'child_alive_after_detach=' + (($ch | ForEach-Object {$_.Id}) -join ',')
    if($ch.Count -gt 0){
      $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
      Start-Process -FilePath $cdb -ArgumentList @('-p',[string]$ch[0].Id,'-cf',(Join-Path $r 'stack_dump.cdb')) -WorkingDirectory $r -RedirectStandardOutput (Join-Path $r 'stack_dump.txt') -RedirectStandardError (Join-Path $r 'stack_dump.err') -WindowStyle Hidden | Out-Null
      Start-Sleep -Seconds 10
    }
    if(Test-Path (Join-Path $r 'stack_dump.txt')){ 'stack_dump_bytes=' + (Get-Item (Join-Path $r 'stack_dump.txt')).Length } else { 'stack_dump_missing' }
    'cdb_now=' + (@(Get-Process -Name cdb -ErrorAction SilentlyContinue).Count)
  }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
