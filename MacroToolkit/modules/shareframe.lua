local MT = MacroToolkit
local L = MT.L
local string, format, strsplit = string, format, strsplit
local StaticPopup_Show = StaticPopup_Show
local CreateFrame = CreateFrame

function MT:CreateSharePopup()
	local frame = CreateFrame("Frame", "MacroToolkitSharePopup", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetFrameStrata("DIALOG")
	frame:EnableKeyboard(true)
	frame:EnableMouse(true)
	if MT.db.profile.scale then frame:SetScale(MT.db.profile.scale) end
	frame:SetSize(320, 206)
	frame:SetPoint("TOP", 0 , -135)
	frame:SetToplevel(true)
	frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile = "true", tileSize = 32, edgeSize = 32, insets = {left = 11, right = 12, top = 12, bottom = 11}})
	--[[
	frame:SetScript("OnKeyDown",
		function(this, key)
			if GetBindingFromClick(key) == "TOGGLEGAMEMENU" then this:Hide()
			elseif GetBindingFromClick(key) == "SCREENSHOT" then RunBinding("SCREENSHOT") end
		end)
	]]--
	frame:Hide()

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	frame.title:SetPoint("TOP", 0, -16)
	
	local mtuser = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate")
	mtuser.text:SetText(L["specific Macro Toolkit user"])
	mtuser:SetChecked(true)
	mtuser.type = "user"
	mtuser:SetHitRectInsets(0, -100, 0, 0)
	mtuser:SetPoint("TOPLEFT", 70, -64)
		
	local mtmuser = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate")
	mtmuser.text:SetText(L["multiple Macro Toolkit users"])
	mtmuser:SetPoint("TOPLEFT", mtuser, "BOTTOMLEFT", 0, -5)
	mtmuser.type = "multi"
	mtmuser:SetHitRectInsets(0, -100, 0, 0)
	
	local chan = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate")
	chan.text:SetText(L["chat channel"])
	chan:SetPoint("TOPLEFT", mtmuser, "BOTTOMLEFT", 0, -5)
	chan.type = "chan"
	chan:SetHitRectInsets(0, -100, 0, 0)
		
	local guild = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate")
	guild.text:SetText(_G.GUILD)
	guild:SetPoint("TOPLEFT", chan, "BOTTOMLEFT", 0, -15)
	guild.type = "guild"
	guild:SetHitRectInsets(0, -100, 0, 0)
	guild:Hide()
	
	local raid = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate")
	raid.text:SetText(_G.RAID)
	raid:SetPoint("TOPLEFT", guild, "BOTTOMLEFT", 0, -5)
	raid.type = "raid"
	raid:SetChecked(true)
	raid:SetHitRectInsets(0, -100, 0, 0)
	raid:Hide()
	
	local party = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate")
	party.text:SetText(_G.PARTY)
	party:SetPoint("TOPLEFT", raid, "BOTTOMLEFT", 0, -5)
	party.type = "party"
	party:SetHitRectInsets(0, -100, 0, 0)
	party:Hide()
	
	local playerframe = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	playerframe:SetSize(280, 16)
	playerframe:SetPoint("LEFT", 60, -40)
	playerframe:Hide()

	local playerlabel = playerframe:CreateFontString("ARTWORK", nil, "GameFontHighlightSmall")
	playerlabel:SetText(format("%s:", _G.PLAYER))
	playerlabel:SetPoint("LEFT")
	
	local function sharemacro()
		MT:ShareMacro(frame.sharetype, frame.channel, frame.player)
		frame:Hide()
	end
	
	local player = CreateFrame("EditBox", "MacroToolkitShareEdit", playerframe, "InputBoxTemplate")
	player:SetSize(100, 16)
	player:SetPoint("LEFT", playerlabel, "RIGHT", 10, 0)
	player:SetScript("OnEscapePressed", function() frame:Hide() end)
	player:SetScript("OnTextChanged", function(this, userinput) frame.player = this:GetText() end)
	player:SetScript("OnEnterPressed", sharemacro)

	local function sharewithonclick(this)
		frame.sharetype = this.type
		if this.type == "chan" then
			mtuser:SetChecked(false)
			mtmuser:SetChecked(false)
			chan:SetChecked(true)
			guild:Show()
			raid:Show()
			party:Show()
			playerframe:Hide()
			frame:SetHeight(241)
		elseif this.type == "user" then
			chan:SetChecked(false)
			mtuser:SetChecked(true)
			mtmuser:SetChecked(false)
			guild:Hide()
			raid:Hide()
			party:Hide()
			playerframe:Show()
			frame:SetHeight(206)
		elseif this.type == "multi" then
			chan:SetChecked(false)
			mtuser:SetChecked(false)
			mtmuser:SetChecked(true)
			guild:Show()
			raid:Show()
			party:Show()
			playerframe:Hide()
			frame:SetHeight(241)
		end
	end
	
	mtuser:SetScript("OnClick", sharewithonclick)
	mtmuser:SetScript("OnClick", sharewithonclick)
	chan:SetScript("OnClick", sharewithonclick)
	
	local function channelonclick(this)
		frame.channel = this.type
		if this.type == "guild" then
			guild:SetChecked(true)
			raid:SetChecked(false)
			party:SetChecked(false)
		elseif this.type == "raid" then
			raid:SetChecked(true)
			guild:SetChecked(false)
			party:SetChecked(false)
		else
			party:SetChecked(true)
			guild:SetChecked(false)
			raid:SetChecked(false)
		end
	end
	
	guild:SetScript("OnClick", channelonclick)
	raid:SetScript("OnClick", channelonclick)
	party:SetScript("OnClick", channelonclick)
	
	local buttons = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	buttons:SetSize(170, 22)
	buttons:SetPoint("BOTTOM", 0, 16)
	
	local ok = CreateFrame("Button", "MacroToolkitShareOK", buttons, "UIPanelButtonTemplate")
	ok:SetSize(80, 22)
	ok:SetText(_G.SHARE_QUEST_ABBREV)
	ok:SetPoint("LEFT")
	ok:SetScript("OnClick", sharemacro)

	local cancel = CreateFrame("Button", "MacroToolkitShareCancel", buttons, "UIPanelButtonTemplate")
	cancel:SetSize(80, 22)
	cancel:SetText(_G.CANCEL)
	cancel:SetPoint("RIGHT")
	cancel:SetScript("OnClick", function() frame:Hide() end)

	frame:SetScript("OnShow",
		function()
			sharewithonclick(mtuser)
			channelonclick(raid)
			frame.player = nil
			MacroToolkitFrame:Hide()
			MT:Skin(frame)
		end)
	frame:SetScript("OnHide", function() MacroToolkitFrame:Show() end)

	return frame
