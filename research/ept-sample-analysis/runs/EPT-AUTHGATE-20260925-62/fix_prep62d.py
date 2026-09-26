t = open('host_prep_base.ps1', encoding='utf-8').read()
lines = t.splitlines(keepends=True)
out = []
for l in lines:
    out.append(l)
    if "SYM_CACHE_DISABLED' } else" in l:
        out.append("  $left=@(Get-ChildItem 'C:\\Windows\\Temp' -File -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -notmatch '^(EPT_|TS_)'})\n")
        out.append("  foreach($f in $left){ Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue }\n")
        out.append("  Write-Host ('TEMP_CLEANED count='+$left.Count)\n")
open('host_prep.ps1', 'w', encoding='utf-8', newline='').write(''.join(out))
print('written', len(out))
