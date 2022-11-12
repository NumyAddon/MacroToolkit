local MT = MacroToolkit
local MTB
local GetBindingText, LoadBindings, SetBinding, GetBindingKey = GetBindingText, LoadBindings, SetBinding, GetBindingKey
local GetBindingFromClick, GetCurrentBindingSet = GetBindingFromClick, GetCurrentBindingSet
local format, string, tonumber = format, string, tonumber
local PlaySound, UnitName, GetMacroInfo, CreateFrame = PlaySound, UnitName, GetMacroInfo, CreateFrame

MT.ACCOUNT_BINDINGS = _G.ACCOUNT_BINDINGS or 1
MT.CHARACTER_BINDINGS = _G.CHARACTERBINDINGS or 2

function MT:CreateBindingFrame()
	local frame = CreateFrame("Button", "MacroToolkitBindingFrame", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("DIALOG")
	frame:EnableKeyboard(true)
	frame:EnableMouse(true)
	if MT.db.profile.scale then frame:SetScale(MT.db.profile.scale) end
	frame:SetSize(500, 206)
	frame:SetPoint("TOP", 0 , -135)
	frame:SetToplevel(true)
	frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile = "true", tileSize = 32, edgeSize = 32, insets = {left = 11, right = 12, top = 12, bottom = 11}})
	frame:SetScript("OnKeyDown", function(this, key) MT:BindingFrameOnKeyDown(this, key) end)
	frame:SetScript("OnMouseUp", function(this, button) MT:BindingFrameOnKeyDown(this, button) end)
	frame:Hide()
	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	frame.title:SetPoint("TOP", 0, -16)
	frame.title:SetText(_G.KEY_BINDINGS)
	frame.macroname = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.macroname:SetPoint("TOP", frame.title, "BOTTOM", 0, -15)
	frame:SetScript("OnShow",
		function()
			MacroToolkitFrame:Hide()
			local tab = PanelTemplates_GetSelectedTab(MacroToolkitFrame)
			local sel = (tab == 3) and MacroToolkitFrame.extra or MacroToolkitFrame.selectedMacro
			local name = (sel > 1000) and MT.db.global.extra[tostring(sel)].name or GetMacroInfo(sel)
			local commandName = (sel > 1000) and format("CLICK MTSB%d:LeftButton", sel) or format("MACRO %s", name)
			frame.selected = commandName
			frame.mname = name
			MT:UpdateBindingFrame()
			frame.profile:SetChecked(GetCurrentBindingSet() == 2)
			if frame.profile:GetChecked() then frame.title:SetFormattedText(_G.CHARACTER_KEY_BINDINGS, UnitName("player"))
			else frame.title:SetText(_G.KEY_BINDINGS) end
			frame.bindingsChanged = nil
			MT:UpdateBindingFrame()
			MT:Skin(frame)
		end)
	frame:SetScript("OnHide",
		function()
			frame.outputtext:SetText("")
			--PlaySound("gsTitleOptionExit")
			PlaySound(799)
			MacroToolkitFrame:Show()
		end)
	frame:RegisterForClicks("AnyUp")
	MTB = frame

	local button1 = CreateFrame("Button", "MacroToolkitBindButton1", frame, "BackdropTemplate,UIPanelButtonTemplate")
	button1:RegisterForClicks("AnyUp")
	button1:SetNormalFontObject(GameFontHighlightSmall)
	button1:SetDisabledFontObject(GameFontDisable)
	button1:SetHighlightFontObject(GameFontHighlightSmall)
	button1:SetSize(180, 22)
	button1:SetPoint("BOTTOMLEFT", 68, 70)
	button1:SetID(1)
	button1:SetScript("OnClick", function(this, button) MT:BindingButtonOnClick(this, button) end)

	local b1label = button1:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	b1label:SetText(_G.KEY1)
	b1label:SetPoint("BOTTOM", button1, "TOP", 0, 5)

	local button2 = CreateFrame("Button", "MacroToolkitBindButton2", frame, "BackdropTemplate,UIPanelButtonTemplate")
	button2:RegisterForClicks("AnyUp")
	button2:SetNormalFontObject(GameFontHighlightSmall)
	button2:SetDisabledFontObject(GameFontDisable)
	button2:SetHighlightFontObject(GameFontHighlightSmall)
	button2:SetSize(180, 22)
	button2:SetPoint("LEFT", button1, "RIGHT", 5, 0)
	button2:SetID(2)
	button2:SetScript("OnClick", function(this, button) MT:BindingButtonOnClick(this, button) end)
	
	local b2label = button1:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	b2label:SetText(_G.KEY2)
	b2label:SetPoint("BOTTOM", button2, "TOP", 0, 5)
	
	frame.outputtext = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	frame.outputtext:SetPoint("BOTTOM", 0, 125)
	frame.profile = CreateFrame("CheckButton", "MacroToolkitBindingProfile", frame, "BackdropTemplate,UICheckButtonTemplate")
	frame.profile:SetSize(20, 20)
	frame.profile:SetPoint("TOPLEFT", button1, "BOTTOMLEFT", -50, -5)
	frame.profile:SetHitRectInsets(0, -100, 0, 0)
	frame.profile.text:SetFormattedText(" %s%s", _G.HIGHLIGHT_FONT_COLOR_CODE, _G.CHARACTER_SPECIFIC_KEYBINDINGS)
	frame.profile.enabled = true
	frame.profile:SetScript("OnClick",
		function(this)
			if this.enabled then PlaySound(856) --PlaySound("igMainMenuOptionCheckBoxOn")
			else PlaySound(857) end --PlaySound("igMainMenuOptionCheckBoxOff") end
			if frame.bindingsChanged then StaticPopup_Show("MACROTOOLKIT_CONFIRM_LOSE_BINDING_CHANGES")
			else MT:ChangeBindingProfile() end
		end)
	frame.profile:SetScript("OnEnter",
		function(this)
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText(_G.CHARACTER_SPECIFIC_KEYBINDING_TOOLTIP, nil, nil, nil, nil, 1)
		end)
	frame.profile:SetScript("OnLeave", GameTooltip_Hide)

	local cancel = CreateFrame("Button", "MacroToolkitBindingCancel", frame, "BackdropTemplate,UIPanelButtonTemplate")
	cancel:SetText(_G.CANCEL)
	cancel:SetSize(80, 22)
	cancel:SetPoint("BOTTOMRIGHT", -15, 14)
	cancel:SetScript("OnClick",
		function()
			LoadBindings(GetCurrentBindingSet())
			frame.outputtext:SetText("")
			frame.selected = nil
			frame:Hide()
		end)

	local ok = CreateFrame("Button", "MacroToolkitBindingOk", frame, "BackdropTemplate,UIPanelButtonTemplate")
	ok:SetText(_G.OKAY)
	ok:SetSize(80, 22)
	ok:SetPoint("RIGHT", cancel, "LEFT", -5, -0)
	ok:SetScript("OnClick",
		function()
			if frame.profile:GetChecked() then frame.which = MT.CHARACTER_BINDINGS
			else
				frame.which = MT.ACCOUNT_BINDINGS
				if GetCurrentBindingSet() == MT.CHARACTER_BINDINGS then
					if not MT.CONFIRMED_DELETE_CHARACTER_SPECIFIC_BINDINGS then
						StaticPopup_Show("MACROTOOLKIT_CONFIRM_DELETING_CHARACTER_SPECIFIC_BINDINGS")
						return
					end
				end
			end
			SaveBindings(frame.which)
			frame.outputtext:SetText("")
			frame.selected = nil
			frame:Hide()
		end)

	frame.unbindbutton = CreateFrame("Button", "MacroToolkitUnbind", frame, "BackdropTemplate,UIPanelButtonTemplate")
	frame.unbindbutton:SetText(_G.UNBIND)
	frame.unbindbutton:SetSize(120, 22)
	frame.unbindbutton:SetPoint("BOTTOMLEFT", 15, 14)
	frame.unbindbutton:SetScript("OnClick",
		function()
			--PlaySound("igMainMenuOptionCheckBoxOn")
			PlaySound(856)
			local key1, key2 = GetBindingKey(frame.selected)
			if key1 then SetBinding(key1, nil) end
			if key2 then SetBinding(key2, nil) end
			if key1 and frame.keyId == 1 then MT:SetBinding(key1, nil, key1)
				if key2 then SetBinding(key2, frame.selected) end
			else
				if key1 then MT:SetBinding(key1, frame.selected) end
				if key2 then NT:SetBinding(key2, nil, key2) end
			end
			MT:UpdateBindingFrame()
			frame.buttonPressed:UnlockHighlight()
			MT:UpdateUnbindKey()
			frame.outputtext:SetText("")
		end)

	return frame
