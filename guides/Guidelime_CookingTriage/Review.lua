local _, addon = ...
local V = addon.Verification
local panel, reportFrame, shownNPC, deferredMode, page, dismissedNPC
local rows, selected = {}, {}
local SIZE = 6
local names = {present = "Есть", absent = "Нет", unseen = "Не проверено", blocked = "Позже", conflict = "Конфликт"}
local kinds = {vendor = "продажа", trainer = "тренер", quest = "квест", drop = "добыча NPC", container = "награда-ящик",
    loot = "добыча", world = "случайная добыча", custom = "особый источник"}
local function label(parent, text, x, y, width, font)
    local t = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT", x, y); t:SetWidth(width); t:SetJustifyH("LEFT"); t:SetText(text)
    return t
end
local function button(parent, text, x, y, width, callback)
    local b = _G.CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 23); b:SetPoint("TOPLEFT", x, y); b:SetText(text); b:SetScript("OnClick", callback)
    return b
end
local function window(name, width, height)
    local f = _G.CreateFrame("Frame", name, _G.UIParent, "BackdropTemplate")
    f:SetSize(width, height); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
    f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
    table.insert(_G.UISpecialFrames, name)
    return f
end
function addon.ShowReport(run)
    run = run or addon.GetRun()
    if not run then addon.Say("Сначала /ctriage start."); return end
    if not reportFrame then
        reportFrame = window("CookingTriageReport", 850, 520)
        label(reportFrame, "Отчёт — Ctrl+A / Ctrl+C для копирования", 18, -17, 750, "GameFontNormalLarge")
        button(reportFrame, "×", 800, -12, 30, function() reportFrame:Hide() end)
        local scroll = _G.CreateFrame("ScrollFrame", nil, reportFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -52); scroll:SetPoint("BOTTOMRIGHT", -42, 22)
        local edit = _G.CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject(_G.ChatFontNormal)
        edit:SetWidth(765); edit:SetPoint("TOPLEFT"); edit:SetMaxLetters(0)
        edit:SetScript("OnTextChanged", function() scroll:UpdateScrollChildRect() end)
        edit:SetScript("OnEscapePressed", function() reportFrame:Hide() end)
        scroll:SetScrollChild(edit); reportFrame.edit = edit
    end
    reportFrame.edit:SetText(V.Report(run, true)); reportFrame.edit:SetCursorPosition(0); reportFrame:Show()
end
local function mark(case, state)
    local run = addon.GetRun()
    if not run then return end
    local ok, message = V.Mark(run, case.id, state, panel.note:GetText(), _G.time(),
        addon.CurrentSnapshot(case), panel.full:GetChecked())
    if not ok then addon.Say(message) end
    addon.RefreshChecks()
end
local function markNonTrainer()
    local run = addon.GetRun()
    if not run or not shownNPC or deferredMode then return end
    local ok, result = V.MarkNonTrainer(run, shownNPC, panel.note:GetText(), _G.time())
    if not ok then addon.Say(result) else addon.Say("Отмечено как отсутствующее тренерское меню: " .. result .. " проверок.") end
    addon.RefreshChecks()
