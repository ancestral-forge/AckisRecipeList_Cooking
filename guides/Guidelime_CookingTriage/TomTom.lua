local _, addon = ...
local current
local enabledBefore

local function Clear()
    if current and current.uid then _G.TomTom:RemoveWaypoint(current.uid) end
    current = nil
    if enabledBefore ~= nil then
        _G.TomTom.profile.arrow.enable = enabledBefore
        enabledBefore = nil
    end
end

-- Guidelime's supported custom-code group interface supplies self.guide/self.step.
-- It keeps both engines independent: only this content pack owns these waypoints.
local bridge = {}
_G.Guidelime[addon.group] = bridge
function bridge:Waypoint(args, event)
    if event == "OnStepCompletion" then
        if current and current.step == self.step then Clear() end
        if addon.activeStep == self.step then addon.activePoint, addon.activeStep = nil, nil end
        return
    end
    if not self.step.active or self.step.completed or self.step.skip then return end
    local point = addon.route[tonumber(args[1])]
    addon.activePoint, addon.activeStep = point, self.step
    if not point or not point.mapID then Clear(); return end
    if current and current.step == self.step and _G.TomTom:IsValidWaypoint(current.uid) then return end
    Clear()
    enabledBefore = _G.TomTom.profile.arrow.enable
    _G.TomTom.profile.arrow.enable = true
    local title = "Cooking Triage: " .. point.title
    local uid = _G.TomTom:AddWaypoint(point.mapID, point.x / 100, point.y / 100, {
        title = title, from = "Cooking Triage", persistent = false,
        minimap = true, world = true, crazy = true, silent = true,
        arrivaldistance = 10, cleardistance = 0,
    })
    if uid then
        current = { uid = uid, step = self.step, guide = self.guide.name }
        -- Explicitly select the arrow even if TomTom returns an existing waypoint.
        _G.TomTom:SetCrazyArrow(uid, 10, title)
    else
        Clear()
    end
end

-- Guidelime removes custom callbacks when another guide loads. Clean up our
-- last arrow on guide changes too, without touching anybody else's waypoints.
local watcher = _G.CreateFrame("Frame")
local elapsedTime = 0
watcher:SetScript("OnUpdate", function(_, elapsed)
    elapsedTime = elapsedTime + elapsed
    if elapsedTime < 0.25 then return end
    elapsedTime = 0
    if current and (_G.GuidelimeDataChar.currentGuide ~= current.guide
        or not current.step.active or current.step.completed or current.step.skip) then Clear() end
    if addon.activeStep and (not addon.activeStep.active or addon.activeStep.completed or addon.activeStep.skip
        or _G.GuidelimeDataChar.currentGuide ~= addon.activeStep.guide.name) then
        addon.activePoint, addon.activeStep = nil, nil
    end
end)
watcher:RegisterEvent("PLAYER_LOGOUT")
watcher:SetScript("OnEvent", Clear)
