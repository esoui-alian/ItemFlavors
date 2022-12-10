local EFT = {addOnName = "EquipmentFlavorText"}
local addOnName = "EquipmentFlavorText"

local itemCollections = EFTDATA.items
local CATEGORIES= "categories"

local itemTypeData = {
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

-----
--OnSelectionChanged
-----
local function OnItemChanged(comboBox, entryText, entry)
	local entryData = entry.data
	local descText = entryData.desc
	local iconFile = entryData.icon

	local infoCtrls = EFT[CATEGORIES]

	if infoCtrls then
		infoCtrls.itemTitle:SetText(entryData.link)
		infoCtrls.itemDesc:SetText(descText)
		infoCtrls.itemIcon:SetTexture(iconFile)
	end
end

-----
--Build Dropdown List
-----

local function BuildCatList(comboBox)
	local defaultEntry = nil
	local trackedEntry = nil

	local lastEntryText = ""
	local function OnCategoryChanged(comboBox, entryText, entry)
		if (not lastEntryData) or lastEntryData == nil then
			lastEntryData = comboBox:GetSelectedItemData()
		end

		local entryData = entry.data
		local entryIType = entryData.itemType
		local entryCtrl = GetControl("EFT_BGItem"..entryIType)
		
		local itemSelectedData = EFT[entryIType].comboBox:GetSelectedItemData()
		if not itemSelectedData then
			entryData.comboBox:SelectFirstItem()
			itemSelectedData = EFT[entryIType].comboBox:GetSelectedItemData()
		end

		OnItemChanged(entryData.comboBox, _, itemSelectedData)

		local lastData = lastEntryData.data
		local lastIType = lastData.itemType
		local lastCtrl = GetControl("EFT_BGItem"..lastIType)

		lastCtrl:SetHidden(true)
		entryCtrl:SetHidden(false)

		lastEntryData = comboBox:GetSelectedItemData()
	end

	comboBox:ClearItems()

	for iType, name in pairs(itemTypeData) do
		local name = zo_strformat("<<1>>", name)
		local comboBox = EFT[CATEGORIES].comboBox

		local entry = ZO_ComboBox:CreateItemEntry(name, OnCategoryChanged)
		entry.data =
		{
			constName	= iType,
			itemType	= iType,
			comboBox	= comboBox,
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

local tostring = tostring

local maxCount = {}
local function BuildItemList(itemType, searchText, comboBox, descCtrl, iconCtrl, titleCtrl)
	local defaultEntry = nil
	local trackedEntry = nil
	
	comboBox:ClearItems()

	local function CreateEntries(itemId, itemData, name, itemType, descText, iconFile, comboBox)
		local entry = ZO_ComboBox:CreateItemEntry(name, OnItemChanged)
		entry.data =
		{
			itemId	= itemData.itemId,
			link	= itemData.link,
			desc	= descText,
			iType	= itemType,
			icon	= iconFile,
		}

		comboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
	end

	-- Put icon in ItemData.lua extract (leave and fTxt so it's localized, or generate in different languages?)

	local searchText = (searchText and searchText ~= "") and tostring(searchText):upper()

	local entryCount = 0

	maxCount[itemType] = maxCount[itemType] or {num = 0, ini = false}
	local maxCountNotDone = (not searchText) and (not maxCount[itemType].ini)

	for itemIndex, itemData in ipairs(itemCollections[itemType]) do
		local itemId = itemData.itemId
		local itemLink = itemData.link
		local iconFile = itemData.iconFile

		local name = itemData.name[1]
		local nameUpper = itemData.name[2]

		local descText = itemData.fTxt[1]
		local descTextUpper = itemData.fTxt[2]
		
		if (not searchText) or (searchText and (nameUpper:find(searchText) or descTextUpper:find(searchText))) then
			if maxCountNotDone then
				maxCount[itemType].num = maxCount[itemType].num + 1
			else entryCount = entryCount + 1 end

			CreateEntries(itemId, itemData, name, itemType, descText, iconFile, comboBox)

			if entryCount >= maxCount[itemType].num then break end --or entryCount >= 500
		end
	end

	if not maxCount[itemType].ini then maxCount[itemType].ini = true end

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
		icon	= containCtrl:GetNamedChild("Icon")
		title	= containCtrl:GetNamedChild("Title")
		desc	= containCtrl:GetNamedChild("Description")

		EFT[CATEGORIES].itemDesc = desc
		EFT[CATEGORIES].itemIcon = icon
		EFT[CATEGORIES].itemTitle = title
		EFT[CATEGORIES].itemContainer = containCtrl
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

function EquipmentFlavorText_OnItemLinkMouseUp(control, _, link, button)
	if not link then
		link = control:GetText()
	end

	ZO_LinkHandler_OnLinkMouseUp(link, button, control)
end

-----
--OnLoad
-----

local function OnLoad(e, addonName)
	if addonName ~= addOnName then return end

	EQUIP_FLAVOR_VARS = ZO_SavedVars:NewAccountWide("EquipmentFlavorText", 0.1, nil, {})

	-- Get Localized Name / Flavor Text
	for iType, collection in pairs(itemCollections) do
		for index, itemData in ipairs(collection) do
			local link = itemData.link
			local itemId = itemData.itemId

			local itemName = iType == EFT_ITYPE_QUEST_ITEM and GetQuestItemNameFromLink(link) or GetItemLinkName(link)
			local itemNameUpper = itemName:upper()

			local fTxt = iType == EFT_ITYPE_QUEST_ITEM and GetQuestItemTooltipText(itemId) or GetItemLinkFlavorText(link)
			local fTxtUpper = fTxt:upper()

			itemCollections[iType][index].name = {zo_strformat("[<<t:1>>]", itemName), itemNameUpper}
			itemCollections[iType][index].fTxt = {fTxt, fTxtUpper}
		end
	end

	-- Populate Dropdowns --

	-- Item Types
	EFT.iControls = {}
	for iType, _ in pairs(itemTypeData) do
		EFT.iControls[iType] = CreateControlFromVirtual("EFT_BGItem", EFT_TopLevel, "EFT_BGItem", iType)
		local dropdown = EFT.iControls[iType]:GetNamedChild("Dropdown")
		local search = EFT.iControls[iType]:GetNamedChild("SearchBGSearch")
		search:SetHandler("OnTextChanged", function(control)
			local buildCtrls = EFT[iType]
			BuildItemList(iType, control:GetText(), buildCtrls.comboBox, buildCtrls.itemDesc, buildCtrls.itemIcon, buildCtrls.itemTitle)
		end, addonName)

		InitializeDropdown(iType, dropdown, nil, iType)
	end

	-- Categories
	local buildCategories = true
	local containCtrl = GetControl("EFT_TopLevelInfoContainer")
	local catDropdown = GetControl("EFT_TopLevelBGCategoriesCategoriesDropdown")
	InitializeDropdown(_, catDropdown, containCtrl, CATEGORIES, buildCategories)

	EVENT_MANAGER:UnregisterForEvent(addOnName, EVENT_ADD_ON_LOADED) 
end
EVENT_MANAGER:RegisterForEvent(addOnName, EVENT_ADD_ON_LOADED, OnLoad) 

-----
--Open/Close
-----

function ToggleEFTInterface()
	local isHidden = EFT.topLevel:IsHidden()
	EFT.topLevel:SetHidden(not isHidden)
end
SLASH_COMMANDS["/equipflavor"] = ToggleEFTInterface