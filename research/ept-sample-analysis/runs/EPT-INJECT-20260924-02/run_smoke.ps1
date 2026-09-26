[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260924-02'
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$root = 'C:\ept_obs\smoke\' + $RunId
$cmdPath = $root + '\parent.cdb'
$childPath = $root + '\smoke_child.cdb'
$outPath = $root + '\cdb.stdout.txt'
$errPath = $root + '\cdb.stderr.txt'
$cdbPath = 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
$hostRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$hostChild = Join-Path $hostRoot 'smoke_child.cdb'
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    Invoke-Command -Session $s -ArgumentList $root -ScriptBlock {
        param($root)
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        foreach ($p in @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(cdb|ping|cmd)$' })) { try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {} }
    }
    Copy-Item -ToSession $s -Path $hostChild -Destination $childPath -Force
    $result = Invoke-Command -Session $s -ArgumentList $root,$cmdPath,$childPath,$outPath,$errPath,$cdbPath -ScriptBlock {
        param($root,$cmdPath,$childPath,$outPath,$errPath,$cdbPath)
        $lines = @(
            '.echo [SMOKE_PARENT_READY]',
            '.childdbg 1',
            'sxd ibp',
            'sxd epr',
            'sxe av',
            'sxe -c "$$><smoke_child.cdb;g" cpr',
            'sxe -c ".echo [SMOKE_PARENT_AV]; .lastevent; r; k; g" av',
            'g'
        )
        [System.IO.File]::WriteAllLines($cmdPath, $lines, [System.Text.Encoding]::ASCII)
        $args = @('-o','-cf',$cmdPath,'C:\Windows\System32\cmd.exe','/c','C:\Windows\System32\ping.exe','-n','2','127.0.0.1')
        $p = Start-Process -FilePath $cdbPath -ArgumentList $args -WorkingDirectory $root -RedirectStandardOutput $outPath -RedirectStandardError $errPath -PassThru -WindowStyle Hidden
        $deadline = (Get-Date).AddSeconds(45)
        while (-not $p.HasExited -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 500 }
        $timedOut = -not $p.HasExited
        if ($timedOut) { try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {} }
        Start-Sleep -Seconds 2
        $exited = $p.HasExited
        $exitCode = $null
        if ($exited) { try { $exitCode = [int]$p.ExitCode } catch {} }
        $stdoutBytes = if (Test-Path $outPath) { (Get-Item $outPath).Length } else { 0 }
        $stderrBytes = if (Test-Path $errPath) { (Get-Item $errPath).Length } else { 0 }
        [pscustomobject]@{ pid=[int]$p.Id; timed_out=$timedOut; exited=$exited; exit_code=$exitCode; stdout_bytes=$stdoutBytes; stderr_bytes=$stderrBytes }
    }
    Copy-Item -FromSession $s -Path $outPath -Destination (Join-Path $hostRoot 'smoke.stdout.txt') -Force
    Copy-Item -FromSession $s -Path $errPath -Destination (Join-Path $hostRoot 'smoke.stderr.txt') -Force
    Copy-Item -FromSession $s -Path $cmdPath -Destination (Join-Path $hostRoot 'smoke_parent.cdb') -Force
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $hostRoot 'smoke_result.json') -Encoding UTF8
    $result | ConvertTo-Json -Depth 8
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; if ($sec) { $sec.Dispose() } }
