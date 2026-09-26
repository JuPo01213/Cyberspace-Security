p = 'host_prep.ps1'
t = open(p, encoding='utf-8').read()
old = """  if(Test-Path -LiteralPath $sym){ Rename-Item -LiteralPath $sym ($sym+'_off_'+(Get-Date -Format 'HHmmss')) -Force; Write-Host 'SYM_CACHE_DISABLED' } else { Write-Host 'SYM_CACHE_ABSENT' }
 }
 Invoke-Command -Session $s -ScriptBlock {
  $left=@(Get-ChildItem 'C:\\Windows\\Temp' -File -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -notmatch '^(EPT_|TS_)'})
  foreach($f in $left){ Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue }
  Write-Host ('TEMP_CLEANED count='+$left.Count)
 }"""
new = """  if(Test-Path -LiteralPath $sym){ Rename-Item -LiteralPath $sym ($sym+'_off_'+(Get-Date -Format 'HHmmss')) -Force; Write-Host 'SYM_CACHE_DISABLED' } else { Write-Host 'SYM_CACHE_ABSENT' }
  $left=@(Get-ChildItem 'C:\\Windows\\Temp' -File -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -notmatch '^(EPT_|TS_)'})
  foreach($f in $left){ Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue }
  Write-Host ('TEMP_CLEANED count='+$left.Count)
 }"""
assert old in t, 'merged block anchor not found'
t = t.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)
print('merged OK')
