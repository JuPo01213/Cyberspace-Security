$ErrorActionPreference = 'Stop'
$runDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$guestDir = 'C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-18'
$dump = '<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260925-82\child_full_recv2.dmp'
$expectedHash = 'CA0FFCEC87A8580E9BFDEF4DAAF90C97FB06A53D597028020FE1EC714830E60D'
$actualHash = (Get-FileHash -LiteralPath $dump -Algorithm SHA256).Hash
if($actualHash -ne $expectedHash){throw 'Historical dump hash mismatch'}
$secret = (Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$secure = ConvertTo-SecureString $secret -AsPlainText -Force
$secret = $null
$credential = [pscredential]::new('<VM_USER>',$secure)
$session = $null
$lock = [Threading.Mutex]::new($false,'Local\EPT_C173_VM_writer')
$held = $false
try {
    $held = $lock.WaitOne(0)
    if(!$held){throw 'VM writer busy'}
    $session = New-PSSession -VMName '<VM_LABEL>' -Credential $credential
    $nonce = [guid]::NewGuid().ToString('N')
    $probe = Invoke-Command -Session $session -ArgumentList $guestDir,$nonce -ScriptBlock {
        param($root,$nonce)
        $ErrorActionPreference = 'Stop'
        if(Test-Path -LiteralPath $root){throw 'Guest run directory already exists'}
        New-Item -ItemType Directory -Path $root | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'canary.txt'),$nonce,[Text.Encoding]::ASCII)
        [pscustomobject]@{nonce=$nonce;hash=(Get-FileHash -LiteralPath (Join-Path $root 'canary.txt') -Algorithm SHA256).Hash}
    }
    if($probe.nonce -ne $nonce){throw 'Control canary mismatch'}
    Copy-Item -FromSession $session -LiteralPath ($guestDir+'\canary.txt') -Destination (Join-Path $runDir 'canary.txt')
    if((Get-FileHash -LiteralPath (Join-Path $runDir 'canary.txt') -Algorithm SHA256).Hash -ne $probe.hash){throw 'Data canary mismatch'}
    'CONTROL_DATA_CANARY_OK'
    Copy-Item -ToSession $session -LiteralPath $dump -Destination ($guestDir+'\input.dmp')
    Copy-Item -ToSession $session -LiteralPath (Join-Path $runDir 'offline-config.cdb') -Destination ($guestDir+'\offline-config.cdb')
    $result = Invoke-Command -Session $session -ArgumentList $guestDir,$expectedHash -ScriptBlock {
        param($root,$expected)
        $ErrorActionPreference = 'Stop'
        if((Get-FileHash -LiteralPath ($root+'\input.dmp') -Algorithm SHA256).Hash -ne $expected){throw 'Guest dump hash mismatch'}
        $env:_NT_SYMBOL_PATH=$root
        $env:_NT_ALT_SYMBOL_PATH=$root
        $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
        $started=[datetime]::UtcNow
        $p=Start-Process -FilePath $cdb -ArgumentList @('-sins','-y',$root,'-z',($root+'\input.dmp'),'-cf',($root+'\offline-config.cdb')) -RedirectStandardOutput ($root+'\offline.stdout.txt') -RedirectStandardError ($root+'\offline.stderr.txt') -PassThru -WindowStyle Hidden
        $completed=$p.WaitForExit(90000)
        if(!$completed){Stop-Process -Id $p.Id -Force; $p.WaitForExit()}
        $record=[pscustomobject]@{input_sha256=$expected;mode='offline_dump_only';sample_launched=$false;patches_applied=$false;completed=$completed;exit_code=$p.ExitCode;started_at_utc=$started.ToString('o');elapsed_sec=([datetime]::UtcNow-$started).TotalSeconds;cdb_version=(Get-Item -LiteralPath $cdb).VersionInfo.FileVersion;stdout_sha256=(Get-FileHash -LiteralPath ($root+'\offline.stdout.txt') -Algorithm SHA256).Hash}
        $record | ConvertTo-Json | Set-Content -LiteralPath ($root+'\result.json') -Encoding UTF8
        $record
    }
    foreach($name in @('offline.stdout.txt','offline.stderr.txt','result.json')){
        Copy-Item -FromSession $session -LiteralPath ($guestDir+'\'+$name) -Destination (Join-Path $runDir $name)
    }
    if((Get-FileHash -LiteralPath (Join-Path $runDir 'offline.stdout.txt') -Algorithm SHA256).Hash -ne $result.stdout_sha256){throw 'Output hash mismatch'}
    $text=[IO.File]::ReadAllText((Join-Path $runDir 'offline.stdout.txt'))
    if(!$result.completed -or $text -notmatch '(?m)^LOCAL_CONFIG_OFFLINE_END\s*$'){throw 'Offline analysis incomplete'}
    $result | ConvertTo-Json
} finally {
    if($session){Remove-PSSession $session}
    if($held){$lock.ReleaseMutex()}
    $lock.Dispose()
    $secure.Dispose()
}
