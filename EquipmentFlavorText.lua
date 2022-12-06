local EFT = {addOnName = "EquipmentFlavorText"}

local CATEGORIES= "categories"
local DISGUISE	= "disguise"
local EQUIPMENT	= "equip"
local QUESTITEM	= "quest"

-----
--OnSelectionChanged
-----
local function OnItemChanged(comboBox, entryText, entry)
	local entryData = entry.data
	local descText = entryData.desc
	local iconFile = entryData.icon

	local equipCtrls = EFT[EQUIPMENT]
	
	equipCtrls.itemTitle:SetText(entryData.link)
	equipCtrls.itemDesc:SetText(descText)
	equipCtrls.itemIcon:SetTexture(iconFile)
end

-----
--Build Dropdown List
-----

local function BuildCatList(comboBox)
	local defaultEntry = nil
	local trackedEntry = nil

	local itemTypeCtrls = {
		[GetString(SI_ARMORY_EQUIPMENT_LABEL)]	= {ctrl = GetControl("EFT_TopLevelBGItem"), comboBox = EFT[EQUIPMENT].comboBox},
		[GetString(SI_INVENTORY_MODE_QUEST_ITEMS)]	={ctrl = GetControl("EFT_TopLevelBGQuestItem"), comboBox = EFT[QUESTITEM].comboBox},
		[GetString(SI_ITEMTYPE13)]	= {ctrl = GetControl("EFT_TopLevelBGDisguiseItem"), comboBox = EFT[DISGUISE].comboBox},
	}

	local lastEntryText = ""
	local function OnCategoryChanged(comboBox, entryText, entry)
		if (not lastEntryText) or lastEntryText == "" then
			lastEntryText = comboBox:GetSelectedItem()
		end

		local entryData = entry.data
		
		local itemSelectedData = entryData.comboBox:GetSelectedItemData()
		if not itemSelectedData then
			entryData.comboBox:SelectFirstItem()
			itemSelectedData = entryData.comboBox:GetSelectedItemData()
		end

		OnItemChanged(entryData.comboBox, _, itemSelectedData)

		itemTypeCtrls[lastEntryText].ctrl:SetHidden(true)	
		itemTypeCtrls[entryText].ctrl:SetHidden(false)

		lastEntryText = entryText
	end

	comboBox:ClearItems()

	for constName, constData in pairs(itemTypeCtrls) do
		local iconFile = ""
		local name = zo_strformat("<<1>>", constName)

		local entry = ZO_ComboBox:CreateItemEntry(name, OnCategoryChanged)
		entry.data =
		{
			constName = constName,
			iconFile = iconFile,
			comboBox = constData.comboBox,
		}

		--trackedEntry = entry
		comboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
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

local function BuildItemList(itemType, searchText, comboBox, descCtrl, iconCtrl, titleCtrl)
	local defaultEntry = nil
	local trackedEntry = nil
	
	comboBox:ClearItems()

	local itemTable = {
		[EQUIPMENT]	= EQUIP_FLAVOR_VARS.itemFlavor,
		[QUESTITEM]	= EQUIP_FLAVOR_VARS.questItemFlavor,
		[DISGUISE]	= EQUIP_FLAVOR_VARS.disguiseItemFlavor,
	}

	for itemId, itemData in pairs(itemTable[itemType]) do
		local itemLink = itemData.link

		local iconFile = itemType == QUESTITEM and GetQuestItemIcon(itemId) or GetItemLinkIcon(itemLink)
		local descText = itemType == QUESTITEM and GetQuestItemTooltipText(itemId) or GetItemLinkFlavorText(itemLink)
		local itemName = itemType == QUESTITEM and GetQuestItemNameFromLink(itemLink) or GetItemLinkName(itemLink)
		local name = zo_strformat("[<<1>>]", itemName)

		local searchText = searchText and tostring(searchText):upper()
		if (not searchText) or (searchText and (name:upper():find(searchText) or descText:upper():find(searchText))) then
			local entry = ZO_ComboBox:CreateItemEntry(name, OnItemChanged)
			entry.data =
			{
				itemId	= itemData.itemId,
				link	= itemData.link,
				fTxt	= itemData.fTxt,
				icon	= iconFile,
				desc	= descText,
			}

			--trackedEntry = entry
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

local function InitializeDropdown(itemType, control, containCtrl, suffix, buildCategories)

	local comboBox = ZO_ComboBox_ObjectFromContainer(control)
	
	EFT[suffix] = {}

	local itemContainer, icon, title, desc
	if containCtrl then
		itemContainer = containCtrl
		icon = itemContainer:GetNamedChild("Icon")
		title = itemContainer:GetNamedChild("Title")
		desc = itemContainer:GetNamedChild("Description")

		EFT[suffix].itemDesc = desc
		EFT[suffix].itemIcon = icon
		EFT[suffix].itemTitle = title
		EFT[suffix].itemContainer = itemContainer
	end

	comboBox:SetSortsItems(true)
	comboBox:SetFont("ZoFontWinT1")
	comboBox:SetSpacing(4)
	comboBox:SetHeight(350)

	EFT[suffix].comboBox = comboBox

	if not buildCategories then
		BuildItemList(itemType, "", comboBox, desc, icon, title)
	else BuildCatList(comboBox) end
