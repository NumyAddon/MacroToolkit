local MT = MacroToolkit
local MTF
local L, _G = MT.L, _G
local LSM = MT.LS("LibSharedMedia-3.0")
local format, string, table, date, ipairs, pairs, select, tostring, strsplit, tonumber, collectgarbage = format, string, table, date, ipairs, pairs, select, tostring, strsplit, tonumber, collectgarbage
local max, mod, strlenutf8, floor, print, assert, loadstring, type, tinsert = max, mod, strlenutf8, floor, print, assert, loadstring, type, tinsert
local GetNumMacros, GetMacroInfo, EditMacro, DeleteMacro, CreateMacro, GetMacroBody, PickupMacro = GetNumMacros, GetMacroInfo, EditMacro, DeleteMacro, CreateMacro, GetMacroBody, PickupMacro
local IsPassiveSpell, GetItemInfo, GetItemSpell, IsModifiedClick, GetSpellBookItemName, GetBindingKey = IsPassiveSpell, GetItemInfo, GetItemSpell, IsModifiedClick, GetSpellBookItemName, GetBindingKey
local UnitName, SetBinding, SecureCmdOptionParse, GetContainerItemInfo, PickupContainerItem = UnitName, SetBinding, SecureCmdOptionParse, GetContainerItemInfo, PickupContainerItem
local BreakUpLargeNumbers, DeleteCursorItem, GetContainerNumSlots, UnitAura, GetNumGroupMembers = BreakUpLargeNumbers, DeleteCursorItem, GetContainerNumSlots, UnitAura, GetNumGroupMembers
local UseContainerItem, SetCVar, SetRaidTarget, PlaySound, HideUIPanel = UseContainerItem, SetCVar, SetRaidTarget, PlaySound, HideUIPanel
local PanelTemplates_GetSelectedTab, StaticPopup_Show, SpellBook_GetSpellBookSlot = PanelTemplates_GetSelectedTab, StaticPopup_Show, SpellBook_GetSpellBookSlot
local CreateFrame, GetBindingText, InCombatLockdown, CursorHasMacro, GetCursorInfo, ClearCursor = CreateFrame, GetBindingText, InCombatLockdown, CursorHasMacro, GetCursorInfo, ClearCursor
local exFormat = "%s%s%s [btn:1]%s LeftButton 1;[btn:2]%s RightButton 1;[btn:3]%s MiddleButton 1;[btn:4]%s Button4 1;[btn:5]%s Button5 1"

-- GLOBALS: ChatEdit_InsertLink StaticPopupDialogs SpellBookFrame MacroToolkitText MacroToolkitEnterText MacroToolkitFauxText MacroToolkitSelMacroName MacroToolkitSelBg MacroToolkitDelete
-- GLOBALS: MacroToolkitExtend MacroToolkitShorten MacroToolkitSelMacroButton MacroToolkitLimit MacroToolkitEdit MacroToolkitCopy GameTooltip MacroToolkitBind MacroToolkitConditions
-- GLOBALS: MacroToolkitShare MacroToolkitClear MacroToolkitBackup MacroToolkitBrokerIcon MacroToolkitNew MacroToolkitCSelMacroName MacroToolkitSelMacroButton.Icon MacroToolkitCText
-- GLOBALS: MacroToolkitCFauxText MacroToolkitCSelMacroButton MacroToolkitCSelMacroButton.Icon MacroToolkitBrokerButton MacroToolkitCopyButton MacroToolkitDB MacroToolkitButton1Name
-- GLOBALS: MacroToolkitErrors MacroToolkitErrorIcon DEFAULT_CHAT_FRAME SendChatMessage SlashCmdList MacroFrame MacroDeleteButton TradeSkillLinkButton MacroToolkitFauxScrollFrame
-- GLOBALS: MacroToolkitErrorBg MacroToolkitErrorScrollFrame ChatEdit_GetActiveWindow MacroFrameText ShowCloak ShowingCloak ShowHelm ShowingHelm CanEjectPassengerFromSeat
-- GLOBALS: EjectPassengerFromSeat UIErrorsFrame SetMapToCurrentZone VehicleExit GetPlayerMapPosition SummonRandomCritter C_MountJournal ToggleDropDownMenu TradeSkillLinkDropDown
-- GLOBALS: GetTradeSkillListLink LoadAddOn ShowMacroFrame IsAddOnLoaded

local NUM_MACROS_PER_ROW = 6

MT.Spells = {}
MT.orphans = {}
MT.defaults = {
	profile = {
		override = false,
		stringcolour = "ffffffff", emotecolour = "ffeedd82", scriptcolour = "ff696969",
		commandcolour = "ff00bfff", spellcolour = "ff9932cc", targetcolour = "ffffd700",
		conditioncolour = "ff8b5a2b", defaultcolour = "ffffffff", errorcolour = "ffff0000",
		itemcolour = "fff08080", mtcolour = "ffcd2ea9", seqcolour ="ff006600", comcolour="ff00aa00",
		usecolours = true, unknown = false, replacemt = true, doublewide = false, broker = false,
		viscondtions = true, visoptionsbutton = true, viscustom = true, hidepopup = false,
		visaddscript = true, visaddslot = true, viscrest = false,
		visbackup = true, visclear = true, visshare = true, useiconlib = true,
		visextend = true, viserrors = true, vismacrobox = true,
		visshorten = true, visbind = true, visdrake = false,
		--escape = true,
		confirmdelete = true,
		x = (UIParent:GetWidth() - 638) / 2,
		y = (UIParent:GetHeight() - 424) / 2,
		height = 424,
		dynamicicon = true, abilityicons = true, achicons = true,
		invicons = true, itemicons = true, miscicons = true, spellicons = true,
		fonts = {edfont = "Friz Quadrata TT", edsize = 10, errfont = "Friz Quadrata TT", errsize = 10,
			mfont = "Friz Quadrata TT", mifont = "Friz Quadrata TT", misize = 10},
	},
	global = {custom = {}, extended = {}, extra = {}, allcharmacros = false},
	char = {extended = {}, wodupgrade = false, brokers = {}},
}

local function showtoolkit()
	local ignore = MTF:IsShown()
	if MT.MTSF then ignore = ignore or MT.MTSF:IsShown() end
	if MT.MTBF then ignore = ignore or MT.MTBF:IsShown() end
	if not ignore then MTF:Show() end
end

local function getExMacroIndex(ext)
	for mi = 1, _G.MAX_ACCOUNT_MACROS + _G.MAX_CHARACTER_MACROS do
		local name, icon, body = GetMacroInfo(mi)
		if name then
			local index = select(3, string.find(body, "MTSB(%d+)"))
			if (index or 0) == ext then return mi end
		end
	end
end

function MT:GetExMacroIndex(ext) return getExMacroIndex(ext) end

local function cleanMacros()
	local delmacros = {}
	local dm = 1
	if not MT.db.char.macros then return end
	for i, m in pairs(MT.db.char.macros) do
		if string.find(m.body, "MacroToolkitSecureButton") then
			delmacros[dm] = i
			dm = dm + 1
		end
	end
	for a = 1, dm do MT.db.char.macros[a] = nil end
end

local function countTables(tablein)
	local ts = 0
	for t, e in pairs(tablein) do ts = ts + 1 end
	return ts
end

