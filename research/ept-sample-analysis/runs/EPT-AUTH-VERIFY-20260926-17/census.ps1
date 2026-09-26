$ErrorActionPreference = 'Stop'
$runDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$secret = (Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$secure = ConvertTo-SecureString $secret -AsPlainText -Force
$secret = $null
$credential = [pscredential]::new('<VM_USER>', $secure)
$session = $null
try {
    $session = New-PSSession -VMName '<VM_LABEL>' -Credential $credential
    $nonce = [guid]::NewGuid().ToString('N')
    $result = Invoke-Command -Session $session -ArgumentList $nonce -ScriptBlock {
        param($nonce)
        $ErrorActionPreference = 'Stop'
        $processes = @(Get-CimInstance Win32_Process | Where-Object {
            $_.Name -match '^(Hardware|EPT_|cdb|windbg)' -or
            ($_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'watcher\.ps1|tcp1029\.ps1|guest_launch\.ps1')
        } | Select-Object Name,ProcessId,ParentProcessId,ExecutablePath)
        $tools = @('C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe','C:\Python313\python.exe','C:\Python312\python.exe','C:\Tools','C:\ept_tools','C:\ept_core') | ForEach-Object {
            [pscustomobject]@{path=$_;exists=(Test-Path -LiteralPath $_)}
        }
        $paths = @('C:\ept_core\Hardware.exe','C:\Windows\System32\Hardware.exe','C:\Windows\System32\Hardware.ini','C:\Windows\System32\Hardware','C:\Windows\System32\EPT.cmd')
        $files = foreach($path in $paths) {
            if(Test-Path -LiteralPath $path -PathType Leaf) {
                $item=Get-Item -LiteralPath $path
                [pscustomobject]@{path=$path;length=$item.Length;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;last_write_utc=$item.LastWriteTimeUtc.ToString('o')}
            }
        }
        [pscustomobject]@{
            nonce=$nonce
            captured_at_utc=[datetime]::UtcNow.ToString('o')
            guest=$env:COMPUTERNAME
            processes=$processes
            adapters=@(Get-NetAdapter | Select-Object Name,Status)
            default_routes=@(Get-NetRoute | Where-Object {$_.DestinationPrefix -in @('0.0.0.0/0','::/0')} | Select-Object DestinationPrefix,NextHop,InterfaceAlias)
            listeners=@(Get-NetTCPConnection -State Listen | Where-Object LocalPort -eq 1029 | Select-Object LocalAddress,LocalPort,OwningProcess)
            drivers=@(Get-CimInstance Win32_SystemDriver | Where-Object {$_.Name -match 'HpDrv|HP_WKS|SWTOOLS|AntiCheatExpert'} | Select-Object Name,State,StartMode,PathName)
            tasks=@(Get-ScheduledTask | Where-Object {$_.TaskName -match '^EPT-|^Hardware$'} | Select-Object TaskName,TaskPath,State)
            artifacts=@($files)
            tools=@($tools)
            roots=@(Get-ChildItem -LiteralPath 'C:\' -Directory | Select-Object -ExpandProperty Name)
        }
    }
    if($result.nonce -ne $nonce){throw 'Control nonce mismatch'}
    $result | Select-Object nonce,captured_at_utc,guest,processes,adapters,default_routes,listeners,drivers,tasks,artifacts,tools,roots | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $runDir 'guest-census.json') -Encoding UTF8
    'CONTROL_CANARY_OK'
    $result | Select-Object captured_at_utc,processes,adapters,listeners,drivers,tasks,artifacts,tools,roots | ConvertTo-Json -Depth 7
} finally {
    if($session){Remove-PSSession $session}
    $secure.Dispose()
}
