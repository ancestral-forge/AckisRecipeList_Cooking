-- Run with: lua local-patches/AckisRecipeList/tests/cooking-map.lua
local source = "local-patches/AckisRecipeList/CookingMap.lua"
local timers, frames, world, mini, known, recipes = {}, {}, {}, {}, {}, {}
local skill, faction, collapsed = 100, "Alliance", false
local reputation, modernReputation = 4, false
local scanHook, route, printMessage
local function check(value, message) assert(value, message) end
-- Events supported by the TBC Anniversary client (Interface 20506).
local supportedEvents = {
    PLAYER_ENTERING_WORLD = true, SKILL_LINES_CHANGED = true, CHAT_MSG_SKILL = true,
    SPELLS_CHANGED = true, TRADE_SKILL_UPDATE = true, UPDATE_FACTION = true,
}

local function surface()
    local object = { scripts = {}, events = {} }
    for _, method in ipairs({ "SetSize", "SetPoint", "ClearAllPoints", "SetAllPoints", "EnableMouseWheel", "RegisterForClicks" }) do
        object[method] = function() end
    end
    function object:SetColorTexture(r, g, b) self.color = { r, g, b } end
    function object:SetTexture(texture) self.texture = texture end
    function object:CreateTexture() return surface() end
    function object:SetScript(event, callback) self.scripts[event] = callback end
    function object:RegisterEvent(event)
        check(supportedEvents[event], "Attempt to register unknown event " .. tostring(event))
        self.events[event] = true
    end
    function object:Hide() self.hidden = true end
    return object
