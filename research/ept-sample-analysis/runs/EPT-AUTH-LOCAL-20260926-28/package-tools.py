"""Package installed Python and Capstone for offline Guest analysis; no samples."""
import hashlib
import json
import sys
import zipfile
from pathlib import Path
import capstone

out = Path(__file__).resolve().parent
archive = out / 'offline-python.zip'
base = Path(sys.base_prefix)
cap = Path(capstone.__file__).parent
excluded = {'site-packages', 'test', 'tests', '__pycache__', 'idlelib', 'tkinter', 'ensurepip', 'turtledemo'}
files = []
for name in ('python.exe','python3.dll','python311.dll','vcruntime140.dll','vcruntime140_1.dll'):
    source = base/name
    if source.is_file():
        files.append((source, name))
for folder in ('Lib','DLLs'):
    for source in (base/folder).rglob('*'):
        if source.is_file() and not set(source.relative_to(base/folder).parts)&excluded:
            files.append((source,source.relative_to(base).as_posix()))
for source in cap.rglob('*'):
    if source.is_file() and '__pycache__' not in source.parts:
        files.append((source,'Lib/site-packages/capstone/'+source.relative_to(cap).as_posix()))
with zipfile.ZipFile(archive,'x',zipfile.ZIP_DEFLATED) as z:
    for source,name in files:
        z.write(source,name)
manifest={'source_python':str(base),'python_version':sys.version,'capstone_version':capstone.__version__,'files':len(files),'archive_bytes':archive.stat().st_size,'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest().upper(),'content':'installed trusted tooling only; no sample or credentials'}
(out/'tooling.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print(json.dumps(manifest,indent=2))
