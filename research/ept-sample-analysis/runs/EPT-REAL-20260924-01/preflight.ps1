$ErrorActionPreference = "Stop"
$pwPath = "<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt"
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("<VM_USER>", $sec)
$vm = "<VM_LABEL>"
$s = New-PSSession -VMName $vm -Credential $cred
try {
    $result = Invoke-Command -Session $s -ScriptBlock {
        $candidateFiles = @(
            "C:\ept_core\Hardware.exe",
            "C:\Windows\System32\Hardware.exe",
            "C:\Windows\System32\EPT_HWID.exe",
            "<HOST_PATH>\Users\<USER>\Desktop\EPT专业游戏维修工具箱V5.1.exe",
            "<HOST_PATH>\Users\<USER>\Desktop\Hardware.exe",
            "<HOST_PATH>\Users\<USER>\Downloads\Hardware.exe"
        )
        $files = foreach ($path in $candidateFiles) {
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                $item = Get-Item -LiteralPath $path
                $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
                [pscustomobject]@{
                    path = $path
                    exists = $true
                    length = $item.Length
                    sha256 = $hash
                    last_write_utc = $item.LastWriteTimeUtc.ToString("o")
                }
            } else {
                [pscustomobject]@{ path = $path; exists = $false }
            }
        }
        $dirs = foreach ($path in @("C:\ept_obs", "C:\ept_core", "C:\HexPatch\tools", "<HOST_PATH>\Users\<USER>\Desktop", "<HOST_PATH>\Users\<USER>\Downloads")) {
            if (Test-Path -LiteralPath $path -PathType Container) {
                [pscustomobject]@{
                    path = $path
                    exists = $true
                    items = @(Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue | Select-Object -First 80 Name,Length,LastWriteTimeUtc,Attributes)
                }
            } else {
                [pscustomobject]@{ path = $path; exists = $false }
            }
        }
        $processes = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match "^(Hardware|EPT|UVT|Hp|cdb|windbg|python)$" } | ForEach-Object {
            [pscustomobject]@{ id = $_.Id; name = $_.ProcessName; path = $_.Path; start_time = try { $_.StartTime.ToUniversalTime().ToString("o") } catch { $null } }
        })
        $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Select-Object Name,Status,MacAddress,ifIndex,InterfaceDescription)
        $ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object InterfaceAlias,IPAddress,PrefixLength)
        $routes = @(Get-NetRoute -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object DestinationPrefix,NextHop,InterfaceAlias,RouteMetric)
        $firewall = @(Get-NetFirewallProfile -ErrorAction SilentlyContinue | Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction)
        [pscustomobject]@{
            computer = $env:COMPUTERNAME
            user = $env:USERNAME
            utc = (Get-Date).ToUniversalTime().ToString("o")
            files = $files
            directories = $dirs
            processes = $processes
            adapters = $adapters
            ipv4 = $ips
            routes = $routes
            firewall = $firewall
        }
    }
    $result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath "<HOST_PATH>/EPT/runs/EPT-REAL-20260924-01/preflight.json" -Encoding UTF8
    $result | ConvertTo-Json -Depth 10
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
}
