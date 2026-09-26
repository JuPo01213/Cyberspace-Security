$ErrorActionPreference='Stop'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestDir='C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-32'
$guestDump='C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-18\input.dmp'
$expected='CA0FFCEC87A8580E9BFDEF4DAAF90C97FB06A53D597028020FE1EC714830E60D'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$secure=ConvertTo-SecureString $pw -AsPlainText -Force
$pw=$null
$s=$null
$m=[Threading.Mutex]::new($false,'Local\EPT_C173_VM_writer')
$held=$false
try{
 $held=$m.WaitOne(0)
 if(!$held){throw 'VM writer busy'}
 $s=New-PSSession -VMName '<VM_LABEL>' -Credential ([pscredential]::new('<VM_USER>',$secure))
 $nonce=[guid]::NewGuid().ToString('N')
 $probe=Invoke-Command -Session $s -ArgumentList $guestDir,$nonce -ScriptBlock {param($r,$n) $ErrorActionPreference='Stop';if(Test-Path -LiteralPath $r){throw 'Guest run directory exists'};New-Item -ItemType Directory -Path $r|Out-Null;[IO.File]::WriteAllText(($r+'\canary.txt'),$n,[Text.Encoding]::ASCII);[pscustomobject]@{nonce=$n;sha=(Get-FileHash -LiteralPath ($r+'\canary.txt') -Algorithm SHA256).Hash}}
 Copy-Item -FromSession $s -LiteralPath ($guestDir+'\canary.txt') -Destination (Join-Path $runDir 'canary.txt')
 if($probe.nonce -ne $nonce -or (Get-FileHash -LiteralPath (Join-Path $runDir 'canary.txt') -Algorithm SHA256).Hash -ne $probe.sha){throw 'Canary mismatch'}
 Copy-Item -ToSession $s -LiteralPath (Join-Path $runDir 'loadconfig-chain.cdb') -Destination ($guestDir+'\loadconfig-chain.cdb')
 $result=Invoke-Command -Session $s -ArgumentList $guestDir,$guestDump,$expected -ScriptBlock {
  param($r,$dump,$expected)
  $ErrorActionPreference='Stop'
  if((Get-FileHash -LiteralPath $dump -Algorithm SHA256).Hash -ne $expected){throw 'Input hash mismatch'}
  $env:_NT_SYMBOL_PATH=$r;$env:_NT_ALT_SYMBOL_PATH=$r
  $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
  $start=[datetime]::UtcNow
  $p=New-Object Diagnostics.Process
  $p.StartInfo.FileName=$cdb
  $p.StartInfo.Arguments='-sins -y '+$r+' -z '+$dump+' -cf '+$r+'\loadconfig-chain.cdb'
  $p.StartInfo.UseShellExecute=$false
  $p.StartInfo.CreateNoWindow=$true
  $p.StartInfo.RedirectStandardOutput=$true
  $p.StartInfo.RedirectStandardError=$true
  [void]$p.Start()
  $outTask=$p.StandardOutput.ReadToEndAsync();$errTask=$p.StandardError.ReadToEndAsync()
  $complete=$p.WaitForExit(90000)
  if(!$complete){$p.Kill()}
  $p.WaitForExit()
  [IO.File]::WriteAllText(($r+'\offline.stdout.txt'),$outTask.Result,[Text.Encoding]::UTF8)
  [IO.File]::WriteAllText(($r+'\offline.stderr.txt'),$errTask.Result,[Text.Encoding]::UTF8)
  $v=[pscustomobject]@{mode='offline_dump_only';input_sha256=$expected;sample_launched=$false;patches_applied=$false;completed=$complete;exit_code=$p.ExitCode;elapsed_sec=([datetime]::UtcNow-$start).TotalSeconds;cdb_version=(Get-Item -LiteralPath $cdb).VersionInfo.FileVersion;stdout_sha256=(Get-FileHash -LiteralPath ($r+'\offline.stdout.txt') -Algorithm SHA256).Hash}
  $v|ConvertTo-Json|Set-Content -LiteralPath ($r+'\result.json') -Encoding UTF8
  $p.Dispose();$v
 }
 foreach($n in @('offline.stdout.txt','offline.stderr.txt','result.json')){Copy-Item -FromSession $s -LiteralPath ($guestDir+'\'+$n) -Destination (Join-Path $runDir $n)}
 if((Get-FileHash -LiteralPath (Join-Path $runDir 'offline.stdout.txt') -Algorithm SHA256).Hash -ne $result.stdout_sha256){throw 'Output hash mismatch'}
 $text=[IO.File]::ReadAllText((Join-Path $runDir 'offline.stdout.txt'))
 if(!$result.completed -or $result.exit_code -ne 0 -or $text -notmatch '(?m)^LOCAL_LOADCONFIG_CHAIN_END\s*$'){throw 'Offline pass incomplete'}
 $result|ConvertTo-Json
}finally{if($s){Remove-PSSession $s};if($held){$m.ReleaseMutex()};$m.Dispose();$secure.Dispose()}