end
local function createPanel()
    panel = window("CookingTriageReview", 850, 585)
    panel:ClearAllPoints(); panel:SetPoint("TOPRIGHT", _G.UIParent, "TOPRIGHT", -30, -90)
    panel.title = label(panel, "Cooking Triage", 18, -16, 740, "GameFontNormalLarge")
    button(panel, "×", 800, -12, 30, function() dismissedNPC = shownNPC; panel:Hide() end)
    panel.summary = label(panel, "", 18, -45, 810)
    label(panel, "У = уверенная группа; ? = сомнительная. Наведи на строку: основание ожидания.", 18, -67, 810)
    for i = 1, SIZE do
        local row = _G.CreateFrame("Frame", nil, panel)
        row:SetSize(812, 48); row:SetPoint("TOPLEFT", 18, -92 - (i - 1) * 54); row:EnableMouse(true)
        row.title = label(row, "", 0, 0, 500)
        row.title:SetHeight(18); row.title:SetWordWrap(false)
        row.stock = label(row, "", 405, 0, 95)
        row.state = label(row, "", 0, -20, 500)
        row.yes = button(row, "Есть", 512, -8, 62, function() mark(row.case, "present") end)
        row.no = button(row, "Нет", 577, -8, 62, function() mark(row.case, "absent") end)
        row.later = button(row, "Позже", 642, -8, 72, function() mark(row.case, "blocked") end)
        row.reset = button(row, "Сброс", 717, -8, 70, function() mark(row.case, "unseen") end)
        row:SetScript("OnEnter", function()
            if not row.case then return end
            _G.GameTooltip:SetOwner(row, "ANCHOR_TOP")
            _G.GameTooltip:AddLine(row.case.name, 1, 1, 1)
            _G.GameTooltip:AddLine(row.case.reason, 1, 0.82, 0, true)
            if row.case.requiresLevel then
                _G.GameTooltip:AddLine("Требуется уровень " .. row.case.requiresLevel .. ".", 1, 0.65, 0.2, true)
            end
            local stock = V.StockLabel(addon.GetRun(), row.case)
            if stock ~= "" then
                _G.GameTooltip:AddLine(stock .. " — ограниченный запас. Если раскуплено, выбери «Позже» и дождись пополнения. Время пополнения неизвестно.", 1, 0.65, 0.2, true)
                _G.GameTooltip:AddLine(stock == "Limited: 1" and "По наблюдению игрока: продано по одному экземпляру каждого рецепта."
                    or "Автоскан видел ограниченный остаток. Максимальный запас неизвестен.", 0.8, 0.8, 0.8, true)
            end
            _G.GameTooltip:AddLine((row.case.event and addon.SeasonText and addon.SeasonText(row.case.event))
                or row.case.deferred or "Наличие в базе не является живой проверкой.", 0.8, 0.8, 0.8, true)
            _G.GameTooltip:AddLine(row.case.id, 0.7, 0.7, 0.7)
            _G.GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() _G.GameTooltip:Hide() end)
        rows[i] = row
    end
    button(panel, "<", 18, -419, 42, function() page = math.max(1, page - 1); addon.RefreshChecks() end)
    panel.page = label(panel, "", 82, -424, 200)
    button(panel, ">", 210, -419, 42, function() page = math.min(math.max(1, math.ceil(#selected / SIZE)), page + 1); addon.RefreshChecks() end)
    panel.full = _G.CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    panel.full:SetPoint("TOPLEFT", 18, -450); panel.full:SetSize(24, 24)
    panel.full:SetScript("OnClick", function() addon.RefreshChecks() end)
    label(panel, "Полный список перепроверен; запас, фильтры и условия не мешают выводу об отсутствии", 47, -454, 770)
    label(panel, "Пояснение ручной отметки (для Есть / Нет / Позже):", 18, -480, 800)
    panel.note = _G.CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    panel.note:SetSize(798, 23); panel.note:SetPoint("TOPLEFT", 24, -500); panel.note:SetAutoFocus(false)
    panel.note:SetMaxLetters(500); panel.note:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    button(panel, "Начать / продолжить", 18, -539, 178, function() addon.StartRun(); addon.Rescan(); addon.RefreshChecks() end)
    button(panel, "Скан меню", 205, -539, 130, function() addon.Rescan(); addon.RefreshChecks() end)
    button(panel, "Отчёт", 344, -539, 120, function() addon.ShowReport() end)
    button(panel, "Завершить пробег", 473, -539, 178, function() addon.ShowReport(addon.FinishRun()); addon.RefreshChecks() end)
    button(panel, "NPC не тренер", 657, -539, 130, markNonTrainer)
    panel:SetScript("OnHide", function() dismissedNPC = shownNPC end)
end
function addon.RefreshChecks()
    if not panel then return end
    local run = addon.GetRun()
    selected = {}
    if run then
        for _, case in ipairs(run.cases) do
            if (deferredMode and case.deferred) or (not deferredMode and case.sourceID == shownNPC
                and (case.kind == "vendor" or case.kind == "trainer" or case.kind == "quest" or case.kind == "container" or case.kind == "drop")) then
                selected[#selected + 1] = case
            end
        end
    end
    table.sort(selected, function(a,b) if a.confidence ~= b.confidence then return a.confidence < b.confidence end; return a.name .. a.id < b.name .. b.id end)
    local node = (run and run.nodes or addon.nodes)[shownNPC]
    panel.title:SetText(deferredMode and "Cooking Triage — отложенные источники" or "Cooking Triage — " .. (node and node.title or "выбери текущую точку"))
    if run then
        local s = V.Stats(run)
        panel.summary:SetText(("У: совпало %d / не совпало %d.  ?: совпало %d / не совпало %d.  %s"):format(
            s.confident.match, s.confident.mismatch, s.uncertain.match, s.uncertain.mismatch,
            run.finished and "Пробег завершён" or "Запись включена"))
    else panel.summary:SetText("Начни пробег кнопкой внизу или /ctriage start. Ожидания будут сохранены до первой проверки.") end
    page = math.min(page or 1, math.max(1, math.ceil(#selected / SIZE)))
    panel.page:SetText(("%d / %d; проверок %d"):format(page, math.max(1, math.ceil(#selected / SIZE)), #selected))
    for i, row in ipairs(rows) do
        local case = selected[(page - 1) * SIZE + i]
        row.case = case
        if case then
            local result = run.results[case.id]
            local state, outcome = result and result.state or "unseen", V.Outcome(case, result)
            local spellName = _G.GetSpellInfo(case.spellID)
            local stock = V.StockLabel(run, case)
            row.title:SetWidth(stock ~= "" and 396 or 500)
            row.stock:SetText(stock ~= "" and "|cffffaa33" .. stock .. "|r" or "")
            row.title:SetText((case.confidence == "confident" and "|cff66ccffУ|r " or "|cffffcc00?|r ") .. (spellName or case.name) .. " — " .. kinds[case.kind])
            row.state:SetText(("Ожидаем: %s. Результат: %s%s"):format(case.expected and "есть" or "нет", names[state],
                outcome == "match" and " |cff66ff66(совпало)|r" or outcome == "mismatch" and " |cffff6666(не совпало)|r" or ""))
            row.no:SetEnabled(not run.finished and V.CanMarkAbsent(case, addon.CurrentSnapshot(case), panel.full:GetChecked()) or false)
            row.yes:SetEnabled(not run.finished); row.later:SetEnabled(not run.finished); row.reset:SetEnabled(not run.finished)
            row:Show()
        else row:Hide() end
    end
end
function addon.InvalidateMenuConfirmation()
    if panel then panel.full:SetChecked(false); addon.RefreshChecks() end
end
function addon.ShowChecks(npc, automatic, deferred)
    if automatic and dismissedNPC == npc then return end
    if not panel then createPanel() end
    if shownNPC ~= npc or deferredMode ~= deferred then
        shownNPC, deferredMode, page = npc, deferred, 1
        panel.full:SetChecked(false); panel.note:SetText("")
    end
    if not automatic then dismissedNPC = nil end
    addon.RefreshChecks(); panel:Show()
end
_G.SLASH_COOKINGTRIAGE1 = "/ctriage"
_G.SlashCmdList.COOKINGTRIAGE = function(message)
    local command, value = message:match("^%s*(%S*)%s*(.-)%s*$")
    if command == "start" then addon.StartRun(); addon.Rescan(); addon.ShowChecks(addon.activePoint and addon.activePoint.npcID)
    elseif command == "finish" then addon.ShowReport(addon.FinishRun()); addon.RefreshChecks()
    elseif command == "report" then
        local index = tonumber(value)
        if index then
            local run = _G.CookingTriageDB and _G.CookingTriageDB.runs[index]
            if run then addon.ShowReport(run) else addon.Say("Нет пробега с номером " .. index) end
        else addon.ShowReport() end
    elseif command == "deferred" then addon.ShowChecks(nil, false, true)
    elseif command == "npc" then addon.ShowChecks(tonumber(value))
    elseif command == "history" then
        for index, run in ipairs(_G.CookingTriageDB and _G.CookingTriageDB.runs or {}) do
            addon.Say(index .. ": " .. _G.date("%Y-%m-%d %H:%M", run.started) .. " — " .. (run.finished and "завершён" or "идёт") .. "; /ctriage report " .. index)
        end
    elseif command == "" then addon.ShowChecks(addon.activePoint and addon.activePoint.npcID or shownNPC)
    else addon.Say("/ctriage [start | finish | report [номер] | history | npc ID | deferred]") end
end
