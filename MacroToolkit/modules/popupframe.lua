local MT = MacroToolkit
local mtpf
local L = MT.L
local GetSpellTabInfo, GetSpellBookItemTexture, GetSpellInfo, GetSpellTexture = GetSpellTabInfo, GetSpellBookItemTexture, GetSpellInfo, GetSpellTexture
local GetFlyoutInfo, GetFlyoutSlotInfo, GetSpellBookItemInfo = GetFlyoutInfo, GetFlyoutSlotInfo, GetSpellBookItemInfo
local string, tinsert, format = string, tinsert, format
local CreateFrame, PlaySound, PanelTemplates_GetSelectedTab = CreateFrame, PlaySound, PanelTemplates_GetSelectedTab
local EditMacro, CreateMacro, GetMacroInfo = EditMacro, CreateMacro, GetMacroInfo

MT.MACRO_ICON_FILENAMES = {}

local function doicongroups()
	MT:RefreshPlayerSpellIconInfo()
	local abilitytextures, achtextures, invtextures = {}, {}, {}
	local itemtextures, misctextures, spelltextures = {}, {}, {}
	local index = 1
	repeat
		local texture = MT:GetBlizzSpellorMacroIconInfo(index)
		local t = string.lower(texture or "")
		if string.find(t, "spell_") then tinsert(spelltextures, texture)
		elseif string.find(t, "ability_") then tinsert(abilitytextures, texture)
		elseif string.find(t, "achievement_") then tinsert(achtextures, texture)
		elseif string.find(t, "inv_") and t ~= "inv_misc_questionmark" then tinsert(invtextures, texture)
		elseif string.find(t, "item_") then tinsert(itemtextures, texture)
		elseif t ~= "" then tinsert(misctextures, texture) end
		index = index + 1
	until not texture
	MT.numabilityicons = #abilitytextures
	MT.numachicons = #achtextures
	MT.numinvicons = #invtextures
	MT.numitemicons = #itemtextures
	MT.nummiscicons = #misctextures
	MT.numspellicons = #spelltextures
	MT.abilityicons = {count = #abilitytextures, GetIconInfo = function(id) return id, "Ability", abilitytextures[id] end }
	MT.achicons = {count = #achtextures, GetIconInfo = function(id) return id, "Achievement", achtextures[id] end }
	MT.invicons = {count = #invtextures, GetIconInfo = function(id) return id, "Inventory", invtextures[id] end }
	MT.itemicons = {count = #itemtextures, GetIconInfo = function(id) return id, "Item", itemtextures[id] end }
	MT.miscicons = {count = #misctextures, GetIconInfo = function(id) return id, "Miscellaneous", misctextures[id] end }
	MT.spellicons = {count = #spelltextures, GetIconInfo = function(id) return id, "Spell", spelltextures[id] end }
end

function MT:CreateMTPopup()
	mtpf = CreateFrame("Frame", "MacroToolkitPopup", MacroToolkitFrame, "BackdropTemplate")
	mtpf:SetMovable(true)
	mtpf:EnableMouse(true)
	if MT.db.profile.scale then mtpf:SetScale(MT.db.profile.scale) end
	mtpf:SetSize(297, 411)
	mtpf:SetPoint("TOPLEFT", MacroToolkitFrame, "TOPRIGHT", 0, 0)
	mtpf:Hide()

	local mtpftl = mtpf:CreateTexture("BACKGROUND")
	mtpftl:SetTexture("Interface\\MacroFrame\\MacroPopup-TopLeft")
	mtpftl:SetSize(256, 368)
	mtpftl:SetPoint("TOPLEFT")

	local mtpftr = mtpf:CreateTexture("BACKGROUND")
	mtpftr:SetTexture("Interface\\MacroFrame\\MacroPopup-TopRight")
	mtpftr:SetSize(64, 368)
	mtpftr:SetPoint("TOPLEFT", 256, 0)

	local mtpfbl = mtpf:CreateTexture("BACKGROUND")
	mtpfbl:SetTexture("Interface\\MacroFrame\\MacroPopup-BotLeft")
	mtpfbl:SetSize(256, 64)
	mtpfbl:SetPoint("TOPLEFT", 0, -368)

	local mtpfbr = mtpf:CreateTexture("BACKGROUND")
	mtpfbr:SetTexture("Interface\\MacroFrame\\MacroPopup-BotRight")
	mtpfbr:SetSize(64, 64)
	mtpfbr:SetPoint("TOPLEFT", 256, -368)

	local mtpfml = mtpf:CreateTexture("BACKGROUND")
	mtpfml:SetTexture("Interface\\MacroFrame\\MacroPopup-TopLeft")
	mtpfml:SetTexCoord(0, 1, 0.3, 1)
	mtpfml:SetSize(405, 207)
	mtpfml:SetPoint("TOPLEFT", mtpftl, "BOTTOMLEFT")
	mtpfml:Hide()

	local mtpfmr = mtpf:CreateTexture("BACKGROUND")
	mtpfmr:SetTexture("Interface\\MacroFrame\\MacroPopup-TopRight")
	mtpfmr:SetTexCoord(0, 1, 0.3, 1)
	mtpfmr:SetSize(64, 207)
	mtpfmr:SetPoint("TOPLEFT", mtpftr, "BOTTOMLEFT")
	mtpfmr:Hide()

	local mtpftitle = mtpf:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	mtpftitle:SetText(_G.MACRO_POPUP_TEXT)
	mtpftitle:SetPoint("TOPLEFT", 24, -21)

	local mtpfcicon = mtpf:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	mtpfcicon:SetText(_G.MACRO_POPUP_CHOOSE_ICON)
	mtpfcicon:SetPoint("TOPLEFT", 24, -69)

	local mtpfavailable = mtpf:CreateFontString("MacroToolkitPopupAvailable", "BACKGROUND", "GameFontHighlightSmall")
	mtpfavailable:SetPoint("LEFT", mtpfcicon, "RIGHT", 20, 0)

	local mtpfedit = CreateFrame("EditBox", "MacroToolkitPopupEdit", mtpf, "BackdropTemplate")
	mtpfedit:SetMaxLetters(16)
	mtpfedit:SetSize(182, 20)
	mtpfedit:SetPoint("TOPLEFT", 29, -35)
	mtpfedit:SetFontObject("ChatFontNormal")

	local mtpfeditl = mtpfedit:CreateTexture("MacroToolkitFramePopupL", "BACKGROUND")
	mtpfeditl:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-FilterBorder")
	mtpfeditl:SetSize(12, 29)
	mtpfeditl:SetPoint("TOPLEFT", -11, 0)
	mtpfeditl:SetTexCoord(0, 0.09375, 0, 1)

	local mtpfeditm = mtpfedit:CreateTexture("MacroToolkitFramePopupM", "BACKGROUND")
	mtpfeditm:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-FilterBorder")
	mtpfeditm:SetSize(175, 29)
	mtpfeditm:SetPoint("LEFT", mtpfeditl, "RIGHT")
	mtpfeditm:SetTexCoord(0.09375, 0.90625, 0, 1)

	local mtpfeditr = mtpfedit:CreateTexture("MacroToolkitFramePopupR", "BACKGROUND")
	mtpfeditr:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-FilterBorder")
	mtpfeditr:SetSize(12, 29)
	mtpfeditr:SetPoint("LEFT", mtpfeditm, "RIGHT")
	mtpfeditr:SetTexCoord(0.90625, 1, 0, 1)

	mtpfedit:SetScript("OnTextChanged",
		function(this)
			local text = string.gsub(this:GetText(), "\"", "")
			MT:PopupOkayUpdate()
			MacroToolkitSelMacroName:SetText(text)
		end)

	mtpfedit:SetScript("OnEscapePressed", function() MT:CancelEdit() end)
	mtpfedit:SetScript("OnEnterPressed", function() if MacroToolkitPopupOk:IsEnabled() then MT:PopupOkayButtonOnClick() end end)

	doicongroups()
	local aisoptions = {
		contentInsets = {0, 0, 0, 0},
		sectionOrder = {"DynamicIcon", "SpellIcons", "AbilityIcons", "AchievementIcons", "InventoryIcons", "ItemIcons", "MiscellaneousIcons"},
		sections = {
			AbilityIcons = MT.abilityicons,
			AchievementIcons = MT.achicons,
			InventoryIcons = MT.invicons,
			SpellIcons = MT.spellicons,
			ItemIcons = MT.itemicons,
			MiscellaneousIcons = MT.miscicons,
		},
	}
	local aisframe = MT.AIS:CreateIconSelectorFrame("MacroToolkitPopupIcons", mtpf, aisoptions)
	aisframe:SetSize(296, 276)
	aisframe:SetPoint("TOPLEFT", 0, -85)
	aisframe.scrollFrame.ScrollBar:ClearAllPoints()
	aisframe.scrollFrame.ScrollBar:SetPoint("TOPLEFT", aisframe.scrollFrame, "TOPRIGHT", -10, -36)
	aisframe.scrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", aisframe.scrollFrame, "BOTTOMRIGHT", -10, 36)
	aisframe:SetScript("OnSelectedIconChanged", function(this) MT:SelectTexture(this:GetSelectedIcon()) end)

	local searchLabel = mtpf:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	searchLabel:SetText(format("%s:", _G.SEARCH))
	searchLabel:SetHeight(22)
	searchLabel:SetPoint("TOPLEFT", aisframe, "BOTTOMLEFT", 20, 15)

	local function searchtextchanged(editBox, userInput)
		if userInput then
			local searchtext = editBox:GetText()
			-- ticket 149
			if MT.SpellCheck then
				local _, _, textnum, _, _, _ = GetSpellInfo(searchtext)
				searchtext = textnum or ""
			end
			aisframe:SetSearchParameter(searchtext)
		end
	end

	local searchBox = CreateFrame("EditBox", "MacroToolkitSearchBox", mtpf, "BackdropTemplate,InputBoxTemplate")
	searchBox:SetAutoFocus(false)
	searchBox:SetSize(150, 22)
	searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
	searchBox:SetScript("OnTextChanged", searchtextchanged)

	local spellsearch = CreateFrame("CheckButton", "MacroToolkitSpellCheck", mtpf, "BackdropTemplate,UICheckButtonTemplate")
	spellsearch:SetSize(32, 32)
	spellsearch:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)

	local function showchecktip()
		GameTooltip:SetOwner(MacroToolkitSpellCheck, "ANCHOR_TOPRIGHT")
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(format("%s%s%s",_G.NORMAL_FONT_COLOR_CODE, L["Spell ID"], _G.FONT_COLOR_CODE_CLOSE))
		GameTooltip:AddLine(L["Search by spell ID"], 1, 1, 1)
		--GameTooltip:AddLine(L["(experimental)"], 1, 1, 1)
		GameTooltip:Show()
	end

	spellsearch:SetScript("OnEnter", showchecktip)
	spellsearch:SetScript("OnLeave", function() GameTooltip:Hide() end)
	spellsearch:SetScript("OnClick", function(this, button) MT.SpellCheck = this:GetChecked() searchtextchanged(MacroToolkitSearchBox, true) end)
	--[[
	local mtpfscroll = CreateFrame("ScrollFrame", "MacroToolkitPopupScroll", mtpf, "FauxScrollFrameTemplate")
	mtpfscroll:SetSize(296, 276)
	mtpfscroll:SetPoint("TOPRIGHT", -39, -98)
	mtpfscroll:SetScript("OnVerticalScroll", function(this, offset) FauxScrollFrame_OnVerticalScroll(this, offset, _G.MACRO_ICON_ROW_HEIGHT, function() MT:PopupUpdate(this) end) end)

	local sb = MacroToolkitPopupScrollScrollBar
	sb:ClearAllPoints()
	sb:SetPoint("TOPLEFT", mtpfscroll, "TOPRIGHT", 6, -22)
	sb:SetPoint("BOTTOMLEFT", mtpfscroll, "BOTTOMRIGHT", 6, 22)

	MacroToolkitPopupScrollScrollBarScrollUpButton:ClearAllPoints()
	MacroToolkitPopupScrollScrollBarScrollUpButton:SetPoint("BOTTOM", sb, "TOP", 0, 5)
	MacroToolkitPopupScrollScrollBarScrollDownButton:ClearAllPoints()
	MacroToolkitPopupScrollScrollBarScrollDownButton:SetPoint("TOP", sb, "BOTTOM", 0, -5)

	local sbt = mtpfscroll:CreateTexture("MacroToolkitFramePopupSBT", "BACKGROUND")
	sbt:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-ScrollBar")
	sbt:SetSize(30, 140)
	sbt:SetPoint("TOPLEFT", mtpfscroll, "TOPRIGHT", -3, 2)
	sbt:SetTexCoord(0, 0.46875, 0.0234375, 0.9609375)

	local sbb = mtpfscroll:CreateTexture("MacroToolkitFramePopupSBB", "BACKGROUND")
	sbb:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-ScrollBar")
	sbb:SetSize(30, 140)
	sbb:SetPoint("BOTTOMLEFT", mtpfscroll, "BOTTOMRIGHT", -3, -2)
	sbb:SetTexCoord(0.53125, 1, 0.03125, 1)

	for mpb = 1, 30 do
		local b = CreateFrame("CheckButton", "MacroToolkitPopupButton" .. mpb, mtpf, "MacroPopupButtonTemplate")
		if mpb == 1 then b:SetPoint("TOPLEFT", 24, -105)
		elseif mpb == 6 or mpb == 11 or mpb == 16 or mpb == 21 or mpb == 26 then b:SetPoint("TOPLEFT", _G["MacroToolkitPopupButton" .. (mpb - 5)], "BOTTOMLEFT", 0, -8)
		else b:SetPoint("LEFT", _G["MacroToolkitPopupButton" .. (mpb - 1)], "RIGHT", 10, 0) end
		b:SetID(mpb)
		b:SetScript("OnClick", function(this) MT:PopupButtonOnClick(this) end)
	end
]]--
	local mtpfcancel = CreateFrame("Button", "MacroToolkitPopupCancel", mtpf, "BackdropTemplate,UIPanelButtonTemplate")
	mtpfcancel:SetText(_G.CANCEL)
	mtpfcancel:SetSize(78, 22)
	mtpfcancel:SetPoint("BOTTOMRIGHT", -11, 13)
	mtpfcancel:SetScript("OnClick",
		function()
			MT:CancelEdit()
			--PlaySound("gsTitleOptionOK")
			PlaySound(798)
		end)

	local mtpfok = CreateFrame("Button", "MacroToolkitPopupOk", mtpf, "BackdropTemplate,UIPanelButtonTemplate")
	mtpfok:SetText(_G.OKAY)
	mtpfok:SetSize(78, 22)
	mtpfok:SetPoint("RIGHT", mtpfcancel, "LEFT", -2, 0)
	mtpfok:SetScript("OnClick", function() MT:PopupOkayButtonOnClick() end)

	mtpf:SetScript("OnShow",
		function(this)
			mtpfedit:SetFocus()
			--PlaySound("igCharacterInfoOpen")
			PlaySound(839)
			--MT:RefreshPlayerSpellIconInfo()
			--MT:PopupUpdate(mtpf)
			--MT:PopupOkayUpdate()
			if this.mode == "new" then
				MacroToolkitText:Hide()
				MacroToolkitFauxText:Hide()
				MT:SelectTexture(1)
				mtpfedit:SetText("")
			elseif this.mode == "edit" then
				if PanelTemplates_GetSelectedTab(MacroToolkitFrame) == 3 then
					local extraMacroInfo = MT.db.global.extra[tostring(MacroToolkitFrame.selectedMacro)]
					mtpfedit:SetText(extraMacroInfo.name)
					aisframe:SetSelectionByName(extraMacroInfo.texture)
				else
					local name, icon = GetMacroInfo(MacroToolkitFrame.selectedMacro)
					mtpfedit:SetText(name)
					aisframe:SetSelectionByName(icon)
				end
			end
			MacroToolkitEdit:Disable()
			MacroToolkitDelete:Disable()
			MacroToolkitNew:Disable()
			MacroToolkitFrameTab1:Disable()
			MacroToolkitFrameTab2:Disable()
			MacroToolkitShorten:Disable()
			MacroToolkitExtend:Disable()
			MacroToolkitBackup:Disable()
			MacroToolkitRestore:Disable()
			MacroToolkitClear:Disable()
			MacroToolkitShare:Disable()
			MacroToolkitBind:Disable()
			MacroToolkitFlyout:Disable()
			MacroToolkitCustom:Disable()
			MacroToolkitConditions:Disable()
			aisframe:SetSectionVisibility("DynamicIcon", MT.db.profile.dynamicicon)
			aisframe:SetSectionVisibility("AbilityIcons", MT.db.profile.abilityicons)
			aisframe:SetSectionVisibility("AchievementIcons", MT.db.profile.achicons)
			aisframe:SetSectionVisibility("InventoryIcons", MT.db.profile.invicons)
			aisframe:SetSectionVisibility("ItemIcons", MT.db.profile.itemicons)
			aisframe:SetSectionVisibility("MiscellaneousIcons", MT.db.profile.miscicons)
			aisframe:SetSectionVisibility("SpellIcons", MT.db.profile.spellicons)
			MT:UpdateIconCount()
			MT:Skin(mtpf)
		end)

	mtpf:SetScript("OnHide",
		function(this)
			if this.mode == "new" then
				MacroToolkitText:Show()
				MacroToolkitFauxText:Show()
				MacroToolkitText:SetFocus()
			end
			MacroToolkitEdit:Enable()
			MacroToolkitDelete:Enable()
			MacroToolkitShorten:Enable()
			MacroToolkitExtend:Enable()
			MacroToolkitBackup:Enable()
			MacroToolkitRestore:Enable()
			MacroToolkitClear:Enable()
			MacroToolkitShare:Enable()
			MacroToolkitBind:Enable()
			MacroToolkitConditions:Enable()
			if #MT.db.global.custom > 0 then MacroToolkitFlyout:Enable() end
			MacroToolkitCustom:Enable()
			--PlaySound("igCharacterInfoClose")
			PlaySound(840)
			local numMacros
			local numAccountMacros, numCharacterMacros = GetNumMacros()
			numMacros = (MacroToolkitFrame.macroBase == 0) and numAccountMacros or numCharacterMacros
			if PanelTemplates_GetSelectedTab(MacroToolkitFrame) == 3 then numMacros = MT:CountExtra() end
			if numMacros < MacroToolkitFrame.macroMax then MacroToolkitNew:Enable() end
			PanelTemplates_UpdateTabs(MacroToolkitFrame)
			_G.MACRO_ICON_FILENAMES = nil
			collectgarbage()
		end)

	local mtpfgl = CreateFrame("Button", "MacroToolkitPopupGoLarge", mtpf, "BackdropTemplate,UIPanelButtonTemplate")

	MT.golarge =
		function()
			mtpf:SetSize(446, 617)
			mtpftl:SetSize(405, 368)
			mtpftr:SetPoint("TOPLEFT", 405, 0)
			mtpfbl:SetSize(405, 64)
			mtpfbl:SetPoint("TOPLEFT", 0, -574)
			mtpfbr:SetPoint("TOPLEFT", 405, -574)
			mtpfml:Show()
			mtpfmr:Show()
			aisframe:SetSize(445, 482)
			aisframe:SetPoint("TOPLEFT", 5, -85)
			mtpfcancel:SetSize(105, 22)
			mtpfok:SetSize(125, 22)
			mtpfgl:SetText(L["Go Small"])
			MT.gonelarge = true
			--PlaySound("igCharacterInfoOpen")
			PlaySound(839)
		end

	MT.gosmall =
		function()
			mtpf:SetSize(297, 411)
			mtpftl:SetSize(256, 368)
			mtpftr:SetPoint("TOPLEFT", 256, 0)
			mtpfbl:SetSize(256, 64)
			mtpfbl:SetPoint("TOPLEFT", 0, -368)
			mtpfbr:SetPoint("TOPLEFT", 256, -368)
			mtpfml:Hide()
			mtpfmr:Hide()
			aisframe:SetSize(296, 276)
			aisframe:SetPoint("TOPLEFT", 0, -85)
			mtpfcancel:SetSize(78, 22)
			mtpfok:SetSize(78, 22)
			mtpfgl:SetText(L["Go Large"])
			MT.gonelarge = nil
			--PlaySound("igCharacterInfoClose")
			PlaySound(840)
		end

	mtpfgl:SetText(L["Go Large"])
	mtpfgl:SetSize(78, 22)
	mtpfgl:SetPoint("TOPRIGHT", -13, -62)
	mtpfgl:SetScript("OnClick",
		function()
			if MT.gonelarge then
				MT.gosmall()
			else
				MT.golarge()
			end
		end)

	return mtpf
end

function MT:RefreshPlayerSpellIconInfo()
	--if MT.MACRO_ICON_FILENAMES then return end

	-- We need to avoid adding duplicate spellIDs from the spellbook tabs for your other specs.
	local activeIcons = {}

	for i = 1, GetNumSpellTabs() do
		local tab, tabTex, offset, numSpells, _ = GetSpellTabInfo(i)
		offset = offset + 1
		local tabEnd = offset + numSpells
		for j = offset, tabEnd - 1 do
			--to get spell info by slot, you have to pass in a pet argument
			local spellType, ID = GetSpellBookItemInfo(j, "player");
			if (spellType ~= "FUTURESPELL") then
				local fileID = GetSpellBookItemTexture(j, "player")
				if (fileID) then
					activeIcons[fileID] = true
				end
			end
			if (spellType == "FLYOUT") then
				local _, _, numSlots, isKnown = GetFlyoutInfo(ID)
				if (isKnown and numSlots > 0) then
					for k = 1, numSlots do
						local spellID, overrideSpellID, isKnown = GetFlyoutSlotInfo(ID, k)
						if (isKnown) then
							local fileID = GetSpellTexture(spellID)
							if (fileID) then
								activeIcons[fileID] = true
							end
						end
					end
				end
			end
		end
	end

	MT.MACRO_ICON_FILENAMES = {}
	for fileDataID in pairs(activeIcons) do
		MT.MACRO_ICON_FILENAMES[#MT.MACRO_ICON_FILENAMES + 1] = fileDataID
	end

	GetLooseMacroIcons(MT.MACRO_ICON_FILENAMES )
	GetLooseMacroItemIcons(MT.MACRO_ICON_FILENAMES)
	GetMacroIcons(MT.MACRO_ICON_FILENAMES)
	GetMacroItemIcons(MT.MACRO_ICON_FILENAMES)
end

function MT:GetSpellorMacroIconInfo(index)
	if not index or not tonumber(index) then return end
	--MT:RefreshPlayerSpellIconInfo()
	--return MT.MACRO_ICON_FILENAMES[index]
	local id, kind, texture = MacroToolkitPopupIcons:GetIconInfo(tonumber(index))
	return texture
end

local function getFilenameFromPath(path)
	local s, e = string.find(string.lower(path), "interface\\icons\\(.-)")
	return string.sub(path, e + 1)
end

function MT:GetBlizzSpellorMacroIconInfo(index)
	if not index then return end
	local info = MT.MACRO_ICON_FILENAMES[index]
	local infonum = tonumber(info)
	if infonum ~= nil then
		return infonum
	else
		return info
	end
end

function MT:PopupOkayUpdate()
	local text = MacroToolkitPopupEdit:GetText()
	text = string.gsub(text, "\"", "")
	if string.len(text) > 0 and mtpf.selectedIcon then MacroToolkitPopupOk:Enable()
	else MacroToolkitPopupOk:Disable() end
	if mtpf.mode == "edit" and string.len(text) > 0 then MacroToolkitPopupOk:Enable() end
end

function MT:SelectTexture(selectedIcon)
	mtpf.selectedIcon = selectedIcon
	mtpf.selectedIconTexture = nil
	local texture = MT:GetSpellorMacroIconInfo(mtpf.selectedIcon) or selectedIcon or "INV_Misc_QuestionMark"
	if type(texture) == "number" then
		MacroToolkitSelMacroButton.Icon:SetTexture(texture)
	else
		MacroToolkitSelMacroButton.Icon:SetTexture(format("INTERFACE\\ICONS\\%s", texture))
	end
	MT:PopupOkayUpdate()
	local mode = mtpf.mode
	mtpf.mode = nil
	mtpf.mode = mode
end

function MT:CancelEdit()
	mtpf:Hide()
	MT:MacroFrameUpdate()
	mtpf.selectedIcon = nil
end

function MT:PopupUpdate(this)
	this = this or mtpf
	local numMacroIcons = #MT.MACRO_ICON_FILENAMES
	local macroPopupIcon, macroPopupButton
	local macroPopupOffset = FauxScrollFrame_GetOffset(MacroToolkitPopupScroll)
	local index

	if this.mode == "new" then MacroToolkitPopupEdit:SetText("")
	elseif this.mode == "edit" then
		local name, _, body = GetMacroInfo(MacroToolkitFrame.selectedMacro)
		MacroToolkitPopupEdit:SetText(name)
	end

	local texture
	for i = 1, 30 do
		macroPopupIcon = _G[format("MacroToolkitPopupButton%dIcon", i)]
		macroPopupButton = _G[format("MacroToolkitPopupButton%d", i)]
		index = (macroPopupOffset * _G.NUM_ICONS_PER_ROW) + i
		texture = MT:GetSpellorMacroIconInfo(index)
		if index <= numMacroIcons and texture then
			if type(texture == "number") then
				macroPopupIcon:SetTexture(texture)
			else
				macroPopupIcon:SetTexture(format("INTERFACE\\ICONS\\%s", texture))
			end
			macroPopupButton:Show()
		else
			macroPopupIcon:SetTexture("")
			macroPopupButton:Hide()
		end
		if mtpf.selectedIcon and index == mtpf.selectedIcon then macroPopupButton:SetChecked(1)
		elseif mtpf.selectedIconTexture == texture then macroPopupButton:SetChecked(1)
		else macroPopupButton:SetChecked(nil) end
	end
	FauxScrollFrame_Update(MacroToolkitPopupScroll, ceil(numMacroIcons / _G.NUM_ICONS_PER_ROW) , 5, _G.MACRO_ICON_ROW_HEIGHT )
end


function MT:PopupButtonOnClick(this) MT:SelectTexture(this:GetID() + (FauxScrollFrame_GetOffset(MacroToolkitPopupScroll) * _G.NUM_ICONS_PER_ROW)) end

function MT:PopupOkayButtonOnClick()
	if InCombatLockdown() then
		MT:CombatMessage()
		MacroToolkitPopup:Hide()
	else
		local index = 1
		local iconTexture = MT:GetSpellorMacroIconInfo(MacroToolkitPopup.selectedIcon)
		local text = MacroToolkitPopupEdit:GetText()
		text = string.gsub(text, "\"", "")
		if MacroToolkitPopup.mode == "new" then
			if PanelTemplates_GetSelectedTab(MacroToolkitFrame) > 2 then
				index = MT:GetNextIndex()
				MT.db.global.extra[tostring(index)] = {name = text, texture = iconTexture, body = ""}
			else
				index = CreateMacro(text, iconTexture, nil, (MacroToolkitFrame.macroBase > 0))
				MacroToolkitText.extended = nil
			end
		elseif MacroToolkitPopup.mode == "edit" then
			if PanelTemplates_GetSelectedTab(MacroToolkitFrame) == 3 then
				index = MacroToolkitFrame.selectedMacro
				local extraMacro = MT.db.global.extra[tostring(index)]
				extraMacro.name = text or extraMacro.name
				extraMacro.texture = iconTexture or extraMacro.texture
			else index = EditMacro(MacroToolkitFrame.selectedMacro, text, iconTexture) end
		end
		MacroToolkitPopup:Hide()
		MacroToolkitFrame.selectedMacro = tonumber(index)
		MT:MacroFrameUpdate()
		--PlaySound("gsTitleOptionOK")
		PlaySound(798)
	end
end

function MT:UpdateIconCount()
	local icframe = MacroToolkitPopupIcons
	local dy = icframe:GetSectionVisibility("DynamicIcon")
	local ab = icframe:GetSectionVisibility("AbilityIcons")
	local ac = icframe:GetSectionVisibility("AchievementIcons")
	local inv = icframe:GetSectionVisibility("InventoryIcons")
	local it = icframe:GetSectionVisibility("ItemIcons")
	local mi = icframe:GetSectionVisibility("MiscellaneousIcons")
	local sp = icframe:GetSectionVisibility("SpellIcons")
	local dyc, abc, acc, invc, itc, mic, spc = 1, MT.numabilityicons, MT.numachicons, MT.numinvicons, MT.numitemicons, MT.nummiscicons, MT.numspellicons
	local visicons = 0 + (dy and dyc or 0) + (ab and abc or 0) + (ac and acc or 0) + (inv and invc or 0) + (it and itc or 0) + (mi and mic or 0) + (sp and spc or 0)
	local filtered = (not dy) or (not ab) or (not ac) or (not inv) or (not it) or (not mi) or (not sp)
	if filtered then MacroToolkitPopupAvailable:SetFormattedText("%s: %d", _G.AVAILABLE, visicons)
	else MacroToolkitPopupAvailable:SetText("") end
end
