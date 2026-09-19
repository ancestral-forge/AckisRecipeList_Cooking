local _, addon = ...

local seasons = {
    WINTER_VEIL = {
        name = "Feast of Winter Veil",
        startMonth = 12, startDay = 16,
        endMonth = 1, endDay = 2,
    },
}

local function window(season, now)
    local time, date = _G.time or os.time, _G.date or os.date
    now = now or time()
    local today = date("*t", now)
    local startYear = today.year
    if season.startMonth > season.endMonth and today.month <= season.endMonth then
        startYear = today.year - 1
    end
    local startTime = time({year = startYear, month = season.startMonth, day = season.startDay, hour = 0})
    local endYear = startYear + (season.startMonth > season.endMonth and 1 or 0)
    local endTime = time({year = endYear, month = season.endMonth, day = season.endDay, hour = 23, min = 59})
    if now > endTime then
        startYear = startYear + 1
        startTime = time({year = startYear, month = season.startMonth, day = season.startDay, hour = 0})
        endYear = startYear + (season.startMonth > season.endMonth and 1 or 0)
        endTime = time({year = endYear, month = season.endMonth, day = season.endDay, hour = 23, min = 59})
    end
    return startTime, endTime
end

function addon.SeasonText(event, now)
    local season = seasons[event]
    if not season then return nil end
    local startTime, endTime = window(season, now)
    local date = _G.date or os.date
    local startDate = date("%Y-%m-%d", startTime)
    local endDate = date("%Y-%m-%d", endTime)
    return season.name .. ": примерно " .. startDate .. " - " .. endDate .. ". Вне события отсутствие не опровергает источник."
end
