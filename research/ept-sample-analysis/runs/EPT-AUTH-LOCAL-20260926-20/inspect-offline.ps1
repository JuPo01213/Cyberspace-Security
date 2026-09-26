$ErrorActionPreference='Stop'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestDir='C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-20'
$guestDump='C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-18\input.dmp'
$expected='CA0FFCEC87A8580E9BFDEF4DAAF90C97FB06A53D597028020FE1EC714830E60D'
$cfg='<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260925-65\captured\SYS32_Hardware.bin'
$cfgHash=(Get-FileHash -LiteralPath $cfg -Algorithm SHA256).Hash
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$secure=ConvertTo-SecureString $pw -AsPlainText -Force;$pw=$null
$s=$null;$m=[Threading.Mutex]::new($false,'Local\EPT_C173_VM_writer');$held=$false
try{
 $held=$m.WaitOne(0);if(!$held){throw 'VM writer busy'}
 $s=New-PSSession -VMName '<VM_LABEL>' -Credential ([pscredential]::new('<VM_USER>',$secure))
 $nonce=[guid]::NewGuid().ToString('N')
 $probe=Invoke-Command -Session $s -ArgumentList $guestDir,$nonce -ScriptBlock {param($r,$n)$ErrorActionPreference='Stop';if(Test-Path -LiteralPath $r){throw 'Guest run directory exists'};New-Item -ItemType Directory -Path $r|Out-Null;[IO.File]::WriteAllText(($r+'\canary.txt'),$n,[Text.Encoding]::ASCII);[pscustomobject]@{nonce=$n;sha=(Get-FileHash -LiteralPath ($r+'\canary.txt') -Algorithm SHA256).Hash}}
 Copy-Item -FromSession $s -LiteralPath ($guestDir+'\canary.txt') -Destination (Join-Path $runDir 'canary.txt')
 if($probe.nonce -ne $nonce -or (Get-FileHash -LiteralPath (Join-Path $runDir 'canary.txt') -Algorithm SHA256).Hash -ne $probe.sha){throw 'Canary mismatch'}
 foreach($n in @('offline-material.cdb','analyze-config.ps1')){Copy-Item -ToSession $s -LiteralPath (Join-Path $runDir $n) -Destination ($guestDir+'\'+$n)}
 Copy-Item -ToSession $s -LiteralPath $cfg -Destination ($guestDir+'\historical-config.bin')
 $result=Invoke-Command -Session $s -ArgumentList $guestDir,$guestDump,$expected,$cfgHash -ScriptBlock {
  param($r,$dump,$expected,$cfgHash)
  $ErrorActionPreference='Stop'
  if((Get-FileHash -LiteralPath $dump -Algorithm SHA256).Hash -ne $expected){throw 'Dump hash mismatch'}
  if((Get-FileHash -LiteralPath ($r+'\historical-config.bin') -Algorithm SHA256).Hash -ne $cfgHash){throw 'Configuration hash mismatch'}
  $env:_NT_SYMBOL_PATH=$r;$env:_NT_ALT_SYMBOL_PATH=$r
  $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
  $p=New-Object Diagnostics.Process;$p.StartInfo.FileName=$cdb
  $p.StartInfo.Arguments='-sins -y '+$r+' -z '+$dump+' -cf '+$r+'\offline-material.cdb'
  $p.StartInfo.UseShellExecute=$false;$p.StartInfo.CreateNoWindow=$true
  $p.StartInfo.RedirectStandardOutput=$true;$p.StartInfo.RedirectStandardError=$true
  [void]$p.Start();$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync()
  $completed=$p.WaitForExit(90000);if(!$completed){$p.Kill()};$p.WaitForExit()
  [IO.File]::WriteAllText(($r+'\offline.stdout.txt'),$o.Result,[Text.Encoding]::UTF8)
  [IO.File]::WriteAllText(($r+'\offline.stderr.txt'),$e.Result,[Text.Encoding]::UTF8)
  $exitCode=$p.ExitCode;$p.Dispose()
  if(!$completed -or $exitCode -ne 0){throw 'Offline debugger did not finish'}
  $analysisStatus='FAILED';$analysisError=$null
  try{& ($r+'\analyze-config.ps1') -Root $r|Out-Null;$analysisStatus='COMPLETED'}catch{$analysisError=$_.Exception.Message}
  $v=[ordered]@{mode='offline_dump_and_configuration_only';input_dump_sha256=$expected;configuration_sha256=$cfgHash;sample_executed=$false;patches_applied=$false;exit_code=$exitCode;analysis_status=$analysisStatus;analysis_error=$analysisError;outputs=@(Get-ChildItem -LiteralPath $r -File|Where-Object{$_.Name -in @('offline.stdout.txt','offline.stderr.txt','config-analysis.json')}|ForEach-Object{[pscustomobject]@{name=$_.Name;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}})}
  $v|ConvertTo-Json -Depth 5|Set-Content -LiteralPath ($r+'\result.json') -Encoding UTF8
  [pscustomobject]$v
 }
 foreach($f in $result.outputs){Copy-Item -FromSession $s -LiteralPath ($guestDir+'\'+$f.name) -Destination (Join-Path $runDir $f.name);if((Get-FileHash -LiteralPath (Join-Path $runDir $f.name) -Algorithm SHA256).Hash -ne $f.sha256){throw 'Output hash mismatch'}}
 Copy-Item -FromSession $s -LiteralPath ($guestDir+'\result.json') -Destination (Join-Path $runDir 'result.json')
 $result|Select-Object mode,input_dump_sha256,configuration_sha256,sample_executed,patches_applied,exit_code,analysis_status,analysis_error,outputs|ConvertTo-Json -Depth 5
 if($result.analysis_status -ne 'COMPLETED'){throw $result.analysis_error}
}finally{if($s){Remove-PSSession $s};if($held){$m.ReleaseMutex()};$m.Dispose();$secure.Dispose()}
