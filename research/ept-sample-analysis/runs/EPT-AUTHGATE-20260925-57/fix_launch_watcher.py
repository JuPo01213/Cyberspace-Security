p = 'guest_launch.ps1'
raw = open(p, 'rb').read()
lines = raw.split(b'\r\n')
if len(lines) < 5:
    lines = raw.split(b'\n')
good = b" $watcher=Start-Process -FilePath 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe' -ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'watcher.ps1'),'-RunId',$RunId) -WorkingDirectory $root -WindowStyle Hidden -PassThru"
fixed = 0
for i, l in enumerate(lines):
    if b'watcher.ps1' in l and b'Start-Process' in l:
        lines[i] = good
        fixed += 1
open(p, 'wb').write(b'\r\n'.join(lines))
chk = open(p, 'rb').read()
print('fixed=', fixed)
print('vt_or_bs_left=', (b'\x0b' in chk) or (b'\x08' in chk))
print('good_path_present=', b'WindowsPowerShell\\v1.0\\powershell.exe' in chk)
