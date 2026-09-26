# Host Authority preflight probe for EPT-C175-COREHARNESS-01
# Control plane: PowerShell Direct (New-PSSession -VMName)
# Data plane: PSSession Copy-Item Host->Guest + readback
# Credential is read at runtime from the existing host-secrets file; never persisted.
$ErrorActionPreference = "Stop"

$pwPath = "<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt"
if (-not (Test-Path $pwPath)) { throw "host-secrets password file missing: $pwPath" }
$pw = (Get-Content $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("<VM_USER>", $sec)
$vm = "<VM_LABEL>"

function Probe-Round {
    param([int]$round, [string]$hostCanaryFile)
    $s = New-PSSession -VMName $vm -Credential $cred
    try {
        $out = Invoke-Command -Session $s -ArgumentList $round, $hostCanaryFile -ScriptBlock {
            param($round, $hostCanaryFile)
            $r = @{}
            $r.computerName = $env:COMPUTERNAME
            $os = Get-CimInstance Win32_OperatingSystem
            $r.osCaption = $os.Caption
            $r.osVersion = $os.Version
            $r.psVersion = $PSVersionTable.PSVersion.ToString()
            $r.readyMarker = Test-Path "C:\<VM_LABEL>_guest_ready.txt"
            $stub = Get-Item "<HOST_PATH>\Users\<USER>\AppData\Local\Microsoft\WindowsApps\python.exe" -ErrorAction SilentlyContinue
            $r.python_stub_length = if ($stub) { $stub.Length } else { $null }
            $found = @()
            foreach ($p in @("C:\Python*\python.exe","C:\ept_obs\python\python.exe","<HOST_PATH>\Users\<USER>\AppData\Local\Programs\Python\*\python.exe")) {
                $found += (Resolve-Path $p -ErrorAction SilentlyContinue | ForEach-Object { $_.Path })
            }
            $r.python_real_found = $found
            $r.system_drive_free_gb = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
            New-Item -ItemType Directory -Force -Path "C:\ept_obs\spool" | Out-Null
            $canary = "C175-PROBE-$round-$(Get-Date -Format yyyyMMddHHmmss)"
            $canaryPath = "C:\ept_obs\spool\canary_$round.txt"
            Set-Content -Path $canaryPath -Value $canary -Encoding ASCII
            $r.canary_written = $canary
            $r.canary_guest_readback = (Get-Content $canaryPath -Raw).Trim()
            $r.canary_guest_match = ($r.canary_written -eq $r.canary_guest_readback)
            # data-plane: read back the file copied from Host by the caller
            if ($hostCanaryFile) {
                $r.datacanary_guest_present = Test-Path "C:\ept_obs\spool\host_canary.txt"
                if ($r.datacanary_guest_present) {
                    $r.datacanary_guest_readback = (Get-Content "C:\ept_obs\spool\host_canary.txt" -Raw).Trim()
                    $r.datacanary_guest_match = ($r.datacanary_guest_readback -eq "HOST-CANARY-C175")
                }
            }
            $r.process_count = (Get-Process).Count
            $r.python_process_count = (Get-Process -Name python -ErrorAction SilentlyContinue).Count
            $r
        }
        # Data-plane Copy-Item test Host -> Guest (only meaningful on round 1; re-checked round 2 readback)
        if ($round -eq 1) {
            Copy-Item -ToSession $s -Path $hostCanaryFile -Destination "C:\ept_obs\spool\host_canary.txt" -Force
        }
        return $out
    } finally {
        Remove-PSSession $s -ErrorAction SilentlyContinue
    }
}

# Host-side canary file for data-plane test
$hostCanary = "<HOST_PATH>/EPT/runs/EPT-C175-COREHARNESS-01/host_canary.txt"
Set-Content -Path $hostCanary -Value "HOST-CANARY-C175" -Encoding ASCII

$result = @{
    run_id   = "EPT-C175-COREHARNESS-01"
    vm       = $vm
    round1   = Probe-Round 1 $hostCanary
    round2   = Probe-Round 2 $null
}
$json = $result | ConvertTo-Json -Depth 6 -Compress
$json | Out-File -FilePath "<HOST_PATH>/EPT/runs/EPT-C175-COREHARNESS-01/probe_result.json" -Encoding utf8
Write-Output $json
