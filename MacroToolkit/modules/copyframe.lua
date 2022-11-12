local _G = _G
local MT = MacroToolkit
local L = MT.L
local AceGUI = MT.LS("AceGUI-3.0")

function MT:CreateCopyFrame()
	local mtcframe = CreateFrame("Frame", "MacroToolkitCopyFrame", UIParent, "BackdropTemplate,ButtonFrameTemplate")

	local function frameMouseUp()
		mtcframe:StopMovingOrSizing()
		MT.db.profile.x = mtcframe:GetLeft()
		MT.db.profile.y = mtcframe:GetBottom()
	end

	if MT.db.profile.scale then mtcframe:SetScale(MT.db.profile.scale) end
	mtcframe:SetSize(638, 424)
	mtcframe:SetMovable(true)
	mtcframe:EnableMouse(true)
	mtcframe:EnableKeyboard(true)
	mtcframe:SetPoint("BOTTOMLEFT", MT.db.profile.x, MT.db.profile.y)
	mtcframe:SetScript("OnMouseDown", function() mtcframe:StartMoving() end)
	mtcframe:SetScript("OnMouseUp", frameMouseUp)
	mtcframe:Hide()

	local mtcfportrait = mtcframe:CreateTexture(nil, "OVERLAY", nil, -1)
	mtcfportrait:SetTexture("Interface\\FriendsFrame\\FriendsFrameScrollIcon")
	mtcfportrait:SetSize(60, 60)
	mtcfportrait:SetPoint("TOPLEFT", -5, 5)

	local mtctitle = mtcframe:CreateFontString(nil, "BORDER", "GameFontNormal")
	mtctitle:SetText(L["Copy Macro"])
	mtctitle:SetPoint("TOP", 0, -5)

	local mtchbleft = mtcframe:CreateTexture(nil, "ARTWORK")
	mtchbleft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	mtchbleft:SetSize(556, 16)
	mtchbleft:SetPoint("TOPLEFT", 2, -210)
	mtchbleft:SetTexCoord(0, 1, 0, 0.25)

	local mtchbright = mtcframe:CreateTexture(nil, "ARTWORK")
	mtchbright:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	mtchbright:SetSize(75, 16)
	mtchbright:SetPoint("LEFT", mtchbleft, "RIGHT", 0, 0)
	mtchbright:SetTexCoord(0, 0.29296875, 0.25, 0.5)

	local mtcselbg = mtcframe:CreateTexture("MacroToolkitCSelBg", "ARTWORK")
	mtcselbg:SetTexture("Interface\\Buttons\\UI-EmptySlot")
	mtcselbg:SetSize(64, 64)
	mtcselbg:SetPoint("TOPLEFT", 5, -218)

	local mtcselname = mtcframe:CreateFontString("MacroToolkitCSelMacroName", "ARTWORK", "GameFontNormalLarge")
	mtcselname:SetJustifyH("LEFT")
	mtcselname:SetSize(256, 16)
	mtcselname:SetPoint("TOPLEFT", mtcselbg, "TOPRIGHT", -4, -10)
	local LSM = MT.LS("LibSharedMedia-3.0")
	local font = LSM:Fetch(LSM.MediaType.FONT, MT.db.profile.fonts.mfont)
	mtcselname:SetFont(font, 16, '')

	local mtcselbutton = CreateFrame("CheckButton", "MacroToolkitCSelMacroButton", mtcframe, "BackdropTemplate,MacroToolkitButtonTemplate")
	mtcselbutton:SetID(0)
	mtcselbutton:SetPoint("TOPLEFT", mtcselbg, 14, -14)
	mtcselbutton:SetScript("OnClick", function(this) this:SetChecked(false) end)
	MacroToolkitCSelMacroButtonUnbound:Hide()

	local mtcmacros = CreateFrame("Frame", "MacroToolkitCButtonContainer", mtcframe, "BackdropTemplate")
	mtcmacros:SetSize(285, 10)
	mtcmacros:SetPoint("TOPLEFT", 12, -66)
	MT:ContainerOnLoad(mtcmacros)

	local mtctextbg = CreateFrame("Frame", "MacroToolkitCTextBg", mtcframe, "BackdropTemplate")
	mtctextbg:SetPoint("TOPLEFT", 6, -289)
	mtctextbg:SetPoint("BOTTOMRIGHT", mtcframe, -8, 30)
	mtctextbg:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, tileSize = 16, tile = true, insets = {left = 5, right = 5, top = 5, bottom = 5}})
	mtctextbg:SetBackdropBorderColor(_G.TOOLTIP_DEFAULT_COLOR.r, _G.TOOLTIP_DEFAULT_COLOR.g, _G.TOOLTIP_DEFAULT_COLOR.b)
	mtctextbg:SetBackdropColor(_G.TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, _G.TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, _G.TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)

	local mtmcscroll = CreateFrame("ScrollFrame", "MacroToolkitCScrollFrame", mtctextbg, "BackdropTemplate,UIPanelScrollFrameTemplate")
	mtmcscroll:SetPoint("TOPLEFT", 10, -6)
	mtmcscroll:SetPoint("BOTTOMRIGHT", -26, 4)

	local function onverticalscroll(this, offset)
		local scrollbar1 = MacroToolkitCScrollFrameScrollBar
		local scrollbar2 = MacroToolkitCFauxScrollFrameScrollBar
		scrollbar1:SetValue(offset)
		scrollbar2:SetValue(offset)
		local mini1, maxi1 = scrollbar1:GetMinMaxValues()
		local mini2, maxi2 = scrollbar2:GetMinMaxValues()
		if offset == 0 then
			MacroToolkitCScrollFrameScrollBarScrollUpButton:Disable()
			MacroToolkitCFauxScrollFrameScrollBarScrollUpButton:Disable()
		else
			MacroToolkitCScrollFrameScrollBarScrollUpButton:Enable()
			MacroToolkitCFauxScrollFrameScrollBarScrollUpButton:Enable()
		end
		if scrollbar1:GetValue() - maxi1 == 0 then
			MacroToolkitCScrollFrameScrollBarScrollDownButton:Disable()
			MacroToolkitCFauxScrollFrameScrollBarScrollDownButton:Disable()
		else
			MacroToolkitCScrollFrameScrollBarScrollDownButton:Enable()
			MacroToolkitCFauxScrollFrameScrollBarScrollDownButton:Enable()
		end
	end

	mtmcscroll:SetScript("OnVerticalScroll", onverticalscroll)
	mtmcscroll:SetScript("OnMouseWheel",
		function(this, value, scrollBar)
			ScrollFrameTemplate_OnMouseWheel(MacroToolkitCFauxScrollFrame, value)
			ScrollFrameTemplate_OnMouseWheel(this, value)
		end)
	local mtmcscrollchild = CreateFrame("EditBox", "MacroToolkitCText", mtmcscroll, "BackdropTemplate")
	mtmcscrollchild:SetMultiLine(true)
	mtmcscrollchild:SetAutoFocus(false)
	mtmcscrollchild:SetCountInvisibleLetters(true)
	mtmcscrollchild:SetSize(mtmcscroll:GetSize())
	mtmcscrollchild:SetEnabled(false)
	mtmcscrollchild:SetScript("OnUpdate",
		function(this)
			ScrollingEdit_OnUpdate(this)
			ScrollingEdit_OnUpdate(MacroToolkitCFauxText)
		end)
	mtmcscrollchild:SetScript("OnEscapePressed", EditBox_ClearFocus)
	font = LSM:Fetch(LSM.MediaType.FONT, MT.db.profile.fonts.edfont)
	mtmcscrollchild:SetFont(font, MT.db.profile.fonts.edsize, '')
	mtmcscroll:SetScrollChild(mtmcscrollchild)

	local mtmcfscroll = CreateFrame("ScrollFrame", "MacroToolkitCFauxScrollFrame", mtctextbg, "BackdropTemplate,UIPanelScrollFrameTemplate")
	mtmcfscroll:SetPoint("TOPLEFT", 10, -6)
	mtmcfscroll:SetPoint("BOTTOMRIGHT", -26, 4)

	local mtmcfscrollchild = CreateFrame("EditBox", "MacroToolkitCFauxText", mtmcfscroll, "BackdropTemplate")
	mtmcfscrollchild:SetMultiLine(true)
	mtmcfscrollchild:SetAutoFocus(false)
	mtmcfscrollchild:SetCountInvisibleLetters(true)
	mtmcfscrollchild:SetSize(mtmcfscroll:GetSize())
	mtmcfscrollchild:SetScript("OnUpdate", nil)
	mtmcfscrollchild:SetScript("OnTextChanged", nil)
	font = LSM:Fetch(LSM.MediaType.FONT, MT.db.profile.fonts.edfont)
	mtmcfscrollchild:SetFont(font, MT.db.profile.fonts.edsize, '')
	mtmcfscroll:SetScrollChild(mtmcfscrollchild)

	local mtcexit = CreateFrame("Button", "MacroToolkitCExit", mtcframe, "BackdropTemplate,UIPanelButtonTemplate")
	mtcexit:SetText(_G.EXIT)
	mtcexit:SetSize(80, 22)
	mtcexit:SetPoint("BOTTOMRIGHT", -5, 4)
	mtcexit:SetScript("OnClick", HideParentPanel)

	local function updatechars(dd)
		local name = UnitName("player")
		local realm = GetRealmName()
		local pname = format("%s - %s", name, realm)
		local chars = {}
		if MacroToolkitDB.char then
			for ch, chd in pairs(MacroToolkitDB.char) do
				if ch ~= pname then
					if chd.extended then
						for idx, ex in pairs(chd.extended) do
							if tonumber(idx) > _G.MAX_ACCOUNT_MACROS then
								chars[ch] = ch
								break
							end
						end
					end
					if chd.macros then chars[ch] = ch end
				end
			end
		end
		dd:SetList(chars)
	end

	local mtcchars = AceGUI:Create("Dropdown")
	mtcchars.frame:SetParent(mtaddscript)
	mtcchars.frame:SetParent(mtcframe)
	mtcchars.label:SetTextColor(1, 1, 1, 1)
	mtcchars:SetWidth(250)
	mtcchars:SetLabel(format("%s:", _G.CHARACTER))
	mtcchars:SetCallback("OnValueChanged",
		function(info, name, key)
			MT.charcopy = key
			MT:SetMacros(false, false, true)
			MT:MacroFrameUpdate()
		end)
	mtcchars:SetPoint("TOPLEFT", 330, -66)
	updatechars(mtcchars)

	local function updateslots(s)
		local _, macros = GetNumMacros()
		macros = _G.MAX_CHARACTER_MACROS - macros
		s:SetFormattedText("%s: |cffffffff%d", L["Macro slots available"], macros)
		if macros == 0 then MacroToolkitCopy:Disable()
		elseif mtcframe.selectedMacro then MacroToolkitCopy:Enable() end
	end

	local mtcslottext = mtcframe:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	mtcslottext:SetPoint("TOPLEFT", mtcchars.frame, "BOTTOMLEFT", 0, -82)

	local mtcnotice = mtcframe:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	mtcnotice:SetPoint("BOTTOMLEFT", mtcslottext, "TOPLEFT", 0, 5)

	local mtccopy = CreateFrame("Button", "MacroToolkitCopy", mtcframe, "BackdropTemplate,UIPanelButtonTemplate")
	mtccopy:SetText(_G.CALENDAR_COPY_EVENT)
	mtccopy:SetSize(80, 22)
	mtccopy:SetPoint("BOTTOMLEFT", 5, 4)
	mtccopy:Disable()
	mtccopy:SetScript("OnClick",
		function()
			local buttonName = format("MacroToolkitCButton%d", mtcframe.selectedMacro)
			local button = _G[buttonName]
			local name = _G[format("%sName", buttonName)]:GetText()
			local icon = string.gsub(string.upper(button.Icon:GetTexture()), "INTERFACE\\ICONS\\", "")
			local body = mtmcscrollchild:GetText()
			MacroToolkitText:SetText(body)
			MacroToolkitFrame.macroBase = _G.MAX_ACCOUNT_MACROS
			if button.extended then
				MacroToolkitFrame.selectedMacro = CreateMacro(name, icon, "MT", true)
				MT:ExtendMacro(true)
			else
				MacroToolkitFrame.selectedMacro = CreateMacro(name, icon, body, true)
			end
			MacroToolkitFrameTab2:GetScript("OnClick")(MacroToolkitFrameTab2)
			updateslots(mtcslottext)
			if MacroToolkitFrame.selectedMacro then
				mtcnotice:SetFormattedText("%s: |cffffffff%s", L["Macro copied"], name)
			else
				mtcnotice:SetFormattedText("|cffff0000%s", _G.SPELL_FAILED_ERROR)
			end
		end)

	mtcframe:SetScript("OnShow",
		function()
			mtcframe:SetPoint("BOTTOMLEFT", MT.db.profile.x, MT.db.profile.y)
			updatechars(mtcchars)
			updateslots(mtcslottext)
			mtcnotice:SetText("")
			MT:MacroFrameUpdate()
			MT:Skin(mtcframe)
			--PlaySound("igCharacterInfoOpen")
			PlaySound(839)
		end)

	mtcframe:SetScript("OnHide",
		function()
			MT:MacroFrameUpdate()
			MacroToolkitFrame:Show()
			--PlaySound("igCharacterInfoClose")
			PlaySound(840)
		end)

	return mtcframe
end