function MT:eventHandler(this, event, arg1, ...)
	if event == "ADDON_LOADED" then
		if arg1 == "MacroToolkit" then
			_G.SLASH_MACROTOOLKIT_CMD1 = format("%smac", MT.slash)
			_G.SLASH_MACROTOOLKIT_CMD2 = format("%smtoolkit", MT.slash)
			_G.SLASH_MACROTOOLKIT_CMD3 = format("%smacrotoolkit", MT.slash)
			SlashCmdList["MACROTOOLKIT_CMD"] = showtoolkit
			for i, s in ipairs(MT.scripts) do
				_G[format("SLASH_MACROTOOLKIT_%s%d", string.upper(s[2]), 1)] = format("%s%s", MT.slash, s[2])
				SlashCmdList[format("MACROTOOLKIT_%s", string.upper(s[2]))] = function(input) MT:DoMTMacroCommand(s[2], input) end
			end
			MT.db = MT.LS("AceDB-3.0"):New("MacroToolkitDB", MT.defaults, "profile")
			if not IsAddOnLoaded("Blizzard_MacroUI") then LoadAddOn("Blizzard_MacroUI") end
			if not MT.db.global.custom then MT.db.global.custom = {} end
			if not MT.db.global.extra then MT.db.global.extra = {} end
			for _, c in ipairs(MT.db.global.custom) do
				_G[format("SLASH_MACROTOOLKIT_CUSTOM_%s%d", string.upper(c.n), 1)] = format("%s%s", MT.slash, c.n)
				SlashCmdList[format("MACROTOOLKIT_CUSTOM_%s", string.upper(c.n))] = function(input) MT:DoCustomCommand(c.s, input) end
			end
		elseif arg1 == "Blizzard_MacroUI" then
			if MT.db.profile.override then
				MT.showmacroframe = ShowMacroFrame
				ShowMacroFrame = showtoolkit
				MT.origMTText = MacroFrameText
			end
			local mtbutton = CreateFrame("Button", "MacroToolkitOpen", MacroFrame, "UIPanelButtonTemplate")
			mtbutton:SetText(L["Toolkit"])
			mtbutton:SetSize(94, 22)
			mtbutton:SetPoint("LEFT", MacroDeleteButton, "RIGHT")
			mtbutton:SetScript("OnClick",
				function()
					HideUIPanel(MacroFrame)
					MTF:Show()
				end)
		elseif arg1 == "Blizzard_TradeSkillUI" then
			--override code to handle tradeskill links
			local function btsui_onclick()
				local activeEditBox =  ChatEdit_GetActiveWindow()
				local activeMacroFrameText
				if MacroFrameText and MacroFrameText:IsShown() and MacroFrameText:HasFocus() then
					activeMacroFrameText = MacroFrameText
				elseif MacroToolkitText:IsShown() and MacroToolkitText:HasFocus() then
					activeMacroFrameText = MacroToolkitText
				end
				if activeMacroFrameText then
					--local link = GetTradeSkillListLink()
					local link = C_TradeSkillUI.GetTradeSkillListLink()
					local text = format("%s%s", activeMacroFrameText:GetText(), link)
					if 255 >= strlenutf8(text) then activeMacroFrameText:Insert(link) end
				elseif activeEditBox then
					--local link = GetTradeSkillListLink()
					-- ticket 134 - fix by picro
					local link = C_TradeSkillUI.GetTradeSkillListLink()
					if not ChatEdit_InsertLink(link) then assert(activeEditBox:GetName(), "Failed to add tradeskill link") end
				--else ToggleDropDownMenu(1, nil, TradeSkillLinkDropDown, "TradeSkillLinkFrame", 25, 25) end
				else ToggleDropDownMenu(1, nil, TradeSkillFrame.LinkToDropDown, TradeSkillFrame.LinkToButton, 25, 25) end
				--PlaySound("igMainMenuOptionCheckBoxOn")
				PlaySound(856)
			end
			--TradeSkillLinkButton:SetScript("OnClick", btsui_onclick)
			TradeSkillFrame.LinkToButton:SetScript("OnClick", btsui_onclick)
		end
	elseif event == "PLAYER_LOGIN" then
		MT:BuildCommandList()
		MT:CreateOptions()
		MTF = MT:CreateMTFrame()
		MT:SetMacros(true)
		MT:CreateSecureFrames()
		--upgrade extended macro variables
		MT:CorrectExtendedMacros()

		if #MT.db.global.extra > 0 then
			for i, e in pairs(MT.db.global.extra) do
				if i < 1000 then
					--upgrade macro numbering for WoD
					MT.global.extra[tostring(tonumber(i) * 10)] = MT.global.extra[i]
					MT.global.extra[i] = nil
				end
			end
		end

		if MT.db.global.extended then
			if not type(MT.db.global.extended["1"]) == "table" then
				for i, e in pairs(MT.db.global.extended) do
					local index = getExMacroIndex(i)
					local name, icon = GetMacroInfo(index)
					MT.db.global.extended[i] = {name = name, icon = string.gsub(string.upper(icon), "INTERFACE\\ICONS\\", ""), body = e}
				end
				if MacroToolkitDB.char then
					for ch, chd in pairs(MacroToolkitDB.char) do
						if chd.extended then
							for i, e in pairs(chd.extended) do MacroToolkitDB.char[ch].extended[i] = {name = "", icon = "", body = e} end
						end
					end
				end
			end
		end
		if MT.db.char.extended then
			if not type(MT.db.char.extended["1"]) == "table" then
				for i, e in pairs(MT.db.char.extended) do
					local index = getExMacroIndex(i)
					local name, icon = GetMacroInfo(index)
					MT.db.char.extended[i].name = name
					MT.db.char.extended[i].icon = string.gsub(string.upper(icon), "INTERFACE\\ICONS\\", "")
				end
			end
		end
		if MT.db.global.allcharmacros then
			local numMacros = select(2, GetNumMacros())
			MT.db.char.macros = {}
			for m = _G.MAX_ACCOUNT_MACROS + 1, _G.MAX_ACCOUNT_MACROS + numMacros do
				local name, texture, body = GetMacroInfo(m)
				if not string.find(body, "MTSB") then
					MT.db.char.macros[m] = {name = name, icon = string.gsub(string.upper(texture), "INTERFACE\\ICONS\\", ""), body = body}
				end
			end
		end
		--if #MT.db.global.extended > 0 then
		if countTables(MT.db.global.extended) > 0 then
			for i, e in pairs(MT.db.global.extended) do
				_G[format("MTSB%d", i)]:SetAttribute("macrotext", e.body)
				_G[format("MTSB%d", i)]:SetAttribute("dynamic", MT:IsDynamic(i))
				MT:UpdateIcon(_G[format("MTSB%d", i)])
			end
		end
		--if #MT.db.char.extended > 0 then
		if countTables(MT.db.char.extended) > 0 then
			for i, e in pairs(MT.db.char.extended) do
				_G[format("MTSB%d", i)]:SetAttribute("macrotext", e.body)
				_G[format("MTSB%d", i)]:SetAttribute("dynamic", MT:IsDynamic(i))
				MT:UpdateIcon(_G[format("MTSB%d", i)])
				--check for orphaned macro
				local found = false
				for om = _G.MAX_ACCOUNT_MACROS + 1, _G.MAX_CHARACTER_MACROS + _G.MAX_ACCOUNT_MACROS do
					local n, t, b = GetMacroInfo(om)
					--local index = select(3, string.find(b, "MTSB(%d+)"))
					if n then if string.find(b, format("MTSB%d", i)) then found = true end end
				end
				if not found then tinsert(MT.orphans, i) end
			end
			--[[
			if #MT.orphans > 0 then
				local d = StaticPopupDialogs.MACROTOOLKIT_DELETEBACKUP
				d.text = format(L["Macro Toolkit has found %d orphaned macros. Restore?"], #MT.orphans)
				d.OnAccept = function()
					for _, m in ipairs(MT.orphans) do
						DEFAULT_CHAT_FRAME:AddMessage(format("|cff99cce6%s:|r%s", L["Restoring macro"], MT.db.char.extended[tostring(m)].name))
						MT:ExtendMacro(false, MT.db.char.extended[tostring(m)].body, tostring(m), true)
					end
				end
				d.OnCancel = function() for _, m in ipairs(MT.orphans) do MT.db.char.extended[tostring(m)] = nil end end
				StaticPopup_Show("MACROTOOLKIT_DELETEBACKUP")
			end
			--]]
		end
		--if #MT.db.global.extra > 0 then
		if countTables(MT.db.global.extra) > 0 then
			for i, e in pairs(MT.db.global.extra) do

				_G[format("MTSB%d", i)]:SetAttribute("macrotext", e.body)
			end
		end
		if not MT.db.profile.usecolours then MacroToolkitFauxScrollFrame:Hide() end
		if not MT.db.profile.viserrors then
			MacroToolkitErrorBg:Hide()
			MacroToolkitErrorScrollFrame:Hide()
		end
		MTF:Hide()
		--if IsAddOnLoaded("ElvUI") then MT:LoadElvSkin() end
		MT.AC = MT.LS("AceComm-3.0")
		MT.AC:RegisterComm("MacroToolkit", function(...) MT:ReceiveMacro(...) end)
		if countTables(MT.db.char.brokers) > 0 then
			for b, d in pairs(MT.db.char.brokers) do MT:CreateBrokerObject(b, d.label) end
		end

		if MacroToolkit.db.profile.useiconlib == true then
			--Try loading the data addon
			loaded, reason = LoadAddOn("MacroToolkitIcons")

			if not loaded then
				--load failed
				MacroToolkit.usingiconlib = nil
			else
				MacroToolkit.usingiconlib = true
			end
		end
	end
end

function MT:GetBackups()
	local tab = PanelTemplates_GetSelectedTab(MTF)
	local var = (tab == 1) and "global" or "char"
	local backup = (tab == 3) and MT.db.global.ebackups or MT.db[var].backups
	local blist = {}
	for _, d in ipairs(backup) do blist[d.d] = d.d end
	return blist
end

function MT:ClearAllMacros()
	local tab = PanelTemplates_GetSelectedTab(MTF)
	local mstart = (tab == 1) and 1 or (_G.MAX_ACCOUNT_MACROS + 1)
	local mend = (tab == 1) and _G.MAX_ACCOUNT_MACROS or (_G.MAX_ACCOUNT_MACROS + _G.MAX_CHARACTER_MACROS)
	if tab < 3 then
		for m = mend, mstart, -1 do
			DeleteMacro(m)
			MT:MacroFrameUpdate()
			_G[format("MTSB%d", m)]:SetAttribute("macrotext", "")
			_G[format("MTSB%d", m)]:SetAttribute("dynamic", false)
		end
		local var = (tab == 1) and "global" or "char"
		MT.db[var].extended = {}
	else
		MT.db.global.extra = {}
		MT:MacroFrameUpdate()
	end
	MT:HideDetails()
	MacroToolkitText:SetText("")
	MacroToolkitFauxText:SetText("")
	MTF.selectedMacro = nil
	MacroToolkitSelMacroName:SetText("")
end

function MT:HexToRGB(hex)
    local ahex, rhex, ghex, bhex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6), string.sub(hex, 7, 8)
	return tonumber(rhex, 16) / 255, tonumber(ghex, 16) / 255, tonumber(bhex, 16) / 255, tonumber(ahex, 16) / 255
