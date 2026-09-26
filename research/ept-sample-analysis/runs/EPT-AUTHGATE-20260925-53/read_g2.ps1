$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
  Write-Host "SESSION_OK"
  $out=Invoke-Command -Session $s -ScriptBlock {
    $p='C:\ept_obs\canary_G.out'
    if(-not (Test-Path $p)){ return "FILE_MISSING" }
    return (Get-Content $p) -join "`n"
  }
  Write-Host ("LEN="+$out.Length)
  $lines=$out -split "`n"
  $idx=[array]::IndexOf(($lines|ForEach-Object{$true}),$true)
  for($i=[Math]::Max(0,$lines.Count-40);$i -lt $lines.Count;$i++){ Write-Host ("{0}| {1}" -f $i,$lines[$i]) }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
