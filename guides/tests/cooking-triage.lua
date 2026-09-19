-- Run from the repository root. Exercises the installed Guidelime parser and
-- custom-code dispatcher; WoW frames and TomTom are mocked, not a live UI test.
local addons = arg[1] or "/Applications/World of Warcraft/_anniversary_/Interface/AddOns/"
local engine = addons .. "Guidelime/"
local source = "guides/Guidelime_CookingTriage/"
local pack, lime, frames, registered = {}, {}, {}, {}
local function load(path, name, namespace) assert(loadfile(path))(name, namespace) end
GetBuildInfo = function() return "2.5.6", "69546", "", 20506 end
GetLocale = function() return "enUS" end
local hbd = {
    GetWorldCoordinatesFromZone = function(_, x, y, map) assert(map); return x, y, map end,
    GetLocalizedMap = function() return nil end,
}
LibStub = function(name) assert(name == "HereBeDragons-2.0"); return hbd end
CreateFrame = function()
    local frame = { scripts = {} }
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    function frame:RegisterEvent() end
    function frame:UnregisterAllEvents() end
    frames[#frames + 1] = frame
    return frame
end
lime.L = setmetatable({}, { __index = function(_, key) return key .. ": %s %s %s" end })
lime.D = {
    faction = "Alliance",
    isClass = function(value) return value == "ROGUE" end,
    getClass = function() return "Rogue" end,
    isFaction = function(value) return value == "ALLIANCE" end,
    getFaction = function() return "Alliance" end,
    isRace = function() return false end,
    isReputation = function() return false end,
    applies = function(step) return not step.classes or step.classes[1] == "Rogue" end,
}
lime.MW = { COLOR_WHITE = "|cFFFFFFFF", COLOR_INACTIVE = "|cFFAAAAAA" }
lime.F = { createPopupFrame = function(message) error(message) end }
load(engine .. "Data/MapDB.lua", "Guidelime", lime)
load(engine .. "Data/FlightmasterDB.lua", "Guidelime", lime)
load(engine .. "GuideParser.lua", "Guidelime", lime)
load(engine .. "CustomCode.lua", "Guidelime", lime)
Guidelime = { registerGuide = function(text, group)
    registered[#registered + 1] = assert(lime.GP.parseGuide(text, group, true, false))
end }
GuidelimeDataChar = {}
local points, removed, arrows, nextID, failAdd = {}, {}, {}, 0, false
local foreign = {}
points[foreign] = true
TomTom = { profile = { arrow = { enable = false } } }
function TomTom:AddWaypoint(map, x, y, options)
    if failAdd then return nil end
    nextID = nextID + 1
    local uid = { id = nextID, map = map, x = x, y = y, options = options }
    points[uid] = true
    return uid
end
function TomTom:IsValidWaypoint(uid) return points[uid] end
function TomTom:RemoveWaypoint(uid) assert(points[uid]); points[uid] = nil; removed[#removed + 1] = uid end
function TomTom:SetCrazyArrow(uid, distance, title)
    assert(points[uid] and self.profile.arrow.enable and distance == 10 and title)
    arrows[#arrows + 1] = uid
end
load(source .. "Catalog.lua", "Guidelime_CookingTriage", pack)
local dailyCase
for _, case in ipairs(pack.catalog) do
    if case.id == "container:24393:11377:43707" then dailyCase = case end
end
assert(dailyCase and dailyCase.requiresLevel == 70 and dailyCase.reward == "daily"
    and dailyCase.deferred:match("фактический loot"))
load(source .. "SkillChecks.lua", "Guidelime_CookingTriage", pack)
load(source .. "Seasons.lua", "Guidelime_CookingTriage", pack)
local winterText = pack.SeasonText("WINTER_VEIL", os.time({year = 2026, month = 9, day = 19, hour = 12}))
assert(winterText:match("Feast of Winter Veil") and winterText:match("2026%-12%-16") and winterText:match("2027%-01%-02"))
load(source .. "Route.lua", "Guidelime_CookingTriage", pack)
load(source .. "TomTom.lua", "Guidelime_CookingTriage", pack)
local watcher = frames[1]
load(source .. "Guides.lua", "Guidelime_CookingTriage", pack)
assert(#registered == 3 and registered[1].title == pack.title)
local guide = registered[1]
assert(guide.faction == "Alliance" and registered[2].faction == "Alliance")
assert(guide.next[1] == registered[2].title)
assert(not guide.autoAddCoordinatesGOTO and not guide.autoAddCoordinatesLOC)
local steps, count = {}, 0
for _, step in ipairs(guide.steps) do
    if step.eval then
        count = count + 1
        local index = assert(tonumber(step.eval:match(",(%d+)$")))
        assert(not steps[index])
        steps[index] = step
        local point, loc, flight, target = pack.route[index]
        for _, element in ipairs(step.elements) do
            assert(element.t ~= "GOTO" and element.t ~= "VENDOR" and element.t ~= "TRAIN"
                and element.t ~= "ACCEPT" and element.t ~= "TURNIN", "Verification must remain manual")
            if element.t == "LOC" then loc = element end
            if element.t == "TARGET" then target = element end
            if element.t == "FLY" then flight = element end
        end
        assert((loc ~= nil) == (point.mapID ~= nil))
        if loc then assert(loc.mapID == point.mapID and loc.x == point.x and loc.y == point.y) end
        if point.npcID then assert(target.targetNpcId == point.npcID) end
        if point.flight then
            assert(flight and flight.flightmaster, "Unknown flight destination: " .. point.flight)
            assert(lime.FM.flightmasterDB[flight.flightmaster].faction ~= "Horde")
        end
        if point.applies then assert(step.classes[1] == point.applies) end
    end
end
assert(count == pack.mainRouteLength)
lime.guides = { [guide.name] = guide }
GuidelimeDataChar.currentGuide = guide.name
lime.CC.parseCustomLuaCode()
assert(#lime.CC.customCodeData == count)
local function call(index, event)
    local frame = lime.CC.customCodeData[index]
    assert(frame.data.step == steps[index] and frame[event])
    frame[event](frame.data, frame.args, event)
end
local first, second
for index, point in ipairs(pack.route) do
    if point.kind == "verify" then if not first then first = index elseif not second then second = index end end
end
call(first, "OnStepUpdate")
assert(#arrows == 0, "Inactive step created an arrow")
steps[first].active = true
call(first, "OnStepActivation")
local uid = arrows[1]
assert(uid and uid.map == pack.route[first].mapID and uid.x == pack.route[first].x / 100)
assert(uid.options.crazy and not uid.options.persistent and uid.options.cleardistance == 0)
call(first, "OnStepUpdate")
assert(#arrows == 1, "Update duplicated the waypoint")
-- Completion of a different step must not clear the selected waypoint.
call(second, "OnStepCompletion")
assert(points[uid])
-- Switching directly to another step replaces only our point.
steps[first].active = false
steps[second].active = true
call(second, "OnStepActivation")
assert(not points[uid] and points[foreign] and #arrows == 2)
steps[second].completed = true
call(second, "OnStepCompletion")
assert(not TomTom.profile.arrow.enable and points[foreign])
steps[second].completed = false
call(second, "OnStepActivation")
GuidelimeDataChar.currentGuide = "another guide"
lime.CC.wipeFrameData()
watcher.scripts.OnUpdate(watcher, 0.3)
assert(not points[arrows[3]] and not TomTom.profile.arrow.enable)
GuidelimeDataChar.currentGuide = guide.name
lime.CC.parseCustomLuaCode()
TomTom.profile.arrow.enable = true
call(second, "OnStepActivation")
steps[second].skip = true
watcher.scripts.OnUpdate(watcher, 0.3)
assert(not points[arrows[4]] and TomTom.profile.arrow.enable)
steps[second].skip = false
TomTom.profile.arrow.enable = false
failAdd = true
call(second, "OnStepActivation")
assert(not TomTom.profile.arrow.enable, "Failed waypoint changed the user's setting")
failAdd = false
call(second, "OnStepActivation")
steps[second].active = false
steps[1].active = true
call(1, "OnStepActivation")
assert(not points[arrows[5]] and not TomTom.profile.arrow.enable)
steps[1].active = false
steps[second].active = true
call(second, "OnStepActivation")
watcher.scripts.OnEvent()
assert(not points[arrows[6]] and points[foreign] and not TomTom.profile.arrow.enable)

-- Independent TBC data checks: faction, zone, NPC coordinates and quest contact.
local db, zones = {}, { private = {} }
QuestieLoader = { ImportModule = function(_, name) return name == "ZoneDB" and zones or db end }
load(addons .. "Questie/Database/TBC/tbcNpcDB.lua")
load(addons .. "Questie/Database/TBC/tbcQuestDB.lua")
load(addons .. "Questie/Database/Zones/data/areaIdToUiMapId.lua")
local compile = loadstring or _G.load
local npcs, quests, maps = assert(compile(db.npcData))(), assert(compile(db.questData))(),
    assert(compile(zones.private.areaIdToUiMapId))()
local checks, uniqueRecipes, uniqueNPCs = 0, {}, {}
for _, point in ipairs(pack.route) do
    if point.npcID then
        local npc = assert(npcs[point.npcID])
        assert(npc[13] == "A" or npc[13] == "AH", "Non-Alliance NPC: " .. npc[1])
        if not point.approximate and not point.entrance and not point.deferred then
            local found = false
            for area, positions in pairs(npc[7] or {}) do
                if maps[area] == point.mapID then
                    for _, position in ipairs(positions) do
                        if math.abs(position[1] - point.x) < 0.5 and math.abs(position[2] - point.y) < 0.5 then found = true end
                    end
                end
            end
            assert(found, "NPC coordinate mismatch: " .. npc[1])
        end
        if point.kind == "verify" then checks = checks + 1; uniqueNPCs[point.npcID] = true end
        for _, case in ipairs(pack.catalog) do if case.sourceID == point.npcID then uniqueRecipes[case.spellID] = true end end
        for _, questID in ipairs(point.quests or {}) do
            local quest, found = assert(quests[questID]), false
            for _, column in ipairs({2, 3}) do
                for _, npcID in ipairs(quest[column] and quest[column][1] or {}) do
                    if npcID == point.npcID then found = true end
                end
            end
            assert(found, "Quest has a different contact: " .. questID)
        end
    end
end
for _, npcID in ipairs({8137,2803,18382,19186,4210,5482,12245,12246,2664,7947,6286,4200}) do
    assert(uniqueNPCs[npcID], "Missing primary audit source: " .. npcID)
end
local recipeCount = 0
for _ in pairs(uniqueRecipes) do recipeCount = recipeCount + 1 end
-- Every source node is visited exactly once, including deferred seasonal nodes.
local visited, caseIDs = {}, {}
for index, point in ipairs(pack.route) do
    if point.kind == "verify" then
        assert(not visited[point.npcID], "Duplicate NPC visit: " .. point.npcID)
        visited[point.npcID] = true
        assert((index > pack.mainRouteLength) == (point.deferred ~= nil))
        for _, id in ipairs(point.caseIDs) do assert(not caseIDs[id]); caseIDs[id] = true end
    end
end
for id in pairs(pack.nodes) do assert(visited[id], "Source omitted from the route: " .. id) end
local uniqueCases = {}
for _, case in ipairs(pack.catalog) do
    assert(not uniqueCases[case.id]); uniqueCases[case.id] = true
    assert(type(case.expected) == "boolean" and (case.confidence == "confident" or case.confidence == "uncertain"))
    if case.kind == "vendor" or case.kind == "trainer" or case.kind == "quest" or case.kind == "container" or case.kind == "drop" then
        assert(caseIDs[case.id], "Source prediction omitted from its NPC step: " .. case.id)
    end
    if case.questID then
        local quest, contact = assert(quests[case.questID]), false
        for _, column in ipairs({2,3}) do
            for _, id in ipairs(quest[column] and quest[column][1] or {}) do if id == case.sourceID then contact = true end end
        end
        assert(contact, "Quest contact mismatch: " .. case.id)
    end
end
-- Load the second guide through the real custom-code dispatcher. Its route
-- indices continue after the main guide, rather than reusing the first NPC.
local deferred = registered[2]
lime.guides[deferred.name] = deferred
GuidelimeDataChar.currentGuide = deferred.name
lime.CC.parseCustomLuaCode()
local callbackCount = 0
for _, frame in ipairs(lime.CC.customCodeData) do
    if frame.data then
        local index = tonumber(frame.args[1]); assert(index > pack.mainRouteLength)
        frame.data.step.active = true
        frame.OnStepActivation(frame.data,frame.args,"OnStepActivation")
        frame.data.step.completed = true
        frame.OnStepCompletion(frame.data,frame.args,"OnStepCompletion")
        callbackCount = callbackCount + 1
    end
end
assert(callbackCount == #pack.route - pack.mainRouteLength)
print(("PASS: 3 guides, %d main route steps, %d NPC checks, %d distinct recipe targets; parser, flights, faction/coordinates/quests and arrow lifecycle"):format(count, checks, recipeCount))