end
function CreateFrame(kind, _, parent)
    local object = surface()
    if kind == "Button" and parent then parent.button = object end
    frames[#frames + 1] = object
    return object
end
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
local function Flush()
    local iterations = 0
    while #timers > 0 do
        iterations = iterations + 1
        assert(iterations < 20, "refresh loop")
        local pending = timers
        timers = {}
        for _, callback in ipairs(pending) do callback() end
    end
end
local function Event(name)
    check(frames[1].events[name], "event was not registered: " .. name)
    frames[1].scripts.OnEvent(frames[1], name)
end
function GetLocale() return "ruRU" end
function UnitFactionGroup() return faction end
function IsPlayerSpell(id) return known[id] end
function IsSpellKnown(id) return known[id] end
function GetNumSkillLines() return collapsed and 1 or 2 end
function GetSkillLineInfo(index)
    if index == 1 then return "Вторичные навыки", true, not collapsed end
    return "Кулинария", false, nil, skill
end
function ExpandSkillHeader() collapsed = false; Event("SKILL_LINES_CHANGED") end
function CollapseSkillHeader() collapsed = true; Event("SKILL_LINES_CHANGED") end
function GetFactionInfoByID() return "Faction", nil, reputation end
FACTION_STANDING_LABEL5 = "Дружелюбие"
FACTION_STANDING_LABEL6 = "Уважение"
FACTION_STANDING_LABEL7 = "Почтение"
HBD_PINS_WORLDMAP_SHOW_WORLD = 3
SlashCmdList = {}
function hooksecurefunc(_, name, callback)
    check(name == "Scan", "only scan hooked")
    scanHook = callback
end
GameTooltip = { lines = {} }
function GameTooltip:SetOwner(owner) self.owner = owner; self.lines = {} end
function GameTooltip:SetText(text) self.lines[#self.lines + 1] = text end
function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = text end
function GameTooltip:AddDoubleLine(left, right) self.lines[#self.lines + 1] = left .. right end
function GameTooltip:IsOwned(owner) return self.owner == owner end
function GameTooltip:Hide() self.owner = nil end
function GameTooltip:Show() end
TomTom = { AddWaypoint = function(_, mapID, x, y, options) route = { mapID, x, y, options } end }

local function acquire(label)
    local object = { entities = {} }
    function object:GetEntity(id) return self.entities[id] end
    function object:Label() return label end
    function object:Name() return label end
    return object
end
local types = {}
for _, name in ipairs({ "Vendor", "Trainer", "Reputation", "Quest", "MobDrop", "WorldDrop" }) do
    types[name] = acquire(name)
end
local function location(mapID, parent, entranceX, entranceY)
    return {
        MapID = function() return mapID end,
        LocalizedName = function() return "Zone " .. mapID end,
        Parent = function() return parent end,
        EntranceCoordinates = function() return entranceX, entranceY end,
    }
end
local function entity(id, who, loc, x, y, expansion)
    return { name = "NPC " .. id, faction = who or "Alliance", Location = loc or location(1),
        coord_x = x or 50, coord_y = y or 60, expansionID = expansion or 1 }
end
types.Vendor.entities[1] = entity(1)
types.Trainer.entities[1] = entity(1)
types.Vendor.entities[2] = entity(2, "Horde")
types.Vendor.entities[3] = entity(3, "Neutral")
types.Reputation.entities[10] = { name = "Rep faction" }
local function recipe(id, required, yellow, green, grey, sources, expansion)
    local object = { skill_level = required, medium_level = yellow, easy_level = green, trivial_level = grey }
    function object:SpellID() return id end
    function object:LocalizedName() return "Recipe " .. id end
    function object:ExpansionID() return expansion or 1 end
    function object:AcquirePairs() return pairs(sources or { [types.Vendor] = { [1] = true } }) end
    recipes[id] = object
    return object
end
local addon = { db = { profile = {} } }
function addon:InitializeProfession(name, suppress)
    check(name == "Кулинария" and suppress, "silent localized init")
    return true
end
function addon:Print(message) printMessage = message end
local private = {
    addon_name = "Ackis Recipe List", AcquireTypes = types,
    MODULE_NAME_TO_LOCALIZED_PROFESSION_NAME_MAPPING = { Cooking = "Кулинария" },
    GetEffectiveExpansionID = function() return 2 end,
    Professions = { Cooking = { Recipes = recipes } },
    Player = { HasRecipeFaction = function(_, data) return not data.wrongFaction end },
    quest_names = {},
    DIFFICULTY_COLORS = {
        impossible = { r = 1, g = 0, b = 0 }, trivial = { r = 0.5, g = 0.5, b = 0.5 },
        easy = { r = 0.25, g = 0.75, b = 0.25 }, medium = { r = 1, g = 1, b = 0 },
        optimal = { r = 1, g = 0.5, b = 0.25 },
    },
}
local HBD = {
    GetLocalizedMap = function(_, id) return id > 0 and id <= 3 and ("Zone " .. id) or nil end,
    GetAllMapIDs = function() return { 1, 2, 3 } end,
}
local pinAPI = {}
function pinAPI:RemoveAllWorldMapIcons() world = {} end
function pinAPI:RemoveAllMinimapIcons() mini = {} end
function pinAPI:AddWorldMapIconMap(_, pin, mapID, x, y, flag)
    check(flag == 3 and mapID > 0 and x > 0 and x <= 1 and y > 0 and y <= 1, "valid map position")
    world[#world + 1] = pin.button
end
function pinAPI:AddMinimapIconMap(_, pin) mini[#mini + 1] = pin.button end
function LibStub(name)
    if name == "AceAddon-3.0" then return { GetAddon = function() return addon end } end
    if name == "HereBeDragons-2.0" then return HBD end
    if name == "HereBeDragons-Pins-2.0" then return pinAPI end
    error(name)
end
assert(loadfile(source))("AckisRecipeList", private)

recipe(1, 100, 125, 150, 175)
for _, case in ipairs({ { 99, "impossible" }, { 100, "optimal" }, { 124, "optimal" },
    { 125, "medium" }, { 149, "medium" }, { 150, "easy" }, { 174, "easy" }, { 175, "trivial" } }) do
    skill = case[1]; Event("SKILL_LINES_CHANGED"); Flush()
    check(#world == 1 and world[1].group.difficulty == case[2], "difficulty at " .. skill)
    check(world[1] ~= mini[1] and world[1].group == mini[1].group, "independent map frames")
    check(world[1].icon.texture:match("VendorGossipIcon"), "vendor bag texture")
end
print("PASS: all five colors and exact skill boundaries; separate map/minimap frames")

skill = 100
recipe(2, 10, 20, 30, 40)
recipe(3, 150, 175, 200, 225)
recipe(4, 100, 125, 150, 175, { [types.Trainer] = { [1] = true } })
recipe(5, 100, 125, 150, 175, { [types.Vendor] = { [2] = true } })
recipe(6, 100, 125, 150, 175, { [types.Vendor] = { [3] = true } }, 3)
recipe(7, 100, 125, 150, 175, { [types.Vendor] = { [3] = true } }).wrongFaction = true
scanHook(); Flush()
check(#world == 2, "trainer and vendor separated; wrong faction and future recipes excluded")
local vendor, trainer
for _, pin in ipairs(world) do
    if pin.group.acquireType == types.Vendor then vendor = pin else trainer = pin end
end
check(#vendor.group.recipes == 3 and vendor.group.difficulty == "optimal", "mixed recipes retained, red does not mask available")
check(trainer.icon.texture:match("Tracking\\Profession"), "profession trainer texture")
check(vendor.group.offsetX ~= trainer.group.offsetX, "vendor and trainer at identical coordinates do not cover each other")
known[1], known[4] = true, true
Event("SPELLS_CHANGED"); Flush()
check(#world == 1 and #world[1].group.recipes == 2 and world[1].group.difficulty == "trivial", "known recipes removed and learned-only trainer gone")
known[2] = true; Event("SPELLS_CHANGED"); Flush()
check(world[1].group.difficulty == "impossible", "all remaining recipes locked")
print("PASS: NPC aggregation, priority, learning events, source textures, faction and expansion filters")

recipe(8, 50, 125, 150, 175, { [types.Reputation] = { [10] = { [1] = { [3] = true }, [3] = { [3] = true } } } })
Event("UPDATE_FACTION"); Flush()
local function RepPin()
    for _, pin in ipairs(world) do if pin.group.name == "NPC 3" then return pin end end
end
check(RepPin().group.difficulty == "impossible" and RepPin().group.recipes[1].blocked, "missing rep red")
reputation = 5; Event("UPDATE_FACTION"); Flush()
check(RepPin().group.difficulty == "optimal" and not RepPin().group.recipes[1].blocked, "one sufficient rep route unlocks recipe")
reputation = 4
C_Reputation = { GetFactionDataByID = function() modernReputation = true; return { reaction = 5 } end }
Event("UPDATE_FACTION"); Flush()
check(modernReputation and RepPin().group.difficulty == "optimal", "modern reputation API")
C_Reputation = nil
skill = 20; reputation = 5; Event("SKILL_LINES_CHANGED"); Flush()
check(RepPin().group.difficulty == "impossible" and not RepPin().group.recipes[1].blocked, "skill blocked with unlocked rep alternative")
print("PASS: source-specific reputation requirements, alternative unlocks and both reputation APIs")

types.Vendor.entities[9] = entity(9, "Neutral", location(99, location(2), 30, 40))
types.Vendor.entities[10] = entity(10, "Neutral", location(99, location(2)))
types.Vendor.entities[11] = entity(11, "Neutral", location(1), 101, 60)
recipe(9, 10, 20, 30, 40, { [types.Vendor] = { [9] = true, [10] = true, [11] = true, [999] = true } })
Event("SPELLS_CHANGED"); Flush()
local entrance
for _, pin in ipairs(world) do
    if pin.group.name == "NPC 9" then entrance = pin end
    check(pin.group.name ~= "NPC 10" and pin.group.name ~= "NPC 11", "no guessed parent or invalid coordinates")
end
check(entrance and entrance.group.mapID == 2 and entrance.group.x == 0.3, "dungeon entrance coordinates")
entrance.scripts.OnClick(entrance)
check(route[1] == 2 and route[2] == 0.3 and not route[4].persistent, "TomTom route uses same position")
collapsed = true; Event("SKILL_LINES_CHANGED"); Flush()
check(collapsed and #world > 0, "collapsed skills detected and restored without loop")
print("PASS: dungeon entrances, missing entities, invalid coordinates, TomTom and collapsed skill headers")

for id = 20, 50 do recipe(id, 10, 20, 30, 40) end
skill = 100; Event("SKILL_LINES_CHANGED"); Flush()
for _, pin in ipairs(world) do if pin.group.name == "NPC 1" then vendor = pin end end
vendor.scripts.OnEnter(vendor)
check(table.concat(GameTooltip.lines, "\n"):match("Колесо мыши"), "long list scrolling hint")
vendor.scripts.OnMouseWheel(vendor, -100)
check(vendor.offset == #vendor.group.recipes - 16, "last page accessible")
vendor.scripts.OnMouseWheel(vendor, 100)
check(vendor.offset == 0, "first page accessible")
local count = #frames
for _ = 1, 5 do Event("SPELLS_CHANGED"); Event("SKILL_LINES_CHANGED"); Event("UPDATE_FACTION"); Flush() end
check(#frames == count, "frames reused across refreshes")
SlashCmdList.ARLCOOKINGMAP("off"); Flush()
check(#world == 0 and #mini == 0 and printMessage:match("выключены"), "off removes only own pins")
SlashCmdList.ARLCOOKINGMAP("on"); Flush()
check(#world > 0, "on restores pins")
skill = nil; Event("SKILL_LINES_CHANGED"); Flush()
check(#world == 0 and #mini == 0, "unlearning Cooking clears map")
print("PASS: tooltip pagination, event coalescing, frame reuse, toggle and unlearned profession")

-- The standard profession API must also work without Classic skill-line APIs.
GetProfessions = function() return nil, nil, nil, nil, 5 end
GetProfessionInfo = function() return "Кулинария", nil, 200, nil, nil, nil, 185 end
GetNumSkillLines = nil
Event("SKILL_LINES_CHANGED"); Flush()
check(#world > 0 and world[1].group.rank == 200, "profession API with sparse return values")
print("PASS: modern skill API")

-- Optional smoke test against a real installed Cooking catalog (no WoW client).
if arg[1] then
    recipes, known = {}, {}
    private.Professions.Cooking.Recipes = recipes
    private.ZONE_LABELS_FROM_NAME = {}
    local function labelsTable()
        return setmetatable({}, { __index = function(self, key) self[key] = key; return key end })
    end
    addon.constants = {
        GAME_VERSIONS = { ORIG = 1, TBC = 2, WOTLK = 3, CATA = 4, MOP = 5, WOD = 6, LEGION = 7, BFA = 8 },
        ZONE_NAMES = labelsTable(), BOSS_NAMES = labelsTable(), FILTER_IDS = labelsTable(),
        ACQUIRE_TYPE_IDS = labelsTable(), ITEM_QUALITIES = labelsTable(),
        FACTION_IDS = labelsTable(), REP_LEVELS = { NEUTRAL = 0, FRIENDLY = 1, HONORED = 2, REVERED = 3, EXALTED = 4 },
    }
    local module = {}
    function addon:GetModule() return module end
    addon.AcquireTypes = types
    for _, acquireType in pairs(types) do
        acquireType.entities = {}
        function acquireType:AddEntity(_, data)
            if data.expansionID and data.expansionID > 2 then return end
            local name = data.locationName
            private.ZONE_LABELS_FROM_NAME[name] = name
            data.Location = {
                LocalizedName = function() return name end,
                MapID = function() return -1 end,
                EntranceCoordinates = function() end,
            }
            self.entities[data.identifier] = data
        end
    end
    function addon:AddTrainer(ownerModule, data) types.Trainer:AddEntity(ownerModule, data) end
    function GetSpellInfo(id) return "Spell " .. id end
    function addon:AddRecipe(_, data)
        local sources = {}
        local object = recipe(data._spellID, 1, 10, 20, 30, sources, data._expansionID)
        function object:SetSkillLevels(required, _, yellow, green, grey)
            self.skill_level, self.medium_level, self.easy_level, self.trivial_level = required, yellow, green, grey
        end
        for method, acquireType in pairs({ AddVendor = types.Vendor, AddTrainer = types.Trainer,
            AddQuest = types.Quest, AddMobDrop = types.MobDrop }) do
            object[method] = function(_, ...)
                sources[acquireType] = sources[acquireType] or {}
                for _, id in ipairs({ ... }) do sources[acquireType][id] = true end
            end
        end
        function object:AddLimitedVendor(...)
            local ids = { ... }
            for index = 1, #ids, 2 do self:AddVendor(ids[index]) end
        end
        function object:AddRepVendor(factionID, level, ...)
            sources[types.Reputation] = sources[types.Reputation] or {}
            local dataByFaction = sources[types.Reputation]
            dataByFaction[factionID] = dataByFaction[factionID] or {}
            dataByFaction[factionID][level] = dataByFaction[factionID][level] or {}
            for _, id in ipairs({ ... }) do dataByFaction[factionID][level][id] = true end
        end
        function object:SetRequiredFaction(required) self.requiredFaction = required end
        for _, method in ipairs({ "SetCraftedItem", "SetRecipeItem", "AddFilters", "AddCustom", "Retire",
            "AddAchievement", "AddWorldDrop", "AddWorldEvent" }) do object[method] = function() end end
        return object
    end
    function private.Player:HasRecipeFaction(data) return not data.requiredFaction or data.requiredFaction == faction end
    local oldLibStub = LibStub
    function LibStub(name)
        if name == "AceLocale-3.0" then return { GetLocale = function() return labelsTable() end } end
        return oldLibStub(name)
    end
    local databasePrivate = { addon = addon, module_name = "Cooking" }
    for _, file in ipairs({ "Trainers", "Vendors", "Quests", "MobDrops", "Recipes" }) do
        assert(loadfile(arg[1] .. "/" .. file .. ".lua"))("AckisRecipeList_Cooking", databasePrivate)
        module["Initialize" .. file](module)
    end
    HBD.GetLocalizedMap = function(_, id) return id >= 1400 and id <= 2000 and ("Localized zone " .. id) or nil end
    GetProfessionInfo = function() return "Кулинария", nil, skill, nil, nil, nil, 185 end
    local total = 0
    for _, data in pairs(recipes) do if data:ExpansionID() <= 2 then total = total + 1 end end
    for _, side in ipairs({ "Alliance", "Horde" }) do
        faction = side
        for _, rank in ipairs({ 1, 100, 175, 225, 300, 375 }) do
            skill = rank; Event("SKILL_LINES_CHANGED"); Flush()
            check(#world > 25 and #world == #mini, "real catalog generated pins for " .. side)
            for _, pin in ipairs(world) do
                check(pin.group.mapID >= 1400, "Classic map ID used for fallback English labels in localized client")
                for _, entry in ipairs(pin.group.recipes) do
                    check(entry.recipe:ExpansionID() <= 2, "no post-TBC catalog recipe")
                end
            end
        end
        print(("PASS: installed %s catalog, %d Classic/TBC recipes, %d source pins; skill 1/100/175/225/300/375")
            :format(side, total, #world))
    end
end