end

function MT:UnbindKey(keyPressed)
	local oldAction = GetBindingAction(keyPressed)
	local sel = MTB and MTB.selected or ""
	if oldAction ~= "" and oldAction ~= sel then
		local key1, key2 = GetBindingKey(oldAction)
		if (not key1 or key1 == keyPressed) and (not key2 or key2 == keyPressed) then
			local bname = GetBindingText(oldAction, "BINDING_NAME_")
			local ubtext
			if string.find(bname, "CLICK MTSB") then
				local bnum = select(3, string.find(bname, "CLICK MTSB(%d+)"))
				local mte = MT.db.global.extra[tonumber(bnum)]
				if mte then ubtext = MT.db.global.extra[tonumber(bnum)].name
				else ubtext = "" end
			elseif string.find(bname, "MACRO %D") then ubtext = string.gsub(bname, "MACRO ", "")
			else
				local s, e, n = string.find(bname, "MACRO (%d+)")
				if s then ubtext = GetMacroInfo(tonumber(n))
				else ubtext = bname end
			end
			if MTB then MTB.outputtext:SetFormattedText(_G.KEY_UNBOUND_ERROR, ubtext) end
		end
	end
	SetBinding(keyPressed)
end

function MT:BindingFrameOnKeyDown(this, key)
	if GetBindingFromClick(key) == "SCREENSHOT" then
		RunBinding("SCREENSHOT")
		return
	elseif GetBindingFromClick(key) == "TOGGLEGAMEMENU" then
		LoadBindings(GetCurrentBindingSet())
		MTB.outputtext:SetText("")
		MTB:Hide()
		return
	end
	if key == "UNKNOWN" or key == "LeftButton" or key == "RightButton" or
		key == "LSHIFT" or key == "LCTRL" or key == "LALT" or
		key == "RSHIFT" or key == "RCTRL" or key == "RALT" then return
	elseif key == "MiddleButton" then key = "BUTTON3"
	else key = string.upper(key) end
	if IsShiftKeyDown() then key = format("SHIFT-%s", key) end
	if IsControlKeyDown() then key = format("CTRL-%s", key) end
	if IsAltKeyDown() then key = format("ALT-%s", key) end
	local key1, key2 = GetBindingKey(MTB.selected)
	if key1 then SetBinding(key1) end
	if key2 then SetBinding(key2) end
	MTB.outputtext:SetText(_G.KEY_BOUND)
	MT:UnbindKey(key)
	if MTB.keyId == 1 then
		MT:SetBinding(key, MTB.selected, key1)
		if key2 then SetBinding(key2, MTB.selected) end
	else
		if key1 then MT:SetBinding(key1, MTB.selected) end
		MT:SetBinding(key, MTB.selected, key2)
	end
	MTB.bindingsChanged = true
	MT:UpdateBindingFrame()
