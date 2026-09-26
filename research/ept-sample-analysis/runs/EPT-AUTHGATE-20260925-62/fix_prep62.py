p = 'host_prep.ps1'
t = open(p, 'utf-8').read() if False else open(p, encoding='utf-8').read()
anchor = """  if(Test-Path -LiteralPath $sym){ Rename-Item -LiteralPath $sym ($sym+'_off_'+(Get-Date -Format 'HHmmss')) -Force; Write-Host 'SYM_CACHE_DISABLED' } else { Write-Host 'SYM_CACHE_ABSENT' }"""
assert anchor in t, 'sym anchor missing'
add = anchor + """
 Invoke-Command -Session $s -ScriptBlock {
  $left=@(Get-ChildItem 'C:\\Windows\\Temp' -File -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -notmatch '^(EPT_|TS_)'})
  foreach($f in $left){ Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue }
  Write-Host ('TEMP_CLEANED count='+$left.Count)
 }"""
t = t.replace(anchor, add, 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)
print('temp cleanup added:', 'TEMP_CLEANED' in t)