end

-----
--XML
-----

function EquipmentFlavorText_TLC_OnInitialized(control)
	EFT.topLevel = control
end

function EquipmentFlavorText_OnEquipItemSearchTextChanged(control)
	local equipCtrls = EFT[EQUIPMENT]
	BuildItemList(EQUIPMENT, control:GetText(), equipCtrls.comboBox, equipCtrls.itemDesc, equipCtrls.itemIcon, equipCtrls.itemTitle)
end

function EquipmentFlavorText_OnQuestItemSearchTextChanged(control)
	local questCtrls = EFT[QUESTITEM]
	BuildItemList(QUESTITEM, control:GetText(), questCtrls.comboBox, questCtrls.itemDesc, questCtrls.itemIcon, questCtrls.itemTitle)
end

function EquipmentFlavorText_OnDisguiseItemSearchTextChanged(control)
	local disguiseCtrls = EFT[DISGUISE]
	BuildItemList(DISGUISE, control:GetText(), disguiseCtrls.comboBox, disguiseCtrls.itemDesc, disguiseCtrls.itemIcon, disguiseCtrls.itemTitle)
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
	EQUIP_FLAVOR_VARS.disguiseItemFlavor = {}
	EQUIP_FLAVOR_VARS.itemNameList = {}

	local count = tonumber(count)

	local validEquipTypes = {
		[ITEMTYPE_ARMOR]		= "Armor",
		[ITEMTYPE_WEAPON]		= "Weapons",
	}

	for i=1,200000 do 
		if not EQUIP_FLAVOR_VARS.itemFlavor[i] then
			local link = "|H1:item:"..i..":364:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:10000:0|h|h" 
			local fTxt = GetItemLinkFlavorText(link) 
			local itemId = GetItemLinkItemId(link)

			local itemName = GetItemLinkName(link)
			local itemType = GetItemLinkItemType(link)		

			if validEquipTypes[itemType] then
				if not (EQUIP_FLAVOR_VARS.itemNameList[itemName] and EQUIP_FLAVOR_VARS.itemNameList[itemName] == fTxt) then	
					if fTxt ~= "" and GetItemLinkFunctionalQuality(link) >= ITEM_FUNCTIONAL_QUALITY_LEGENDARY then	
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

		if not EQUIP_FLAVOR_VARS.disguiseItemFlavor[i] then
			local link = "|H1:item:"..i..":1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0|h|h" 
			local fTxt = GetItemLinkFlavorText(link) 
			local itemId = GetItemLinkItemId(link)

			local itemName = GetItemLinkName(link)
			local itemType = GetItemLinkItemType(link)	

			--Check these aren't null
			if itemType == ITEMTYPE_DISGUISE then
				if not (EQUIP_FLAVOR_VARS.itemNameList[itemName] and EQUIP_FLAVOR_VARS.itemNameList[itemName] == fTxt) then	
					if fTxt ~= "" then
						EQUIP_FLAVOR_VARS.disguiseItemFlavor[i] = {itemId = itemId, link = link, fTxt = fTxt}
						EQUIP_FLAVOR_VARS.itemNameList[itemName] = fTxt
					end
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

	local lastAPIUpdate = EQUIP_FLAVOR_VARS.lastAPIUpdate
	if lastAPIUpdate ~= GetAPIVersion() then
		GenerateItemFlavorTextList()
		lastAPIUpdate = GetAPIVersion()
	end

	-- Populate Dropdown
	local containCtrl = GetControl("EFT_TopLevelInfoContainer")

	local control	= GetControl("EFT_TopLevelBGItemDropdown")
	local qControl	= GetControl("EFT_TopLevelBGQuestItemDropdown")
	local cControl	= GetControl("EFT_TopLevelBGDisguiseItemDropdown")

	local catCtrl = GetControl("EFT_TopLevelBGCategoriesCategoriesDropdown")

	-- Item Dropdowns
	InitializeDropdown(EQUIPMENT, control, containCtrl, EQUIPMENT)
	InitializeDropdown(QUESTITEM, qControl, containCtrl, QUESTITEM)
	InitializeDropdown(DISGUISE, cControl, containCtrl, DISGUISE)

	-- Categories
	local buildCategories = true
	InitializeDropdown(_, catCtrl, _, CATEGORIES, buildCategories)

	EVENT_MANAGER:UnregisterForEvent(EFT.addOnName, EVENT_ADD_ON_LOADED) 
end
EVENT_MANAGER:RegisterForEvent(EFT.addOnName, EVENT_ADD_ON_LOADED, OnLoad) 

-----
--Open/Close
-----

function ToggleEFTInterface()
	local isHidden = EFT.topLevel:IsHidden()
	EFT.topLevel:SetHidden(not isHidden)
end
SLASH_COMMANDS["/equipflavor"] = ToggleEFTInterface