-- Created by Armir, Area 52, Ascension
-- Influenced by Outfitter by Rhenyra.

local IS_DEV = false
local addonColor = "FF40A6FF"
local AddonFolder = ...
-- SpecializationOutfitterPublicDB
-- SpecializationOutfitterPrivateDB

local mainFrame = nil
local specFrames = {}
local Database = {}
local Database_BySpellName = {}
local Database_Length = 0
local OutfitNameTrim_MaxLen = 15
local OutfitNameTrim_MaxWidth = 117

local function DevPrint(msg)
    if IS_DEV or (SpecializationOutfitterPublicDB and SpecializationOutfitterPublicDB.IsDev) then
        print("|c" .. addonColor .. "SO|r " .. tostring(msg))
    end
end

local Database_OLD_Unused_Just_For_Reference = {
    [979993] = {ID = 979993, SpellName = "Specialization I"},
    [979994] = {ID = 979994, SpellName = "Specialization II"},
    [979995] = {ID = 979995, SpellName = "Specialization III"},
    [979996] = {ID = 979996, SpellName = "Specialization IV"},
    [979997] = {ID = 979997, SpellName = "Specialization V"},
    [979986] = {ID = 979986, SpellName = "Specialization VI"},
    [979987] = {ID = 979987, SpellName = "Specialization VII"},
    [979988] = {ID = 979988, SpellName = "Specialization VIII"},
    [84874] = {ID = 84874, SpellName = "Specialization IX"},
    [84876] = {ID = 84876, SpellName = "Specialization X"},
    [84878] = {ID = 84878, SpellName = "Specialization XI"},
    [84880] = {ID = 84880, SpellName = "Specialization XII"},
    [84882] = {ID = 84882, SpellName = "Specialization XIII"},
    [84884] = {ID = 84884, SpellName = "Specialization XIV"},
    [84886] = {ID = 84886, SpellName = "Specialization XV"},
    [84888] = {ID = 84888, SpellName = "Specialization XVI"},
    [84890] = {ID = 84890, SpellName = "Specialization XVII"},
    [84892] = {ID = 84892, SpellName = "Specialization XVIII"},
    [84894] = {ID = 84894, SpellName = "Specialization XIX"},
    [84896] = {ID = 84896, SpellName = "Specialization XX"}
}

function LoadData()
	if not SpecializationOutfitterPublicDB then
		SpecializationOutfitterPublicDB = {}
		SpecializationOutfitterPublicDB.IsDev = false
	end
	if not SpecializationOutfitterPrivateDB then
		SpecializationOutfitterPrivateDB = {}
		SpecializationOutfitterPrivateDB.OutfitChoice = {}
	end
	
	local knownOutfitsLookup = {}
	for _, outfitName in ipairs(GetKnownOutfits()) do knownOutfitsLookup[outfitName] = true end
	
	Database = {}
	Database_BySpellName = {}
	Database_Length = 0
	
	for SpecIndex=1,9999 do
		local SpecSpellId = SpecializationUtil.GetSpecializationSpell(SpecIndex)
		DevPrint("Spec "..tostring(SpecIndex)..": "..tostring(SpecSpellId))
		if not SpecSpellId then break end
		
		local specName, specIcon = SpecializationUtil.GetSpecializationInfo(SpecIndex)
		local spellName = GetSpellInfo(SpecSpellId)
		local chosenOutfit = SpecializationOutfitterPrivateDB.OutfitChoice[SpecSpellId] or ""

		local entry = {}
		entry.Index = SpecIndex
		entry.SpellId = SpecSpellId
		entry.SpellName = spellName
		entry.Known = IsSpellKnown(SpecSpellId)
		entry.SpecName = specName
		entry.SpecIcon = specIcon
		entry.ChosenOutfit = chosenOutfit
		entry.ChosenOutfitExists = (chosenOutfit == "") or (knownOutfitsLookup[chosenOutfit] == true)

		Database[SpecSpellId] = entry
		Database_BySpellName[spellName] = entry
		Database_Length = Database_Length + 1
	end
end


