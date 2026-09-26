p = 'guest_launch.ps1'
t = open(p, encoding='utf-8').read()
anchor = """ Add-Event @{type='CDB_ATTACHED';debugger_pid=[int]$dbg.Id;target_pid=[int]$attach.Id}"""
assert anchor in t, 'child attach anchor missing'
add = anchor + """
 $pcmd=Join-Path $root 'parent_obs.cdb'
 $pout=Join-Path $root 'parent_cdb.stdout.txt'
 $perr=Join-Path $root 'parent_cdb.stderr.txt'
 $pdb=Start-Process -FilePath $cdb -ArgumentList @('-p',[string]$parent.Id,'-cf',$pcmd) -WorkingDirectory $root -RedirectStandardOutput $pout -RedirectStandardError $perr -PassThru -WindowStyle Hidden
 Add-Event @{type='PARENT_CDB_ATTACHED';debugger_pid=[int]$pdb.Id;target_pid=[int]$parent.Id}"""
t = t.replace(anchor, add, 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)
print('guest_launch parent-observer added:', 'PARENT_CDB_ATTACHED' in t)