end

function MT:RGBToHex(r, g, b, a)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	a = a <= 1 and a >= 0 and a or 0
	return string.format("%.2x%.2x%.2x%.2x", a*255, r*255, g*255, b*255)
end

function MT:DoCustomCommand(luatext, input)
	local a1, a2, a3, a4 = strsplit(" ", input)
	if not a1 then a1, a2, a3, a4 = strsplit(",", input) end
	local script = string.format("local arg1, arg2, arg3, arg4 = \"%s\", \"%s\", \"%s\", \"%s\"\n%s", a1 or "", a2 or "", a3 or "", a4 or "", luatext)
	assert(loadstring(script))()
end

function MT:DoMTMacroCommand(command, parameters)
	if command == "mtce" then UIErrorsFrame:Clear()
	elseif command == "mteo" then UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
	elseif command == "mtex" then UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	elseif command == "mtc" then MT:Eval(parameters)
	elseif command == "mtrp" then SummonRandomCritter()
	elseif command == "mtso" then SetCVar("Sound_EnableSFX", 1)
	elseif command == "mtsx" then SetCVar("Sound_EnableSFX", 0)
	elseif command == "mtrt" then
		local t, m = strsplit(" ", parameters)
		SetRaidTarget(t, m)
	elseif command == "mtfm" then
		if parameters then
			-- ticket 132 solution provided by Merlin_vr1
			if SecureCmdOptionParse(parameters) then C_MountJournal.SummonByID(0) end
		else C_MountJournal.Summon(0) end
	elseif command == "mtev" then VehicleExit()
	elseif command == "mtmc" then
		SetMapToCurrentZone()
		local x, y = GetPlayerMapPosition("player")
		print(format("%.1f %.1f", x*100, y*100))
	elseif command == "mttc" then ShowCloak(not ShowingCloak())
	elseif command == "mtth" then ShowHelm(not ShowingHelm())
	elseif command == "mtep" then for seat = 1,2 do if CanEjectPassengerFromSeat(seat) then EjectPassengerFromSeat(seat) end end
	elseif command == "mtsg" then
		local GetContainerItemInfo, GetItemInfo, UseContainerItem, cash = GetContainerItemInfo, GetItemInfo, UseContainerItem, 0
		for bag = 0, 4 do
			for slot = 1, GetContainerNumSlots(bag) do
				local _, qty, _, _, _, _, itemlink = GetContainerItemInfo(bag, slot)
				if string.find(itemlink or "", "9d9d9d") then
					local vendorprice = select(11, GetItemInfo(itemlink)) * qty
					cash = cash + vendorprice
					UseContainerItem(bag, slot)
				end
			end
		end
		local gold = floor(cash / (_G.COPPER_PER_SILVER * _G.SILVER_PER_GOLD))
		local goldDisplay = BreakUpLargeNumbers(gold)
		local silver = floor((cash - (gold * _G.COPPER_PER_SILVER * _G.SILVER_PER_GOLD)) / _G.COPPER_PER_SILVER)
		local copper = mod(cash, _G.COPPER_PER_SILVER)
		local goldtexture = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12|t"
		local silvertexture = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12|t"
		local coppertexture = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12|t"
		print(format("%s: %s%s%s%s%s%s", L["Sell grey items"], gold, goldtexture, silver, silvertexture, copper, coppertexture))
	elseif command == "mtdg" then
		local GetContainerItemInfo, GetItemInfo, PickupContainerItem, DeleteCursorItem = GetContainerItemInfo, GetItemInfo, PickupContainerItem, DeleteCursorItem
		for bag = 0, 4 do
			for slot = 1, GetContainerNumSlots(bag) do
				local itemlink = select(7, GetContainerItemInfo(bag, slot))
				if string.find(itemlink or "", "9d9d9d") then
					PickupContainerItem(bag, slot)
					DeleteCursorItem()
				end
			end
		end
	elseif command == "mtnb" then
		local UnitAura, UnitName = UnitAura, UnitName
		local msg = format("%s: ", L["No food buff"])
		local ppl = _G.NONE
		for member = 1, GetNumGroupMembers() do
			for buff = 1, 41 do
				local aura = UnitAura(format("raid%d", member), buff)
				if aura == L["Well Fed"] or aura == L["Food"] then break
				elseif buff == 41 and aura ~= L["Well Fed"] then ppl = format("%s%s ", ppl, UnitName(format("raid%d", member))) end
			end
		end
		SendChatMessage(format("%s%s", msg, ppl), MT.channel or "raid")
	elseif command == "mtnf" then
		local UnitAura, UnitName = UnitAura, UnitName
		local msg = format("%s: ", L["No flask"])
		local ppl = _G.NONE
		for member = 1, GetNumGroupMembers() do
			for buff = 1, 41 do
				local aura = UnitAura(format("raid%d", member), buff)
				if aura then
					if string.find(aura, L["Flask"])or string.find(aura, L["Distilled"])then break end
				elseif buff == 41 then ppl = format("%s%s ", ppl, UnitName(format("raid%d", member))) end
			end
		end
		SendChatMessage(format("%s%s", msg, ppl), "raid")
	elseif command == "mtp" then
		parameters = string.lower(parameters)
		local conditions, msg, chan, target, ctarget, execute
		local cs, ce = string.find(parameters, "%[.+%]%s+")
		if cs then
			conditions = string.sub(parameters, cs, ce)
			execute, ctarget = SecureCmdOptionParse(format("%s%s %s", MT.slash, MT.target, conditions))
			if not execute then return end
			msg = string.sub(parameters, ce + 1)
		else msg = parameters end
		chan = string.match(msg, "raid ") or string.match(msg, "chat ") or string.match(msg, "guild ") or string.match(msg, "party ")
		if chan then
			cs, ce = string.find(msg, chan)
			msg = string.sub(msg, ce + 1)
		else chan = "chat " end
		local t = string.match(msg, "%%(.)")
		if t == "t" then target = UnitName("target")
		elseif t == "f" then target = UnitName("focus")
		elseif t == "c" then
			if ctarget then target = UnitName(ctarget)
			else return end
		end
		if t then
			if not target then return
			else msg = string.gsub(msg, format("%%%%%s", t), target) end
		end
		chan = string.sub(chan, 1, string.len(chan) - 1)
		if chan == "chat" then DEFAULT_CHAT_FRAME:AddMessage(format("|cff99cce6%s|r", msg))
		else SendChatMessage(msg, chan) end
	end