local OutfitNameTrim_TextMeasurer = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local OutfitNameTrim_Register = {}
function OutfitNameTrim(outfitName)
	if not outfitName then return "" end
	if OutfitNameTrim_Register[outfitName] then return OutfitNameTrim_Register[outfitName] end -- Cached result

	OutfitNameTrim_TextMeasurer:SetText(outfitName)

	-- Fits already
	if OutfitNameTrim_TextMeasurer:GetStringWidth() <= OutfitNameTrim_MaxWidth then
		OutfitNameTrim_Register[outfitName] = outfitName
		return outfitName
	end

	local trimmed = outfitName
	
	local while_max_attempts = 9999
	while string.len(trimmed) > 0 do
		trimmed = string.sub(trimmed, 1, -2)

		local testText = trimmed .. "..."
		OutfitNameTrim_TextMeasurer:SetText(testText)

		if OutfitNameTrim_TextMeasurer:GetStringWidth() <= OutfitNameTrim_MaxWidth then
			OutfitNameTrim_Register[outfitName] = testText
			return testText
		end
		
		if while_max_attempts < 0 then break end
		while_max_attempts = while_max_attempts - 1
	end

	OutfitNameTrim_Register[outfitName] = "..."
	return "..."
end







function GetKnownOutfits()
    -- 1. Get the Outfit Category ID
    local categoryIDs = C_AppearanceCollection.GetCategoriesForType("APPEARANCE_TYPE_OUTFIT")
    local categoryID = categoryIDs and categoryIDs[1]
    
    if not categoryID then 
        return {} 
    end

    -- 2. Switch context to Outfits
    C_AppearanceCollection.ApplyCategoryFilter(categoryID, "", {}, {})

    local maxPages = C_AppearanceCollection.GetCategoryMaxPages()
    local outfits = {}

    -- 3. Iterate all pages
    for page = 1, maxPages do
        local pageItems = C_AppearanceCollection.GetCategoryAppearances(page)
        if pageItems then
            for _, name in ipairs(pageItems) do
                -- Filter out the "New Outfit" button placeholder if present
                if name ~= "New Outfit" then
                    table.insert(outfits, name)
                end
            end
        end
    end
    
    -- 4. Sort alphabetically (A-Z)
    table.sort(outfits)
    
    return outfits
end

function ApplyOutfitByName(outfitEntry)
	local OutfitName = outfitEntry.ChosenOutfit
    DevPrint("ApplyOutfitByName " .. tostring(OutfitName))

    if not OutfitName or OutfitName == "" then
        DevPrint("Error: OutfitName is empty.")
        return
    end

    local knownOutfits = GetKnownOutfits()
    local found = false
    
    for _, name in ipairs(knownOutfits) do
        if name == OutfitName then
            found = true
            break
        end
    end

	if not found then
		-- DevPrint("Error: Outfit '" .. OutfitName .. "' not found in known outfits.")

		print("|cFFFF0000Specialization Outfit Error:|r |cFFFFFFFF" .. tostring("Outfit not found") .. "|r")
		print("|cFFFF0000Missing outfit name:|r |cFFFFFFFF" .. tostring(OutfitName) .. "|r")
		print("|cFFFF0000Specialization:|r |cFFFFFFFF" .. tostring(outfitEntry.SpellName) .. "|r")
		print("|cFFFF0000Type|r |cFFFFFFFF" .. tostring("/specfit") .. "|r|cFFFF0000 to set proper outfit.|r")

		return
	end

	-- 1. Stage the outfit as pending
	C_AppearanceOutfit.SetPendingOutfit(OutfitName)
	-- 2. Check if valid
	local canApply, reason = C_Appearance.CanApplyPendingAppearances()
	if canApply then
		-- 3. Commit the changes
		-- The 'false' argument matches the specific call used by the Apply button in the UI
		C_Appearance.ApplyPendingAppearances(false)
		DevPrint("Successfully applied outfit: " .. OutfitName)
	else
		DevPrint("Could not apply outfit. Reason: " .. tostring(reason))

		print("|cFFFF0000Specialization Outfit Error:|r |cFFFFFFFF" .. tostring("wardrobe error") .. "|r")
		print("|cFFFF0000Reason:|r |cFFFFFFFF" .. tostring(reason) .. "|r")
	end
end



