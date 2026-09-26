[CmdletBinding()]
param(
    [string]$VmName = '<VM_LABEL>',
    [string]$RunId = 'EPT-INJECT-20260924-01',
    [int]$WaitSeconds = 120
)

$ErrorActionPreference = 'Stop'
$pwPath = '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt'
$pw = (Get-Content -LiteralPath $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('<VM_USER>', $sec)
$guestRoot = 'C:\ept_obs\spool\' + $RunId
$s = New-PSSession -VMName $VmName -Credential $cred
try {
    $result = Invoke-Command -Session $s -ArgumentList $guestRoot,$RunId,$WaitSeconds -ScriptBlock {
        param($guestRoot,$RunId,$WaitSeconds)
        $log = Join-Path $guestRoot 'cdb.log'
        $err = Join-Path $guestRoot 'cdb.err.txt'
        $child = Join-Path $guestRoot 'child_honest.cdb'
        $cmd = Join-Path $guestRoot 'cdb_command.txt'
        $lines = @(
            '.echo [INJ_PARENT_ATTACH]',
            '.symfix',
            '.reload',
            '.childdbg 1',
            'sxd ibp',
            'sxe av',
            'sxe -c "$$><' + $child + ';g" cpr',
            'sxe -c ".echo [INJ_PARENT_AV]; .lastevent; r; k; g" av',
            'bu 14235f67b ".echo [INJ_PARENT_ENTRY]; r rip; g"',
            'g'
        )
        Set-Content -LiteralPath $cmd -Value $lines -Encoding ASCII
        Add-Content -LiteralPath (Join-Path $guestRoot 'events.ndjson') -Value (([ordered]@{ utc=(Get-Date).ToUniversalTime().ToString('o'); type='CDB_START_REQUESTED'; cdb_path='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'; command_file=$cmd; child_command_file=$child } | ConvertTo-Json -Compress)) -Encoding UTF8
        $proc = Start-Process -FilePath 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe' -ArgumentList @('-o','-cf',$cmd,'C:\ept_core\Hardware.exe','-k','CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','-n','2','-m','1') -WorkingDirectory $guestRoot -RedirectStandardOutput $log -RedirectStandardError $err -PassThru
        $start = Get-Date
        $seen = $false
        while (((Get-Date) - $start).TotalSeconds -lt $WaitSeconds) {
            if (Test-Path -LiteralPath $log -PathType Leaf) {
                $text = Get-Content -LiteralPath $log -Raw -ErrorAction SilentlyContinue
                if ($text -match '\[INJ_CHILD_ATTACHED\]') { $seen = $true; break }
            }
            Start-Sleep -Seconds 1
        }
        [pscustomobject]@{ run_id=$RunId; cdb_pid=[int]$proc.Id; child_attached=$seen; cdb_log=$log; cdb_err=$err; command_file=$cmd; checked_utc=(Get-Date).ToUniversalTime().ToString('o') }
    }
    $json = $result | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'cdb_start_result.json'), $json, [System.Text.UTF8Encoding]::new($false))
    $json
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; if ($sec) { $sec.Dispose() } }