end

function MT:FindScript(scriptname) for _, s in ipairs(MT.scripts) do if s[1] == scriptname then return s end end end

function MT:ShowShortened(chars)
	if not MT.db.profile.hidepopup then -- ticket 147
		StaticPopupDialogs["MACROTOOLKIT_SHORTENED"] = {
			text = string.format((chars == 1) and L["Macro shortened by %d character"] or L["Macro shortened by %d characters"], chars),
			button1 = _G.OKAY, timeout = 0, exclusive = 1, whileDead = 1, hideOnEscape = 1}
		StaticPopup_Show("MACROTOOLKIT_SHORTENED")
	else --PlaySound("igCharacterInfoOpen") end
		PlaySound(839) end
end

function MT:SetMacros(account, extra, copy)
	MTF.macroBase = account and 0 or _G.MAX_ACCOUNT_MACROS
	MTF.macroMax = account and _G.MAX_ACCOUNT_MACROS or _G.MAX_CHARACTER_MACROS
	if extra then
		if MT:CountExtra() > 0 then MTF.selectedMacro = 1001
		else MTF.selectedMacro = nil end
		MTF.macroBase = 1000
	elseif copy then
		MTF.selectedMacro = 1
		MTF.macroBase = 1
	else
		local numAccountMacros, numCharacterMacros = GetNumMacros()
		if (account and numAccountMacros or numCharacterMacros) > 0 then MTF.selectedMacro = MTF.macroBase + 1
		else MTF.selectedMacro = nil end
	end
end

function MT:FormatMacro(macrotext)
	if macrotext == "" then return "", "" end
	local lines = {strsplit("\n", macrotext)}
	local mout, eout = "", ""
	for n, l in ipairs(lines) do
		if l == "" then mout = format("%s\n", mout)
		else
			local f, err = MT:ParseMacro(l)
			if not f then break end
			mout = format("%s%s\n", mout, f)
			for _, e in ipairs(err) do eout = format("%s%s\n", eout, e) end
		end
	end
	mout = string.sub(mout, 1, strlenutf8(mout) - 1)
	return mout, eout
end

function MT:UpdateExtended(index, body, mindex)
	local var = (index > _G.MAX_ACCOUNT_MACROS) and "char" or "global"
	local mindex = tostring(mindex)
	if not MT.db[var].extended then MT.db[var].extended = {} end
	local name, icon = GetMacroInfo(index)
	MT.db[var].extended[mindex] = {name = name, icon = string.gsub(string.upper(icon), "INTERFACE\\ICONS\\", ""), body = body}
end

function MT:DeleteExtended(index)
	local var = (MTF.selectedMacro > _G.MAX_ACCOUNT_MACROS) and "char" or "global"
	index = tostring(index)
	MT.db[var].extended[index] = nil
end

function MT:ExtendClick(this)
	MTF.textChanged = true
	if not MacroToolkitText.extended then MT:ExtendMacro()
	else MT:UnextendMacro() end
end

function MT:GetNextIndex()
	local tab = PanelTemplates_GetSelectedTab(MTF)
	local index = (tab == 2) and (_G.MAX_ACCOUNT_MACROS + 1) or 1
	local mstart, mend = index, (tab == 2) and (_G.MAX_ACCOUNT_MACROS + _G.MAX_CHARACTER_MACROS) or _G.MAX_ACCOUNT_MACROS
	if tab == 3 then
		index = 1001
		mstart = 1001
		mend = 1000 + _G.MAX_ACCOUNT_MACROS
	end
	for m = mstart, mend do
		local var = (m > _G.MAX_ACCOUNT_MACROS) and "char" or "global"
		local ex = (tab == 3) and MT.db.global.extra or MT.db[var].extended
		if not ex[tostring(m)] then index = m; break end
	end
	return tostring(index)
end

function MT:GetCurrentIndex(extra)
	if not MTF.selectedMacro then return end
	if not MacroToolkitText.extended then return end
	local body = select(3, GetMacroInfo(MTF.selectedMacro))
	local index = select(3, string.find(body, "MTSB(%d+)"))
	return index
end

local function checktooltip(showtooltip, body)
	if showtooltip then
		if showtooltip == _G.SLASH_SHOWTOOLTIP1 then
			local _, _, firstspell = MT:ShortenMacro(body)
			if firstspell then showtooltip = string.format("%s %s", _G.SLASH_SHOWTOOLTIP1, firstspell) end
		end
	end
	return showtooltip
end

