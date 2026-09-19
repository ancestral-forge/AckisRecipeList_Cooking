"""Install the local Cooking map extension into an existing ARL Classic addon."""
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

backup = source / "backups" / datetime.now().strftime("%Y%m%d-%H%M%S-%f")
backup.mkdir(parents=True)
shutil.copy2(toc, backup / toc.name)
installed = target / entry.decode()
if installed.exists():
    shutil.copy2(installed, backup / installed.name)

shutil.copy2(source / installed.name, installed)
toc.write_bytes(updated)
assert installed.read_bytes() == (source / installed.name).read_bytes()
assert toc.read_bytes() == updated
print(f"Installed: {installed}")
print(f"SHA256: {hashlib.sha256(installed.read_bytes()).hexdigest()}")
print(f"Backup: {backup}")
