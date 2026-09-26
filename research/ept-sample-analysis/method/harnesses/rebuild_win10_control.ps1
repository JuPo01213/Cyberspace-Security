[CmdletBinding()]
param(
    [string]$VmName = '<OTHER_VM_LABEL>',
    [string]$IsoPath = '<HOST_PATH>\Windows.iso',
    [string]$BaseFolder = '<HOST_PATH>\VMs',
    [string]$HostShare = '<HOST_PATH>\HexPatch',
    [string]$SamplePath = '<HOST_PATH>\EPT\sample',
    [string]$GuestUser = '<VM_USER>',
    [int]$MemoryMB = 4096,
    [int]$CpuCount = 2,
    [int]$DiskSizeMB = 65536
)

$ErrorActionPreference = 'Stop'
$vbox = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
$additionsIso = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxGuestAdditions.iso'
$vmDirectory = Join-Path $BaseFolder $VmName
$diskPath = Join-Path $vmDirectory ($VmName + '.vdi')
$secretDirectory = Join-Path $vmDirectory 'host-secrets'
$passwordPath = Join-Path $secretDirectory ($GuestUser + '.password.txt')
$manifestPath = Join-Path $vmDirectory 'rebuild-manifest.json'

function Invoke-VBox {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    & $vbox @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ('VBoxManage failed with exit code ' + $LASTEXITCODE + ': ' + ($Arguments -join ' '))
    }
}

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '')
    } finally {
        $stream.Dispose()
        $sha.Dispose()
    }
}

function New-LocalPassword {
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%+=' 
    $bytes = New-Object byte[] 28
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    $tail = -join ($bytes | ForEach-Object { $alphabet[$_ % $alphabet.Length] })
    return ('A' + 'a' + '7' + '!' + $tail)
}

if (-not (Test-Path -LiteralPath $vbox)) { throw 'VBoxManage.exe was not found.' }
if (-not (Test-Path -LiteralPath $IsoPath)) { throw ('Windows ISO not found: ' + $IsoPath) }
if (-not (Test-Path -LiteralPath $additionsIso)) { throw ('Guest Additions ISO not found: ' + $additionsIso) }
if (-not (Test-Path -LiteralPath $HostShare)) { throw ('Host share not found: ' + $HostShare) }
if (-not (Test-Path -LiteralPath $SamplePath)) { throw ('Authoritative sample directory not found: ' + $SamplePath) }

$registeredVm = & $vbox list vms | Select-String ('"' + [regex]::Escape($VmName) + '"')
if ($registeredVm) { throw ('A VM named ' + $VmName + ' is already registered.') }
if (Test-Path -LiteralPath $vmDirectory) { throw ('VM directory already exists; refusing to overwrite: ' + $vmDirectory) }

[void][System.IO.Directory]::CreateDirectory($secretDirectory)
$identitySid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
& icacls.exe $secretDirectory /inheritance:r /grant:r (('*' + $identitySid + ':(OI)(CI)F')) | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Failed to restrict the host secret directory ACL.' }

$password = New-LocalPassword
[System.IO.File]::WriteAllText($passwordPath, $password, [System.Text.UTF8Encoding]::new($false))
& icacls.exe $passwordPath /inheritance:r /grant:r (('*' + $identitySid + ':F')) | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Failed to restrict the host password file ACL.' }

Invoke-VBox @('createvm', ('--name=' + $VmName), ('--basefolder=' + $BaseFolder), '--ostype=Windows10_64', '--register')
Invoke-VBox @('modifyvm', $VmName, '--memory=4096', '--cpus=2', '--vram=128', '--graphicscontroller=vboxsvga', '--firmware=bios', '--chipset=piix3', '--ioapic=on', '--rtcuseutc=on', '--nic1=nat', '--audio-enabled=off', '--clipboard-mode=disabled', '--drag-and-drop=disabled')
Invoke-VBox @('storagectl', $VmName, '--name=SATA', '--add=sata', '--controller=IntelAhci', '--bootable=on')
Invoke-VBox @('storagectl', $VmName, '--name=IDE', '--add=ide', '--controller=PIIX4', '--bootable=on')
Invoke-VBox @('createmedium', 'disk', ('--filename=' + $diskPath), ('--size=' + $DiskSizeMB), '--format=VDI')
Invoke-VBox @('storageattach', $VmName, '--storagectl=SATA', '--port=0', '--device=0', '--type=hdd', ('--medium=' + $diskPath))
Invoke-VBox @('storageattach', $VmName, '--storagectl=IDE', '--port=1', '--device=0', '--type=dvddrive', ('--medium=' + $IsoPath))

Invoke-VBox @('sharedfolder', 'add', $VmName, '--name=HexPatch', ('--hostpath=' + $HostShare), '--automount')

$unattended = @( 
    'unattended', 'install', $VmName,
    ('--iso=' + $IsoPath),
    ('--user=' + $GuestUser),
    ('--user-password-file=' + $passwordPath),
    ('--admin-password-file=' + $passwordPath),
    '--full-user-name=EPT Lab',
    ('--hostname=' + $VmName + '.lab.local'),
    '--no-install-additions'
)
$installArguments = $unattended + '--start-vm=gui'
& $vbox @installArguments *> $null
if ($LASTEXITCODE -ne 0) { throw 'Unattended Windows installation failed; password output was suppressed.' }

$guestRunning = $false
for ($attempt = 0; $attempt -lt 60; $attempt++) {
    $stateLine = & $vbox showvminfo $VmName --machinereadable | Select-String 'VMState='
    if ([string]$stateLine -match 'running') { $guestRunning = $true; break }
    Start-Sleep -Seconds 1
}
if (-not $guestRunning) { throw 'VM did not reach running state after unattended install.' }
Invoke-VBox @('sharedfolder', 'add', $VmName, '--name=EPTSample', ('--hostpath=' + $SamplePath), '--readonly', '--automount', '--transient')

$manifest = [ordered]@{
    vm_name = $VmName
    guest_user = $GuestUser
    password_file = $passwordPath
    iso_path = $IsoPath
    iso_sha256 = Get-Sha256Hex -Path $IsoPath
    additions_iso_path = $additionsIso
    host_share = $HostShare
    sample_share = $SamplePath
    sample_sha256 = (Get-ChildItem -LiteralPath $SamplePath -File | Where-Object { $_.Name -like 'EPT*.exe' } | ForEach-Object { Get-Sha256Hex -Path $_.FullName })
    guestcontrol_domain = 'auto-from-GuestProperty'
    launch_state = 'INSTALL_STARTED'
}
[System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false))
$password = $null

[pscustomobject]@{
    status = 'INSTALL_STARTED'
    vm_name = $VmName
    guest_user = $GuestUser
    password_file = $passwordPath
    manifest_path = $manifestPath
    host_share = $HostShare
    sample_share = $SamplePath
    sample_sha256 = $manifest.sample_sha256
    next_step = 'Wait for Windows setup to finish, install Guest Additions separately from the GUI, then run guestcontrol_preflight.ps1 without -Launch.'
} | ConvertTo-Json -Depth 5
