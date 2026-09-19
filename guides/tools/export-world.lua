-- Export installed TBC world data for the catalogue builder. No WoW runtime.
local root = assert(arg[1]) .. "/Questie/Database/"
local db, zones = {}, {private = {}}
QuestieLoader = { ImportModule = function(_, name) return name == "ZoneDB" and zones or db end }
assert(loadfile(root .. "TBC/tbcNpcDB.lua"))()
assert(loadfile(root .. "TBC/tbcQuestDB.lua"))()
assert(loadfile(root .. "Zones/data/areaIdToUiMapId.lua"))()
local compile = loadstring or load
local npcs, quests, maps = assert(compile(db.npcData))(), assert(compile(db.questData))(),
    assert(compile(zones.private.areaIdToUiMapId))()
local function json(value)
    if type(value) == "number" or type(value) == "boolean" then return tostring(value) end
    if type(value) == "string" then
        return '"' .. value:gsub('[%z\1-\31\\"]', function(c) return ("\\u%04x"):format(c:byte()) end) .. '"'
    end
    if value == nil then return "null" end
    local parts = {}
    for key, item in pairs(value) do parts[#parts + 1] = json(tostring(key)) .. ":" .. json(item) end
    table.sort(parts)
    return "{" .. table.concat(parts, ",") .. "}"
end
local result = {npcs = {}, quests = {}, flights = {}}
for id, npc in pairs(npcs) do
    local positions = {}
    for area, coords in pairs(npc[7] or {}) do
        for _, xy in ipairs(coords) do
            positions[#positions + 1] = {area = area, mapID = maps[area], x = xy[1], y = xy[2]}
        end
    end
    result.npcs[id] = {name = npc[1], faction = npc[13], positions = positions, flags = npc[15]}
end
for id, quest in pairs(quests) do
    result.quests[id] = {name = quest[1], starts = quest[2] and quest[2][1], ends = quest[3] and quest[3][1],
        races = quest[6], classes = quest[7]}
end
LibStub = function() return {} end
GetBuildInfo = function() return "2.5.6", "69546", "", 20506 end
local lime = {}
assert(loadfile(arg[1] .. "/Guidelime/Data/FlightmasterDB.lua"))("Guidelime", lime)
for _, flight in pairs(lime.FM.flightmasterDB) do
    if flight.npcId and flight.faction ~= "Horde" then result.flights[flight.npcId] = flight end
end
print(json(result))
