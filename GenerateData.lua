-----
-- Build Initial List
-----

-- Get ZOS Localized Strings
local itemTypes = {
	[ITEMTYPE_NONE]			= GetString(SI_ITEMFILTERTYPE5),
	[ITEMTYPE_WEAPON]		= GetString(SI_ITEMTYPE1),
	[ITEMTYPE_ARMOR]		= GetString(SI_ITEMTYPE2),
	[ITEMTYPE_FOOD]			= GetString(SI_ITEMTYPE4),
	[ITEMTYPE_TROPHY]		= GetString(SI_ITEMTYPE5),
	[ITEMTYPE_SIEGE]		= GetString(SI_ITEMTYPE6),
	[ITEMTYPE_POTION]		= GetString(SI_ITEMTYPE7),
	[ITEMTYPE_TOOL]			= GetString(SI_ITEMTYPE9),
	[ITEMTYPE_INGREDIENT]	= GetString(SI_ITEMTYPE10),
	[ITEMTYPE_DRINK]		= GetString(SI_ITEMTYPE12),
	[ITEMTYPE_DISGUISE]		= GetString(SI_ITEMTYPE14),
	[ITEMTYPE_LURE]			= GetString(SI_ITEMTYPE16),
	--[ITEMTYPE_CONTAINER]	= GetString(SI_ITEMTYPE18),	-- Too many extras
	[ITEMTYPE_SOUL_GEM]		= GetString(SI_ITEMTYPE19),
	[ITEMTYPE_RECIPE]		= GetString(SI_ITEMTYPE29),
	[ITEMTYPE_COLLECTIBLE]	= GetString(SI_ITEMTYPE34),
	[ITEMTYPE_TRASH]		= GetString(SI_ITEMTYPE48),
	[ITEMTYPE_FISH]			= GetString(SI_ITEMTYPE54),
	[ITEMTYPE_TREASURE]		= GetString(SI_ITEMTYPE56),	-- Exclude this one?
	[ITEMTYPE_CROWN_ITEM]	= GetString(SI_ITEMTYPE57),
	[ITEMTYPE_FURNISHING]	= GetString(SI_ITEMTYPE61),
	[ITEMTYPE_RECALL_STONE]	= GetString(SI_ITEMTYPE69),
	[EFT_ITYPE_QUEST_ITEM]	= GetString(SI_ITEM_FORMAT_STR_QUEST_ITEM),	-- Quest Items (Custom Number)
}

itemConds = {
	[ITEMTYPE_ARMOR] = {
		"By researching this piece of gear,",
	},
	[ITEMTYPE_TROPHY] = {
		"A rare map indicating",
		"A rare report indicating",
	},
	[ITEMTYPE_INGREDIENT] = {
		"An ingredient",
		"Use to make",
		"can be sold.",
	},
	[ITEMTYPE_CONTAINER] = {
		"Contains a",
		"Ability-Altering",
		"This box contains",
	},
	[ITEMTYPE_COLLECTIBLE] = {
		"Grants an Outfit Style Collectible.",
		"Use to learn the",
	},
	[ITEMTYPE_CROWN_ITEM] = {
		"This consumable can be used only",
		"This item has no cooldown.",
		"Created by a",
	},
	[ITEMTYPE_FURNISHING] = {
		"This is a .+ house item.",
	},
}

local function GenerateItemFlavorTextList()
	EQUIP_FLAVOR_VARS.itemNameList = {}

	EQUIP_FLAVOR_VARS.items = {}
	for i=1,200000 do
		local link = "|H1:item:"..i..":364:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:10000:0|h|h"
		local itemType = GetItemLinkItemType(link)

		if itemTypes[itemType] then
			local fTxt = GetItemLinkFlavorText(link)

			local skipStringFound
			if itemConds[itemType] then
				for _, str in pairs(itemConds[itemType]) do
					if fTxt:find(str) then
						skipStringFound = true
					end
				end
			end

			if (fTxt ~= "" and (not skipStringFound)) or itemType == ITEMTYPE_DISGUISE then
				local itemId = GetItemLinkItemId(link)
				local iconFile = GetItemLinkIcon(link)
				local itemName = GetItemLinkName(link)

				EQUIP_FLAVOR_VARS.items[itemType] = EQUIP_FLAVOR_VARS.items[itemType] or {}

				if not (EQUIP_FLAVOR_VARS.itemNameList[itemName] and EQUIP_FLAVOR_VARS.itemNameList[itemName] == fTxt) then
					local numEntries = #EQUIP_FLAVOR_VARS.items[itemType] + 1
					EQUIP_FLAVOR_VARS.items[itemType][numEntries] = {itemType = itemType, iconFile = iconFile, itemId = itemId, link = link}
					EQUIP_FLAVOR_VARS.itemNameList[itemName] = fTxt
				end
			end
		end

		local itemId = i
		local qlink = "|H1:quest_item:"..i.."|h|h"
		local iconFile = GetQuestItemIcon(itemId)
		local fTxt = GetQuestItemTooltipText(itemId)
		local itemName = GetQuestItemNameFromLink(qlink)

		EQUIP_FLAVOR_VARS.items[EFT_ITYPE_QUEST_ITEM] = EQUIP_FLAVOR_VARS.items[EFT_ITYPE_QUEST_ITEM] or {}

		if not (EQUIP_FLAVOR_VARS.itemNameList[itemName] and EQUIP_FLAVOR_VARS.itemNameList[itemName] == fTxt) then			
			if fTxt ~= "" then
				local numEntries = #EQUIP_FLAVOR_VARS.items[EFT_ITYPE_QUEST_ITEM] + 1
				EQUIP_FLAVOR_VARS.items[EFT_ITYPE_QUEST_ITEM][numEntries] = {
					itemType = EFT_ITYPE_QUEST_ITEM,
					iconFile = iconFile,
					itemId = itemId,
					link = qlink,
				}

				EQUIP_FLAVOR_VARS.itemNameList[itemName] = fTxt
			end
		end

	end

	EQUIP_FLAVOR_VARS.itemNameList = {}
end
SLASH_COMMANDS["/genitems"] = GenerateItemFlavorTextList