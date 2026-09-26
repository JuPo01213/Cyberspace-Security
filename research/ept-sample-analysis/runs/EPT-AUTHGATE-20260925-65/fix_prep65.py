p = 'host_prep.ps1'
t = open(p, encoding='utf-8').read()
old = " Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)if(Test-Path -LiteralPath $r){Remove-Item -LiteralPath $r -Recurse -Force};New-Item -ItemType Directory -Force -Path $r|Out-Null;Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb|windbg)'}|Stop-Process -Force -ErrorAction SilentlyContinue}"
new = (" Invoke-Command -Session $s -ArgumentList $guestRoot -ScriptBlock {param($r)"
       "Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -match 'watcher\\.ps1'} | ForEach-Object {Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue};"
       "Start-Sleep -Seconds 1;"
       "if(Test-Path -LiteralPath $r){Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue};"
       "New-Item -ItemType Directory -Force -Path $r|Out-Null;"
       "Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^(Hardware|EPT_|cdb|windbg)'}|Stop-Process -Force -ErrorAction SilentlyContinue}")
assert old in t, 'cleanup anchor not found'
t = t.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)
print('watcher-kill added')