function MT:ExtendMacro(save, macrobody, idx, exists)
	local body = macrobody or MacroToolkitText:GetText()
	local index = save and MT:GetCurrentIndex() or MT:GetNextIndex()
	local securebutton = _G[format("MTSB%d", exists and idx or index)]
	local showtooltip = select(3, string.find(body, "(#showtooltip.-)\n"))
	local show = select(3, string.find(body, "(#show .-)\n"))
	showtooltip = checktooltip(showtooltip, body)
	if showtooltip then
		local characterLimit, longestExtendedMacroLength, newLineLength = 255, 143, 1
		local showtooltipLimit = (characterLimit - longestExtendedMacroLength - newLineLength)
		if strlenutf8(showtooltip) > showtooltipLimit then
			StaticPopupDialogs["MACROTOOLKIT_TOOLONG"].text = format(
				L["Macro Toolkit can only handle tooltip commands up to a maximum of %d characters. Your tooltip will not work as expected unless you shorten it"],
				showtooltipLimit
			)
			StaticPopup_Show("MACROTOOLKIT_TOOLONG")
			showtooltip = nil
		end
	end
	if showtooltip then showtooltip = format("%s\n", showtooltip) else showtooltip = "" end
	if show then show = format("%s\n", show) else show = "" end

	if not exists then
		MT:UpdateExtended(idx or MTF.selectedMacro, body, index)
		securebutton:SetAttribute("macrotext", body)
		securebutton:SetAttribute("dynamic", MT:IsDynamic(idx or MTF.selectedMacro))
	end
	--modified 15/12/13 - need to ensure button info is passed to the secure frame
	--local newbody = format("%s%s%s %s", showtooltip, show, MT.click, securebutton:GetName())
	local n = format("MTSB%d", exists and idx or index)
	local newbody = format(exFormat, showtooltip, show, MT.click, n, n, n, n, n)
	if not idx then
		MacroToolkitText.extended = true
		_G[format("MacroToolkitButton%d", (MTF.selectedMacro - MTF.macroBase))].extended = true
	end
	if exists then CreateMacro(MT.db.char.extended[idx].name, MT.db.char.extended[idx].icon, newbody, tonumber(idx) > _G.MAX_ACCOUNT_MACROS)
	else EditMacro(idx or MTF.selectedMacro, nil, nil, newbody) end
	if not save and not idx and not exists then
		MacroToolkitExtend:SetText(L["Unextend"])
		MacroToolkitText:GetScript("OnTextChanged")(MacroToolkitText)
		MT:UpdateCharLimit()
	end
	return n
end

--function to modify any extended macro created prior to the fix that passes
--button information to the secure button frames
function MT:CorrectExtendedMacros()
	--if MT.db.profile.extendedcorrected then return end
	--MT.db.profile.extendedcorrected = true

	cleanMacros()
	--fix macros
	for m = 1, _G.MAX_ACCOUNT_MACROS + _G.MAX_CHARACTER_MACROS do
		local body = select(3, GetMacroInfo(m))
		if body then
			if string.find(body, format("%s MacroToolkitSecureButton%%d+", MT.click)) then
				local b = format("MTSB%d", string.match(body, "MacroToolkitSecureButton(%d+)"))
				local showtooltip = select(3, string.find(body, "(#showtooltip.-)\n"))
				local show = select(3, string.find(body, "(#show .-)\n"))
				if showtooltip then showtooltip = format("%s\n", showtooltip) else showtooltip = "" end
				if show then show = format("%s\n", show) else show = "" end
				local newbody = format(exFormat, showtooltip, show, MT.click, b, b, b, b, b)
				EditMacro(m, nil, nil, newbody)
			end
			-- upgrade for the 10.0.0 /click workaround - updated to 10.0.2 pain
			if string.find(body, format("%s %sMTSBP?%%d+", MT.click, '%[btn:1%]')) then
				local b = format("MTSB%d", string.match(body, "MTSBP?(%d+)"))
				local showtooltip = select(3, string.find(body, "(#showtooltip.-)\n"))
				local show = select(3, string.find(body, "(#show .-)\n"))
				if showtooltip then showtooltip = format("%s\n", showtooltip) else showtooltip = "" end
				if show then show = format("%s\n", show) else show = "" end
				local newbody = format(exFormat, showtooltip, show, MT.click, b, b, b, b, b)
				EditMacro(m, nil, nil, newbody)
			end
		end
	end

	--fix bindings
	if MT.db.global.extra then
		for i, b in pairs(MT.db.global.extra) do
			local keybind1, keybind2 = GetBindingKey(format("CLICK MacroToolkitSecureButton%d:LeftButton", i))
			if keybind1 or keybind2 then
				local newcommand = format("CLICK MTSB%d:LeftButton", i)
				if keybind1 then SetBinding(keybind1, newcommand) end
				if keybind2 then SetBinding(keybind2, newcommand) end
			end
		end
	end
end

local function unextend(body)
	local mbody = select(3, GetMacroInfo(MTF.selectedMacro))
	local mindex = select(3, string.find(mbody, "MTSBP?(%d+)"))
	local securebutton = _G[format("MTSB%d", mindex)]
	MT:DeleteExtended(mindex)
	securebutton:SetAttribute("macrotext", "")
	securebutton:SetAttribute("dynamic", false)
	MacroToolkitText.extended = nil
	_G[format("MacroToolkitButton%d", (MTF.selectedMacro - MTF.macroBase))].extended = nil
	MacroToolkitExtend:SetText(L["Extend"])
	EditMacro(MTF.selectedMacro, nil, nil, body)
	MT:MacroFrameUpdate()
	MT:UpdateCharLimit()
end

function MT:UnextendMacro()
	local body = MacroToolkitText:GetText()
	if strlenutf8(body) > 255 then
		StaticPopupDialogs.MACROTOOLKIT_DELETEBACKUP.text = L["Your macro will be truncated to 255 characters. Are you sure?"]
		StaticPopupDialogs.MACROTOOLKIT_DELETEBACKUP.OnAccept = function() unextend(string.sub(body, 1, 255)) end
		StaticPopup_Show("MACROTOOLKIT_DELETEBACKUP")
	else unextend(body) end
end

function MT:GetExtendedBody(index, tab)
	local var = (tab == 1) and "global" or "char"
	if not MT.db[var].extended then return ""
	elseif not MT.db[var].extended[index] then return ""
	else return MT.db[var].extended[index].body end
end

function MT:UpdateCharLimit()
	if not MTF.selectedMacro then return end
	local extended = MacroToolkitText.extended
	local dct = MacroToolkitText:GetText()
	local chars = strlenutf8(dct)
	local limit = extended and 1024 or 255
	if MTF.selectedMacro > 1000 or extended then
		if chars > 1024 then
			local ft = string.sub(dct, 1, 1024)
			MacroToolkitText:SetText(ft)
		end
	elseif chars > 255 and not extended then
		local ft = string.sub(dct, 1, 255)
		MacroToolkitText:SetText(ft)
	end
	MacroToolkitLimit:SetFormattedText(L["%d of %d characters used"], chars, limit)
end

function MT:UpdateErrors(errortext)
	MacroToolkitErrors:SetText(errortext)
	local icon, tt = MacroToolkitErrorIcon, GameTooltip
	if errortext ~= "" then
		icon:Show()
		icon:SetScript("OnEnter",
			function()
				tt:SetOwner(icon, "ANCHOR_LEFT")
				tt:ClearLines()
				tt:AddLine(_G.ERRORS)
				local lines = {strsplit("\n", errortext)}
				for _, l in ipairs(lines) do tt:AddLine(format("|cffffffff%s", l)) end
				tt:Show()
			end)
	else icon:Hide() end
end

function MT:CountExtra()
	local count = 0
	for i, e in pairs(MT.db.global.extra) do count = count + 1 end
	return count
end

function MT:SelOnClick(this)
	if InCombatLockdown() then return end
	this:SetChecked(false)
	PickupMacro(MTF.selectedMacro)
end

