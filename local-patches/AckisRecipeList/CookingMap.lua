-- Cooking recipe map for Ackis Recipe List Classic. Loaded by the core TOC.
local _, private = ...
local addon = _G.LibStub("AceAddon-3.0"):GetAddon(private.addon_name)
local HBD = _G.LibStub("HereBeDragons-2.0")
local pins = _G.LibStub("HereBeDragons-Pins-2.0")
local types = private.AcquireTypes
local colors = private.DIFFICULTY_COLORS
local russian = _G.GetLocale() == "ruRU"
local labels = russian and {
    title = "Кулинария", reputation = "Нужна репутация: %s — %s",
    page = "%d–%d из %d. Колесо мыши — остальные рецепты.",
    route = "ЛКМ — маршрут TomTom", on = "Метки готовки включены.", off = "Метки готовки выключены.",
    winterVeil = "Feast of Winter Veil: примерно %s - %s. Вне события отсутствие не опровергает источник.",
} or {
    title = "Cooking", reputation = "Requires reputation: %s — %s",
    page = "%d–%d of %d. Mouse wheel to scroll recipes.",
    route = "Left click for a TomTom waypoint", on = "Cooking pins enabled.", off = "Cooking pins disabled.",
    winterVeil = "Feast of Winter Veil: roughly %s - %s. Absence outside the event does not disprove the source.",
}
local textures = {
    [types.Vendor] = "Interface\\GossipFrame\\VendorGossipIcon",
    [types.Trainer] = "Interface\\Minimap\\Tracking\\Profession",
    [types.Quest] = "Interface\\GossipFrame\\AvailableQuestIcon",
    [types.MobDrop] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
}
local priority = { impossible = 0, trivial = 1, easy = 2, medium = 3, optimal = 4 }
local owner, pool = {}, {}
local frame = _G.CreateFrame("Frame")
local queued, readingSkills = false, false
local PAGE_SIZE = 16
local winterVeilVendors = {[13420]=true, [13429]=true, [13432]=true, [13433]=true, [13435]=true, [23010]=true, [23012]=true, [23064]=true}
local winterVeilRecipes = {[21143]=true, [21144]=true, [45022]=true}

local function WinterVeilWindow()
    local now = (_G.time or os.time)()
    local today = (_G.date or os.date)("*t", now)
    local startYear = today.year
    if today.month == 1 then startYear = today.year - 1 end
    local startTime = (_G.time or os.time)({year = startYear, month = 12, day = 16, hour = 0})
    local endTime = (_G.time or os.time)({year = startYear + 1, month = 1, day = 2, hour = 23, min = 59})
    if now > endTime then
        startYear = startYear + 1
        startTime = (_G.time or os.time)({year = startYear, month = 12, day = 16, hour = 0})
        endTime = (_G.time or os.time)({year = startYear + 1, month = 1, day = 2, hour = 23, min = 59})
    end
    return (_G.date or os.date)("%Y-%m-%d", startTime), (_G.date or os.date)("%Y-%m-%d", endTime)
end

local function SeasonalNote(group, spellID)
    if group.acquireType == types.Vendor and winterVeilVendors[group.sourceID] and winterVeilRecipes[spellID] then
        return labels.winterVeil:format(WinterVeilWindow())
    end
end

-- The core's zone table uses Retail IDs; use Classic/TBC UiMapIDs before Cata.
-- Resolve by ARL's zone label, not a localized or fallback English zone name.
local classicMaps = {
    DUROTAR = 1411, MULGORE = 1412, THE_BARRENS = 1413,
    ALTERAC_MOUNTAINS = 1416, ARATHI_HIGHLANDS = 1417, BADLANDS = 1418,
    BLASTED_LANDS = 1419, TIRISFAL_GLADES = 1420, SILVERPINE_FOREST = 1421,
    WESTERN_PLAGUELANDS = 1422, EASTERN_PLAGUELANDS = 1423, HILLSBRAD_FOOTHILLS = 1424,
    THE_HINTERLANDS = 1425, DUN_MOROGH = 1426, SEARING_GORGE = 1427,
    BURNING_STEPPES = 1428, ELWYNN_FOREST = 1429, DEADWIND_PASS = 1430,
    DUSKWOOD = 1431, LOCH_MODAN = 1432, REDRIDGE_MOUNTAINS = 1433,
    STRANGLETHORN_VALE = 1434, SWAMP_OF_SORROWS = 1435, WESTFALL = 1436,
    WETLANDS = 1437, TELDRASSIL = 1438, DARKSHORE = 1439, ASHENVALE = 1440,
    THOUSAND_NEEDLES = 1441, STONETALON_MOUNTAINS = 1442, DESOLACE = 1443,
    FERALAS = 1444, DUSTWALLOW_MARSH = 1445, TANARIS = 1446, AZSHARA = 1447,
    FELWOOD = 1448, UNGORO_CRATER = 1449, MOONGLADE = 1450, SILITHUS = 1451,
    WINTERSPRING = 1452, STORMWIND_CITY = 1453, ORGRIMMAR = 1454, IRONFORGE = 1455,
    THUNDER_BLUFF = 1456, DARNASSUS = 1457, UNDERCITY = 1458,
    EVERSONG_WOODS = 1941, GHOSTLANDS = 1942, AZUREMYST_ISLE = 1943,
    HELLFIRE_PENINSULA = 1944, ZANGARMARSH = 1946, THE_EXODAR = 1947,
    SHADOWMOON_VALLEY_OUTLAND = 1948, BLADES_EDGE_MOUNTAINS = 1949,
    BLOODMYST_ISLE = 1950, NAGRAND_OUTLAND = 1951, TEROKKAR_FOREST = 1952,
    NETHERSTORM = 1953, SILVERMOON_CITY = 1954, SHATTRATH_CITY = 1955,
    ISLE_OF_QUELDANAS = 1957,
}

