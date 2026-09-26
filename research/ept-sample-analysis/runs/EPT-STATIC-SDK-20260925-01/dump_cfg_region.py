import re
IMG = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\image_140000000.bin"
BASE = 0x140000000
data = open(IMG,"rb").read()
def at(va, n):
    return data[va-BASE:va-BASE+n]
print("=== GBK/ANSI decode of msgbox text @0x140f92ed0 (80 bytes) ===")
b = at(0x140f92ed0, 80)
print(" hex:", b[:48].hex())
for enc in ("gbk","cp936","big5","utf-8"):
    try: print(f" {enc}: " + b.split(b"\x00")[0].decode(enc, "replace")[:60])
    except Exception as e: print(f" {enc}: ERR {e}")
print()
print("=== region 0x140f92c00-0x140f93000 : ascii strings ===")
reg = at(0x140f92c00, 0x400)
for m in re.finditer(rb"[\x20-\x7e]{4,}", reg):
    print(f"  {0x140f92c00+m.start():#x}  {m.group().decode('latin1')}")
print()
print("=== region 0x140f92c00-0x140f93000 : utf16le strings ===")
for m in re.finditer(rb"(?:[\x20-\x7e]\x00){4,}", reg):
    print(f"  {0x140f92c00+m.start():#x}  {m.group().decode('utf-16le','replace')}")