end

function MT:ShareMacro(sharetype, channel, player)
	local name, texture, body
	if MacroToolkitFrame.selectedMacro > 1000 then
		local em = MT.db.global.extra[tostring(MacroToolkitFrame.selectedMacro)]
		name, texture, body = em.name, em.texture, em.body
	else name, texture, body = GetMacroInfo(MacroToolkitFrame.selectedMacro) end
	texture = string.gsub(string.upper(texture), "INTERFACE\\ICONS\\", "")
	local details = format("%s%s%s%s%s", name, string.char(9), texture, string.char(9), body)
	if sharetype == "user" and player then
		MT.AC:SendCommMessage("MacroToolkit", details, "WHISPER", player)
	elseif sharetype == "multi" then
		MT.AC:SendCommMessage("MacroToolkit", details, string.upper(channel))
	elseif sharetype == "chan" then
		local lines = {strsplit("\n", body)}
		for _, l in ipairs(lines) do ChatThrottleLib:SendChatMessage("NORMAL", "MacroToolkit", l, string.upper(channel)) end
	end
end

local function addmacro(name, texture, body)
	local gm, cm = GetNumMacros()
	local em = MT:CountExtra()
	local cs, es
	if gm == _G.MAX_ACCOUNT_MACROS then
		if cm == _G.MAX_CHARACTER_MACROS then
			if em == _G.MAX_ACCOUNT_MACROS then
				StaticPopupDialogs.MACROTOOLKIT_ALERT.text = L["You have no more room for macros!"]
				StaticPopupDialogs.MACROTOOLKIT_ALERT.showAlert = 1
				StaticPopup_Show("MACROTOOLKIT_ALERT")
				return
			else es = true end
		else cs = true end
	end
	if es then MT.db.global.extra[1000 + es + 1] = {name = name, texture = texture, body = body}
	else CreateMacro(name, texture, body, cs) end
	MT:MacroFrameUpdate()
	StaticPopupDialogs.MACROTOOLKIT_ALERT.text = L["Macro added"]
	StaticPopupDialogs.MACROTOOLKIT_ALERT.showAlert = nil
	StaticPopup_Show("MACROTOOLKIT_ALERT")
end

function MT:ReceiveMacro(prefix, msg, dist, sender)
	if prefix == "MacroToolkit" then
		local name, texture, body = strsplit(string.char(9), msg)
		StaticPopupDialogs.MACROTOOLKIT_DELETEBACKUP.text = format(L["%s is trying to send you a macro. Accept?"], sender)
		StaticPopupDialogs.MACROTOOLKIT_DELETEBACKUP.OnAccept = function() addmacro(name, texture, body) end
		StaticPopup_Show("MACROTOOLKIT_DELETEBACKUP")
	end
end
