param([string]$SnapshotName='C173-gen1-ready2')
$ErrorActionPreference='Stop'
Checkpoint-VM -Name <VM_LABEL> -SnapshotName $SnapshotName
Get-VMSnapshot -VMName <VM_LABEL> | Select-Object Name,CreationTime | Format-Table -AutoSize | Out-String
