local _, addon = ...
local callbacks = " --OnStepActivation,OnStepUpdate,OnStepCompletion >> Waypoint,"
local lines = {
    "[N" .. addon.title .. "]",
    "[DПолная перепроверка источников Cooking: Альянс и нейтральные NPC, включая изученные рецепты. Начало в Шаттрате; все грифоны открыты. /ctriage start фиксирует ожидания, /ctriage report показывает совпадения отдельно для уверенной и сомнительной групп. TomTom Crazy Arrow ведёт к текущему шагу.]",
    "[GA Alliance]",
    "[GG off][GL off][GI off]",
    "[NXDeferred Sources]",
}
local deferred = {"[NDeferred Sources]", "[DСезонные и отложенные источники Cooking. Выбирай нужный шаг по условиям; непрерывного маршрута здесь нет.]", "[GA Alliance]", "[GG off][GL off][GI off]", "[NXSkill Breakpoint Checks]"}
for index, point in ipairs(addon.route) do
    local text = point.text
    if point.mapID then
        -- LOC does not auto-complete a verification when the player merely arrives.
        text = ("[L%.2f,%.2f %s] %s"):format(point.x, point.y, point.zone, text)
    end
    if point.npcID then text = ("[TAR%d-] "):format(point.npcID) .. text end
    if point.applies then text = "[A " .. point.applies .. "] " .. text end
    if point.flight then text = "[F " .. point.flight .. "] " .. text end
    if point.title then text = "*" .. point.title .. "* \\" .. text end
    local target = index <= addon.mainRouteLength and lines or deferred
    target[#target + 1] = text .. callbacks .. index
end
_G.Guidelime.registerGuide(table.concat(lines, "\n"), addon.group)
_G.Guidelime.registerGuide(table.concat(deferred, "\n"), addon.group)

local skills = {
    "[NSkill Breakpoint Checks]",
    "[DПроверки спорных порогов Cooking и источников, которые нельзя подтвердить обычным обходом NPC.]",
    "[GA Alliance]", "[GG off][GL off][GI off]",
}
for _, text in ipairs(addon.skillChecks) do skills[#skills + 1] = text .. callbacks .. "0" end
_G.Guidelime.registerGuide(table.concat(skills, "\n"), addon.group)
