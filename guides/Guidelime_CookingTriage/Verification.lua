local _, addon = ...
local V = {}
addon.Verification = V
local menuKinds = {vendor = true, trainer = true, quest = true}
-- Player observation, 2026-09-14: Vendor-Tron sold one of each, then the rows vanished.
-- Display metadata only: do not reclassify the frozen expectations in an active run.
local vendorTronLimited = {[3398] = true, [6419] = true, [15855] = true,
    [15861] = true, [15863] = true, [15910] = true}
local function limitedStock(case, stock)
    for _, id in ipairs(case.items) do
        local count = stock and stock[id]
        if type(count) == "number" and count >= 0 then return true end
    end
    return false
end
function V.StockLabel(run, case)
    if case.kind ~= "vendor" then return "" end
    if case.sourceID == 12245 and vendorTronLimited[case.spellID] then return "Limited: 1" end
    if run.limitedStock and run.limitedStock[case.id] then return "Limited" end
    -- Existing runs already contain stock in observations and result evidence.
    for _, snapshot in ipairs(run.observations["vendor:" .. case.sourceID .. ":0"] or {}) do
        if limitedStock(case, snapshot.stock) then return "Limited" end
    end
    local result = run.results[case.id]
    for _, entry in ipairs(result and result.history or {}) do
        local evidence = entry.evidence or {}
        if limitedStock(case, evidence.stock or (evidence.snapshot and evidence.snapshot.stock)) then return "Limited" end
    end
    return ""
