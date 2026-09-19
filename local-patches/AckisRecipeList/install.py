"""Install local Cooking patches into an existing ARL Classic addon."""
import hashlib
from datetime import datetime
from pathlib import Path
import shutil
import sys


source = Path(__file__).resolve().parent
target = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
    "/Applications/World of Warcraft/_anniversary_/Interface/AddOns/AckisRecipeList"
)
toc = target / "AckisRecipeList.toc"
original = toc.read_bytes()
assert (target / "Waypoint.lua").is_file(), "Ackis Recipe List core not found"
newline = b"\r\n" if b"\r\n" in original else b"\n"
entry = b"CookingMap.lua"
updated = original
if entry not in [line.strip() for line in original.splitlines()]:
    updated = original.rstrip(b"\r\n") + newline + newline + entry + newline

patched_files = [
    Path("CookingMap.lua"),
    Path("Objects/AcquireType/Vendor.lua"),
]
backup = source / "backups" / datetime.now().strftime("%Y%m%d-%H%M%S-%f")
backup.mkdir(parents=True)
shutil.copy2(toc, backup / toc.name)
for relative in patched_files:
    installed = target / relative
    if installed.exists():
        backup_target = backup / relative
        backup_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(installed, backup_target)

for relative in patched_files:
    installed = target / relative
    installed.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / relative, installed)
    assert installed.read_bytes() == (source / relative).read_bytes()
toc.write_bytes(updated)
assert toc.read_bytes() == updated
for relative in patched_files:
    installed = target / relative
    print(f"Installed: {installed}")
    print(f"SHA256: {hashlib.sha256(installed.read_bytes()).hexdigest()}")
print(f"Backup: {backup}")