function MT:MacroFrameUpdate()
	local numMacros, tab
	local numAccountMacros, numCharacterMacros = GetNumMacros()
	local macroButtonName, macroButton, macroIcon, macroName, macroUnbound
	local name, texture, body
	local selectedName, selectedBody, selectedIcon
	local tab = PanelTemplates_GetSelectedTab(MTF)
	local exmacros = {}

	numMacros = (MTF.macroBase == 0) and numAccountMacros or numCharacterMacros
	if MT.MTCF then if MT.MTCF:IsShown() then tab = 4 end end
	if tab == 3 then
		numMacros = MT:CountExtra()
		for i, exm in pairs(MT.db.global.extra) do table.insert(exmacros, {name = exm.name, texture = exm.texture, body = exm.body, index = i}) end
		table.sort(exmacros, function(a, b) return (a.name or "") < (b.name or "") end)
	elseif tab == 2 then
		if numMacros == _G.MAX_CHARACTER_MACROS then MacroToolkitCopyButton:Disable()
		else MacroToolkitCopyButton:Enable() end
	elseif tab == 4 then
		numMacros = 0
		if MT.charcopy then
			if MacroToolkitDB.char[MT.charcopy].extended then
				for i, exm in pairs(MacroToolkitDB.char[MT.charcopy].extended) do
					if tonumber(i) > _G.MAX_ACCOUNT_MACROS then
						local mname = (exm.name == "") and "xxx" or exm.name
						local micon = (exm.icon == "") and "INV_MISC_QUESTIONMARK" or exm.icon
						table.insert(exmacros, {name = mname, texture = micon, body = exm.body, extended = true})
						numMacros = numMacros + 1
					end
				end
			end
			if MT.db.global.allcharmacros then
				if MacroToolkitDB.char[MT.charcopy].macros then
					for _, m in pairs(MacroToolkitDB.char[MT.charcopy].macros) do
						table.insert(exmacros, {name = m.name, texture = m.icon, body = m.body})
						numMacros = numMacros + 1
					end
				end
			end
			table.sort(exmacros, function(a, b) return a.name < b.name end)
		end
	end
	local maxMacroButtons = (tab == 4) and _G.MAX_CHARACTER_MACROS or max(_G.MAX_ACCOUNT_MACROS, _G.MAX_CHARACTER_MACROS)
	--local fsize = select(2, MacroToolkitButton1Name:GetFont())
	local font = LSM:Fetch(LSM.MediaType.FONT, MT.db.profile.fonts.mifont)
	local k1, k2
	local bname = (tab == 4) and "MacroToolkitCButton" or "MacroToolkitButton"

	for i = 1, maxMacroButtons do
		macroButtonName = format("%s%d", bname, i)
		macroButton = _G[macroButtonName]
		macroIcon = macroButton.Icon --_G[format("%sIcon", macroButtonName)]
		macroName = _G[format("%sName", macroButtonName)]
		macroUnbound = _G[format("%sUnbound", macroButtonName)]
		macroName:SetFont(font, MT.db.profile.fonts.misize, "")
		--macroButton:SetChecked(false)
		if i <= MTF.macroMax then
			if i <= numMacros then
				macroUnbound:Hide()
				if tab == 3 then
					local em = exmacros[i]
					if em then
						if em.texture then	-- ticket 76
							texture = tonumber(em.texture) or format("Interface\\Icons\\%s", em.texture)
							name, body = em.name, em.body
							local commandName = format("CLICK MTSB%d:LeftButton", em.index)
							k1, k2 = GetBindingKey(commandName)
							if not (k1 or k2) then macroUnbound:Show() end
							macroButton.extra = tonumber(em.index)
						end
					end
				elseif tab == 4 then
					local em = exmacros[i]
					texture = tonumber(em.texture) or format("Interface\\Icons\\%s", em.texture)
					name, body = em.name, em.body
				else name, texture, body = GetMacroInfo(MTF.macroBase + i) end
				macroIcon:SetTexture(texture)
				macroName:SetText(name)
				macroButton:Enable()
				-- Highlight Selected Macro
				local pos
				if MTF.selectedMacro then pos = ((tab == 3) and MTF.extrapos or (MTF.selectedMacro - MTF.macroBase)) end
				if tab == 4 then pos = MT.MTCF.selectedMacro end
				if MTF.selectedMacro and i == pos then
					macroButton:SetChecked(true)
					if tab < 4 then MacroToolkitSelMacroName:SetText(name)
					else MacroToolkitCSelMacroName:SetText(name) end
					local index
					if body then _, _, index = string.find(body, "MTSBP?(%d+)") end
					if index then
						body = MT:GetExtendedBody(index, tab)
						MacroToolkitText.extended = true
						MacroToolkitExtend:SetText(L["Unextend"])
						macroButton.extended = true
						if MT.db.profile.visextend then MacroToolkitExtend:Show() end
						MacroToolkitSelMacroButton:SetScript("OnClick", function(this) MT:SelOnClick(this) end)
					elseif tab == 3 then
						MacroToolkitText.extended = true
						macroButton.extended = true
						MacroToolkitExtend:Hide()
						MacroToolkitSelMacroButton:SetScript("OnClick", function(this) this:SetChecked(false) end)
						if not (k1 or k2) then MacroToolkitLimit:SetText(_G.NOT_BOUND)
						else
							if k1 then MacroToolkitLimit:SetText(GetBindingText(k1, "KEY_"))
							elseif k2 then MacroToolkitLimit:SetText(GetBindingText(k2, "KEY_")) end
						end
					else
						MacroToolkitText.extended = nil
						macroButton.extended = nil
						MacroToolkitExtend:SetText(L["Extend"])
						if MT.db.profile.visextend then MacroToolkitExtend:Show() end
						MacroToolkitSelMacroButton:SetScript("OnClick", function(this) MT:SelOnClick(this) end)
					end
					body = body or ""
					local m, e = MT:FormatMacro(body)
					if tab < 4 then
						MacroToolkitText:SetText(body)
						MacroToolkitFauxText:SetText(m)
						MT:UpdateErrors(e)
						MacroToolkitSelMacroButton:SetID(i)
						MacroToolkitSelMacroButton.Icon:SetTexture(texture)
						if MT.MTPF then
							if type(texture) == "number" then
								MT.MTPF.selectedIconTexture = texture
							else
								if texture then
									MT.MTPF.selectedIconTexture = string.gsub(string.upper(texture), "INTERFACE\\ICONS\\", "")
								else
									MT.MTPF.selectedIconTexture = nil
								end
							end
						end
					else
						MacroToolkitCText:SetText(body)
						MacroToolkitCFauxText:SetText(m)
						MacroToolkitCSelMacroButton:SetID(i)
						MacroToolkitCSelMacroButton.Icon:SetTexture(texture)
					end
					if MT.db.profile.broker then
						local result, cmd = _G.ERR_NOT_IN_COMBAT, ""
						if not InCombatLockdown() then result, cmd = MT:RunCommands(true, body) end
						local mname = MacroToolkitSelMacroName:GetText()
						if result then
							MT.brokericon:SetTexture("Interface\\COMMON\\Indicator-Red")
							MacroToolkitBrokerIcon:SetScript("OnEnter",
									function(this)
										GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
										GameTooltip:SetText("Macro Toolkit Broker")
										GameTooltip:AddLine(format("|cffff0000%s|r", cmd))
										GameTooltip:AddLine(format("|cffffffffReason: |cff4466cc%s|r", result))
										GameTooltip:Show()
									end)
							MTF.brokerok = false
							if MT:FindBrokerName(mname) then MT:BrokerRemove()
							else MacroToolkitBrokerButton:Hide() end
						else
							MT.brokericon:SetTexture("Interface\\COMMON\\Indicator-Green")
							MacroToolkitBrokerIcon:SetScript("OnEnter", nil)
							if MT:FindBrokerName(mname) then MT:BrokerRemove()
							else MT:BrokerAdd() end
							MTF.brokerok = true
						end
						MacroToolkitBrokerIcon:Show()
					else MacroToolkitBrokerIcon:Hide() end
				else macroButton:SetChecked(false) end
				if tab == 4 then macroButton.extended = exmacros[i].extended end
			else
				macroButton:SetChecked(false)
				if tab == 3 then macroButton.extra = 1001 end
				macroIcon:SetTexture("")
				macroName:SetText("")
				macroUnbound:Hide()
			end
			macroButton:Show()
		else macroButton:Hide() end
	end

	-- Macro Details
	if MTF.selectedMacro ~= nil then
		MT:ShowDetails()
		MacroToolkitDelete:Enable()
		MacroToolkitShorten:Enable()
		MacroToolkitExtend:Enable()
		MacroToolkitBackup:Enable()
		MacroToolkitShare:Enable()
		MacroToolkitBind:Enable()
		MacroToolkitConditions:Enable()
	else
		MT:HideDetails()
		MacroToolkitDelete:Disable()
		MacroToolkitShorten:Disable()
		MacroToolkitExtend:Disable()
		MacroToolkitBackup:Disable()
		MacroToolkitShare:Disable()
		MacroToolkitBind:Disable()
		MacroToolkitConditions:Disable()
		MacroToolkitBrokerIcon:Hide()
	end

	--Update New Button
	if numMacros < MTF.macroMax then MacroToolkitNew:Enable()
	else MacroToolkitNew:Disable() end

	-- Disable Buttons
	if MT.MTPF then
		if MT.MTPF:IsShown() then
			MacroToolkitEdit:Disable()
			MacroToolkitDelete:Disable()
			MacroToolkitShorten:Disable()
			MacroToolkitExtend:Disable()
			MacroToolkitBackup:Disable()
			MacroToolkitClear:Disable()
			MacroToolkitShare:Disable()
			MacroToolkitBind:Disable()
			MacroToolkitConditions:Disable()
		else
			MacroToolkitEdit:Enable()
			MacroToolkitDelete:Enable()
			MacroToolkitShorten:Enable()
			MacroToolkitExtend:Enable()
			MacroToolkitBackup:Enable()
			MacroToolkitClear:Enable()
			MacroToolkitShare:Enable()
			MacroToolkitBind:Enable()
			MacroToolkitConditions:Enable()
		end
	end

	if not MTF.selectedMacro then
		MacroToolkitDelete:Disable()
		MacroToolkitShorten:Disable()
		MacroToolkitExtend:Disable()
		MacroToolkitShare:Disable()
		MacroToolkitBind:Disable()
	end

	if numMacros > 0 then MacroToolkitClear:Enable()
	else MacroToolkitClear:Disable() end
