#!/bin/bash
cd <HOST_PATH>
for i in 1 2 3; do
  echo "=== CYCLE $i ==="
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_prep.ps1 2>&1 | grep -E "TASK_STARTED|CHILD_FOUND|PREP_DONE" | head -3
  sleep 175
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_harvest.ps1 2>&1 | grep -E "HARVEST_DONE|miss" | head -2
  python - <<'PYEOF'
t=open('cdb.stdout.txt','rb').read().decode('utf-8',errors='replace')
lines=t.splitlines()
big=None
i=0
while i<len(lines):
    if lines[i].strip()=='WFW':
        j=i+1; rcx=r8=None
        while j<len(lines) and lines[j].startswith('rcx='): rcx=lines[j].split('=')[1].strip(); j+=1
        while j<len(lines) and lines[j].startswith('r8='): r8=int(lines[j].split('=')[1].strip().replace('`',''),16); j+=1
        if r8 and r8>0x100000: big=(i,rcx,r8); break
        i=j
    else: i+=1
full=sum(1 for l in lines if l.strip()=='CWEXA_OBS')>0
print("RESULT: big_write=",big," gui_obs=",sum(1 for l in lines if l.strip()=='CWEXA_OBS')>0," cfw=",sum(1 for l in lines if l.strip()=='CFW'))
if big:
    i,rcx,r8=big
    print("=== PROBE OUTPUT ===")
    for k in range(i,min(len(lines),i+24)):
        print(f"{k:4d}| {lines[k][:140]}")
PYEOF
done
