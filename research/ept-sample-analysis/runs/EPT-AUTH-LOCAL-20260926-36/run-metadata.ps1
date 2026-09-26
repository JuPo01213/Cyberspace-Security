$ErrorActionPreference='Stop'
$r=Split-Path -Parent $MyInvocation.MyCommand.Path
$g='C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-36'
$source='<HOST_PATH>\EPT\runs\EPT-AUTH-LOCAL-20260926-20'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$ss=ConvertTo-SecureString $pw -AsPlainText -Force
$pw=$null;$s=$null;$m=[Threading.Mutex]::new($false,'Local\EPT_C173_VM_writer');$held=$false
try {
  $held=$m.WaitOne(0);if(!$held){throw 'VM writer busy'}
  $s=New-PSSession -VMName '<VM_LABEL>' -Credential ([pscredential]::new('<VM_USER>',$ss))
  Invoke-Command -Session $s -ArgumentList $g -ScriptBlock {
    param($g)
    $ErrorActionPreference='Stop'
    if(Test-Path -LiteralPath $g){throw 'Run exists'}
    New-Item -ItemType Directory -Path $g|Out-Null
  }
  Copy-Item -ToSession $s -LiteralPath (Join-Path $r 'field-metadata.ps1') -Destination ($g+'\field-metadata.ps1') -Force
  foreach($n in @('embedded-key.bin','embedded-iv.bin','historical-config.bin')){
    Copy-Item -ToSession $s -LiteralPath (Join-Path $source $n) -Destination ($g+'\'+$n) -Force
  }
  $o=Invoke-Command -Session $s -FilePath (Join-Path $r 'field-metadata.ps1') -ArgumentList $g
  $h=Invoke-Command -Session $s -ArgumentList $g -ScriptBlock {param($g)(Get-FileHash -LiteralPath ($g+'\field-metadata.json') -Algorithm SHA256).Hash}
  Copy-Item -FromSession $s -LiteralPath ($g+'\field-metadata.json') -Destination (Join-Path $r 'field-metadata.json') -Force
  if((Get-FileHash -LiteralPath (Join-Path $r 'field-metadata.json') -Algorithm SHA256).Hash -ne $h){throw 'Hash mismatch'}
  $o
} finally {
  if($s){Remove-PSSession $s}
  if($held){$m.ReleaseMutex()}
  $m.Dispose();$ss.Dispose()
}
