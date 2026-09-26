#!/usr/bin/env bash
# E 盘空间守卫（只读）。用法：bash <HOST_PATH>
set -uo pipefail
EVID=<HOST_PATH>
mkdir -p "$EVID"

echo "== E: 容量 =="
df -h /mnt/e | tail -1
FREE_G=$(df --output=avail -BG /mnt/e | tail -1 | tr -dc '0-9')
if   [ "${FREE_G:-0}" -lt 60 ];  then echo "!! STOP 线：可用 ${FREE_G}G < 60G，禁止新实验，先回收"
elif [ "${FREE_G:-0}" -lt 100 ]; then echo "!  WARN 线：可用 ${FREE_G}G < 100G，仅只读分析"
else echo "OK 可用 ${FREE_G}G"
fi

echo
echo "== 主要目录 =="
du -xsh <HOST_PATH> <HOST_PATH> <HOST_PATH> <HOST_PATH> <HOST_PATH> 2>/dev/null

echo
echo "== <OTHER_VM_LABEL> 快照 =="
cmd.exe /C "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" snapshot <OTHER_VM_LABEL> list > "$EVID/_disk_guard_snapshots.tmp" 2>&1 || true
grep -E '^ *Name: ' "$EVID/_disk_guard_snapshots.tmp" | tail -30
grep -cE '^ *Name: ' "$EVID/_disk_guard_snapshots.tmp" | sed 's/^/节点数: /'

echo
echo "== 近期大文件（>100M，按时间倒序前 15）=="
find <HOST_PATH> <HOST_PATH> -type f -size +100M -printf '%TY-%Tm-%Td %TH:%TM %10s %p\n' 2>/dev/null | sort -r | head -15

echo
echo "== 快照目录体积 =="
du -xsh <HOST_PATH> <HOST_PATH> 2>/dev/null
