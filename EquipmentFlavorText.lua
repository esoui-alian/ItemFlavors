EFT = {addOnName = "EquipmentFlavorText"}

-----
--Build Dropdown List
-----

local function BuildItemList(questItem, searchText, comboBox, descCtrl, iconCtrl, titleCtrl)
	local desc = descCtrl
	local icon = iconCtrl
	local title = titleCtrl

    local function OnSelectionChanged(comboBox, entryText, entry)
		local entryData = entry.data
		local descText = entryData.desc
		local iconFile = entryData.icon

		title:SetText(entryData.link)
		desc:SetText(descText)
		icon:SetTexture(iconFile)
    end

	local defaultEntry = nil
    local trackedEntry = nil
    
    comboBox:ClearItems()

	local itemTable
	if not questItem then
		itemTable = EQUIP_FLAVOR_VARS.itemFlavor
	else
		itemTable = EQUIP_FLAVOR_VARS.questItemFlavor
	end

    for itemId, itemData in pairs(itemTable) do
		local itemLink = itemData.link

		local iconFile = questItem and GetQuestItemIcon(itemId) or GetItemLinkIcon(itemLink)
		local descText = questItem and GetQuestItemTooltipText(itemId) or GetItemLinkFlavorText(itemLink)
		local itemName = questItem and GetQuestItemNameFromLink(itemLink) or GetItemLinkName(itemLink)
		local name = zo_strformat("[<<1>>]", itemName)

		local searchText = searchText and searchText:upper()
		if (not searchText) or (searchText and (name:upper():find(searchText) or descText:upper():find(searchText))) then
			local entry = ZO_ComboBox:CreateItemEntry(name, OnSelectionChanged)
			entry.data =
			{
				itemId	= itemData.itemId,
				link	= itemData.link,
				fTxt	= itemData.fTxt,
				icon	= iconFile,
				desc	= descText,
			}

			trackedEntry = entry
			comboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
		end
    end

	comboBox:UpdateItems()

    local IGNORE_CALLBACK = false
    local selectedEntry = trackedEntry or defaultEntry
    if selectedEntry then
        comboBox:SelectItem(selectedEntry, IGNORE_CALLBACK)
    else
        comboBox:SelectFirstItem()
    end
end

-----
--Initialize Dropdown
-----

local function InitializeItemDropdown()
	local control = GetControl("EFT_TopLevelBGItemDropdown")
	local itemComboBox = ZO_ComboBox_ObjectFromContainer(control)
	local itemContainer = GetControl("EFT_TopLevelBGItemInfoContainer")
	
	local icon = itemContainer:GetNamedChild("Icon")
    local title = itemContainer:GetNamedChild("Title")
	local desc = itemContainer:GetNamedChild("Description")


	itemComboBox:SetSortsItems(true)
    itemComboBox:SetFont("ZoFontWinT1")
    itemComboBox:SetSpacing(4)
    itemComboBox:SetHeight(350)
    EFT.itemComboBox = itemComboBox
	EFT.itemContainer = itemContainer

	EFT.itemDesc = desc
	EFT.itemIcon = icon
	EFT.itemTitle = title

    BuildItemList(false, _, itemComboBox, desc, icon, title)
end

local function InitializeQuestItemDropdown()
	local control = GetControl("EFT_TopLevelBGQuestItemDropdown")
	local questItemComboBox = ZO_ComboBox_ObjectFromContainer(control)
	local questItemContainer = GetControl("EFT_TopLevelBGQuestItemInfoContainer")
	
	local icon = questItemContainer:GetNamedChild("Icon")
    local title = questItemContainer:GetNamedChild("Title")
	local desc = questItemContainer:GetNamedChild("Description")


	questItemComboBox:SetSortsItems(true)
    questItemComboBox:SetFont("ZoFontWinT1")
    questItemComboBox:SetSpacing(4)
    questItemComboBox:SetHeight(350)
    EFT.questItemComboBox = questItemComboBox
	EFT.questItemContainer = questItemContainer

	EFT.questItemDesc = desc
	EFT.questItemIcon = icon
	EFT.questItemTitle = title

    BuildItemList(true, _, questItemComboBox, desc, icon, title)
end

-----
--XML
-----

function EquipmentFlavorText_TLC_OnInitialized(control)
	EFT.topLevel = control
