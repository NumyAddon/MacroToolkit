local MT = MacroToolkit
local L = MT.L
local string, format = string, format
local CreateFrame, ipairs, table = CreateFrame, ipairs, table

function MT:CreateScriptFrame()
	local mtsf = CreateFrame("Frame", "MacroToolkitScriptFrame", UIParent, "BackdropTemplate,ButtonFrameTemplate")

	local function frameMouseUp()
		mtsf:StopMovingOrSizing()
		MT.db.profile.x = mtsf:GetLeft()
		MT.db.profile.y = mtsf:GetBottom()
	end

	mtsf:SetMovable(true)
	mtsf:EnableMouse(true)
	if MT.db.profile.scale then mtsf:SetScale(MT.db.profile.scale) end
	mtsf:SetSize(638, 424)
	mtsf:SetPoint("BOTTOMLEFT", MT.db.profile.x, MT.db.profile.y)
	mtsf:SetScript("OnMouseDown", function() mtsf:StartMoving() end)
	mtsf:SetScript("OnMouseUp", frameMouseUp)
	mtsf:Hide()

	local mtstitle = mtsf:CreateFontString(nil, "BORDER", "GameFontNormal")
	mtstitle:SetText(L["Custom slash command"])
	mtstitle:SetPoint("TOP", 0, -5)
	
	local mtsfportrait = mtsf:CreateTexture(nil, "OVERLAY", nil, -1)
	mtsfportrait:SetTexture("Interface\\LFGFRAME\\BattlenetWorking0")
	mtsfportrait:SetSize(96, 96)
	mtsfportrait:SetPoint("TOPLEFT", -25, 25)
	
	local mtsname = mtsf:CreateFontString("MacroToolkitScriptName", "ARTWORK", "GameFontNormalLarge")
	mtsname:SetSize(0, 0)
	mtsname:SetPoint("CENTER", 0, 175)
	mtsname:SetTextColor(MT:HexToRGB(MT.db.profile.commandcolour))

	local mthint = mtsf:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	mthint:SetText(L["Arguments can be accessed using the variables arg1 to arg4"])
	mthint:SetSize(180, 32)
	mthint:SetTextColor(1, 1, 1, 0.75)
	mthint:SetPoint("TOPRIGHT", -7, -25)

	local mtshbleft = mtsf:CreateTexture(nil, "ARTWORK")
	mtshbleft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	mtshbleft:SetSize(556, 16)
	mtshbleft:SetPoint("TOPLEFT", 2, -300)
	mtshbleft:SetTexCoord(0, 1, 0, 0.25)

	local mtshbright = mtsf:CreateTexture(nil, "ARTWORK")
	mtshbright:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	mtshbright:SetSize(75, 16)
	mtshbright:SetPoint("LEFT", mtshbleft, "RIGHT", 0, 0)
	mtshbright:SetTexCoord(0, 0.29296875, 0.25, 0.5)

	local mtenters = mtsf:CreateFontString("MacroToolkitScriptEnter", "ARTWORK", "GameFontHighlightSmall")
	mtenters:SetFormattedText("%s:", L["Enter script"])
	mtenters:SetPoint("TOPLEFT", 50, -48)

	local mtsexit = CreateFrame("Button", "MacroToolkitScriptExit", mtsf, "BackdropTemplate,UIPanelButtonTemplate")
	mtsexit:SetText(_G.EXIT)
	mtsexit:SetSize(80, 22)
	mtsexit:SetPoint("BOTTOMRIGHT", -5, 4)
	mtsexit:SetScript("OnClick", HideParentPanel)
	
	local mtsdel = CreateFrame("Button", "MacroToolkitScriptDelete", mtsf, "BackdropTemplate,UIPanelButtonTemplate")
	mtsdel:SetText(_G.DELETE)
	mtsdel:SetSize(80, 22)
	mtsdel:SetPoint("BOTTOMLEFT", 4, 4)
	mtsdel:SetScript("OnClick",
		function()
			local delindex
			for i, s in ipairs(MT.db.global.custom) do
				if s.n == MT.newslash then
					delindex = i
					break
				end
			end
			table.remove(MT.db.global.custom, delindex)
			_G[format("SLASH_MACROTOOLKIT_CUSTOM_%s", string.upper(MT.newslash))] = nil
			SlashCmdList[format("MACROTOOLKIT_CUSTOM_%s", string.upper(MT.newslash))] = nil
			mtsf:Hide()
		end)

	local mtsscrollbg = CreateFrame("Frame", "MacroToolkitScriptScrollBg", mtsf, "BackdropTemplate")
	mtsscrollbg:SetSize(623, 244)
	mtsscrollbg:SetPoint("TOPLEFT", 7, -62)
	mtsscrollbg:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, tileSize = 16, tile = true, insets = {left = 5, right = 5, top = 5, bottom = 5}})
	mtsscrollbg:SetBackdropBorderColor(_G.TOOLTIP_DEFAULT_COLOR.r, _G.TOOLTIP_DEFAULT_COLOR.g, _G.TOOLTIP_DEFAULT_COLOR.b)
	mtsscrollbg:SetBackdropColor(_G.TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, _G.TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, _G.TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)
	
	local mtsscroll = CreateFrame("ScrollFrame", "MacroToolkitScriptScroll", mtsf, "BackdropTemplate,UIPanelScrollFrameTemplate")
	mtsscroll:SetSize(589, 230)
	mtsscroll:SetPoint("TOPLEFT", mtsscrollbg, 6, -8)
	
	local mtsscrollchild = CreateFrame("EditBox", "MacroToolkitScriptText", mtsf, "BackdropTemplate")
	mtsscrollchild:SetMultiLine(true)
	mtsscrollchild:SetSize(589, 230)
	mtsscrollchild:SetScript("OnCursorChanged", ScrollingEdit_OnCursorChanged)
	mtsscrollchild:SetScript("OnUpdate", function(this, elapsed) ScrollingEdit_OnUpdate(this, elapsed, this:GetParent()) end)
	mtsscrollchild:SetScript("OnEscapePressed", function() mtsf:Hide() end)
	mtsscrollchild:SetFontObject("GameFontHighlightSmall")
	mtsscroll:SetScrollChild(mtsscrollchild)
	
	local mtserrorbg = CreateFrame("Frame", "MacroToolkitScriptErrorBg", mtsf, "BackdropTemplate")
	mtserrorbg:SetSize(623, 90)
	mtserrorbg:SetPoint("BOTTOMLEFT", 7, 27)
	mtserrorbg:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, tileSize = 16, tile = true, insets = {left = 5, right = 5, top = 5, bottom = 5}})
	mtserrorbg:SetBackdropBorderColor(_G.TOOLTIP_DEFAULT_COLOR.r, _G.TOOLTIP_DEFAULT_COLOR.g, _G.TOOLTIP_DEFAULT_COLOR.b)
	mtserrorbg:SetBackdropColor(_G.TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, _G.TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, _G.TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)
	
	local mtserrorscroll = CreateFrame("ScrollFrame", "MacroToolkitScriptErrors", mtsf, "BackdropTemplate,UIPanelScrollFrameTemplate")
	mtserrorscroll:SetSize(589, 76)
	mtserrorscroll:SetPoint("TOPLEFT", mtserrorbg, 6, -8)
	
	local mtsescrollchild = CreateFrame("EditBox", "MacroToolkitScrollErrorText", mtsf, "BackdropTemplate")
	mtsescrollchild:SetMultiLine(true)
	mtsescrollchild:SetSize(589, 76)	
	mtsescrollchild:Disable()
	mtsescrollchild:SetScript("OnUpdate", function(this, elapsed) ScrollingEdit_OnUpdate(this, elapsed, this:GetParent()) end)
	mtsescrollchild:SetFontObject("GameFontHighlightSmall")
	mtserrorscroll:SetScrollChild(mtsescrollchild)
	
	local mtstextbutton = CreateFrame("Button", "MacroToolkitScriptFocus", mtsf, "BackdropTemplate")
	mtstextbutton:SetSize(589, 230)
	mtstextbutton:SetPoint("TOPLEFT", mtsscrollchild)
	mtstextbutton:SetScript("OnClick", function() mtsscrollchild:SetFocus() end)
	
	local mtssave = CreateFrame("Button", "MacroToolkitScriptSave", mtsf, "BackdropTemplate,UIPanelButtonTemplate")
	mtssave:SetText(_G.SAVE)
	mtssave:SetSize(80, 22)
	mtssave:SetPoint("RIGHT", mtsexit, "LEFT")
	mtssave:SetScript("OnClick",
		function()
			local luatext = mtsscrollchild:GetText()
			local slashname = mtsname:GetText()
			local func, err = loadstring(luatext, slashname)
			if err then
				--PlaySoundFile("Sound/INTERFACE/igQuestFailed.ogg")
				mtsescrollchild:SetText(format("|c%s%s|r\n\n%s", MT.db.profile.errorcolour, err, L["Save failed"]))
			else
				table.insert(MT.db.global.custom, {n = MT.newslash, s = luatext})
				_G[format("SLASH_MACROTOOLKIT_CUSTOM_%s1", string.upper(MT.newslash))] = slashname
				SlashCmdList[format("MACROTOOLKIT_CUSTOM_%s", string.upper(MT.newslash))] = function(input) MT:DoCustomCommand(luatext, input) end
				mtsf:Hide()
			end
		end)
	
	mtsf:SetScript("OnShow",
		function()
			mtsf:SetPoint("BOTTOMLEFT", MT.db.profile.x, MT.db.profile.y)
			mtsname:SetText(MT.newslash and (format("%s%s", MT.slash, MT.newslash)) or _G.UNKNOWN)
			mtsescrollchild:SetText("")
			local scripttext = ""
			for _, s in ipairs(MT.db.global.custom) do
				if s.n == MT.newslash then
					scripttext = s.s
					break
				end
			end
			mtsscrollchild:SetText(scripttext)
			MT:Skin(mtsf)
		end)
	
	mtsf:SetScript("OnHide", function() MacroToolkitFrame:Show() end)
	return mtsf
end
