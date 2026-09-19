"""Build frozen recipe/source expectations from the audit and installed TBC world data."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ADDONS = sys.argv[1] if len(sys.argv) > 1 else "/Applications/World of Warcraft/_anniversary_/Interface/AddOns"
world = json.loads(subprocess.check_output(["lua", str(ROOT / "tools/export-world.lua"), ADDONS], text=True))
baseline = json.loads((ROOT / "data/baseline.json").read_text())
current = {}
source_path = ROOT.parent / "Recipes.lua"
if not source_path.exists():
    source_path = Path(ADDONS) / "AckisRecipeList_Cooking/Recipes.lua"
source_text = source_path.read_text()
for block in re.split(r"(?=\s+recipe = AddRecipe\()", source_text):
    match = re.search(r"recipe = AddRecipe\((\d+), V\.(ORIG|TBC)", block)
    if match:
        current[int(match[1])] = {
            method: sorted({int(value) for args in re.findall(r"recipe:" + method + r"\(([^)]*)\)", block, re.S)
                            for value in re.findall(r"\b\d+\b", args)})
            for method in ("AddVendor", "AddTrainer", "AddQuest", "AddMobDrop")
        }
assert not set(current) - {r["spellID"] for r in baseline["recipes"]}, "New installed recipes need audit baselines"
maps = {
    1413: "The Barrens", 1416: "Alterac Mountains", 1417: "Arathi Highlands", 1418: "Badlands",
    1424: "Hillsbrad Foothills", 1425: "The Hinterlands", 1426: "Dun Morogh", 1429: "Elwynn Forest",
    1431: "Duskwood", 1432: "Loch Modan", 1433: "Redridge Mountains", 1434: "Stranglethorn Vale",
    1436: "Westfall", 1437: "Wetlands", 1438: "Teldrassil", 1439: "Darkshore", 1440: "Ashenvale",
    1443: "Desolace", 1444: "Feralas", 1445: "Dustwallow Marsh", 1446: "Tanaris", 1448: "Felwood",
    1451: "Silithus", 1452: "Winterspring", 1453: "Stormwind City", 1455: "Ironforge", 1457: "Darnassus",
    1943: "Azuremyst Isle", 1944: "Hellfire Peninsula", 1946: "Zangarmarsh", 1947: "The Exodar",
    1948: "Shadowmoon Valley", 1949: "Blade's Edge Mountains", 1950: "Bloodmyst Isle", 1951: "Nagrand",
    1952: "Terokkar Forest", 1955: "Shattrath City",
}
seasonal = {13420, 13429, 13432, 13433, 13435, 23010, 23012, 23064}
capitals_horde = {1454, 1456, 1458, 1954}
nodes, cases, excluded = {}, {}, []


def values(obj):
    return list(obj.values()) if isinstance(obj, dict) else list(obj or [])


def node(npc_id):
    if npc_id in nodes:
        return nodes[npc_id]
    npc = world["npcs"].get(str(npc_id))
    if not npc or npc.get("faction") not in ("A", "AH") or npc_id == 23012:
        return None
    positions = values(npc["positions"])
    positions.sort(key=lambda p: (p.get("mapID", 0), p["x"], p["y"]))
    valid = [p for p in positions if p.get("mapID") in maps and 0 < p["x"] <= 100 and 0 < p["y"] <= 100]
    if positions and all(p.get("mapID") in capitals_horde for p in positions):
        return None  # A neutral flag inside a hostile capital is not an Alliance stop.
    result = {"npcID": npc_id, "title": npc["name"], "faction": npc["faction"]}
    if valid:
        result.update({k: valid[0][k] for k in ("mapID", "x", "y")})
        result["zone"] = maps[result["mapID"]]
    elif npc_id in (12245, 12246):
        result.update(mapID=1443, zone=maps[1443], x=60 if npc_id == 12245 else 40, y=38 if npc_id == 12245 else 79,
                      approximate=True)
    elif npc_id == 8696:
        # Instance interior has no usable TBC zone coordinates: navigate to entrance.
        result.update(mapID=1413, zone=maps[1413], x=49, y=95, entrance=True)
    elif npc_id == 14354:
        result.update(mapID=1444, zone=maps[1444], x=64.9, y=30.2, entrance=True)
    else:
        result["deferred"] = "Нет проверенных координат TBC"
    if npc_id in seasonal:
        result["deferred"] = "Зимний Покров: проверять во время события"
    nodes[npc_id] = result
    return result


def add(recipe, kind, source_id, expected=True, confidence="uncertain", reason="Источник требует проверки", quest_id=None):
    npc = node(source_id) if kind in ("vendor", "trainer", "quest") else None
    if kind in ("vendor", "trainer", "quest") and not npc:
        excluded.append({"spellID": recipe["spellID"], "kind": kind, "sourceID": source_id, "questID": quest_id,
                         "reason": "Horde, hostile capital, or no TBC NPC entity"})
        return
    case_id = f"{kind}:{source_id}:{quest_id or 0}:{recipe['spellID']}"
    case = {"id": case_id, "spellID": recipe["spellID"], "name": recipe["name"], "items": recipe["items"],
            "kind": kind, "sourceID": source_id, "expected": expected, "confidence": confidence, "reason": reason}
    if quest_id:
        case["questID"] = quest_id
    if recipe["spellID"] == 9513:
        case["class"] = "ROGUE"
    if npc and npc.get("deferred"):
        case["deferred"] = npc["deferred"]
    elif kind not in ("vendor", "trainer", "quest"):
        case["deferred"] = "Требуется отдельная проверка происхождения; отсутствие за один заход ничего не опровергает"
    cases[case_id] = case


for recipe in baseline["recipes"]:
    if "ALLIANCE" not in recipe["factions"]:
        continue
    for kind, method in (("vendor", "AddVendor"), ("trainer", "AddTrainer"), ("quest", "AddQuest")):
        original = set(recipe["original"][method])
        revised = set(recipe["sources"][method])
        reference = set(x["npcId"] if isinstance(x, dict) else x for x in recipe["reference"][kind])
        if kind == "vendor":
            revised.update(x for args in recipe["repVendors"] for x in args[2:] if isinstance(x, int))
        installed = set(current.get(recipe["spellID"], {}).get(method, []))
        for source_id in sorted(original | revised | reference | installed):
            present = source_id in revised or source_id in reference
            agreed = source_id in original and source_id in revised and (not reference or source_id in reference)
            confidence = "confident" if agreed else "uncertain"
            reason = "Источник согласован в исходной базе и аудите; живой проверки ещё нет" if agreed else "Источник добавлен, удалён или расходится между базами"
            if kind == "vendor" and source_id == 2664 and recipe["spellID"] == 18246:
                present, confidence, reason = False, "uncertain", "Kelsey: две TBC-базы ожидают отсутствие; ARL указывает продажу"
            if kind == "vendor" and source_id == 4894 and recipe["spellID"] in (25704, 25954):
                present, confidence, reason = False, "confident", "Предыдущий полный живой магазин Craig: 18 товаров, этих рецептов нет"
            if source_id in (8137, 2803, 18382, 19186, 12245, 12246):
                confidence, reason = "uncertain", "Приоритетная гипотеза прошлого triage: нужна живая проверка"
            if kind == "quest":
                quest = world["quests"].get(str(source_id))
                if not quest:
                    excluded.append({"spellID": recipe["spellID"], "kind": "quest", "sourceID": source_id, "reason": "No TBC quest entity"})
                    continue
                # TBC race mask: human, dwarf, night elf, gnome, draenei.
                if quest.get("races", 0) and not quest["races"] & 1101:
                    continue
                contacts = set(values(quest.get("starts")) + values(quest.get("ends")))
                # These quests award random containers, not the recipe directly.
                if source_id in (11377, 11379, 11380, 11381, 11665, 11666, 11667, 11668, 11669):
                    for npc_id in contacts:
                        add(recipe, "container", npc_id, True, "uncertain", "Случайный рецепт в наградном контейнере; нужна добыча", source_id)
                        node(npc_id)
                else:
                    for npc_id in contacts:
                        add(recipe, kind, npc_id, present, confidence, reason, source_id)
            else:
                add(recipe, kind, source_id, present, confidence, reason)
    for method, kind in (("AddMobDrop", "drop"), ("AddWorldDrop", "world"), ("AddCustom", "custom")):
        for source_id in recipe["sources"][method]:
            add(recipe, kind, source_id, True, "uncertain", "Источник без гарантированной проверки меню")
            if kind == "drop":
                node(source_id)
    # Container IDs from independent references, including sources omitted by ARL.
    for item_id in recipe["reference"]["loot"]:
        add(recipe, "loot", item_id, True, "uncertain", "Ожидается в добыче предмета/контейнера; не гарантированное выпадение")

# Keep only NPCs actually used by a case or an explicit container contact.
used = {c["sourceID"] for c in cases.values() if c["kind"] in ("vendor", "trainer", "quest", "container", "drop")}
nodes = {i: n for i, n in nodes.items() if i in used}
flights = {}
for npc_id in world["flights"]:
    npc = world["npcs"].get(npc_id)
    if npc:
        for p in values(npc["positions"]):
            if p.get("mapID") in maps and 0 < p["x"] < 100 and 0 < p["y"] < 100:
                flights[int(npc_id)] = {"npcID": int(npc_id), "title": npc["name"], "zone": maps[p["mapID"]],
                                        "mapID": p["mapID"], "x": p["x"], "y": p["y"]}
                break
ordered = sorted(cases.values(), key=lambda c: c["id"])
payload = {"nodes": nodes, "cases": ordered}
revision = hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()[:16]


def lua(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return "{" + ",".join(map(lua, value)) + "}"
    if isinstance(value, dict):
        return "{" + ",".join(f"[{lua(k)}]={lua(v)}" for k, v in value.items()) + "}"
    raise TypeError(value)


lines = ["-- Generated by guides/tools/build-catalog.py; edit the inputs, not this file.", "local _, addon = ...",
         f"addon.catalogRevision = {lua(revision)}", "addon.nodes = {"]
lines.extend(f"    [{i}] = {lua(n)}," for i, n in sorted(nodes.items()))
lines += ["}", "addon.flightNodes = " + lua(flights), "addon.catalog = {"]
lines.extend("    " + lua(c) + "," for c in ordered)
lines += ["}", ""]
(ROOT / "Guidelime_CookingTriage/Catalog.lua").write_text("\n".join(lines))
(ROOT / "data/excluded.json").write_text(json.dumps(excluded, ensure_ascii=False, indent=2) + "\n")
(ROOT / "data/current-sources.json").write_text(json.dumps(current, indent=2, sort_keys=True) + "\n")
counts = {tier: sum(c["confidence"] == tier for c in ordered) for tier in ("confident", "uncertain")}
print(f"Catalogue {revision}: {len(nodes)} NPCs, {len(ordered)} cases, {counts}")
print("Regular nodes:", ", ".join(str(i) for i, n in sorted(nodes.items()) if not n.get("deferred")))
