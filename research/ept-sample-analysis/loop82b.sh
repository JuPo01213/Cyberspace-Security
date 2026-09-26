#!/bin/bash
cd <HOST_PATH>
for i in 1 2 3 4; do
  echo "=== CYCLE $i ==="
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_prep.ps1 2>&1 | grep -E "CHILD_FOUND|PREP_DONE" | head -2
  sleep 170
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_harvest.ps1 2>&1 | grep -E "HARVEST_DONE|miss full" | head -2
  python -c "
import os
if os.path.exists('full_image_runtime.bin'): print('FULL_IMAGE_OK', os.path.getsize('full_image_runtime.bin'))
else: print('still missing')
"
done
