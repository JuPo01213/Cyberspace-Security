p='host_harvest.ps1'
t=open(p,encoding='utf-8').read()
anchor=" Write-Host 'HARVEST_DONE'"
assert anchor in t, 'harvest anchor missing'
add=" Copy-Item -FromSession $s -Path (Join-Path $guestRoot 'captured') -Destination (Join-Path $runDir 'captured') -Recurse -Force -ErrorAction SilentlyContinue\n"
t=t.replace(anchor, add+anchor, 1)
open(p,'w',encoding='utf-8',newline='\r\n').write(t)
print('captured pull added')
