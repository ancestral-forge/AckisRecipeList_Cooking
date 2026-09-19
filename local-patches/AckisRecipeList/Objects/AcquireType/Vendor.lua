-- ----------------------------------------------------------------------------
-- Localized Lua globals.
-- ----------------------------------------------------------------------------

local type = _G.type

local date = _G.date or os.date
local time = _G.time or os.time


-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local _, private = ...

local LibStub = _G.LibStub
local L = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

-- ----------------------------------------------------------------------------
-- Imports.
-- ----------------------------------------------------------------------------
local BASIC_COLORS = private.BASIC_COLORS
local CATEGORY_COLORS = private.CATEGORY_COLORS
local COORDINATES_FORMAT = private.COORDINATES_FORMAT

local russian = _G.GetLocale and _G.GetLocale() == "ruRU"
local labels = russian and {
	seasonalPrefix = "Сезонное событие",
	winterVeil = "Feast of Winter Veil: примерно %s - %s. Вне события отсутствие не опровергает источник.",
	winterVeilTooltip = "примерно %s - %s; вне события отсутствие не опровергает источник",
} or {
	seasonalPrefix = "Seasonal event",
	winterVeil = "Feast of Winter Veil: roughly %s - %s. Absence outside the event does not disprove the source.",
	winterVeilTooltip = "roughly %s - %s; absence outside the event does not disprove the source",
}
local winterVeilVendors = {[13420]=true, [13429]=true, [13432]=true, [13433]=true, [13435]=true, [23010]=true, [23012]=true, [23064]=true}
local winterVeilRecipes = {[21143]=true, [21144]=true, [45022]=true}

local function WinterVeilWindow()
	local now = time()
	local today = date("*t", now)
	local startYear = today.year
	if today.month == 1 then
		startYear = today.year - 1
	end
	local startTime = time({year = startYear, month = 12, day = 16, hour = 0})
	local endTime = time({year = startYear + 1, month = 1, day = 2, hour = 23, min = 59})
	if now > endTime then
		startYear = startYear + 1
		startTime = time({year = startYear, month = 12, day = 16, hour = 0})
		endTime = time({year = startYear + 1, month = 1, day = 2, hour = 23, min = 59})
	end
	return date("%Y-%m-%d", startTime), date("%Y-%m-%d", endTime)
end

local function WinterVeilNote(spellID, vendorID, tooltip)
	if winterVeilVendors[vendorID] and winterVeilRecipes[spellID] then
		if tooltip then
			return labels.winterVeilTooltip:format(WinterVeilWindow())
		end
		return labels.winterVeil:format(WinterVeilWindow())
	end
end