end

function MT:ContainerOnLoad(container)
	local maxMacroButtons = (container:GetName() == "MacroToolkitCButtonContainer") and _G.MAX_CHARACTER_MACROS or max(_G.MAX_ACCOUNT_MACROS, _G.MAX_CHARACTER_MACROS)
	local bname = (container:GetName() == "MacroToolkitCButtonContainer") and "MacroToolkitCButton" or "MacroToolkitButton"
	local OnDragStart = function(button) if not InCombatLockdown() then PickupMacro(MTF.macroBase + button:GetID()) end end
	local OnClick = function(button, btn) self:MacroButtonOnClick(button, btn) end
	local button
	local buttonWidth = 45
	local buttonsPerRow = container:GetWidth() / buttonWidth
	for i = 1, maxMacroButtons do
		button = CreateFrame("CheckButton", format("%s%d", bname, i), container, "MacroToolkitButtonTemplate")
		button:SetScript("OnClick", OnClick)
		button:SetScript("OnDragStart", OnDragStart)
		button:SetID(i)
	end
	self:RepositionContainerButtons(container)
end

function MT:RepositionContainerButtons(container)
	local maxMacroButtons = (container:GetName() == "MacroToolkitCButtonContainer") and _G.MAX_CHARACTER_MACROS or max(_G.MAX_ACCOUNT_MACROS, _G.MAX_CHARACTER_MACROS)
	local bname = (container:GetName() == "MacroToolkitCButtonContainer") and "MacroToolkitCButton" or "MacroToolkitButton"
	local buttonWidth = 49
	local oldButtonsPerRow = container.buttonsPerRow
	local buttonsPerRow = math.max(6, math.floor((container:GetWidth() + 5) / buttonWidth))
	if buttonsPerRow == oldButtonsPerRow then return end
	container.buttonsPerRow = buttonsPerRow
	for i = 1, maxMacroButtons do
		local button = _G[format("%s%d", bname, i)]
		button:ClearAllPoints()
		if i == 1 then
			button:SetPoint("TOPLEFT", container, "TOPLEFT", 6, -6)
		elseif mod(i, buttonsPerRow) == 1 then
			button:SetPoint("TOP", _G[format("%s%d", bname, i - buttonsPerRow)], "BOTTOM", 0, -10)
		else
			button:SetPoint("LEFT", _G[format("%s%d", bname, i - 1)], "RIGHT", 13, 0)
		end
	end
end

function MT:MacroButtonOnClick(this, button)
	MT:SaveMacro()
	local tab = PanelTemplates_GetSelectedTab(MTF)
	MTF.selectedMacro = (tab == 3) and this.extra or (MTF.macroBase + this:GetID())
	if MT.MTCF then
		if MT.MTCF:IsShown() then
			tab = 4
			if _G[format("%sName", this:GetName())]:GetText() then
				MT.MTCF.selectedMacro = this:GetID()
				MacroToolkitCopy:Enable()
			end
		end
	end
	local name
	if tab == 3 then
		MTF.extra = this.extra
		MTF.extrapos = this:GetID()
		if MT.db.global.extra[tostring(this.extra)] then name = MT.db.global.extra[tostring(this.extra)].name end
	elseif tab == 4 then name = _G[format("%sName", this:GetName())]:GetText()
	else name = GetMacroInfo(MTF.selectedMacro) end
	if not name then
		if CursorHasMacro() and tab < 3 then
			local maxm = (tab == 1) and _G.MAX_ACCOUNT_MACROS or _G.MAX_CHARACTER_MACROS
			local mcount = select(tab, GetNumMacros())
			if maxm == mcount then
				StaticPopupDialogs.MACROTOOLKIT_ALERT.text = L["You have no more room for macros!"]
				StaticPopupDialogs.MACROTOOLKIT_ALERT.showAlert = 1
				StaticPopup_Show("MACROTOOLKIT_ALERT")
				MTF.selectedMacro = nil
				MT:HideDetails()
				MT:MacroFrameUpdate()
				return
			end
			local _, mid = GetCursorInfo()
			local name, texture, body = GetMacroInfo(mid)
			texture = string.gsub(string.upper(texture), "INTERFACE\\ICONS\\", "")
			local s, e, index = string.find(body, "MTSB(%d+)")
			if s then
				local bg, bc, ni = MT.db.global.extended[index], MT.db.char.extended[index]
				if bg and tab == 2 then
					ni = MT:GetNextIndex()
					MT.db.char.extended[ni] = bg
					MT.db.global.extended[index] = nil
				elseif bc and tab == 1 then
					ni = MT:GetNextIndex()
					MT.db.global.extended[ni] = bc
					MT.db.char.extended[index] = nil
				end
				body = string.gsub(body, "MTSB%d+", format("MTSB%d", ni)) -- ticket 67
			end
			CreateMacro(name, texture, body, tab == 2)
			MT:MacroFrameUpdate()
			DeleteMacro(mid)
			ClearCursor()
		else
			MTF.selectedMacro = nil
			MT:HideDetails()
			MT:MacroFrameUpdate()
		end
	end
	MacroToolkitText.extended = button.extended
	MT:MacroFrameUpdate()
	if MT.MTPF then MT.MTPF:Hide() end
	MacroToolkitText:ClearFocus()