function SpellCastFinished(unit, SpellName, spellRank, spellInterruptable)
	if unit ~= "player" or not SpellName then return end
	
	local outfitEntry = Database_BySpellName[SpellName]
	if not outfitEntry then return end
	
	DevPrint("Cast "..tostring(SpellName)..", "..tostring(spellRank)..", "..tostring(spellInterruptable)..", "..tostring(unit))
	ApplyOutfitByName(outfitEntry)
end



function CreateSpecFrame(parent, index)
	local frame = CreateFrame("Frame", "SpecFrame"..index, parent)
	frame:SetSize(400, 40)
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -30 - ((index-1) * 45))
	
	-- Icon
	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	frame.icon:SetSize(32, 32)
	frame.icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
	
	-- Spec Name
	frame.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.name:SetPoint("LEFT", frame.icon, "RIGHT", 10, 0)
	frame.name:SetJustifyH("LEFT")
	frame.name:SetWidth(150)
	frame.name:SetTextColor(1, 1, 1) -- White text
	
	-- Dropdown for Outfits
	frame.dropdown = CreateFrame("Frame", "SpecDropdown"..index, frame, "UIDropDownMenuTemplate")
	frame.dropdown:SetPoint("LEFT", frame.name, "RIGHT", 20, 0)
	frame.dropdown.initialize = function(self, level)
		local outfits = GetKnownOutfits()
		local info = UIDropDownMenu_CreateInfo()
		
		-- Add "No Outfit" option
		info.text = "No Outfit"
		info.value = ""
		info.checked = (frame.chosenOutfit == "")
		info.func = function(self)
			frame.chosenOutfit = self.value
			UIDropDownMenu_SetText(frame.dropdown, "No Outfit")
			
			-- Save to database
			if frame.specSpellId then
				SpecializationOutfitterPrivateDB.OutfitChoice[frame.specSpellId] = frame.chosenOutfit
				if Database[frame.specSpellId] then
					Database[frame.specSpellId].ChosenOutfit = frame.chosenOutfit
				end
			end
		end
		UIDropDownMenu_AddButton(info, level)
		
		-- Add all known outfits
		for _, outfitName in ipairs(outfits) do
			info.text = outfitName
			info.value = outfitName
			info.checked = (frame.chosenOutfit == outfitName)
			info.func = function(self)
				frame.chosenOutfit = self.value
				UIDropDownMenu_SetText(frame.dropdown, OutfitNameTrim(outfitName))
				
				-- Save to database
				if frame.specSpellId then
					SpecializationOutfitterPrivateDB.OutfitChoice[frame.specSpellId] = frame.chosenOutfit
					if Database[frame.specSpellId] then
						Database[frame.specSpellId].ChosenOutfit = frame.chosenOutfit
					end
				end
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end
	
	-- Store reference
	specFrames[index] = frame
	
	return frame
end

function CreateMainFrame()
	if mainFrame then
		LoadData()
		UpdateSpecFrames()
		mainFrame:Show()
		return
	end
	
	-- Create main frame with proper backdrop
	mainFrame = CreateFrame("Frame", "SpecializationOutfitterFrame", UIParent)
	mainFrame:SetSize(420, 100)
	mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	mainFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = {left = 11, right = 12, top = 12, bottom = 11}
	})
	mainFrame:SetBackdropColor(0, 0, 0, 0.8)
	mainFrame:SetMovable(true)
	mainFrame:EnableMouse(true)
	mainFrame:RegisterForDrag("LeftButton")
	mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
	mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
	mainFrame:SetClampedToScreen(true)
	table.insert(UISpecialFrames, "SpecializationOutfitterFrame") -- Esc Support
	mainFrame:Hide()
	
	-- Title
	mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.title:SetPoint("TOP", 0, -10)
	mainFrame.title:SetText("|c"..addonColor.."Specialization Outfitter|r")
	mainFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 16)
	
	-- Close button
	mainFrame.closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
	mainFrame.closeBtn:SetPoint("TOPRIGHT", -5, -5)
	mainFrame.closeBtn:SetScript("OnClick", function()
		mainFrame:Hide()
	end)
	
	-- Made by text in bottom right corner
	mainFrame.madeBy = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	mainFrame.madeBy:SetPoint("BOTTOMRIGHT", -14, 12)
	mainFrame.madeBy:SetText("|cFF888888made by Armir, Area52|r")
	mainFrame.madeBy:SetJustifyH("RIGHT")
	
	-- Create warning message frame (hidden by default)
	mainFrame.warningFrame = CreateFrame("Frame", "SpecOutfitterWarningFrame", mainFrame)
	mainFrame.warningFrame:SetAllPoints(mainFrame)
	mainFrame.warningFrame:Hide()
	
	-- Warning message text
	mainFrame.warningText = mainFrame.warningFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.warningText:SetPoint("CENTER", 0, 0)
	mainFrame.warningText:SetText("|cFFFF0000This addon works only when you have\nmore than one Specialization available|r")
	mainFrame.warningText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	mainFrame.warningText:SetJustifyH("CENTER")
	
	-- Create frames for all possible specializations
	for i = 1, Database_Length do
		DevPrint("CreateSpecFrame "..tostring(i))
		CreateSpecFrame(mainFrame, i)
	end