private.RegisterAcquireType({
	-- ----------------------------------------------------------------------------
	-- Data.
	-- ----------------------------------------------------------------------------
	_colorData = { hex = "aad372", r = 0.67, g = 0.83, b = 0.45 },
	_hasCoordinates = true,
	_hasEntities = true,
	_label = "VENDOR",
	_name = L["Vendor"],
	-- ----------------------------------------------------------------------------
	-- Methods.
	-- ----------------------------------------------------------------------------
	_func_expand_list_entry = function(self, entry_index, entry_type, parent_entry, identifier, _, recipe, hide_location, hide_type)
		local vendor = self:GetEntity(identifier)

		if not vendor or not self.CanDisplayFaction(vendor.faction) then
			return entry_index
		end

		local quantity = vendor.item_list[recipe:SpellID()]
		local entry = private.CreateListEntry(entry_type, parent_entry, recipe)
		entry:SetNPCID(identifier)
		entry:SetLocation(vendor.Location)
		entry:SetText("%s%s %s%s",
			self.EntryPadding,
			hide_type and "" or private.SetTextColor(self:ColorData().hex, self:Name()) .. ":",
			self.ColorNameByFaction(vendor.name, vendor.faction),
			type(quantity) == "number" and private.SetTextColor(BASIC_COLORS.white.hex, (" (%d)"):format(quantity)) or "")

		entry_index = private.list_frame:InsertEntry(entry, entry_index, true)

		local coord_text = ""

		if vendor.coord_x ~= 0 and vendor.coord_y ~= 0 then
			coord_text = private.SetTextColor(CATEGORY_COLORS.coords.hex, COORDINATES_FORMAT:format(vendor.coord_x, vendor.coord_y))
		end

		local seasonal_note = WinterVeilNote(recipe:SpellID(), identifier)

		if coord_text == "" and hide_location then
			if seasonal_note then
				entry = private.CreateListEntry(entry_type, parent_entry, recipe)
				entry:SetNPCID(identifier)
				entry:SetLocation(vendor.Location)
				entry:SetText("%s%s", self.EntryPadding:rep(2), private.SetTextColor(BASIC_COLORS.white.hex, seasonal_note))
				return private.list_frame:InsertEntry(entry, entry_index, true)
			end
			return entry_index
		end

		entry = private.CreateListEntry(entry_type, parent_entry, recipe)
		entry:SetNPCID(identifier)
		entry:SetLocation(vendor.Location)
		local locName = (vendor.Location and vendor.Location.LocalizedName and vendor.Location:LocalizedName()) or "Unknown"
		entry:SetText("%s%s %s",
			self.EntryPadding:rep(2),
			hide_location and "" or private.SetTextColor(CATEGORY_COLORS.location.hex, locName),
			coord_text)

		entry_index = private.list_frame:InsertEntry(entry, entry_index, true)

		if seasonal_note then
			entry = private.CreateListEntry(entry_type, parent_entry, recipe)
			entry:SetNPCID(identifier)
			entry:SetLocation(vendor.Location)
			entry:SetText("%s%s", self.EntryPadding:rep(2), private.SetTextColor(BASIC_COLORS.white.hex, seasonal_note))
			entry_index = private.list_frame:InsertEntry(entry, entry_index, true)
		end

		return entry_index
	end,
	_func_insert_tooltip_text = function(self, recipe, identifier, localizedLocationName, _, addline_func)
		local vendor = self:GetEntity(identifier)

		if not vendor then
			return
		end
		if localizedLocationName then
			if not (vendor.Location and vendor.Location.LocalizedName and vendor.Location:LocalizedName() == localizedLocationName) then
				return
			end
		end
		local display_tip, name_color = self.GetTipFactionInfo(vendor.faction)

		if not display_tip then
			return
		end
		addline_func(0, -1, false, L["Vendor"], self:ColorData(), vendor.name, name_color)

		local locName = (vendor.Location and vendor.Location.LocalizedName and vendor.Location:LocalizedName()) or "Unknown"
		if vendor.coord_x ~= 0 and vendor.coord_y ~= 0 then
			addline_func(1, -2, true, locName, CATEGORY_COLORS.location, COORDINATES_FORMAT:format(vendor.coord_x, vendor.coord_y), CATEGORY_COLORS.coords)
		else
			addline_func(1, -2, true, locName, CATEGORY_COLORS.location, "", CATEGORY_COLORS.coords)
		end
		local quantity = vendor.item_list[recipe:SpellID()]

		if type(quantity) == "number" then
			addline_func(2, -2, true, L["LIMITED_SUPPLY"], self:ColorData(), ("(%d)"):format(quantity), BASIC_COLORS.white)
		end
		local seasonal_note = WinterVeilNote(recipe:SpellID(), identifier, true)
		if seasonal_note then
			addline_func(2, -2, true, labels.seasonalPrefix, self:ColorData(), seasonal_note, BASIC_COLORS.white)
		end
	end,
	_func_waypoint_target = function(self, id_num)
		if not private.db.profile.mapvendor then
			return
		end

		local vendor = self:GetEntity(id_num)
		if vendor and self.CanDisplayFaction(vendor.faction) then
			return vendor
		end
	end,
})