local function IsKnown(spellID)
    return (_G.IsPlayerSpell and _G.IsPlayerSpell(spellID))
        or (_G.IsSpellKnown and _G.IsSpellKnown(spellID))
end

local function ReadCookingSkill()
    local name = private.MODULE_NAME_TO_LOCALIZED_PROFESSION_NAME_MAPPING.Cooking
    if _G.GetProfessions and _G.GetProfessionInfo then
        for _, index in pairs({ _G.GetProfessions() }) do
            local skillName, _, rank, _, _, _, skillID = _G.GetProfessionInfo(index)
            if skillID == 185 or skillName == name then return rank end
        end
    end
    local function ReadSkillLines()
        for index = 1, _G.GetNumSkillLines() do
            local skillName, header, _, rank = _G.GetSkillLineInfo(index)
            if not header and skillName == name then return rank end
        end
    end
    local rank = ReadSkillLines()
    if rank then return rank end

    -- A collapsed skill header must not hide Cooking. Restore the player's UI.
    local collapsed = {}
    readingSkills = true
    for index = _G.GetNumSkillLines(), 1, -1 do
        local headerName, header, expanded = _G.GetSkillLineInfo(index)
        if header and not expanded then
            collapsed[headerName] = true
            _G.ExpandSkillHeader(index)
        end
    end
    rank = ReadSkillLines()
    for index = _G.GetNumSkillLines(), 1, -1 do
        local headerName, header = _G.GetSkillLineInfo(index)
        if header and collapsed[headerName] then _G.CollapseSkillHeader(index) end
    end
    _G.C_Timer.After(0, function() readingSkills = false end)
    return rank
end

local function Difficulty(recipe, rank, blocked)
    if blocked or rank < recipe.skill_level then return "impossible" end
    if rank >= recipe.trivial_level then return "trivial" end
    if rank >= recipe.easy_level then return "easy" end
    if rank >= recipe.medium_level then return "medium" end
    return "optimal"
end

local function ReputationRequirement(factionID, level)
    local reputation = types.Reputation:GetEntity(factionID)
    local name = reputation and reputation.name or tostring(factionID)
    local standing
    if _G.C_Reputation and _G.C_Reputation.GetFactionDataByID then
        local data = _G.C_Reputation.GetFactionDataByID(factionID)
        standing = data and data.reaction
    elseif _G.GetFactionInfoByID then
        standing = select(3, _G.GetFactionInfoByID(factionID))
    end
    if not standing or standing < level + 4 then
        return labels.reputation:format(name, _G["FACTION_STANDING_LABEL" .. (level + 4)] or tostring(level))
    end
end

local function SourcePosition(entity)
    local location, x, y = entity.Location, entity.coord_x, entity.coord_y
    if not location then return end
    local entranceX, entranceY = location:EntranceCoordinates()
    if entranceX and entranceY and entranceX > 0 and entranceY > 0 then
        location, x, y = location:Parent(), entranceX, entranceY
    end
    if not location or not x or not y or x <= 0 or y <= 0 or x > 100 or y > 100 then return end
    -- Never place zone-relative coordinates on a guessed parent map.
    local mapID = location:MapID()
    if private.GetEffectiveExpansionID() <= 2 then
        local label = private.ZONE_LABELS_FROM_NAME and private.ZONE_LABELS_FROM_NAME[location:LocalizedName()]
        if label and classicMaps[label] then mapID = classicMaps[label] end
    end
    if not mapID or not HBD:GetLocalizedMap(mapID) then
        mapID = nil
        for _, candidate in ipairs(HBD:GetAllMapIDs()) do
            if HBD:GetLocalizedMap(candidate) == location:LocalizedName() then
                mapID = candidate
                break
            end
        end
    end
    if mapID then return mapID, x / 100, y / 100 end
