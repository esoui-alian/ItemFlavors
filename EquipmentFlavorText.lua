local EquipFlavorText = {addOnName = "EquipmentFlavorText"}

-----
-- Item Flavor Text
-----

local function GenerateItemFlavorTextList(count)
	EQUIP_FLAVOR_VARS.itemFlavor = {}

	local count = tonumber(count)

	local validItemTypes = {
		[ITEMTYPE_ARMOR]			= "Armor",
		[ITEMTYPE_WEAPON]			= "Weapons",
	}

	for i=1, 2000 do 
		if not EQUIP_FLAVOR_VARS.itemFlavor[i] then
			local link = "|H1:item:"..i..":364:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:10000:0|h|h" 
			local fTxt = GetItemLinkFlavorText(link) 
			local itemId = GetItemLinkItemId(link)

			if fTxt ~= "" then
				local itemType = GetItemLinkItemType(link)			

				if validItemTypes[itemType] then
					EQUIP_FLAVOR_VARS.itemFlavor[i] = {itemId = itemId, link = link, fTxt = fTxt}
				end
			end
		end
	end
end
SLASH_COMMANDS["/itemflavor"] = GenerateItemFlavorTextList

local function OnLoad(e, addOnName)
	if addOnName ~= EquipFlavorText.addOnName then return end

	EQUIP_FLAVOR_VARS = ZO_SavedVars:NewAccountWide("AlianymDevTools", 0.1, nil, DefaultValues)

	EVENT_MANAGER:UnregisterForEvent(EquipFlavorText.addOnName, EVENT_ADD_ON_LOADED) 
end
EVENT_MANAGER:RegisterForEvent(EquipFlavorText.addOnName, EVENT_ADD_ON_LOADED, OnLoad) 