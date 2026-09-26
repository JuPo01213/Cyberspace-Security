[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260924-01'
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$guestRoot = 'C:\ept_obs\spool\' + $RunId
$src = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'child_inject.cdb'
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    Copy-Item -ToSession $s -Path $src -Destination ($guestRoot + '\child_inject.cdb') -Force
    $hash = Invoke-Command -Session $s -ArgumentList ($guestRoot + '\child_inject.cdb') -ScriptBlock { param($p) (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant() }
    [System.IO.File]::WriteAllText((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'child_inject_guest_hash.txt'), $hash, [System.Text.UTF8Encoding]::new($false))
    $hash
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; if ($sec) { $sec.Dispose() } }
