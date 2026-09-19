"""Install the Cooking Triage content pack; leave its dependencies untouched."""
from datetime import datetime
import hashlib
from pathlib import Path
import shutil
import sys


root = Path(__file__).resolve().parent
source = root / "Guidelime_CookingTriage"
addons = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
    "/Applications/World of Warcraft/_anniversary_/Interface/AddOns"
)
target = addons / source.name
files = ("Guidelime_CookingTriage.toc", "Catalog.lua", "SkillChecks.lua", "Route.lua", "Verification.lua",
         "Recorder.lua", "Review.lua", "TomTom.lua", "Guides.lua")
for dependency in ("Guidelime", "TomTom"):
    if not (addons / dependency).is_dir():
        raise SystemExit(f"Missing dependency: {addons / dependency}")
for name in files:
    if not (source / name).is_file():
        raise SystemExit(f"Missing source: {source / name}")

existing = [name for name in files if (target / name).exists()]
if existing:
    backup = root / "backups" / datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup.mkdir(parents=True)
    for name in existing:
        shutil.copy2(target / name, backup / name)
    print(f"Backup: {backup}")

target.mkdir(parents=True, exist_ok=True)
for name in files:
    shutil.copy2(source / name, target / name)
    data = (target / name).read_bytes()
    if data != (source / name).read_bytes():
        raise SystemExit(f"Verification failed: {target / name}")
    print(f"{hashlib.sha256(data).hexdigest()}  {name}")
print(f"Installed and verified: {target}")
