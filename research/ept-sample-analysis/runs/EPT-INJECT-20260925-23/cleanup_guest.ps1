[CmdletBinding()]
param([string]$VmName='<VM_LABEL>', [string]$Spool='C:\ept_obs\spool', [string]$RemoveRunId='')

$ErrorActionPreference='Stop'
$pwPath='<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw=(Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec=ConvertTo-SecureString $pw -AsPlainText -Force
$cred=New-Object System.Management.Automation.PSCredential('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
try {
    $r=Invoke-Command -Session $s -ScriptBlock {
        param($spool, $RemoveRunId)
        # kill leftover debugger / sample processes
        $names=@('cdb','windbg','ntsd','Hardware','R3')
        foreach($n in $names){
            Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
                try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; "killed $n pid=$($_.Id)" } catch { "kill failed $n pid=$($_.Id)" }
            }
        }
        Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'EPT_*' } | ForEach-Object {
            try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; "killed EPT_ pid=$($_.Id)" } catch {}
        }
        Start-Sleep -Seconds 2
        # report what remains
        $left=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $_.ProcessName -match '^(cdb|windbg|ntsd|Hardware|R3)$' -or $_.ProcessName -like 'EPT_*' } | Select-Object Id,ProcessName)
        # clean empty-ish spool dirs we may retry
        if (Test-Path -LiteralPath $spool) {
            Get-ChildItem -LiteralPath $spool -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $cnt=@(Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue).Count
                if ($cnt -eq 0) { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue; "removed empty dir $($_.Name)" }
            }
        }
        if ($RemoveRunId) {
            $dir = Join-Path $spool $RemoveRunId
            if (Test-Path -LiteralPath $dir) {
                Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
                "removed run dir $RemoveRunId"
            }
        }
        [pscustomobject]@{ remaining=$left }
    } -ArgumentList $spool, $RemoveRunId
    "remaining: " + (($r.remaining | ForEach-Object { "$($_.ProcessName):$($_.Id)" }) -join ', ')
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
