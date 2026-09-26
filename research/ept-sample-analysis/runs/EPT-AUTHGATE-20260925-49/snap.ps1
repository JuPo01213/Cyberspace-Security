Checkpoint-VM -Name <VM_LABEL> -SnapshotName C173-gen1-testsign-ready
Get-VMSnapshot -VMName <VM_LABEL> | ForEach-Object { $_.Name }
