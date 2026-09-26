[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260925-01'
)
$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    Invoke-Command -Session $s -ScriptBlock {
        param($r)
        '=== spool root ==='
        if (Test-Path -LiteralPath $r -PathType Container) {
            Get-ChildItem -LiteralPath $r -Force | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize | Out-String -Width 220
        } else {
            "spool missing: $r"
        }
        '=== scheduled tasks (EPT) ==='
        Get-ScheduledTask | Where-Object { $_.TaskName -like '*EPT*' } | Select-Object TaskName,State | Format-Table -AutoSize | Out-String -Width 220
    } -ArgumentList ('C:\ept_obs\spool\' + $RunId)
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