end

function EquipmentFlavorText_TLC_OnShow(control)
	--Stub
end

function EquipmentFlavorText_OnItemSearchTextChanged(control)
	BuildItemList(false, control:GetText(), EFT.itemComboBox, EFT.itemDesc, EFT.itemIcon, EFT.itemTitle)
end

function EquipmentFlavorText_OnQuestItemSearchTextChanged(control)
	BuildItemList(true, control:GetText(), EFT.questItemComboBox, EFT.questItemDesc, EFT.questItemIcon, EFT.questItemTitle)
end

function EquipmentFlavorText_OnItemLinkMouseUp(control, _, link, button)
	if not link then
		link = control:GetText()
	end

	ZO_LinkHandler_OnLinkMouseUp(link, button, control)
end

-----
-- Build Initial List
-----

local function GenerateItemFlavorTextList(count)
	EQUIP_FLAVOR_VARS.itemFlavor = {}
	EQUIP_FLAVOR_VARS.questItemFlavor = {}
	EQUIP_FLAVOR_VARS.itemNameList = {}

	local count = tonumber(count)

	local validItemTypes = {
		[ITEMTYPE_ARMOR]			= "Armor",
		[ITEMTYPE_WEAPON]			= "Weapons",
	}

	for i=1,200000 do 
		if not EQUIP_FLAVOR_VARS.itemFlavor[i] then
			local link = "|H1:item:"..i..":364:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:10000:0|h|h" 
			local fTxt = GetItemLinkFlavorText(link) 
			local itemId = GetItemLinkItemId(link)

			local itemName = GetItemLinkName(link)

			if not (EQUIP_FLAVOR_VARS.itemNameList[itemName] and EQUIP_FLAVOR_VARS.itemNameList[itemName] == fTxt) then	
				if fTxt ~= "" and GetItemLinkFunctionalQuality(link) >= ITEM_FUNCTIONAL_QUALITY_LEGENDARY then
					local itemType = GetItemLinkItemType(link)			

					if validItemTypes[itemType] then
						EQUIP_FLAVOR_VARS.itemFlavor[i] = {itemId = itemId, link = link, fTxt = fTxt}
						EQUIP_FLAVOR_VARS.itemNameList[itemName] = fTxt
					end
				end
			end
		end
		
		if not EQUIP_FLAVOR_VARS.questItemFlavor[i] then
			local itemId = i
			local link = "|H1:quest_item:"..i.."|h|h" 
			local fTxt = GetQuestItemTooltipText(itemId) 

			local itemName = GetQuestItemNameFromLink(link)

			if not (EQUIP_FLAVOR_VARS.itemNameList[itemName] and EQUIP_FLAVOR_VARS.itemNameList[itemName] == fTxt) then			
				if fTxt ~= "" then
					EQUIP_FLAVOR_VARS.questItemFlavor[i] = {itemId = itemId, link = link, fTxt = fTxt}
					EQUIP_FLAVOR_VARS.itemNameList[itemName] = fTxt
				end
			end
		end
	end

	EQUIP_FLAVOR_VARS.itemNameList = {}
end
SLASH_COMMANDS["/itemflavor"] = GenerateItemFlavorTextList

-----
--OnLoad
-----

local function OnLoad(e, addOnName)
	if addOnName ~= EFT.addOnName then return end

	EQUIP_FLAVOR_VARS = ZO_SavedVars:NewAccountWide("EquipmentFlavorText", 0.1, nil, {})

	if (not EQUIP_FLAVOR_VARS.questItemFlavor) or (not EQUIP_FLAVOR_VARS.itemFlavor) then
		GenerateItemFlavorTextList()
	end

	-- Populate Dropdown
	InitializeItemDropdown()
	InitializeQuestItemDropdown()

	EVENT_MANAGER:UnregisterForEvent(EFT.addOnName, EVENT_ADD_ON_LOADED) 
end
EVENT_MANAGER:RegisterForEvent(EFT.addOnName, EVENT_ADD_ON_LOADED, OnLoad) 

-----
--Open/Close
-----

local function ToggleInterface()
	local isHidden = EFT.topLevel:IsHidden()
	EFT.topLevel:SetHidden(not isHidden)
end
SLASH_COMMANDS["/equipflavor"] = ToggleInterface