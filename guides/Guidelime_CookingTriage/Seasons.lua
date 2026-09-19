local _, addon = ...

local seasons = {
    WINTER_VEIL = {
        text = "Seasonal Event: Feast of Winter Veil",
    },
}

function addon.SeasonText(event)
    local season = seasons[event]
    if not season then return nil end
    return season.text
end
