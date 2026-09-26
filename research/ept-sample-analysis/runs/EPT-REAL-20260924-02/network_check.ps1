[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-REAL-20260924-02'
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    $guest = Invoke-Command -Session $s -ArgumentList $RunId -ScriptBlock {
        param($RunId)
        $now = (Get-Date).ToUniversalTime().ToString('o')
        $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Select-Object Name,Status,ifIndex,MacAddress,InterfaceDescription)
        $ip = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object InterfaceAlias,IPAddress,PrefixLength)
        $routes = @(Get-NetRoute -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object DestinationPrefix,NextHop,InterfaceAlias,RouteMetric)
        $probes = @()
        foreach ($target in @('<PRIVATE_IP>','1.1.1.1','198.18.0.1')) {
            $r = [ordered]@{ target = $target; ping = $null; tcp80 = $null; error = $null }
            try {
                $pingClient = New-Object System.Net.NetworkInformation.Ping
                $reply = $pingClient.Send($target, 1000)
                $r.ping = ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success)
            } catch { $r.error = $_.Exception.Message }
            try {
                $client = New-Object System.Net.Sockets.TcpClient
                $async = $client.BeginConnect($target, 80, $null, $null)
                $r.tcp80 = $async.AsyncWaitHandle.WaitOne(2000) -and $client.Connected
                $client.Close()
            } catch { $r.error = $_.Exception.Message }
            $probes += [pscustomobject]$r
        }
        $dns = $null
        try { $dns = @(Resolve-DnsName -Name example.com -Type A -ErrorAction Stop | Select-Object -First 3 Name,IPAddress) } catch { $dns = @([pscustomobject]@{ error = $_.Exception.Message }) }
        $defaultRoute = @($routes | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' })
        [pscustomobject]@{
            run_id = $RunId
            guest_host = $env:COMPUTERNAME
            utc = $now
            adapters = $adapters
            ipv4 = $ip
            routes = $routes
            default_route = $defaultRoute
            external_probes = $probes
            dns = $dns
            interpretation = 'Hyper-V adapter state and actual probe results are recorded separately; stale guest IP/routes alone are not treated as connectivity.'
        }
    }
    $out = $guest | ConvertTo-Json -Depth 12
    $path = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'network_check.json'
    [System.IO.File]::WriteAllText($path, $out, [System.Text.UTF8Encoding]::new($false))
    $out
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
