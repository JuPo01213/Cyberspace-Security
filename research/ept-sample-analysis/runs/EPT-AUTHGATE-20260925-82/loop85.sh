#!/bin/bash
cd <HOST_PATH>
for i in 1 2 3 4; do
  echo "=== CYCLE $i ==="
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_prep.ps1 2>&1 | grep -E "CHILD_FOUND|PREP_DONE" | head -2
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File wait_harvest.ps1 2>&1 | grep -E "WAIT_DONE"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_harvest.ps1 2>&1 | grep -E "HARVEST_DONE|miss early|miss child" | head -3
  python -c "
import os
for f in ['early_death.dmp','child_full.dmp']:
    print(f, os.path.getsize(f) if os.path.exists(f) else 'MISSING')
"
done