end

function MT:BindingButtonOnClick(this, button)
	--PlaySound("igMainMenuOptionCheckBoxOn")
	PlaySound(856)
	if button == "LeftButton" or button == "RightButton" then
		if MTB.buttonPressed == this then MTB.outputtext:SetText("")
		else
			MTB.buttonPressed = this
			MTB.keyId = this:GetID()
			MTB.outputtext:SetFormattedText(_G.BIND_KEY_TO_COMMAND, MTB.mname)
		end
		MT:UpdateBindingFrame()
		return
	end
	MT:BindingFrameOnKeyDown(this, button)
	MT:UpdateUnbindKey()
end

function MT:SetBinding(key, selectedBinding, oldKey)
	if SetBinding(key, selectedBinding) then return
	else
		if oldKey then SetBinding(oldKey, selectedBinding) end
		MTB.outputtext:SetText(_G.KEYBINDINGFRAME_MOUSEWHEEL_ERROR)
	end
end

function MT:UpdateUnbindKey()
	if MTB.buttonPressed then
		if MTB.buttonPressed.commandName then MTB.unbindbutton:Enable()
		else MTB.unbindbutton:Disable() end
	else MTB.unbindbutton:Disable() end
end

function MT:ChangeBindingProfile()
	if MTB.profile:GetChecked() then
		LoadBindings(MT.CHARACTER_BINDINGS)
		MTB.title:SetFormattedText(_G.CHARACTER_KEY_BINDINGS, UnitName("player"))
	else
		LoadBindings(MT.ACCOUNT_BINDINGS)
		MTB.title:SetText(_G.KEY_BINDINGS)
	end
	MTB.outputtext:SetText("")
	MT:UpdateBindingFrame()
end

function MT:UpdateBindingFrame()
	local name = MTB.mname
	local commandName = (MacroToolkitFrame.selectedMacro > 1000) and format("CLICK MTSB%d:LeftButton", MacroToolkitFrame.selectedMacro) or format("MACRO %s", name)
	MTB.macroname:SetText(name)
	local b1, b2 = MacroToolkitBindButton1, MacroToolkitBindButton2
	local k1, k2 = GetBindingKey(commandName)
	if k1 then
		b1:SetText(GetBindingText(k1, "KEY_"))
		b1.commandName = commandName
		b1:SetAlpha(1)
	else
		b1:SetFormattedText("%s%s", _G.NORMAL_FONT_COLOR_CODE, _G.NOT_BOUND)
		b1.commandName = nil
		b1:SetAlpha(0.8)
	end
	if k2 then
		b2:SetText(GetBindingText(k2, "KEY_"))
		b2.commandName = commandName
		b2:SetAlpha(1)
	else
		b2:SetFormattedText("%s%s", _G.NORMAL_FONT_COLOR_CODE, _G.NOT_BOUND)
		b2.commandName = nil
		b2:SetAlpha(0.8)
	end
	b1:UnlockHighlight()
	b2:UnlockHighlight()
	if MTB.selected == commandName then
		if MTB.keyId == 1 then b1:LockHighlight()
		elseif MTB.keyId == 2 then b2:LockHighlight() end
	end
	MT:UpdateUnbindKey()
end
