#!/usr/bin/env bash
OUT="<HOST_PATH>/EPT/runs/EPT-STATIC-SDK-20260925-01"
BIN="<HOST_PATH>/EPT/artifacts/captures/stream_C6/stream_text.bin"
IMG="$OUT/image_140000000.bin"
mkdir -p "$OUT/raw" "$OUT/rawimg"
run() {
  name="$1"; va="$2"; size="$3"
  rizin -n -q -e scr.color=0 -e scr.utf8=false -b 64 -a x86 -m 0x140000000 -c "pD $size @ $va" "$BIN" > "$OUT/raw/$name.txt" 2>&1
  echo "TEXT $name lines=$(wc -l < "$OUT/raw/$name.txt")"
}
runimg() {
  name="$1"; va="$2"; size="$3"
  rizin -n -q -e scr.color=0 -e scr.utf8=false -b 64 -a x86 -m 0x140000000 -c "pD $size @ $va" "$IMG" > "$OUT/rawimg/$name.txt" 2>&1
  echo "IMG  $name lines=$(wc -l < "$OUT/rawimg/$name.txt")"
}
run set_host 0x1403b3280 176
run init 0x1403b34d0 1750
run cardlogin_head 0x1403b3d30 12288
run get_server_option 0x1403c47e0 493
run is_login 0x1403c49d0 151
run aux_2f90 0x1403b2f90 336
run aux_30e0 0x1403b30e0 336
run aux_3320 0x1403b3320 336
runimg sethost_tgt 0x1416f98f0 512
runimg init_tgt 0x14166f7ba 512
echo "=== init head (clean) ==="
sed -n '1,8p' "$OUT/raw/init.txt"
echo "=== cardlogin head (clean) ==="
sed -n '1,8p' "$OUT/raw/cardlogin_head.txt"
echo "=== sethost_tgt ==="
sed -n '1,20p' "$OUT/rawimg/sethost_tgt.txt"
