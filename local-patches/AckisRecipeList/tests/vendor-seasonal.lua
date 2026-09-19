-- Run with: lua local-patches/AckisRecipeList/tests/vendor-seasonal.lua
local source = "local-patches/AckisRecipeList/Objects/AcquireType/Vendor.lua"
local acquireType, entries = nil, {}

local fixedNow = os.time({year = 2026, month = 9, day = 19, hour = 12})
function time(value)
	if value then return os.time(value) end
	return fixedNow
end
function date(format, value) return os.date(format, value) end
function GetLocale() return "ruRU" end

function LibStub(name)
	assert(name == "AceLocale-3.0", name)
	return { GetLocale = function() return { Vendor = "Продавец", LIMITED_SUPPLY = "Ограниченный запас продажи" } end }
end

local function check(value, message) assert(value, message) end
local colors = {
	white = { hex = "ffffff", r = 1, g = 1, b = 1 },
	location = { hex = "40ff40", r = 0.25, g = 1, b = 0.25 },
	coords = { hex = "ffff40", r = 1, g = 1, b = 0.25 },
}
local private = {
	addon_name = "Ackis Recipe List",
	BASIC_COLORS = { white = colors.white },
	CATEGORY_COLORS = { location = colors.location, coords = colors.coords },
	COORDINATES_FORMAT = "(%.2f, %.2f)",
	list_frame = {
		InsertEntry = function(_, entry, index)
			table.insert(entries, entry)
			return index + 1
		end,
	},
	SetTextColor = function(hex, text) return ("|c%s%s|r"):format(hex, text) end,
	RegisterAcquireType = function(object) acquireType = object end,
	CreateListEntry = function()
		local entry = {}
		function entry:SetNPCID(id) self.npcID = id end
		function entry:SetLocation(location) self.location = location end
		function entry:SetText(format, ...)
			self.text = format:format(...)
		end
		return entry
	end,
}

assert(loadfile(source))("AckisRecipeList", private)
check(acquireType, "vendor acquire type registered")

local location = { LocalizedName = function() return "Stormwind City" end }
local vendors = {
	[13435] = { name = "Khole Jinglepocket", faction = "Alliance", Location = location, coord_x = 55.01, coord_y = 59.26, item_list = { [21144] = true } },
	[1] = { name = "Ordinary Vendor", faction = "Alliance", Location = location, coord_x = 10, coord_y = 20, item_list = { [2540] = true } },
}
function acquireType:GetEntity(id) return vendors[id] end
function acquireType:ColorData() return self._colorData end
function acquireType:Name() return self._name end
function acquireType.CanDisplayFaction() return true end
function acquireType.GetTipFactionInfo() return true, colors.white end
function acquireType.ColorNameByFaction(name) return name end
acquireType.EntryPadding = "  "

local function recipe(spellID)
	return { SpellID = function() return spellID end }
end

local tooltipLines = {}
local function addline_func(_, _, _, left, _, right)
	tooltipLines[#tooltipLines + 1] = tostring(left) .. " " .. tostring(right)
end

acquireType._func_insert_tooltip_text(acquireType, recipe(21144), 13435, nil, nil, addline_func)
local tooltip = table.concat(tooltipLines, "\n")
check(tooltip:match("Seasonal Event"), "seasonal tooltip label")
check(tooltip:match("Feast of Winter Veil"), "seasonal event name in tooltip")
check(not tooltip:match("2026%-12%-16") and not tooltip:match("absence outside"), "seasonal tooltip stays compact")

tooltipLines = {}
acquireType._func_insert_tooltip_text(acquireType, recipe(2540), 1, nil, nil, addline_func)
check(not table.concat(tooltipLines, "\n"):match("Сезонное событие"), "ordinary vendor has no seasonal tooltip")

entries = {}
acquireType._func_expand_list_entry(acquireType, 0, "acquire", {}, 13435, nil, recipe(21144), false, false)
local listText = {}
for _, entry in ipairs(entries) do listText[#listText + 1] = entry.text end
listText = table.concat(listText, "\n")
check(listText:match("Feast of Winter Veil"), "seasonal note shown in expanded list")
check(not listText:match("2026%-12%-16") and not listText:match("absence outside"), "seasonal list note stays compact")

print("PASS: seasonal vendor notes appear in classic ARL vendor tooltip and expanded source list")
