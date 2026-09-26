[CmdletBinding()]
param(
    [string]$RunId = 'EPT-REAL-20260924-01'
)
$ErrorActionPreference = 'Stop'
$root = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'harvest'
$doneText = Get-Content -LiteralPath (Join-Path $root 'done.json') -Raw
$done = $doneText | ConvertFrom-Json
$events = @(Get-Content -LiteralPath (Join-Path $root 'events.ndjson') | ForEach-Object {
    $line = $_
    if ($line -match '"type":"PROCESS_SEEN"') {
        [pscustomobject]@{
            utc = ([regex]::Match($line,'"utc":"([^"]+)"')).Groups[1].Value
            pid = [int]([regex]::Match($line,'"pid":(\d+)')).Groups[1].Value
            ppid = [int]([regex]::Match($line,'"ppid":(\d+)')).Groups[1].Value
            name = ([regex]::Match($line,'"name":"([^"]*)"')).Groups[1].Value
            path = ([regex]::Match($line,'"path":"([^"]*)"')).Groups[1].Value
            command_line = ([regex]::Match($line,'"command_line":"([^"]*)"')).Groups[1].Value
        }
    }
})
$changes = @(Get-Content -LiteralPath (Join-Path $root 'file_changes.json') -Raw | ConvertFrom-Json)
$summary = [ordered]@{
    run_id = $RunId
    status = [string]$done.status
    mode = [string]$done.mode
    evidence_scope = [string]$done.evidence_scope
    target_path = [string]$done.target_path
    target_pid = [int]$done.target_pid
    input_state = [string]$done.input_state
    target_native_return = [string]$done.target_native_return
    target_caller_diff_bytes = [string]$done.target_caller_diff_bytes
    rc06_entry = [string]$done.rc06_entry
    rc06_return = [string]$done.rc06_return
    post_decode_behavior = [string]$done.post_decode_behavior
    process_events = $events
    file_changes = @($changes | Select-Object path,before,after)
    output_bytes = [ordered]@{ stdout = (Get-Item (Join-Path $root 'target.stdout.txt')).Length; stderr = (Get-Item (Join-Path $root 'target.stderr.txt')).Length }
    interpretation = 'This is a real genB target Guest run with a synthetic invalid card and no response injection. It demonstrates natural deployment activity but does not close RC06 or post-decode behavior.'
}
$path = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'natural_summary.json'
$summary | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $path -Encoding UTF8
$summary | ConvertTo-Json -Depth 16
