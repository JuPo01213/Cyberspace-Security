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
        $out=[ordered]@{}
        # 1. scheduled tasks mentioning Hardware / EPT / Microsoft\Hardware
        $tasks=@()
        foreach($t in @(Get-ScheduledTask -ErrorAction SilentlyContinue)){
            if(($t.TaskPath -match 'Hardware|Microsoft') -or ($t.TaskName -match 'Hardware|EPT|R3')){
                $lr=$null; $nr=$null
                $i=Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue
                if($i -ne $null){
                    if($i.LastRunTime -ne $null){ $lr=$i.LastRunTime.ToString('o') }
                    if($i.NextRunTime -ne $null){ $nr=$i.NextRunTime.ToString('o') }
                }
                $tasks+= [pscustomobject]@{ path=$t.TaskPath; name=$t.TaskName; state=$t.State; last_run=$lr; next_run=$nr }
            }
        }
        $out.tasks=$tasks
        # 2. sample deployment files
        $paths=@('C:\Windows\System32\Hardware.exe','C:\Windows\System32\R3.exe','C:\Windows\System32\EPT.cmd',
                 'C:\Windows\System32\Logs','C:\Windows\System32\HardwareLogs','C:\Windows\Temp\HardwareTask.xml')
        $files=@()
        foreach($p in $paths){
            if(Test-Path -LiteralPath $p){
                $it=Get-Item -LiteralPath $p
                $files+= [pscustomobject]@{
                    path=$p; exists=$true
                    length=if($it.PSIsContainer){$null}else{[int64]$it.Length}
                    is_dir=$it.PSIsContainer
                    last_write_utc=$it.LastWriteTimeUtc.ToString('o')
                    sha256=if(-not $it.PSIsContainer){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()}else{$null}
                }
            } else { $files+= [pscustomobject]@{ path=$p; exists=$false } }
        }
        $out.files=$files
        # 3. running processes of interest
        $out.procs=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $_.ProcessName -match '^(Hardware|R3|EPT_)' } | Select-Object Id,ProcessName,Path)
        # 4. any .sys dropped recently in System32\drivers (driver component release)
        $out.recent_sys=@(Get-ChildItem 'C:\Windows\System32\drivers' -Filter '*.sys' -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTimeUtc -gt (Get-Date).AddDays(-1) } |
            Select-Object Name,Length,LastWriteTimeUtc)
        [pscustomobject]$out
    }
    $r | ConvertTo-Json -Depth 8 | Out-File -FilePath (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'persistence.json') -Encoding utf8
    "=== TASKS ==="; $r.tasks | Format-Table -AutoSize | Out-String -Width 200
    "=== FILES ==="; $r.files | Format-Table -AutoSize | Out-String -Width 200
    "=== PROCS ==="; $r.procs | Format-Table -AutoSize | Out-String -Width 200
    "=== RECENT SYS ==="; $r.recent_sys | Format-Table -AutoSize | Out-String -Width 200
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    if ($sec) { $sec.Dispose() }
}
