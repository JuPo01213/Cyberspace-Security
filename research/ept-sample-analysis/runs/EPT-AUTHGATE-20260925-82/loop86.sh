#!/bin/bash
cd <HOST_PATH>
for i in 1 2 3; do
  echo "=== CYCLE $i ==="
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_prep.ps1 2>&1 | grep -E "CHILD_FOUND|PREP_DONE" | head -2
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File wait_harvest.ps1 2>&1 | grep -E "WAIT_DONE" | head -1
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_harvest.ps1 2>&1 | grep -E "HARVEST_DONE|miss early|miss child" | head -3
  python -c "
import os
t=open('cdb.stdout.txt','rb').read().decode('utf-8',errors='replace')
lines=t.splitlines()
h={m:sum(1 for l in lines if l.strip()==m) for m in ['MUT','RECV','FATAL_THUNK','CFW','CWEXA_OBS','EXIT_SKIP']}
print(h)
for f in ['early_death.dmp','child_full.dmp']:
    print(f, os.path.getsize(f) if os.path.exists(f) else 'MISSING')
"
done
