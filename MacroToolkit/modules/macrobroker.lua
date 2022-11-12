--****************************************************************
--* Code based on the abandoned addon -- Macro Broker by Tuhljin *
--****************************************************************

local MT = MacroToolkit
local assert, type, strlower, select, strmatch, format, tonumber, strsub, strlen, strtrim = assert, type, strlower, select, strmatch, format, tonumber, strsub, strlen, strtrim
local ipairs, error, pcall, loadstring, tinsert = ipairs, error, pcall, loadstring, tinsert
local GetSpellInfo, GetSpellLink, GetItemInfo, GetItemIcon, GetSpellTexture = GetSpellInfo, GetSpellLink, GetItemInfo, GetItemIcon, GetSpellTexture
local GetInventoryItemLink, GetInventoryItemTexture = GetInventoryItemLink, GetInventoryItemTexture
local SecureCmdOptionParse, CreateFrame = SecureCmdOptionParse, CreateFrame
local _G = _G
local L = MT.L
 
-- GLOBALS: DEFAULT_CHAT_FRAME UIParent ChatEdit_SendText

function MT:IsSecureCmd(slash, arg)
	local tradeskills, secure = {2018, 2108, 2259, 2550, 2656, 2842, 3273, 3908, 4036, 7411, 25229, 45357, 53428}, false
    slash = strlower(slash)
	local noslash = strmatch(slash, format("%s(.+)", MT.slash))
	if arg and MT:IsCast(noslash) then
    -- Although it is normally considered a secure command, /cast can safely be used with tradeskill "spells":
		if not MT.tradeskills then
			MT.tradeskills = {}
			for _, s in ipairs(tradeskills) do local n = GetSpellInfo(s) tinsert(MT.tradeskills, n) end
		end
		arg = SecureCmdOptionParse(arg)
		if arg then
			arg = strtrim(strlower(arg))
			secure = true
			for i, v in ipairs(MT.tradeskills) do
				if arg == strlower(v) then
					secure = false
					break
				end
			end
		else return end
	elseif IsSecureCmd(slash) then secure = true end
	return secure
end

local fauxChatFrame_AddMessage
function MT:fauxChatFrame()
	if not fauxChatFrame_AddMessage then
		fauxChatFrame_AddMessage = function(self, text, ...)
			if text == _G.HELP_TEXT_SIMPLE then self.UnrecognizedCmd = true end
			if self.ShowMessages then DEFAULT_CHAT_FRAME:AddMessage(text, ...) end
		end
    end
    return {AddMessage = fauxChatFrame_AddMessage}
end

local runbox
function MT:Execute(command, parse)
    local editbox = DEFAULT_CHAT_FRAME.editBox
    local slash = strmatch(command, format("^(%s[^%%s]+)", MT.slash))
    if slash and MT:IsSecureCmd(slash, strsub(command, slash:len() + 2)) then return false, "secure" end
	if not parse then
		if not runbox then runbox = CreateFrame("EditBox", "MacroToolkit_EditBox", UIParent, "BackdropTemplate,MacroToolkit_EditBoxTemplate") end
		runbox.chatFrame.UnrecognizedCmd = nil
		runbox.chatFrame.ShowMessages = not not showHelp  -- "not not" to make sure it's a boolean
		runbox:SetAttribute("chatType", editbox:GetAttribute("chatType"))
		runbox:SetText(command)
		ChatEdit_SendText(runbox)
		if runbox.chatFrame.UnrecognizedCmd then return false, "unrecognised" end
	end
    return true
end

function MT:Eval(msg)
    if msg and msg ~= "" then
		local cmd = SecureCmdOptionParse(msg)
		if cmd then
			local success, reason = MT:Execute(cmd)
			if not success and reason == "secure" then DEFAULT_CHAT_FRAME:AddMessage(MT.L["Cannot execute secure commands"], 1, 0.15, 0.15) end
		end
	end
end

local function chatprint(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end

function MT:RunCommands(parse, macrotext)
	local slash, success, reason
	for slash in gmatch(macrotext or "", "(/%w+[^\n]+)") do
		if slash then 
			slash = strlower(slash)
			if MT:IsStopMacro(strmatch(slash, format("%s(.+)", MT.slash))) then if SecureCmdOptionParse(line) then return end
			else
				if strlen(slash) > 255 then slash = strsub(line, 1, 255) end
				success, reason = MT:Execute(slash, parse)
				if not success then return reason, slash end
			end
		end
	end
end

local function onclick(name)
	local macrotext = GetMacroBody(GetMacroIndexByName(name))
	if macrotext then MT:RunCommands(false, macrotext) end
end

function MT:CreateBrokerObject(name, label)
	local obj = MT.LDB:GetDataObjectByName(name)
	if not obj then obj = MT.LDB:NewDataObject(name, {type = "data source", text = label, label = label}) end
	if obj then
		obj.OnClick = function() onclick(label) end
		obj.OnLeave = GameTooltip_Hide
		obj.OnEnter = function (this)
			local text, macrotext = _G.MACRO
			if this.text then if type(this.text) == "table" then text = this.text:GetText() end end
			GameTooltip:SetOwner(this, "ANCHOR_LEFT")
			GameTooltip:SetText("Macro Toolkit")
			if text ~= _G.MACRO then macrotext = GetMacroBody(GetMacroIndexByName(text)) end
			if macrotext then
				for slash in gmatch(macrotext or "", "(/%w+[^\n]+)") do GameTooltip:AddLine(format("|cff66b2ff%s|r", slash)) end
			else GameTooltip:AddLine(format("|cff66b2ff%s|r", text)) end
			GameTooltip:Show()
		end
	end
end

function MT:FindBrokerName(label)
	local name
	for n, b in pairs(MT.db.char.brokers) do
		if b.label == label then
			name = n
			break
		end
	end
	return name
end

local function brokeradd()
	if MacroToolkitFrame.textChanged then
		MT:SaveMacro()
		MT:MacroFrameUpdate()
		if not MacroToolkitFrame.brokerok then return end
	end
	local name = MacroToolkitSelMacroName:GetText()
	if not name then return end
	local n = format("MTK %s", name)
	MT.db.char.brokers[n] = {label = name}
	MT:CreateBrokerObject(n, name)
	GameTooltip_Hide()
	MT:MacroFrameUpdate()
end

local function brokerremove()
	local name = MT:FindBrokerName(MacroToolkitSelMacroName:GetText())
	if name then
		MT.db.char.brokers[name] = nil
		MT:MacroFrameUpdate()
	end
end

function MT:BrokerAdd()
	local b = MacroToolkitBrokerButton
	b:SetNormalTexture("Interface\\Buttons\\UI-AttributeButton-Encourage-Up")
	b:SetPushedTexture("Interface\\Buttons\\UI-AttributeButton-Encourage-Down")
	b:SetHighlightTexture("Interface\\Buttons\\UI-AttributeButton-Encourage-Hilight")
	b:SetScript("OnClick", brokeradd)
	b:SetScript("OnEnter", 
		function(this)
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Add broker"])
			GameTooltip:AddLine(format("|cffffffff%s|r", L["Requires a UI reload to take effect"]))
			GameTooltip:Show()
		end)
	b:Show()
end

function MT:BrokerRemove()
	local b = MacroToolkitBrokerButton
	b:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
	b:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
	b:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
	b:SetScript("OnClick", brokerremove)
	b:SetScript("OnEnter", 
		function(this)
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Remove broker"])
			GameTooltip:AddLine(format("|cffffffff%s|r", L["Requires a UI reload to take effect"]))
			GameTooltip:Show()
		end)
	b:Show()
end
