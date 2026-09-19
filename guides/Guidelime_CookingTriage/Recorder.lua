local _, addon = ...
local V, windows, latest, queued, generations = addon.Verification, {}, {}, {}, {}
local frame = _G.CreateFrame("Frame")
local tip = _G.CreateFrame("GameTooltip", "CookingTriageScanTooltip", _G.UIParent, "GameTooltipTemplate")
local function pack(...) return {n = select("#", ...), ...} end
local function api(name, ...)
    local fn = _G[name]
    if type(fn) ~= "function" then return nil end
    local result = pack(pcall(fn, ...))
    if result[1] then return unpack(result, 2, result.n) end
end
function addon.Say(text) _G.print("|cff33ff99Cooking Triage:|r " .. text) end
local function database()
    _G.CookingTriageDB = _G.CookingTriageDB or {runs = {}}
    return _G.CookingTriageDB
end
function addon.GetRun() local db = database(); return db.active and db.runs[db.active] end
function addon.StartRun()
    local db, run = database(), addon.GetRun()
    if run and not run.finished then addon.Say("Продолжается существующий пробег; данные не сброшены."); return run end
    local _, class = _G.UnitClass("player")
    run = V.NewRun(_G.UnitName("player") .. "-" .. _G.GetRealmName(), class, _G.time(), pack(_G.GetBuildInfo()))
    db.runs[#db.runs + 1], db.active = run, #db.runs + 1
    addon.Say("Новый пробег: " .. #run.cases .. " проверок. Ожидания и группы зафиксированы.")
    return run
end
function addon.FinishRun()
    local run = addon.GetRun()
    if run then run.finished = run.finished or _G.time(); run.report = V.Report(run, true) end
    return run
end
local function npcID(guid)
    return type(guid) == "string" and tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")) or nil
end
local function linkID(link, kind)
    return type(link) == "string" and tonumber(link:match(kind .. ":(%d+)")) or nil
end
local function on(value) return value == true or value == 1 end
local function tooltip(method, index)
    tip:SetOwner(_G.UIParent, "ANCHOR_NONE"); tip:ClearLines()
    local ok = pcall(tip[method], tip, index)
    local spell, lines
    if ok then
        if method == "SetTrainerService" then local _, id = tip:GetSpell(); spell = id end
        lines = {}
        for i = 1, tip:NumLines() do
            local left, right = _G["CookingTriageScanTooltipTextLeft" .. i], _G["CookingTriageScanTooltipTextRight" .. i]
            lines[#lines + 1] = {left = left and left:GetText(), right = right and right:GetText()}
        end
    end
    tip:Hide()
    return spell, lines
end
function addon.Scan(kind, guid)
    local run = addon.GetRun()
    if not run or run.finished or windows[kind] ~= guid or _G.UnitGUID("npc") ~= guid then return end
    local id = npcID(guid)
    if not id or not run.nodes[id] then return end
    local snapshot = {kind = kind, npcID = id, guid = guid, at = _G.time(), build = pack(_G.GetBuildInfo()),
        rows = {}, items = {}, spells = {}, stock = {}, complete = true, unresolved = 0}
    local n
    if kind == "vendor" then
        n = api("GetMerchantNumItems")
        snapshot.filter = api("GetMerchantFilter")
        if snapshot.filter ~= nil and snapshot.filter ~= _G.LE_MERCHANT_FILTER_ALL then snapshot.complete = false end
        for i = 1, n or 0 do
            local link = api("GetMerchantItemLink", i)
            local item = linkID(link, "item") or api("GetMerchantItemID", i)
            local info = pack(api("GetMerchantItemInfo", i))
            local _, lines = tooltip("SetMerchantItem", i)
            snapshot.rows[#snapshot.rows + 1] = {itemID = item, link = link, info = info, tooltip = lines}
            if item then snapshot.items[item] = true; snapshot.stock[item] = info[5] end
            if not item or not info[1] then snapshot.unresolved = snapshot.unresolved + 1 end
        end
    elseif kind == "trainer" then
        n = api("GetNumTrainerServices")
        snapshot.filters = {}
        for _, key in ipairs({"available", "unavailable", "used"}) do
            snapshot.filters[key] = api("GetTrainerServiceTypeFilter", key)
            if not on(snapshot.filters[key]) then snapshot.complete = false end
        end
        for i = 1, n or 0 do
            local name, subtext, serviceType, expanded = api("GetTrainerServiceInfo", i)
            local row = {name = name, subtext = subtext, serviceType = serviceType, expanded = expanded}
            if serviceType == "header" then
                if not on(expanded) then snapshot.complete = false end
            else
                local spell, lines = tooltip("SetTrainerService", i)
                row.spellID, row.tooltip = spell, lines
                row.skill = pack(api("GetTrainerServiceSkillReq", i))
                if spell then snapshot.spells[spell] = true else snapshot.unresolved = snapshot.unresolved + 1 end
            end
            snapshot.rows[#snapshot.rows + 1] = row
        end
    elseif kind == "quest" then
        snapshot.questID = api("GetQuestID")
        if not snapshot.questID or snapshot.questID == 0 then return end
        n = 0
        for _, group in ipairs({{"reward", "GetNumQuestRewards"}, {"choice", "GetNumQuestChoices"}}) do
            local count = api(group[2])
            if not count then snapshot.complete = false end
            for i = 1, count or 0 do
                n = n + 1
                local link = api("GetQuestItemLink", group[1], i)
                local item = linkID(link, "item")
                snapshot.rows[#snapshot.rows + 1] = {itemID = item, link = link, kind = group[1]}
                if item then snapshot.items[item] = true else snapshot.unresolved = snapshot.unresolved + 1 end
            end
        end
    else return end
    snapshot.complete = snapshot.complete and type(n) == "number" and snapshot.unresolved == 0
    latest[kind] = snapshot
    V.Observe(run, snapshot)
    if addon.ShowChecks then addon.ShowChecks(id, true) end
end
function addon.CurrentSnapshot(case)
    local s = latest[case.kind]
    if s and windows[case.kind] == s.guid and _G.UnitGUID("npc") == s.guid and V.Matches(case, s) then return s end
end
local function schedule(kind, retry)
    local guid = windows[kind]
    if not guid then return end
    local generation = generations[kind]
    if queued[kind] then return end
    local token = {}; queued[kind] = token
    -- Retry after the client fills item/spell data. Never attribute a delayed scan to target.
    _G.C_Timer.After(0.25, function()
        if queued[kind] ~= token then return end
        queued[kind] = nil
        if generations[kind] == generation then addon.Scan(kind, guid) end
    end)
    if retry then _G.C_Timer.After(1.5, function()
        if generations[kind] == generation then addon.Scan(kind, guid) end
    end) end
end
local shows = {MERCHANT_SHOW = "vendor", TRAINER_SHOW = "trainer", QUEST_DETAIL = "quest", QUEST_COMPLETE = "quest"}
local updates = {MERCHANT_UPDATE = "vendor", TRAINER_UPDATE = "trainer", TRAINER_SERVICE_INFO_NAME_UPDATE = "trainer"}
local closes = {MERCHANT_CLOSED = "vendor", TRAINER_CLOSED = "trainer", QUEST_FINISHED = "quest"}
for event in pairs(shows) do frame:RegisterEvent(event) end
for event in pairs(updates) do frame:RegisterEvent(event) end
for event in pairs(closes) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent", function(_, event)
    local kind = shows[event]
    if kind then
        generations[kind] = (generations[kind] or 0) + 1
        windows[kind], latest[kind], queued[kind] = _G.UnitGUID("npc"), nil, nil
        if addon.InvalidateMenuConfirmation then addon.InvalidateMenuConfirmation() end
        schedule(kind, true)
    elseif updates[event] then
        kind = updates[event]
        -- A pending scan must not leave the previous menu eligible for an absence claim.
        latest[kind] = nil
        if addon.InvalidateMenuConfirmation then addon.InvalidateMenuConfirmation() end
        schedule(kind)
    elseif closes[event] then
        kind = closes[event]; windows[kind], latest[kind], queued[kind] = nil, nil, nil
        generations[kind] = (generations[kind] or 0) + 1
        if addon.RefreshChecks then addon.RefreshChecks() end
    end
end)
function addon.Rescan()
    for kind, guid in pairs(windows) do addon.Scan(kind, guid) end
end
