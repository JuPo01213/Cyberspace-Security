[CmdletBinding()]
param([string]$VmName='<VM_LABEL>')

$ErrorActionPreference='Stop'
$pwPath='<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw=(Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec=ConvertTo-SecureString $pw -AsPlainText -Force
$cred=New-Object System.Management.Automation.PSCredential('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
try {
    $r=Invoke-Command -Session $s -ScriptBlock {
        $p='C:\Windows\System32\EPT.cmd'
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            $b=[System.IO.File]::ReadAllBytes($p)
            $ascii=[System.Text.Encoding]::ASCII.GetString($b)
            $uni=[System.Text.Encoding]::Unicode.GetString($b)
            [pscustomobject]@{
                exists=$true
                path=$p
                length=$b.Length
                sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()
                last_write_utc=(Get-Item -LiteralPath $p).LastWriteTimeUtc.ToString('o')
                ascii_text=$ascii
                unicode_text=$uni
                b64=[Convert]::ToBase64String($b)
            }
        } else { [pscustomobject]@{ exists=$false; path=$p } }
    }
    $r | ConvertTo-Json -Depth 6 | Out-File -FilePath (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'ept_cmd.json') -Encoding utf8
    # also copy the raw file locally for offline inspection
    $dst=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'EPT.cmd.raw'
    Copy-Item -FromSession $s -Path 'C:\Windows\System32\EPT.cmd' -Destination $dst -Force -ErrorAction SilentlyContinue
    "length=$($r.length) sha256=$($r.sha256) last_write=$($r.last_write_utc)"
    "--- ASCII ---"
    $r.ascii_text
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
