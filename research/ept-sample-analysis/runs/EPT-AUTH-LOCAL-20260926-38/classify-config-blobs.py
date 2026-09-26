import base64, hashlib, json, math, sys
from pathlib import Path
from mdmp_read import MiniDump

root=Path(sys.argv[1]); dump=Path(sys.argv[2])
expected='ca0ffcec87a8580e9bfdef4daaf90c97fb06a53d597028020fe1ec714830e60d'
raw=dump.read_bytes(); assert hashlib.sha256(raw).hexdigest()==expected
m=MiniDump(dump)
# The plaintext is reconstructed only in memory from the already verified local
# AES inputs. Do not persist or print it.
key=(root/'embedded-key.bin').read_bytes(); iv=(root/'embedded-iv.bin').read_bytes(); enc=(root/'historical-config.bin').read_bytes()
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
plain=unpad(AES.new(key,AES.MODE_CBC,iv).decrypt(enc[4:]),16)
assert len(plain)==890
encoded=[plain[o:o+99] for o in (0x3b,0x9f,0x103)]
assert encoded[0]==encoded[1]==encoded[2]
decoded=base64.b64decode(encoded[0]+b'=', validate=True)
assert len(decoded)==74

def classify(data):
    printable=sum(32<=x<=126 or x in (9,10,13) for x in data)
    zero=data.count(0)
    entropy=0.0
    for n in {data.count(i) for i in set(data)}:
        p=n/len(data); entropy += -p*math.log2(p)
    return {'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest().upper(),'printable_count':printable,'zero_count':zero,'entropy':round(entropy,5),'utf8_valid':_valid_utf8(data),'utf16le_valid':_valid_utf16(data),'magic':data[:4].hex(),'u32le':int.from_bytes(data[:4],'little'),'tail4':data[-4:].hex()}

def _valid_utf8(data):
    try: data.decode('utf-8'); return True
    except UnicodeDecodeError: return False

def _valid_utf16(data):
    try: data.decode('utf-16le'); return True
    except UnicodeDecodeError: return False

def occurrences(needle, limit=200):
    found=[]
    for start,size,off in m.ranges:
        block=raw[off:off+size]
        pos=0
        while True:
            pos=block.find(needle,pos)
            if pos<0: break
            found.append(start+pos)
            pos += 1
            if len(found)>=limit: return found
    return found
report={
 'scope':'offline_local_config_blob_classification',
 'dump_sha256':expected,
 'encoded_field_offsets':['0x3b','0x9f','0x103'],
 'encoded_fields_identical':encoded[0]==encoded[1]==encoded[2],
 'encoded_sha256':hashlib.sha256(encoded[0]).hexdigest().upper(),
 'decoded':classify(decoded),
 'encoded_occurrences_in_dump':len(occurrences(encoded[0])),
 'decoded_occurrences_in_dump':len(occurrences(decoded)),
 'encoded_occurrence_addresses':[hex(x) for x in occurrences(encoded[0])],
 'decoded_occurrence_addresses':[hex(x) for x in occurrences(decoded)],
 'authorization_proven':False,
 'sample_executed':False,
 'raw_material_emitted':False,
 'limitations':['Occurrence search is bounded to captured MemoryList/Memory64 ranges.','A static occurrence does not prove a runtime producer or license semantics.']
}
(root/'blob-classification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
