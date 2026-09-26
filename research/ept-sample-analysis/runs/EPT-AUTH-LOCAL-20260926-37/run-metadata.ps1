$ErrorActionPreference = 'Stop'
$runDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$guestDir = 'C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-37'
$sourceGuest = 'C:\ept_obs\spool\EPT-AUTH-LOCAL-20260926-20'
$pw = (Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$secure = ConvertTo-SecureString $pw -AsPlainText -Force
$pw = $null
$session = $null
$mutex = [Threading.Mutex]::new($false, 'Local\EPT_C173_VM_writer')
$held = $false
try {
    $held = $mutex.WaitOne(0)
    if(!$held) { throw 'VM writer busy' }
    $session = New-PSSession -VMName '<VM_LABEL>' -Credential ([pscredential]::new('<VM_USER>', $secure))
    $nonce = [guid]::NewGuid().ToString('N')
    Invoke-Command -Session $session -ArgumentList $guestDir,$nonce -ScriptBlock {
        param($root,$nonce)
        $ErrorActionPreference = 'Stop'
        if(Test-Path -LiteralPath $root) { throw 'Run directory exists' }
        New-Item -ItemType Directory -Path $root | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'canary.txt'), $nonce, [Text.Encoding]::ASCII)
    }
    Copy-Item -FromSession $session -LiteralPath (Join-Path $guestDir 'canary.txt') -Destination (Join-Path $runDir 'canary.txt')
    if([IO.File]::ReadAllText((Join-Path $runDir 'canary.txt')) -ne $nonce) { throw 'Data canary failed' }
    Copy-Item -ToSession $session -LiteralPath (Join-Path $runDir 'field-metadata.ps1') -Destination (Join-Path $guestDir 'field-metadata.ps1') -Force
    $output = Join-Path $guestDir 'field-metadata.json'
    $message = Invoke-Command -Session $session -FilePath (Join-Path $runDir 'field-metadata.ps1') -ArgumentList $sourceGuest,$output
    $guestHash = Invoke-Command -Session $session -ArgumentList $output -ScriptBlock { param($path) (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
    Copy-Item -FromSession $session -LiteralPath $output -Destination (Join-Path $runDir 'field-metadata.json') -Force
    $hostHash = (Get-FileHash -LiteralPath (Join-Path $runDir 'field-metadata.json') -Algorithm SHA256).Hash
    if($hostHash -ne $guestHash) { throw 'Metadata hash mismatch' }
    [ordered]@{
        mode = 'offline_configuration_field_metadata'
        sample_executed = $false
        validation_result_modified = $false
        report_sha256 = $hostHash
        guest_message = [string]$message
    } | ConvertTo-Json
} finally {
    if($session) { Remove-PSSession $session }
    if($held) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
    $secure.Dispose()
}
