$ErrorActionPreference='Stop'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestDir='C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-34'
$sourceDumps=@(
  @{host='<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260925-82\child_full_recv2.dmp';name='recv2.dmp';sha='CA0FFCEC87A8580E9BFDEF4DAAF90C97FB06A53D597028020FE1EC714830E60D'},
  @{host='<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260926-15\early_death.dmp';name='early-death.dmp';sha=$null},
  @{host='<HOST_PATH>\EPT\runs\EPT-INJECT-20260925-23\harvest\mem_parent.dmp';name='mem-parent.dmp';sha=$null}
)
foreach($d in $sourceDumps){if(!(Test-Path -LiteralPath $d.host)){throw ('Missing input: '+$d.host)};$d.sha=(Get-FileHash -LiteralPath $d.host -Algorithm SHA256).Hash}
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim();$ss=ConvertTo-SecureString $pw -AsPlainText -Force;$pw=$null
$s=$null;$mutex=[Threading.Mutex]::new($false,'Local\EPT_C173_VM_writer');$held=$false
try{
 $held=$mutex.WaitOne(0);if(!$held){throw 'VM writer busy'}
 $s=New-PSSession -VMName '<VM_LABEL>' -Credential ([pscredential]::new('<VM_USER>',$ss))
 Invoke-Command -Session $s -ArgumentList $guestDir -ScriptBlock {param($g)$ErrorActionPreference='Stop';if(Test-Path -LiteralPath $g){throw 'Run directory exists'};New-Item -ItemType Directory -Path $g|Out-Null}
 Copy-Item -ToSession $s -LiteralPath (Join-Path $runDir 'compare-globals.py') -Destination ($guestDir+'\compare-globals.py')
 Copy-Item -ToSession $s -LiteralPath '<HOST_PATH>\EPT\method\scripts\mdmp_read.py' -Destination ($guestDir+'\mdmp_read.py')
 foreach($d in $sourceDumps){Copy-Item -ToSession $s -LiteralPath $d.host -Destination ($guestDir+'\'+$d.name);$actual=Invoke-Command -Session $s -ArgumentList $guestDir,$d.name -ScriptBlock {param($g,$n)(Get-FileHash -LiteralPath ($g+'\'+$n) -Algorithm SHA256).Hash};if($actual -ne $d.sha){throw ('Guest hash mismatch: '+$d.name)}}
 $result=Invoke-Command -Session $s -ArgumentList $guestDir -ScriptBlock {
  param($g)
  $ErrorActionPreference='Stop'
  $python='C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-28\python\python.exe'
  & $python -E -s ($g+'\compare-globals.py') $g ($g+'\recv2.dmp') ($g+'\early-death.dmp') ($g+'\mem-parent.dmp')
  if($LASTEXITCODE -ne 0){throw 'Comparison script failed'}
  [pscustomobject]@{mode='offline_historical_dump_comparison';sample_executed=$false;report_sha256=(Get-FileHash -LiteralPath ($g+'\global-comparison.json') -Algorithm SHA256).Hash}
 }
 Copy-Item -FromSession $s -LiteralPath ($guestDir+'\global-comparison.json') -Destination (Join-Path $runDir 'global-comparison.json')
 if((Get-FileHash -LiteralPath (Join-Path $runDir 'global-comparison.json') -Algorithm SHA256).Hash -ne $result.report_sha256){throw 'Report hash mismatch'}
 $result|ConvertTo-Json
}finally{if($s){Remove-PSSession $s};if($held){$mutex.ReleaseMutex()};$mutex.Dispose();$ss.Dispose()}
