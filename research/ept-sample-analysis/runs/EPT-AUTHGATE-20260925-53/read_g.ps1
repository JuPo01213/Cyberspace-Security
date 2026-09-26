$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
 Invoke-Command -Session $s -ScriptBlock { Get-Content 'C:\ept_obs\canary_G.out' | Select-String -Pattern 'Couldn.t resolve|CREATESVC|STARTSVC|OPENSVC|TERM_PROC|ALL_BU_ISSUED|CANARY_G_STOP' | Select-Object -First 25 }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
