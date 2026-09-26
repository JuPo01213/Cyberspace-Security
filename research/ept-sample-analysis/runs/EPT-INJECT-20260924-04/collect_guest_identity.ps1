[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260924-03'
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>',$sec)
$hostRoot = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'identity'
New-Item -ItemType Directory -Force -Path $hostRoot | Out-Null
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    $paths = @(
        'C:\ept_core\Hardware.exe',
        'C:\Windows\System32\Hardware.exe',
        'C:\Windows\Temp\EPT_46F4557F_E917B6D2.exe',
        'C:\Windows\Temp\EPT_15669800_B33D1B09.exe'
    )
    $records = @()
    foreach ($path in $paths) {
        $exists = Invoke-Command -Session $s -ArgumentList $path -ScriptBlock {
            param($p)
            Test-Path -LiteralPath $p -PathType Leaf
        }
        if (-not $exists) {
            $records += [pscustomobject]@{ path=$path; exists=$false }
            continue
        }
        $leaf = Split-Path -Leaf $path
        $dest = Join-Path $hostRoot $leaf
        Copy-Item -FromSession $s -Path $path -Destination $dest -Force
        $item = Get-Item -LiteralPath $dest
        $records += [pscustomobject]@{
            path = $path
            exists = $true
            host_path = $dest
            length = [int64]$item.Length
            sha256 = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToUpperInvariant()
            last_write_utc = $item.LastWriteTimeUtc.ToString('o')
        }
    }
    $records | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $hostRoot 'identity.json') -Encoding UTF8
    $records | ConvertTo-Json -Depth 8
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
