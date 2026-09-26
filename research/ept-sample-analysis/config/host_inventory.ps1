[CmdletBinding()]
param([string]$OutputPath = '<HOST_PATH>/EPT/artifacts/host_inventory.json')
$ErrorActionPreference = 'Continue'
function Invoke-Version([string]$File,[string[]]$Arguments) {
  $cmd = Get-Command $File -ErrorAction SilentlyContinue
  if (-not $cmd) { return [pscustomobject]@{command=$File;found=$false;source=$null;output=@()} }
  $out = @(& $cmd.Source @Arguments 2>&1 | Select-Object -First 8 | ForEach-Object { $_.ToString() })
  [pscustomobject]@{command=$File;found=$true;source=$cmd.Source;output=$out}
}
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$inventory = [ordered]@{
  collected_utc = [DateTime]::UtcNow.ToString('o')
  host = [ordered]@{
    computer_name = $env:COMPUTERNAME
    os = $os | Select-Object Caption,Version,BuildNumber,OSArchitecture
    cpu = $cpu | Select-Object Name,NumberOfLogicalProcessors,AddressWidth
    memory_bytes = $cs.TotalPhysicalMemory
    powershell = $PSVersionTable.PSVersion.ToString()
  }
  virtualization = [ordered]@{
    hyperv_cmdlets_available = [bool](Get-Command Get-VM -ErrorAction SilentlyContinue)
    hyperv_vms = if (Get-Command Get-VM -ErrorAction SilentlyContinue) { @(Get-VM -ErrorAction SilentlyContinue | Select-Object Name,State,Generation,Version) } else { @() }
    hyperv_switches = if (Get-Command Get-VMSwitch -ErrorAction SilentlyContinue) { @(Get-VMSwitch -ErrorAction SilentlyContinue | Select-Object Name,SwitchType,NetAdapterInterfaceDescription) } else { @() }
    wsl_list = @(wsl.exe -l -v 2>&1 | ForEach-Object { ($_.ToString() -replace [char]0, '').Trim() } | Where-Object { $_ })
  }
  tools = @(
    (Invoke-Version 'git' @('--version'))
    (Invoke-Version 'python' @('--version'))
    (Invoke-Version 'py' @('--version'))
    (Invoke-Version 'node' @('--version'))
    (Invoke-Version 'npm' @('--version'))
    (Invoke-Version 'docker' @('--version'))
    (Invoke-Version 'podman' @('--version'))
    (Invoke-Version 'ssh' @('-V'))
    (Invoke-Version 'java' @('-version'))
    (Invoke-Version 'qemu-system-x86_64' @('--version'))
    (Invoke-Version 'VBoxManage' @('--version'))
    ([pscustomobject]@{command='ghidraRun.bat';found=$false;source=$null;output=@('GUI launcher intentionally not executed during inventory')})
  )
  paths = @('<HOST_PATH>/EPT','<HOST_PATH>/VMs','<HOST_PATH>/Users/<USER>/.codebuddy','<HOST_PATH>/Users/<USER>/.pi') | ForEach-Object {
    $item = Get-Item -LiteralPath $_ -ErrorAction SilentlyContinue
    [pscustomobject]@{path=$_;exists=($null -ne $item);type=if($item){$item.GetType().Name}else{$null}}
  }
  agent_capabilities = [ordered]@{
    codebuddy_root = '<HOST_PATH>/Users/<USER>/.codebuddy'
    pi_root = '<HOST_PATH>/Users/<USER>/.pi'
    workspace = '<HOST_PATH>/EPT'
    note = 'MCP client capabilities must be verified from local configuration after inventory.'
  }
}
$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$inventory | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
$inventory | ConvertTo-Json -Depth 8
