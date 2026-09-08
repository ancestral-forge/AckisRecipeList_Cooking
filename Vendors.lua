-------------------------------------------------------------------------------
-- Module namespace.
-------------------------------------------------------------------------------
local FOLDER_NAME, private = ...

local addon = private.addon
if not addon then
	return
end

local constants = addon.constants
local module = addon:GetModule(private.module_name)
local L = _G.LibStub("AceLocale-3.0"):GetLocale(addon.constants.addon_name)

local Z = constants.ZONE_NAMES
local V = constants.GAME_VERSIONS

-----------------------------------------------------------------------
-- What we _really_ came here to see...
-----------------------------------------------------------------------
function module:InitializeVendors()
	local function AddVendor(vendorID, vendorName, zoneName, coordX, coordY, faction, expansionID)
		addon.AcquireTypes.Vendor:AddEntity(module, {
			coord_x = coordX,
			coord_y = coordY,
			expansionID = expansionID,
			faction = faction,
			identifier = vendorID,
			item_list = {},
			locationName = zoneName,
			name = vendorName,
		})
	end

	-----------------------------------------------------------------------
	-- Vanilla
	-----------------------------------------------------------------------
	AddVendor(340,		L["Kendor Kabonka"],			Z.STORMWIND_CITY,			74.6,	36.8,	"Alliance",	V.ORIG)
	AddVendor(734,		L["Corporal Bluth"],			Z.STRANGLETHORN_VALE,		38.0,	3.0,	"Alliance",	V.ORIG)
	AddVendor(1149,		L["Uthok"],						Z.STRANGLETHORN_VALE,		31.6,	28.0,	"Horde",	V.ORIG)
	AddVendor(1465,		L["Drac Roughcut"],				Z.LOCH_MODAN,				35.6,	49.0,	"Alliance",	V.ORIG)
	AddVendor(1684,		L["Khara Deepwater"],			Z.LOCH_MODAN,				39.5,	39.3,	"Alliance",	V.ORIG)
	AddVendor(2118,		L["Abigail Shiel"],				Z.TIRISFAL_GLADES,			61.0,	52.4,	"Horde",	V.ORIG)
	AddVendor(2397,		L["Derak Nightfall"],			Z.HILLSBRAD_FOOTHILLS,		63.0,	19.6,	"Horde",	V.ORIG)
	AddVendor(2664,		L["Kelsey Yance"],				Z.STRANGLETHORN_VALE,		28.2,	74.4,	"Neutral",	V.ORIG)
	AddVendor(2803,		L["Malygen"],					Z.FELWOOD,					62.2,	25.6,	"Alliance",	V.ORIG)
	AddVendor(2806,		"Bale",							Z.FELWOOD,					34.8,	53.2,	"Horde",	V.ORIG)
	AddVendor(2814,		L["Narj Deepslice"],			Z.ARATHI_HIGHLANDS,			45.6,	47.6,	"Alliance",	V.ORIG)
	AddVendor(2821,		L["Keena"],						Z.ARATHI_HIGHLANDS,			74.0,	32.6,	"Horde",	V.ORIG)
	AddVendor(3027,		L["Naal Mistrunner"],			Z.THUNDER_BLUFF,			51.0,	52.5,	"Horde",	V.ORIG)
	AddVendor(3029,		L["Sewa Mistrunner"],			Z.THUNDER_BLUFF,			55.8,	47.0,	"Horde",	V.ORIG)
	AddVendor(3081,		L["Wunna Darkmane"],			Z.MULGORE,					46.1,	58.2,	"Horde",	V.ORIG)
	AddVendor(3085,		L["Gloria Femmel"],				Z.REDRIDGE_MOUNTAINS,		26.7,	43.5,	"Alliance",	V.ORIG)
	AddVendor(3178,		L["Stuart Fleming"],			Z.WETLANDS,			 		8.0,	58.2,	"Alliance",	V.ORIG)
	AddVendor(3333,		L["Shankys"],					Z.ORGRIMMAR,				70.0,	29.4,	"Horde",	V.ORIG)
	AddVendor(3400,		L["Xen'to"],					Z.ORGRIMMAR,				57.6,	53.2,	"Horde",	V.ORIG)
	AddVendor(3482,		L["Tari'qa"],					Z.THE_BARRENS,				51.6,	30.0,	"Horde",	V.ORIG)
	AddVendor(3489,		L["Zargh"],						Z.THE_BARRENS,				52.6,	29.8,	"Horde",	V.ORIG)
	AddVendor(3497,		L["Kilxx"],						Z.THE_BARRENS,				62.8,	38.2,	"Neutral",	V.ORIG)
	AddVendor(3550,		L["Martine Tramblay"],			Z.TIRISFAL_GLADES,			65.8,	59.6,	"Horde",	V.ORIG)
	AddVendor(3881,		L["Grimtak"],					Z.DUROTAR,					50.7,	42.8,	"Horde",	V.ORIG)
	AddVendor(3960,		"Ulthaan",						Z.ASHENVALE,				50.0,	66.6,	"Alliance",	V.ORIG)
	AddVendor(4223,		L["Fyldan"],					Z.DARNASSUS,				48.6,	21.6,	"Alliance",	V.ORIG)
	AddVendor(4265,		L["Nyoma"],						Z.TELDRASSIL,				57.2,	61.2,	"Alliance",	V.ORIG)
	AddVendor(4305,		L["Kriggon Talsone"],			Z.WESTFALL,					36.2,	90.1,	"Alliance",	V.ORIG)
	AddVendor(4553,		L["Ronald Burch"],				Z.UNDERCITY,				62.3,	43.1,	"Horde",	V.ORIG)
	AddVendor(4574,		L["Lizbeth Cromwell"],			Z.UNDERCITY,				81.0,	30.7,	"Horde",	V.ORIG)
	AddVendor(4782,		L["Truk Wildbeard"],			Z.THE_HINTERLANDS,			14.4,	42.5,	"Alliance",	V.ORIG)
	AddVendor(4879,		L["Ogg'marr"],					Z.DUSTWALLOW_MARSH,			36.6,	31.0,	"Horde",	V.ORIG)
	AddVendor(4894,		L["Craig Nollward"],			Z.DUSTWALLOW_MARSH,			66.9,	45.2,	"Alliance",	V.ORIG)
	AddVendor(5160,		L["Emrul Riknussun"],			Z.IRONFORGE,				59.9,	37.7,	"Alliance",	V.ORIG)
	AddVendor(5162,		L["Tansy Puddlefizz"],			Z.IRONFORGE,				48.0,	6.3,	"Alliance",	V.ORIG)
	AddVendor(5483,		L["Erika Tate"],				Z.STORMWIND_CITY,			75.8,	36.8,	"Alliance",	V.ORIG)
	AddVendor(5494,		L["Catherine Leland"],			Z.STORMWIND_CITY,			45.8,	58.2,	"Alliance",	V.ORIG)
	AddVendor(5748,		L["Killian Sanatha"],			Z.SILVERPINE_FOREST,		33.0,	17.8,	"Horde",	V.ORIG)
	AddVendor(5940,		L["Harn Longcast"],				Z.MULGORE,					47.5,	55.1,	"Horde",	V.ORIG)
	AddVendor(5942,		L["Zansoa"],					Z.DUROTAR,					56.0,	73.4,	"Horde",	V.ORIG)
	AddVendor(6779,		L["Smudge Thunderwood"],		Z.ALTERAC_MOUNTAINS,		86.0,	79.6,	"Neutral",	V.ORIG)
	AddVendor(7733,		L["Innkeeper Fizzgrimble"],		Z.TANARIS,					52.4,	27.8,	"Neutral",	V.ORIG)
	AddVendor(7947,		L["Vivianna"],					Z.FERALAS,					31.2,	43.4,	"Alliance",	V.ORIG)
	AddVendor(8137,		L["Gikkix"],		            Z.TANARIS,					66.6,	22.0,	"Neutral", 	V.ORIG)
	AddVendor(8139,		L["Jabbey"],		            Z.TANARIS,					67.0,	22.0,	"Neutral",	V.ORIG)
	AddVendor(8145,		L["Sheendra Tallgrass"],		Z.FERALAS,					74.6,	42.8,	"Horde",	V.ORIG)
	AddVendor(8150,		L["Janet Hommers"],				Z.DESOLACE,					66.2,	6.6,	"Alliance",	V.ORIG)
	AddVendor(8307,		L["Tarban Hearthgrain"],		Z.THE_BARRENS,				55.0,	32.0,	"Horde",	V.ORIG)
	AddVendor(8508,		L["Gretta Ganter"],				Z.DUN_MOROGH,				31.6,	44.6,	"Alliance",	V.ORIG)
	AddVendor(10118,	L["Nessa Shadowsong"],			Z.TELDRASSIL,				56.2,	92.4,	"Alliance",	V.ORIG)
	AddVendor(11187,	L["Himmik"],					Z.WINTERSPRING,				61.2,	39.0,	"Neutral",	V.ORIG)
	AddVendor(12033,	L["Wulan"],						Z.DESOLACE,					26.2,	69.8,	"Horde",	V.ORIG)
	AddVendor(12245,	L["Vendor-Tron 1000"],			Z.DESOLACE,					60.0,	38.0,	"Neutral",	V.ORIG)
	AddVendor(12246,	L["Super-Seller 680"],			Z.DESOLACE,					40.0,	79.0,	"Neutral",	V.ORIG)
	AddVendor(12962,	L["Wik'Tar"],					Z.ASHENVALE,				11.8,	34.0,	"Horde",	V.ORIG)
	AddVendor(13429,	L["Nardstrum Copperpinch"],		Z.UNDERCITY,				67.5,	38.7,	"Horde",	V.ORIG)
	AddVendor(13432,	L["Seersa Copperpinch"],		Z.THUNDER_BLUFF,			42.0,	55.1,	"Horde",	V.ORIG)
	AddVendor(13435,	L["Khole Jinglepocket"],		Z.STORMWIND_CITY,			55.0,	59.2,	"Alliance",	V.ORIG)
	AddVendor(14738,	L["Otho Moji'ko"],				Z.THE_HINTERLANDS,			79.2,	79.0,	"Horde",	V.ORIG)

	-----------------------------------------------------------------------
	-- TBC
	-----------------------------------------------------------------------
	AddVendor(16253,	L["Master Chef Mouldier"],		Z.GHOSTLANDS,				48.4,	31.0,	"Horde",	V.TBC)
	AddVendor(16262,	L["Landraelanis"],				Z.EVERSONG_WOODS,			49.0,	47.0,	"Horde",	V.TBC)
	AddVendor(16585,	L["Cookie One-Eye"],			Z.HELLFIRE_PENINSULA,		54.6,	41.1,	"Horde",	V.TBC)
	AddVendor(16677,	L["Quelis"],					Z.SILVERMOON_CITY,			69.3,	70.4,	"Horde",	V.TBC)
	AddVendor(16718,	L["Phea"],						Z.THE_EXODAR,				54.7,	26.5,	"Alliance",	V.TBC)
	AddVendor(16826,	L["Sid Limbardi"],				Z.HELLFIRE_PENINSULA,		54.3,	63.6,	"Alliance",	V.TBC)
	AddVendor(17246,	L["\"Cookie\" McWeaksauce"],	Z.AZUREMYST_ISLE,			46.7,	70.5,	"Alliance",	V.TBC)
	AddVendor(18015,	L["Gambarinka"],				Z.ZANGARMARSH,				31.7,	49.3,	"Horde",	V.TBC)
	AddVendor(18427,	L["Fazu"],						Z.BLOODMYST_ISLE,			53.5,	56.5,	"Alliance",	V.TBC)
	AddVendor(18911,	L["Juno Dufrain"],				Z.ZANGARMARSH,				78.0,	66.1,	"Neutral",	V.TBC)
	AddVendor(18957,	L["Innkeeper Grilka"],			Z.TEROKKAR_FOREST,			48.8,	45.1,	"Horde",	V.TBC)
	AddVendor(18960,	L["Rungor"],					Z.TEROKKAR_FOREST,			48.8,	46.1,	"Horde",	V.TBC)
	AddVendor(19038,	L["Supply Officer Mills"],		Z.TEROKKAR_FOREST,			55.7,	53.1,	"Alliance",	V.TBC)
	AddVendor(19195,	L["Jim Saltit"],				Z.SHATTRATH_CITY,			63.6,	68.6,	"Neutral",	V.TBC)
	AddVendor(19296,	L["Innkeeper Biribi"],			Z.TEROKKAR_FOREST,			56.7,	53.3,	"Alliance",	V.TBC)
	AddVendor(20028,	L["Doba"],						Z.ZANGARMARSH,				42.3,	27.9,	"Alliance",	V.TBC)
	AddVendor(20096,	L["Uriku"],						Z.NAGRAND_OUTLAND,			56.2,	73.3,	"Alliance",	V.TBC)
	AddVendor(20097,	L["Nula the Butcher"],			Z.NAGRAND_OUTLAND,			58.0,	35.7,	"Horde",	V.TBC)
	AddVendor(20916,	L["Xerintha Ravenoak"],			Z.BLADES_EDGE_MOUNTAINS,	62.5,	40.3,	"Neutral",	V.TBC)
	AddVendor(21113,	L["Sassa Weldwell"],			Z.BLADES_EDGE_MOUNTAINS,	61.3,	68.9,	"Alliance",	V.TBC)
	AddVendor(23010,	L["Wolgren Jinglepocket"],		Z.THE_EXODAR,				55.2,	48.6,	"Alliance",	V.TBC)
	AddVendor(23012,	L["Hotoppik Copperpinch"],		Z.SILVERMOON_CITY,			63.5,	79.1,	"Horde",	V.TBC)
	AddVendor(23064,	L["Eebee Jinglepocket"],		Z.SHATTRATH_CITY,			51.0,	31.3,	"Neutral",	V.TBC)

	-----------------------------------------------------------------------
	-- Wrath of The Lich King
	-----------------------------------------------------------------------
	AddVendor(26868,	L["Provisioner Lorkran"],		Z.GRIZZLY_HILLS,			22.6,	66.1,	"Horde",	V.WOTLK)
	AddVendor(31031,	L["Misensi"],					Z.DALARAN_NORTHREND,		70.1,	38.5,	"Horde",	V.WOTLK)
	AddVendor(31032,	L["Derek Odds"],				Z.DALARAN_NORTHREND,		41.5,	64.8,	"Alliance",	V.WOTLK)
	AddVendor(33595,	L["Mera Mistrunner"],			Z.ICECROWN,					72.4,	20.9,	"Neutral",	V.WOTLK)
	AddVendor(34382,	L["Chapman"],					Z.UNDERCITY,				68.1,	11.2,	"Horde",	V.WOTLK)

	-----------------------------------------------------------------------
	-- Cataclysm
	-----------------------------------------------------------------------
	AddVendor(340,		L["Kendor Kabonka"],			Z.STORMWIND_CITY,			76.6,	53.6,	"Alliance",	V.CATA)
	AddVendor(734,		L["Corporal Bluth"],			Z.NORTHERN_STRANGLETHORN,	47.4,	10.2,	"Alliance",	V.CATA)
	AddVendor(1149,		L["Uthok"],						Z.NORTHERN_STRANGLETHORN,	37.4,	49.2,	"Horde",	V.CATA)
	AddVendor(2397,		L["Derak Nightfall"],			Z.HILLSBRAD_FOOTHILLS,		57.6,	45.2,	"Horde",	V.CATA)
	AddVendor(2664,		L["Kelsey Yance"],				Z.THE_CAPE_OF_STRANGLETHORN,42.8,	69.1,	"Neutral",	V.CATA)
	AddVendor(2814,		L["Narj Deepslice"],			Z.ARATHI_HIGHLANDS,			39.6,	48.8,	"Alliance",	V.CATA)
	AddVendor(3178,		L["Stuart Fleming"],			Z.WETLANDS,			 		6.2,	57.4,	"Alliance",	V.CATA)
	AddVendor(3333,		L["Shankys"],					Z.ORGRIMMAR,				66.4,	41.8,	"Horde",	V.CATA)
	AddVendor(3400,		L["Xen'to"],					Z.ORGRIMMAR,				32.4,	69.0,	"Horde",	V.CATA)
	AddVendor(3482,		L["Tari'qa"],					Z.NORTHERN_BARRENS,			49.0,	58.2,	"Horde",	V.CATA)
	AddVendor(3489,		L["Zargh"],						Z.NORTHERN_BARRENS,			50.6,	57.8,	"Horde",	V.CATA)
	AddVendor(3497,		L["Kilxx"],						Z.NORTHERN_BARRENS,			68.6,	72.6,	"Neutral",	V.CATA)
	AddVendor(4223,		L["Fyldan"],					Z.DARNASSUS,				49.8,	36.4,	"Alliance",	V.CATA)
	AddVendor(4265,		L["Nyoma"],						Z.TELDRASSIL,				56.6,	53.6,	"Alliance",	V.CATA)
	AddVendor(5483,		L["Erika Tate"],				Z.STORMWIND_CITY,			77.6,	53.0,	"Alliance",	V.CATA)
	AddVendor(5494,		L["Catherine Leland"],			Z.STORMWIND_CITY,			55.0,	69.6,	"Alliance",	V.CATA)
	AddVendor(5748,		L["Killian Sanatha"],			Z.SILVERPINE_FOREST,		59.2,	33.6,	"Horde",	V.CATA)
	AddVendor(5942,		L["Zansoa"],					Z.DUROTAR,					57.4,	77.0,	"Horde",	V.CATA)
	AddVendor(6779,		L["Smudge Thunderwood"],		Z.HILLSBRAD_FOOTHILLS,		71.0,	45.8,	"Neutral",	V.CATA)
	AddVendor(7733,		L["Innkeeper Fizzgrimble"],		Z.TANARIS,					52.6,	28.0,	"Neutral",	V.CATA)
	AddVendor(7947,		L["Vivianna"],					Z.FERALAS,					46.2,	41.6,	"Alliance",	V.CATA)
	AddVendor(8307,		L["Tarban Hearthgrain"],		Z.NORTHERN_BARRENS,			55.0,	61.6,	"Horde",	V.CATA)
	AddVendor(8508,		L["Gretta Ganter"],				Z.NEW_TINKERTOWN,			51.8,	50.0,	"Alliance",	V.CATA)
	AddVendor(10118,	L["Nessa Shadowsong"],			Z.TELDRASSIL,				54.0,	90.0,	"Alliance",	V.CATA)
	AddVendor(11187,	L["Himmik"],					Z.WINTERSPRING,				59.8,	51.4,	"Neutral",	V.CATA)
	AddVendor(13435,	L["Khole Jinglepocket"],		Z.STORMWIND_CITY,			62.8,	70.2,	"Alliance",	V.CATA)
	AddVendor(40589,	L["Dirge Quikcleave"],			Z.TANARIS,					52.6,	29.1,	"Neutral",	V.CATA)
	AddVendor(46708,	L["Suja"],						Z.ORGRIMMAR,				56.5,	61.2,	"Horde",	V.CATA)
	AddVendor(48060,	L["\"Chef\" Overheat"],			Z.BADLANDS,					65.1,	39.1,	"Neutral",	V.CATA)
	AddVendor(49701,	L["Bario Matalli"],				Z.STORMWIND_CITY, 			50.6,	71.6,	"Alliance",	V.CATA)
	AddVendor(49737,	L["Shazdar"],					Z.ORGRIMMAR,				56.8,	62.3,	"Horde",	V.CATA)
	AddVendor(49885,	L["KTC Train-a-Tron Deluxe"],	Z.AZSHARA, 					57.0, 	50.6, 	"Horde",	V.CATA)
	AddVendor(51504,	L["Velia Moonbow"],				Z.DARNASSUS,				64.6,	37.6,	"Alliance",	V.CATA)
	AddVendor(54232,	L["Mrs. Gant"],					Z.THE_CAPE_OF_STRANGLETHORN,42.6,	72.8,	"Neutral",	V.CATA)
	AddVendor(55103,	L["Galissa Sundew"],			Z.DARKMOON_ISLAND,			52.6,	88.4,	"Neutral",	V.CATA)
	AddVendor(56069,	L["Tatia Brine"],				Z.DARKMOON_ISLAND,			52.5,	88.6,	"Neutral",	V.CATA)

	-----------------------------------------------------------------------
	-- Mist of Pandaria
	-----------------------------------------------------------------------
	AddVendor(58706,	L["Gina Mudclaw"],				Z.VALLEY_OF_THE_FOUR_WINDS,	52.4,	51.6,	"Neutral",	V.MOP)
	AddVendor(63721,	L["Nat Pagle"],					Z.KRASARANG_WILDS,			68.4, 	43.5,	"Neutral",	V.MOP)
	AddVendor(64084,	L["Jojo"],						Z.VALE_OF_ETERNAL_BLOSSOMS,	62.4,	26.6,	"Alliance",	V.MOP)
	AddVendor(64126,	L["Stephen Wong"],				Z.VALLEY_OF_THE_FOUR_WINDS,	59.1,	16.2,	"Horde",	V.MOP)
	AddVendor(64395,	L["Nam Ironpaw"],				Z.VALLEY_OF_THE_FOUR_WINDS,	53.5,	51.3,	"Neutral",	V.MOP)
	AddVendor(64465,	L["Noodles"],					Z.VALLEY_OF_THE_FOUR_WINDS,	52.4,	51.6,	"Neutral",	V.MOP)

	-----------------------------------------------------------------------
	-- Warlords of Dreanor
	-----------------------------------------------------------------------
	AddVendor(76928,	L["Kraank"],					Z.FROSTWALL,				36.8,	39.6,	"Horde",	V.WOD)
	AddVendor(80159,	L["Arsenio Zerep"],				Z.LUNARFALL,				60.9,	76.2,	"Alliance",	V.WOD)

	-----------------------------------------------------------------------
	-- Legion
	-----------------------------------------------------------------------
	AddVendor(101846,	L["Nomi"],						Z.DALARAN_BROKENISLES,		40.1,	66.1,	"Neutral",	V.LEGION)
	AddVendor(112226,	L["Markus Hjolbruk"],			Z.SURAMAR,					71.6,	48.8,	"Neutral",	V.LEGION)
	AddVendor(120456,	L["Keeper Raynae"],				Z.VALSHARAH,				53.4,	72.8,	"Neutral",	V.LEGION)

	self.InitializeVendors = nil
end