end

function MT:HideDetails()
	MacroToolkitEdit:Hide()
	MacroToolkitLimit:Hide()
	MacroToolkitText:Hide()
	MacroToolkitFauxText:Hide()
	MacroToolkitSelMacroName:Hide()
	MacroToolkitSelBg:Hide()
	MacroToolkitSelMacroButton:Hide()
end

function MT:ShowDetails()
	MacroToolkitEdit:Show()
	MacroToolkitLimit:Show()
	MacroToolkitEnterText:Show()
	MacroToolkitText:Show()
	MacroToolkitFauxText:Show()
	MacroToolkitSelMacroName:Show()
	MacroToolkitSelBg:Show()
	MacroToolkitSelMacroButton:Show()
	MacroToolkitShorten:Enable()
	MacroToolkitExtend:Enable()
end

function MT:IsDynamic(index)
	if not index then return false end
	local body = select(2, GetMacroInfo(index))
	if not body or body == "" then return false end
	return strlower(body) == "interface\\icons\\inv_misc_questionmark"
end

function MT:SaveMacro()
	if InCombatLockdown() then
		MT:CombatMessage()
		return
	end
	if MTF.textChanged and MTF.selectedMacro then
		if MTF.selectedMacro > 1000 then
			--if not MTF.extra then return end
			if not MT.db.global.extra then MT.db.global.extra = {} end
			if not MT.db.global.extra[tostring(MTF.selectedMacro)] then MT.db.global.extra[tostring(MTF.selectedMacro)] = {} end
			MT.db.global.extra[tostring(MTF.selectedMacro)].body = MacroToolkitText:GetText()
			_G[format("MTSB%d", MTF.selectedMacro)]:SetAttribute("macrotext", MacroToolkitText:GetText())
		else
			if MacroToolkitText.extended then
				local n = MT:ExtendMacro(true)
				MT:UpdateIcon(_G[n])
			else EditMacro(MTF.selectedMacro, nil, nil, MacroToolkitText:GetText()) end
		end
		MTF.textChanged = nil
	end
end

local function getMacroIcon(texture) for i, t in ipairs(MT.MACRO_ICON_FILENAMES) do if string.upper(t) == texture then return i end end end

function MT:GetBackupName()
	local tab = PanelTemplates_GetSelectedTab(MTF)
	local mtype = _G[format("MacroToolkitFrameTab%d", tab)]:GetText()
	StaticPopupDialogs.MACROTOOLKIT_BACKUPNAME.text = format("|cffeedd82%s|r\n\n%s", mtype, L["Enter a name for this backup"])
	StaticPopup_Show("MACROTOOLKIT_BACKUPNAME")
end

function MT:SetBackupName(dialog)
	local name = dialog.editBox:GetText() or ""
	dialog:Hide()
	MT:BackupMacros(name)
end

function MT:BackupMacros(backupname)
	local name, texture, body, fname
	local macros = {n=backupname, d=date(L["datetime format"]), m={}}
	local tab = PanelTemplates_GetSelectedTab(MTF)
	local var = (tab == 1) and "global" or "char"
	local start = (tab == 1) and 1 or (_G.MAX_ACCOUNT_MACROS + 1)
	local finish = (tab == 1) and _G.MAX_ACCOUNT_MACROS or (_G.MAX_ACCOUNT_MACROS + _G.MAX_CHARACTER_MACROS)
	if tab == 3 then
		var = "global"
		start = 1001
		finish = 1000 + MT:CountExtra()
	end
	MT:RefreshPlayerSpellIconInfo()
	for m = start, finish do
		if start > 1000 then
			local em = MT.db.global.extra[tostring(m)]
			name, texture, body = em.name, em.texture, em.body
		else name, texture, body = GetMacroInfo(m) end
		if name then
			if string.find(body, "MTSB") then body = _G[format("MTSB%d", m)]:GetAttribute("macrotext") end
			if type(texture) == "number"  then
				fname = texture
			else
				fname = string.gsub(string.upper(texture), "INTERFACE\\ICONS\\", "")
			end
			table.insert(macros.m, {index = m, icon = fname, body = body, name = name})
		end
	end
	if not MT.db[var].backups then MT.db[var].backups = {} end
	table.insert(MT.db[var].backups, macros)
	MT:SetLastBackupDate()
	MT:GetLastBackupDate()
	MT.MACRO_ICON_FILENAMES = nil
	collectgarbage()
end

function MT:SetLastBackupDate()
	local tab = PanelTemplates_GetSelectedTab(MTF)
	local var = (tab == 1) and "global" or "char"
	local backup = (tab == 3) and MT.db.global.ebackups or MT.db[var]
	backup.lastbackup = date(L["datetime format"])
end

function MT:IsSecureAction(action)
	if string.find(action, "TARGET") or string.find(action, "ACTIONBUTTON") then return true end
	local secureactions = {"TURNLEFT", "TURNRIGHT", "STRAFERIGHT", "STRAFELEFT", "MOVEBACKWARD", "ATTACKTARGET", "MOVEFORWARD", "SITORSTAND", "PITCHUP", "PITCHDOWN", "TOGGLEAUTORUN", "TOGGLERUN"}
	for _, a in ipairs(secureactions) do
		if action == a then return true end
	end
end

--*****************************
--code to handle clicking links
--*****************************
local function MTChatEdit_InsertLink(linktext)
	if MacroToolkitText and MacroToolkitText:IsVisible() then
		local item
		if string.find(linktext, "item:", 1, true) then item = GetItemInfo(linktext)
		else linktext = select(3, string.find(linktext, "h%[(.*)%]|h")) end
		if not linktext then return end
		local cursorPosition = MacroToolkitText:GetCursorPosition()
		if cursorPosition == 0 or string.sub(MacroToolkitText:GetText(), cursorPosition, cursorPosition) == "\n" then
			if item then
				if GetItemSpell(linktext) then MacroToolkitText:Insert(format("%s %s\n", _G.SLASH_USE1, item))
				else MacroToolkitText:Insert(format("%s %s\n", _G.SLASH_EQUIP1, item)) end
			else MacroToolkitText:Insert(format("%s %s\n", _G.SLASH_CAST1, linktext)) end
		else MacroToolkitText:Insert(item or linktext) end
		MacroToolkitText:GetScript("OnTextChanged")(MacroToolkitText)
		MTF.textChanged = 1
		cccount = 1
		return true
	end
	return false
end

local function MTSpellButton_OnModifiedClick(this, button)
	if IsModifiedClick("CHATLINK") then
		if MTF:IsShown() then
			local slot = SpellBook_GetSpellBookSlot(this)
			if slot > _G.MAX_SPELLS then return end
			local spellName, subSpellName = GetSpellBookItemName(slot, SpellBookFrame.bookType)
			if spellName and not IsPassiveSpell(slot, SpellBookFrame.bookType) then
				if subSpellName and (string.len(subSpellName) > 0) then ChatEdit_InsertLink(format("%s(%s)", spellName, subSpellName))
				else ChatEdit_InsertLink(spellName) end
			end
			return
		end
	end
end

function MT:CombatMessage()
	StaticPopupDialogs.MACROTOOLKIT_ALERT.text = _G.ERR_NOT_IN_COMBAT
	StaticPopup_Show("MACROTOOLKIT_ALERT")
end

-- no longer required
--hooksecurefunc("SpellButton_OnModifiedClick", MTSpellButton_OnModifiedClick)
--hooksecurefunc("ChatEdit_InsertLink", MTChatEdit_InsertLink)
