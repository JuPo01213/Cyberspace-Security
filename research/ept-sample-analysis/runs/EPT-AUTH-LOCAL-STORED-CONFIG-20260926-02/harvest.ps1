[CmdletBinding()]
param([string]$VmName='<VM_LABEL>',[string]$RunId='EPT-AUTH-LOCAL-STORED-CONFIG-20260926-02')
$ErrorActionPreference='Stop'
$runDir=Split-Path -Parent $MyInvocation.MyCommand.Path
$guestRoot='C:\ept_obs\spool\'+$RunId
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=ConvertTo-SecureString $pw -AsPlainText -Force
$cred=[pscredential]::new('<VM_USER>',$sec)
$mutex=[Threading.Mutex]::new($false,'Local\EPT_C173_VM_writer');$held=$false;$s=$null
try {
    $held=$mutex.WaitOne(0);if(-not $held){throw 'VM writer busy'}
    $s=New-PSSession -VMName $VmName -Credential $cred
    $names=Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)if(-not(Test-Path -LiteralPath $r)){throw "guest run missing: $r"};@(Get-ChildItem -LiteralPath $r -File -Force|Select-Object -ExpandProperty Name)}
    foreach($n in $names){Copy-Item -FromSession $s -LiteralPath ($guestRoot+'\'+$n) -Destination (Join-Path $runDir $n) -Force}
    $guestHashes=Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)@((Get-ChildItem -LiteralPath $r -File -Force|Get-FileHash -Algorithm SHA256)|ForEach-Object{[pscustomobject]@{name=$_.Path.Substring($r.Length+1);sha256=$_.Hash.ToUpperInvariant();length=(Get-Item -LiteralPath $_.Path).Length}})}
    $hostHashes=@();foreach($g in @($guestHashes)){$p=Join-Path $runDir $g.name;if(-not(Test-Path -LiteralPath $p)){throw "harvest missing: $($g.name)"};$h=Get-FileHash -LiteralPath $p -Algorithm SHA256;$hostHashes+=[pscustomobject]@{name=$g.name;guest_sha256=$g.sha256;host_sha256=$h.Hash.ToUpperInvariant();guest_length=$g.length;host_length=(Get-Item $p).Length;match=($h.Hash.ToUpperInvariant() -eq $g.sha256 -and (Get-Item $p).Length -eq $g.length)}}
    if(@($hostHashes|Where-Object{-not $_.match}).Count -gt 0){throw 'harvest hash mismatch'}
    $verify=[ordered]@{run_id=$RunId;guest_root=$guestRoot;harvested_utc=(Get-Date).ToUniversalTime().ToString('o');files=$hostHashes;control='PowerShell Direct';network_scope='excluded';sample_executed='true';hashes_verified='true'}
    $verify|ConvertTo-Json -Depth 12|Set-Content -LiteralPath (Join-Path $runDir 'harvest_verify.json') -Encoding UTF8
    $verify|ConvertTo-Json -Depth 12
}finally{if($s){Remove-PSSession $s};if($held){$mutex.ReleaseMutex()};$mutex.Dispose();$sec.Dispose()}