end

local function CollectSources(profession, rank)
    local groups = {}
    local faction = _G.UnitFactionGroup("player")
    local expansion = private.GetEffectiveExpansionID()
    local function AddSource(recipe, acquireType, sourceID, blocked)
        local entity = acquireType:GetEntity(sourceID)
        if not entity or (entity.expansionID and entity.expansionID > expansion) then return end
        if entity.faction and entity.faction ~= "Neutral" and entity.faction ~= faction then return end
        local mapID, x, y = SourcePosition(entity)
        if not mapID then return end
        local key = acquireType:Label() .. ":" .. sourceID
        local group = groups[key]
        if not group then
            group = {
                name = entity.name or private.quest_names[sourceID] or tostring(sourceID),
                acquireType = acquireType, mapID = mapID, x = x, y = y,
                rank = rank, sourceID = sourceID, entries = {}, difficulty = "impossible",
            }
            groups[key] = group
        end
        local spellID = recipe:SpellID()
        local difficulty = Difficulty(recipe, rank, blocked)
        local existing = group.entries[spellID]
        -- A vendor may have several ways to unlock the same recipe.
        if not existing or priority[difficulty] > priority[existing.difficulty]
            or (existing.blocked and not blocked) then
            group.entries[spellID] = { recipe = recipe, difficulty = difficulty, blocked = blocked }
        end
        if priority[difficulty] > priority[group.difficulty] then group.difficulty = difficulty end
    end

    for spellID, recipe in pairs(profession.Recipes) do
        if recipe:ExpansionID() <= expansion and not IsKnown(spellID)
            and private.Player:HasRecipeFaction(recipe) then
            for acquireType, data in recipe:AcquirePairs() do
                if acquireType == types.Reputation then
                    for factionID, levels in pairs(data) do
                        for level, vendors in pairs(levels) do
                            local blocked = ReputationRequirement(factionID, level)
                            for vendorID in pairs(vendors) do AddSource(recipe, types.Vendor, vendorID, blocked) end
                        end
                    end
                elseif textures[acquireType] then
                    for sourceID in pairs(data) do AddSource(recipe, acquireType, sourceID) end
                end
            end
        end
    end

    local result, positions = {}, {}
    for _, group in pairs(groups) do
        group.recipes = {}
        for _, entry in pairs(group.entries) do group.recipes[#group.recipes + 1] = entry end
        group.entries = nil
        table.sort(group.recipes, function(a, b)
            if a.difficulty ~= b.difficulty then return priority[a.difficulty] > priority[b.difficulty] end
            if a.recipe.skill_level ~= b.recipe.skill_level then return a.recipe.skill_level < b.recipe.skill_level end
            return a.recipe:SpellID() < b.recipe:SpellID()
        end)
        result[#result + 1] = group
        local position = ("%d:%.6f:%.6f"):format(group.mapID, group.x, group.y)
        positions[position] = positions[position] or {}
        local neighbors = positions[position]
        neighbors[#neighbors + 1] = group
    end
    table.sort(result, function(a, b)
        if a.mapID ~= b.mapID then return a.mapID < b.mapID end
        if a.x ~= b.x then return a.x < b.x end
        if a.y ~= b.y then return a.y < b.y end
        return a.name < b.name
    end)
    for _, neighbors in pairs(positions) do
        table.sort(neighbors, function(a, b)
            return a.acquireType:Label() .. a.name < b.acquireType:Label() .. b.name
        end)
        for index, group in ipairs(neighbors) do
            group.offsetX = (index - (#neighbors + 1) / 2) * 25
        end
    end
    return result
end

local function ShowTooltip(pin)
    local group = pin.group
    local tooltip = _G.GameTooltip
    tooltip:SetOwner(pin, "ANCHOR_RIGHT")
    tooltip:SetText(group.name, 1, 1, 1)
    tooltip:AddLine(group.acquireType:Name() .. " — " .. labels.title .. ": " .. group.rank, 1, 0.82, 0)
    tooltip:AddLine(("%s (%.1f, %.1f)"):format(HBD:GetLocalizedMap(group.mapID), group.x * 100, group.y * 100))
    local last = math.min(#group.recipes, pin.offset + PAGE_SIZE)
    for index = pin.offset + 1, last do
        local entry = group.recipes[index]
        local recipe, color = entry.recipe, colors[entry.difficulty]
        tooltip:AddDoubleLine(recipe:LocalizedName(), ("[%d]"):format(recipe.skill_level),
            color.r, color.g, color.b, color.r, color.g, color.b)
        local seasonal = SeasonalNote(group, recipe:SpellID())
        if seasonal then tooltip:AddLine(seasonal, 0.8, 0.8, 0.8, true) end
        if entry.blocked then tooltip:AddLine(entry.blocked, 1, 0, 0, true) end
    end
    if #group.recipes > PAGE_SIZE then
        tooltip:AddLine(labels.page:format(pin.offset + 1, last, #group.recipes), 1, 1, 1, true)
    end
    if _G.TomTom then tooltip:AddLine(labels.route, 0.7, 0.7, 0.7) end
    tooltip:Show()
end

local function CreatePin()
    local anchor = _G.CreateFrame("Frame", nil, _G.UIParent)
    anchor:SetSize(24, 24)
    local pin = _G.CreateFrame("Button", nil, anchor)
    pin.anchor = anchor
    pin:SetSize(24, 24)
    pin.border = pin:CreateTexture(nil, "BACKGROUND")
    pin.border:SetAllPoints()
    local background = pin:CreateTexture(nil, "BORDER")
    background:SetPoint("TOPLEFT", 2, -2)
    background:SetPoint("BOTTOMRIGHT", -2, 2)
    background:SetColorTexture(0.05, 0.05, 0.05, 0.9)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetPoint("TOPLEFT", 3, -3)
    pin.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    pin:SetScript("OnEnter", ShowTooltip)
    pin:SetScript("OnLeave", function() _G.GameTooltip:Hide() end)
    pin:EnableMouseWheel(true)
    pin:SetScript("OnMouseWheel", function(self, delta)
        self.offset = math.max(0, math.min(#self.group.recipes - PAGE_SIZE, self.offset - delta * PAGE_SIZE))
        ShowTooltip(self)
    end)
    pin:RegisterForClicks("LeftButtonUp")
    pin:SetScript("OnClick", function(self)
        local group = self.group
        if _G.TomTom then
            _G.TomTom:AddWaypoint(group.mapID, group.x, group.y, {
                title = labels.title .. ": " .. group.name, persistent = false,
            })
        end
    end)
    return pin
end

local function ClearPins()
    pins:RemoveAllWorldMapIcons(owner)
    pins:RemoveAllMinimapIcons(owner)
    for _, pair in ipairs(pool) do
        for _, pin in ipairs(pair) do
            if _G.GameTooltip:IsOwned(pin) then _G.GameTooltip:Hide() end
            pin.anchor:Hide()
            pin.group = nil
        end
    end
end

local function Refresh()
    ClearPins()
    if not addon.db or addon.db.profile.cookingmap == false then return end
    local rank = ReadCookingSkill()
    if not rank or rank < 1 then return end
    local name = private.MODULE_NAME_TO_LOCALIZED_PROFESSION_NAME_MAPPING.Cooking
    if not addon:InitializeProfession(name, true) then return end
    local profession = private.Professions.Cooking
    if not profession then return end
    for index, group in ipairs(CollectSources(profession, rank)) do
        local pair = pool[index]
        if not pair then
            pair = { CreatePin(), CreatePin() }
            pool[index] = pair
        end
        for _, pin in ipairs(pair) do
            pin.group, pin.offset = group, 0
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", pin.anchor, "CENTER", group.offsetX, 0)
            pin.icon:SetTexture(textures[group.acquireType])
            local color = colors[group.difficulty]
            pin.border:SetColorTexture(color.r, color.g, color.b, 1)
        end
        -- HBD reparents icons: the world map and minimap need separate frames.
        pins:AddWorldMapIconMap(owner, pair[1].anchor, group.mapID, group.x, group.y,
            _G.HBD_PINS_WORLDMAP_SHOW_WORLD)
        pins:AddMinimapIconMap(owner, pair[2].anchor, group.mapID, group.x, group.y, true, false)
    end
end

local function QueueRefresh(_, event)
    if queued or (event == "SKILL_LINES_CHANGED" and readingSkills) then return end
    queued = true
    _G.C_Timer.After(0.25, function()
        Refresh()
        queued = false
    end)
end

for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL",
    "SPELLS_CHANGED", "TRADE_SKILL_UPDATE", "UPDATE_FACTION" }) do
    frame:RegisterEvent(event)
end
frame:SetScript("OnEvent", QueueRefresh)

_G.SLASH_ARLCOOKINGMAP1 = "/arlcookingmap"
_G.SlashCmdList.ARLCOOKINGMAP = function(message)
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    if message == "off" then addon.db.profile.cookingmap = false
    elseif message == "on" then addon.db.profile.cookingmap = true
    else addon.db.profile.cookingmap = addon.db.profile.cookingmap == false end
    addon:Print(addon.db.profile.cookingmap and labels.on or labels.off)
    QueueRefresh()
end

_G.hooksecurefunc(addon, "Scan", QueueRefresh)
