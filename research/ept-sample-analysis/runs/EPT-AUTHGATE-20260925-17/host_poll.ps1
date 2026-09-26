[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[int]$WaitSeconds=25)
$ErrorActionPreference='Stop'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=ConvertTo-SecureString $pw -AsPlainText -Force
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
$LF=[char]10
try {
 $o=Invoke-Command -Session $s -ArgumentList $WaitSeconds,$LF -ScriptBlock {param($w,$LF)
  $r='C:\ept_obs\spool\EPT-AUTHGATE-20260925-17'
  $p1=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb)'})
  $c1=($p1|ForEach-Object {"$($_.ProcessName):$($_.Id):cpu=$([math]::Round($_.CPU,2))"}) -join ' | '
  $len1=0;if(Test-Path ($r+'\cdb.stdout.txt')){$len1=(Get-Item ($r+'\cdb.stdout.txt')).Length}
  Start-Sleep -Seconds $w
  $p2=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb)'})
  $c2=($p2|ForEach-Object {"$($_.ProcessName):$($_.Id):cpu=$([math]::Round($_.CPU,2))"}) -join ' | '
  $len2=0;if(Test-Path ($r+'\cdb.stdout.txt')){$len2=(Get-Item ($r+'\cdb.stdout.txt')).Length}
  $flags=@();foreach($x in @('C:\Windows\System32\Logs','C:\Windows\System32\HardwareLogs','C:\Windows\System32\R3.exe','C:\Windows\System32\Hardware.ini','C:\Windows\Temp\HardwareTask.xml')){if(Test-Path $x){$flags+=$x}}
  $tail=''
  try{$fs=[IO.File]::Open(($r+'\cdb.stdout.txt'),'Open','Read','ReadWrite');$rd=New-Object IO.StreamReader($fs);$t=$rd.ReadToEnd();$rd.Close();$fs.Close();$lines=$t -split "\r?\n";$tail=($lines|Select-Object -Last 16) -join $LF}catch{$tail='READ_ERR'}
  "T0: $c1  stats=$len1"
  "T${w}: $c2  stats=$len2"
  "flags: $($flags -join ', ')"
  "--- stdout tail ---"
  $tail
 }
 $o
} finally {Remove-PSSession $s -ErrorAction SilentlyContinue;$sec.Dispose()}
