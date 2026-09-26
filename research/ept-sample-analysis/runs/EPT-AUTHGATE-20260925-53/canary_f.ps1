$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName <VM_LABEL> -Credential $cred
try {
 Invoke-Command -Session $s -ScriptBlock {
  $sym='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\sym'
  "=== SYM DIR BEFORE ==="
  if(Test-Path $sym){ Get-ChildItem $sym -Recurse -File | ForEach-Object {$_.FullName.Replace($sym,'')+' '+$_.Length} | Select-Object -First 20 } else { "NO SYM DIR" }
  if(Test-Path $sym){ Rename-Item $sym ($sym+'_disabled_by_ept') -Force; "RENAMED=True" }
 }
 Copy-Item -ToSession $s -Path '.\canary_C.cdb' -Destination 'C:\ept_obs\canary_F.cdb' -Force
 Invoke-Command -Session $s -ScriptBlock {
  $cdb='C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe'
  $p=Start-Process -FilePath $cdb -ArgumentList @('-cf','C:\ept_obs\canary_F.cdb','cmd.exe','/c','echo X') -WindowStyle Hidden -RedirectStandardOutput 'C:\ept_obs\canary_F.out' -RedirectStandardError 'C:\ept_obs\canary_F.err' -PassThru
  if(-not $p.WaitForExit(90000)){Stop-Process -Id $p.Id -Force}
  $c=Get-Content 'C:\ept_obs\canary_F.out' -Raw
  "resolve_errors=" + ([regex]::Matches($c,"Couldn't resolve error at")).Count
  ($c -split "`n" | Where-Object {$_ -match "CANARY_C_BEGIN|CANARY_C_STOP|X_KERNEL32_EXIT|^0{6}|Couldn't resolve"} | Select-Object -First 12) -join "`n"
  "=== X_EXITP SECTION ==="
  ($c -split "`n" | Select-String -Pattern 'ExitVDM|ExitProcessImpl|SleepEx|SleepStub|CreateProcessWStub|OpenService' | Select-Object -First 8) -join "`n"
 }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
