$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
 Copy-Item -ToSession $s -Path '.\canary_A.cdb','.\canary_B.cdb' -Destination 'C:\ept_obs\' -Force
 Invoke-Command -Session $s -ScriptBlock {
  $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
  foreach($t in @('A','B')){
    $out="C:\ept_obs\canary_$t.out"
    $p=Start-Process -FilePath $cdb -ArgumentList @('-cf',"C:\ept_obs\canary_$t.cdb",'cmd.exe','/c','echo X') -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError "C:\ept_obs\canary_$t.err" -PassThru
    if(-not $p.WaitForExit(60000)){Stop-Process -Id $p.Id -Force}
  }
  foreach($t in @('A','B')){
    "=== CANARY $t ==="
    $c=Get-Content "C:\ept_obs\canary_$t.out" -Raw
    ($c -split "`n" | Where-Object {$_ -match "CANARY|_ARMED|Couldn't resolve|^\s*\d+\s+bu|ExitProcess|OpenServiceA|^\s*\d+"} | Select-Object -First 30) -join "`n"
  }
 }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