end
function V.Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}; for key, item in pairs(value) do copy[key] = V.Copy(item) end; return copy
end
function V.NewRun(character, class, now, build)
    local run = {character = character, started = now, build = build, revision = addon.catalogRevision,
        cases = {}, results = {}, observations = {}, nodes = V.Copy(addon.nodes)}
    for _, case in ipairs(addon.catalog) do
        if not case.class or case.class == class then run.cases[#run.cases + 1] = V.Copy(case) end
    end
    return run
end
function V.Find(run, id)
    for _, case in ipairs(run.cases) do if case.id == id then return case end end
end
function V.Matches(case, snapshot)
    return case.sourceID == snapshot.npcID and case.kind == snapshot.kind
        and (case.kind ~= "quest" or case.questID == snapshot.questID)
end
function V.Present(case, snapshot)
    if not V.Matches(case, snapshot) then return false end
    if case.kind == "trainer" then return snapshot.spells and snapshot.spells[case.spellID] or false end
    for _, id in ipairs(case.items) do if snapshot.items and snapshot.items[id] then return true end end
    return false
end
local function record(run, case, state, evidence)
    local result = run.results[case.id] or {history = {}}
    local previous = result.state
    -- Conflicting observations need review; an empty menu never cancels a positive.
    if (previous == "present" and state == "absent") or (previous == "absent" and state == "present") then state = "conflict" end
    result.state, result.evidence = state, V.Copy(evidence)
    if #result.history == 8 then table.remove(result.history, 1) end
    result.history[#result.history + 1] = {state = state, evidence = V.Copy(evidence)}
    run.results[case.id] = result
end
function V.Observe(run, snapshot)
    if run.finished then return end
    local key = snapshot.kind .. ":" .. snapshot.npcID .. ":" .. (snapshot.questID or 0)
    local history = run.observations[key] or {}
    if #history == 4 then table.remove(history, 1) end
    history[#history + 1] = V.Copy(snapshot)
    run.observations[key] = history
    for _, case in ipairs(run.cases) do
        if V.Present(case, snapshot) then
            if case.kind == "vendor" and limitedStock(case, snapshot.stock) then
                -- Keep the flag even after buying the item and rotating old snapshots.
                run.limitedStock = run.limitedStock or {}
                run.limitedStock[case.id] = true
            end
            local result = run.results[case.id]
            if not result or (result.state ~= "present" and result.state ~= "conflict") then
                record(run, case, "present", {at = snapshot.at, method = "menu", npcID = snapshot.npcID,
                    kind = snapshot.kind, questID = snapshot.questID, stock = snapshot.stock,
                    filters = snapshot.filters, build = snapshot.build})
            end
        end
    end
end
function V.CanMarkAbsent(case, snapshot, confirmed)
    return confirmed and menuKinds[case.kind] and snapshot and snapshot.complete
        and V.Matches(case, snapshot) and not V.Present(case, snapshot)
end
function V.Mark(run, id, state, note, now, snapshot, confirmed)
    if run.finished then return false, "Пробег завершён; начни новый для новых наблюдений." end
    local case = V.Find(run, id)
    if not case then return false, "Проверка не входит в этот пробег." end
    if state ~= "present" and state ~= "absent" and state ~= "blocked" and state ~= "unseen" then return false, "Неизвестный результат." end
    if state == "absent" and not V.CanMarkAbsent(case, snapshot, confirmed) then
        return false, "Нужно открытое полное меню этого источника и подтверждение проверки. При ограничениях выбери Позже."
    end
    if state ~= "unseen" and (not note or not note:find("%S")) then return false, "Добавь пояснение к ручной отметке." end
    record(run, case, state, {at = now, method = "manual", note = note, snapshot = snapshot and V.Copy(snapshot)})
    return true
end
function V.MarkNonTrainer(run, npcID, note, now)
    if run.finished then return false, "Пробег завершён; начни новый для новых наблюдений." end
    if not note or not note:find("%S") then return false, "Добавь пояснение к ручной отметке." end
    local count = 0
    for _, case in ipairs(run.cases) do
        if case.sourceID == npcID and case.kind == "trainer" then
            record(run, case, "absent", {at = now, method = "manual-nontrainer", note = note,
                npcID = npcID, reason = "NPC не является тренером; меню тренера отсутствует"})
            count = count + 1
        end
    end
    if count == 0 then return false, "Для этого NPC нет проверок тренера." end
    return true, count
end
function V.Outcome(case, result)
    local state = result and result.state or "unseen"
    if state == "present" or state == "absent" then
        return ((state == "present") == case.expected) and "match" or "mismatch"
    end
    return state
end
function V.Stats(run)
    local stats = {}
    for _, tier in ipairs({"confident", "uncertain"}) do
        stats[tier] = {total = 0, match = 0, mismatch = 0, unseen = 0, blocked = 0, conflict = 0}
    end
    for _, case in ipairs(run.cases) do
        local group = stats[case.confidence]
        local outcome = V.Outcome(case, run.results[case.id])
        group.total, group[outcome] = group.total + 1, group[outcome] + 1
    end
    return stats
end
local function clean(value) return tostring(value or ""):gsub("[\t\r\n]", " ") end
function V.Report(run, detailed)
    local lines = {"Cooking Triage Verification", "Персонаж: " .. run.character .. "; база: " .. run.revision,
        "Группа\tВсего\tСовпало\tНе совпало\tНе проверено\tОтложено\tКонфликт\tСовпадений среди проверенных"}
    local stats = V.Stats(run)
    for _, tier in ipairs({"confident", "uncertain"}) do
        local s = stats[tier]
        local tested = s.match + s.mismatch
        lines[#lines + 1] = ("%s\t%d\t%d\t%d\t%d\t%d\t%d\t%s"):format(
            tier == "confident" and "Уверенная" or "Сомнительная", s.total, s.match, s.mismatch,
            s.unseen, s.blocked, s.conflict, tested > 0 and ("%.1f%%"):format(s.match * 100 / tested) or "—")
    end
    lines[#lines + 1] = "Единица: рецепт + источник (для квеста также quest ID). Уверенность зафиксирована до проверки."
    if detailed then
        lines[#lines + 1] = "ID\tГруппа\tРецепт\tИсточник\tОжидание\tНаблюдение\tИтог\tОснование ожидания\tПодтверждение"
        for _, case in ipairs(run.cases) do
            local result = run.results[case.id]
            local npc = run.nodes[case.sourceID]
            lines[#lines + 1] = table.concat({case.id, case.confidence, clean(case.name), clean(npc and npc.title or case.sourceID),
                case.expected and "present" or "absent", result and result.state or "unseen", V.Outcome(case, result),
                clean(case.reason), clean(result and result.evidence and (result.evidence.note or result.evidence.method))}, "\t")
        end
    end
    return table.concat(lines, "\n")
end
