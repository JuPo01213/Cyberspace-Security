$ErrorActionPreference='Stop'
$r=Split-Path -Parent $MyInvocation.MyCommand.Path;$g='C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-30'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim();$ss=ConvertTo-SecureString $pw -AsPlainText -Force;$pw=$null
$s=$null;$m=[Threading.Mutex]::new($false,'Local\EPT_C173_VM_writer');$held=$false
try{
 $held=$m.WaitOne(0);if(!$held){throw 'VM writer busy'}
 $s=New-PSSession -VMName '<VM_LABEL>' -Credential ([pscredential]::new('<VM_USER>',$ss))
 $nonce=[guid]::NewGuid().ToString('N')
 Invoke-Command -Session $s -ArgumentList $g,$nonce -ScriptBlock {param($g,$n)$ErrorActionPreference='Stop';if(Test-Path -LiteralPath $g){throw 'Run exists'};New-Item -ItemType Directory -Path $g|Out-Null;[IO.File]::WriteAllText(($g+'\canary.txt'),$n,[Text.Encoding]::ASCII)}
 Copy-Item -FromSession $s -LiteralPath ($g+'\canary.txt') -Destination ($r+'\canary.txt')
 if([IO.File]::ReadAllText(($r+'\canary.txt')) -ne $nonce){throw 'Data canary failed'}
 Copy-Item -ToSession $s -LiteralPath ($r+'\scan-protected.py') -Destination ($g+'\scan-protected.py')
 Copy-Item -ToSession $s -LiteralPath '<HOST_PATH>\EPT\method\scripts\mdmp_read.py' -Destination ($g+'\mdmp_read.py')
 $v=Invoke-Command -Session $s -ArgumentList $g -ScriptBlock {
  param($g)
  $ErrorActionPreference='Stop';$python='C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-28\python\python.exe'
  & $python -I 'C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-28\canary.py' | Out-Null
  if($LASTEXITCODE -ne 0){throw 'Offline Python canary failed'}
  $p=New-Object Diagnostics.Process;$p.StartInfo.FileName=$python
  $p.StartInfo.Arguments='-E -s '+$g+'\scan-protected.py '+$g+' C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-18\input.dmp'
  $p.StartInfo.UseShellExecute=$false;$p.StartInfo.CreateNoWindow=$true;$p.StartInfo.RedirectStandardOutput=$true;$p.StartInfo.RedirectStandardError=$true
  $start=[datetime]::UtcNow;[void]$p.Start();$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$ok=$p.WaitForExit(180000)
  if(!$ok){$p.Kill()};$p.WaitForExit()
  [IO.File]::WriteAllText(($g+'\scan.stdout.txt'),$out.Result,[Text.Encoding]::UTF8);[IO.File]::WriteAllText(($g+'\scan.stderr.txt'),$err.Result,[Text.Encoding]::UTF8)
  $v=[pscustomobject]@{mode='offline_dump_scan';complete=$ok;exit_code=$p.ExitCode;elapsed_sec=([datetime]::UtcNow-$start).TotalSeconds;sample_executed=$false;outputs=@(Get-ChildItem -LiteralPath $g -File|Where-Object{$_.Name -in @('scan.stdout.txt','scan.stderr.txt','protected-references.json')}|ForEach-Object{[pscustomobject]@{name=$_.Name;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}})}
  $v|ConvertTo-Json -Depth 5|Set-Content -LiteralPath ($g+'\result.json') -Encoding UTF8;$p.Dispose();$v
 }
 foreach($f in $v.outputs){Copy-Item -FromSession $s -LiteralPath ($g+'\'+$f.name) -Destination ($r+'\'+$f.name);if((Get-FileHash -LiteralPath ($r+'\'+$f.name) -Algorithm SHA256).Hash -ne $f.sha256){throw 'Output hash mismatch'}}
 Copy-Item -FromSession $s -LiteralPath ($g+'\result.json') -Destination ($r+'\result.json')
 $v|Select-Object mode,complete,exit_code,elapsed_sec,sample_executed,outputs|ConvertTo-Json -Depth 5
 if(!$v.complete -or $v.exit_code -ne 0){throw 'Offline scan incomplete'}
}finally{if($s){Remove-PSSession $s};if($held){$m.ReleaseMutex()};$m.Dispose();$ss.Dispose()}