end

function UpdateSpecFrames()
	local knownOutfits = GetKnownOutfits()
	local visibleCount = 0
	local rowOffset = 40
	
	-- Count known specializations
	local knownSpecCount = 0
	for spellId, data in pairs(Database) do
		if data.Known then
			knownSpecCount = knownSpecCount + 1
		end
	end
	
	-- Check if we have at least 2 known specializations
	if knownSpecCount < 2 then
		if mainFrame.warningFrame then mainFrame.warningFrame:Show() end -- Show warning message and hide all spec frames
		for i = 1, #specFrames do specFrames[i]:Hide() end -- Hide all spec frames
		mainFrame:SetHeight(150) -- Set frame to warning size
		return
	else
		if mainFrame.warningFrame then mainFrame.warningFrame:Hide() end -- Hide warning message if showing
	end
	
	-- Update all spec frames with current data
	for i = 1, #specFrames do
		local frame = specFrames[i]
		local specData = nil
		
		-- Find spec data for this frame
		for spellId, data in pairs(Database) do
			if data.Index == i then
				specData = data
				frame.specSpellId = spellId
				break
			end
		end
		
		if specData and specData.Known then
			-- Update frame with spec data
			frame.icon:SetTexture(specData.SpecIcon)
			frame.name:SetText(specData.SpecName or "Unknown Spec")
			frame.chosenOutfit = specData.ChosenOutfit or ""
			
			if specData.ChosenOutfitExists then
				if frame.chosenOutfit == "" then
					UIDropDownMenu_SetText(frame.dropdown, "No Outfit")
				else
					UIDropDownMenu_SetText(frame.dropdown, OutfitNameTrim(frame.chosenOutfit))
				end			
			else
				UIDropDownMenu_SetText(frame.dropdown, "|cFFFF0000Outfit not found|r")
			end
			
			-- Position and show frame
			frame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -30 - (visibleCount * rowOffset))
			frame:Show()
			visibleCount = visibleCount + 1
		else
			-- Hide frame if spec not known
			frame:Hide()
		end
	end
	
	-- Adjust main frame height based on visible frames
	local newHeight = math.max(100, visibleCount * rowOffset + 50)
	mainFrame:SetHeight(newHeight)
end

-- Create and register frame for events
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

-- Event handler
EventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, spellName, spellRank, spellInterruptable = ...	
		SpellCastFinished(unit, spellName, spellRank, spellInterruptable)
	elseif event == "ADDON_LOADED" then
		local loadedAddon = ...
		if loadedAddon == AddonFolder then
			LoadData()
			CreateMainFrame()
		end
	end
end)

-- Create slash command
SLASH_SPECFIT1 = "/specfit"
SlashCmdList["SPECFIT"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "dev" then
        SpecializationOutfitterPublicDB.IsDev = not SpecializationOutfitterPublicDB.IsDev
        if SpecializationOutfitterPublicDB.IsDev then
            print("SpecFit Dev Mode: ON")
        else
            print("SpecFit Dev Mode: OFF")
        end
        return
    end

    CreateMainFrame()
end


DEFAULT_CHAT_FRAME:AddMessage("Welcome to |c"..addonColor.."Specialization Outfitter|r by Armir, Area52.")
DEFAULT_CHAT_FRAME:AddMessage("Type |c"..addonColor.."/specfit|r to start.")







