local _G = _G
local MT = MacroToolkit
MT.LS = LibStub
MT.L = MT.LS("AceLocale-3.0"):GetLocale("MacroToolkit")
MT.AIS = MT.LS("LibAdvancedIconSelector-MTK")
MT.LDB = MT.LS("LibDataBroker-1.1")
MT.slash = string.sub(_G.SLASH_CAST1, 1, 1)
MT.click = _G.SLASH_CLICK1
MT.target = _G.SLASH_TARGET1
local L = MT.L
local SendChatMessage, format = SendChatMessage, format

MT.frame:RegisterEvent("ADDON_LOADED")
MT.frame:RegisterEvent("PLAYER_LOGIN")
MT.frame:SetScript("OnEvent", function(...) MT:eventHandler(...) end)
MT.commands = {}

MT.scripts = {
	{L["Clear UI errors"],"mtce"},
	{L["Disable UI errors"],"mtex"},
	{L["Enable UI errors"],"mteo"},
	{L["Random non-combat pet"],"mtrp"},
	{L["Enable sound effects"],"mtso"},
	{L["Disable sound effects"],"mtsx"},
	{L["Set raid target"],"mtrt","raidtarget"},
	{L["Exit vehicle"],"mtev"},
	{L["Print map coordinates"],"mtmc"},
	{L["Toggle cloak"],"mttc"},
	{L["Toggle helm"],"mtth"},
	{L["Eject passenger"],"mtep"},
	{L["Sell grey items"],"mtsg"},
	{L["Destroy grey items"],"mtdg"},
	{L["No food buff"],"mtnb","buff"},
	{L["No flask"],"mtnf","buff"},
	{L["Summon random favourite mount"],"mtfm"},
	{L["Print a message"],"mtp"},
	{L["Conditional execution"], "mtc"},
}

MT.slots = {
	[1]=_G.INVTYPE_HEAD,
	[2]=_G.INVTYPE_NECK,
	[3]=_G.INVTYPE_SHOULDER,
	[4]=_G.INVTYPE_BODY,
	[5]=_G.INVTYPE_CHEST,
	[6]=_G.INVTYPE_WAIST,
	[7]=_G.INVTYPE_LEGS,
	[8]=_G.INVTYPE_FEET,
	[9]=_G.INVTYPE_WRIST,
	[10]=_G.INVTYPE_HAND,
	[11]=format("%s 1",_G.INVTYPE_FINGER),
	[12]=format("%s 2",_G.INVTYPE_FINGER),
	[13]=format("%s 1",_G.INVTYPE_TRINKET),
	[14]=format("%s 2",_G.INVTYPE_TRINKET),
	[15]=_G.INVTYPE_BACK,
	[16]=_G.INVTYPE_WEAPONMAINHAND,
	[17]=_G.INVTYPE_WEAPONOFFHAND,
	[18]=_G.INVTYPE_RANGED,
	[19]=_G.INVTYPE_TABARD,
}
--0=none,1=numeric,2=textual,3=alphanumeric,4=party/raid,5=mod keys,6=mouse buttons,7=numeric with /,8=alphanumeric with spaces
MT.conditions={
	["actionbar"]=1,
	["bar"]=1,
	["bonusbar"]=1,
	["btn"]=6,
	["button"]=6,
	["canexitvehicle"]=0,
	["channeling"]=0,
	["channelling"]=0,
	["combat"]=0,
	["cursor"]=2,
	["dead"]=0,
	["equipped"]=2,
	["exists"]=0,
	["extrabar"]=1,
	["flyable"]=0,
	["flying"]=0,
	["form"]=1,
	["group"]=4,
	["harm"]=0,
	["help"]=0,
	["indoors"]=0,
	["known"]=8,
	["mod"]=5,
	["modifier"]=5,
	["mounted"]=0,
	["none"]=0,
	["outdoors"]=0,
	["overridebar"]=1,
	["party"]=0,
	["pet"]=2,
	["petbattle"]=0,
	["possessbar"]=1,
	["pvptalent"]=7,
	["raid"]=0,
	["spec"]=1,
	["stance"]=1,
	["stealth"]=0,
	["swimming"]=0,
	["talent"]=7,
	["unithasvehicleui"]=0,
	["vehicleui"]=0,
	["worn"]=2,
}

MT.optargs={
	[6]={"1","2","3","4","5","LeftButton","MiddleButton","RightButton","Button4","Button5"},
	[5]={
		"alt","altctrl","altshift","altshiftctrl","altctrlshift",
		"shift","shiftctrl","shiftalt","shiftaltctrl","shiftctrlalt",
		"ctrl","ctrlalt","ctrlshift","ctrlshiftalt","ctrlaltshift",
		"AUTOLOOTTOGGLE","STICKCAMERA","SPLITSTACK","PICKUPACTION","COMPAREITEMS", -- specify whichever key is bound to these actions
		"OPENALLBAGS","QUESTWATCHTOGGLE","SELFCAST", -- specify whichever key is bound to these actions
	},
	[4]={"party","raid"},
}

--add some globals to make things easier
_G.SLASH_SHOW1="#show"
_G.SLASH_SHOWTOOLTIP1="#showtooltip"

--{short form, parameters (0=none,1=required,2=optional,5=removed/disabled)}
MT.commandinfo={
	["SHOW"]=2,
	["SHOWTOOLTIP"]=2,
	["ASSIST"]=2,
	["BATTLEGROUND"]=1,
	["BENCHMARK"]=2,
	["CANCELAURA"]=1,
	["CAST"]=1,
	["CASTHLYPH"]=1,
	["CASTRANDOM"]=1,
	["CASTSEQUENCE"]=1,
	["CHANGEACTIONBAR"]=1,
	["CHANNEL"]=1,
	["CHAT_AFK"]=2,
	["CHAT_ANNOUNCE"]=1,
	["CHAT_BAN"]=1,
	["CHAT_CINVITE"]=1,
	["CHAT_DND"]=2,
	["CHAT_KICK"]=1,
	["CHAT_MODERATE"]=1,
	["CHAT_MODERATOR"]=1,
	["CHAT_MUTE"]=1,
	["CHAT_OWNER"]=1,
	["CHAT_PASSWORD"]=1,
	["CHAT_UNBAN"]=1,
	["CHAT_UNMODERATOR"]=1,
	["CHAT_UNMUTE"]=1,
	["CLEAR_WORLD_MARKER"]=2,
	["CLICK"]=1,
	["CONSOLE"]=1,
	["DUEL"]=2,
	["DUMP"]=2,
	["EMOTE"]=1,
	["EQUIP"]=1,
	["EQUIP_SET"]=1,
	["EQUIP_TO_SLOT"]=1,
	["EVENTTRACE"]=2,
	["FOCUS"]=2,
	["FOLLOW"]=2,
	["FRAMESTACK"]=2,
	["FRIENDS"]=1,
	["GUILD"]=1,
	["GUILD_DEMOTE"]=1,
	["GUILD_INVITE"]=1,
	["GUILD_LEADER"]=1,
	["GUILD_MOTD"]=2,
	["GUILD_PROMOTE"]=1,
	["GUILD_UNINVITE"]=1,
	["IGNORE"]=1,
	["INVITE"]=1,
	["JOIN"]=1,
	["LEAVE"]=1,
	["LIST_CHANNEL"]=2,
	["SETTHRESHOLD"]=1,
	["MAINASSISTON"]=1,
	["MAINTANKON"]=1,
	["OFFICER"]=1,
	["PARTY"]=1,
	["PET_AUTOCASTOFF"]=1,
	["PET_AUTOCASTON"]=1,
	["PET_AUTOCASTTOGGLE"]=1,
	["PROMOTE"]=1,
	["RAID"]=1,
	["RAID_WARNING"]=1,
	["RANDOM"]=2,
	["REMOVEFRIEND"]=1,
	["REPLY"]=1,
	["SAY"]=1,
	["SCRIPT"]=1,
	["SET_TITLE"]=2,
	["SMART_WHISPER"]=1,
	["STARTATTACK"]=2,
	["STOPWATCH"]=2,
	["SWAPACTIONBAR"]=1,
	["TARGET"]=1,
	["TARGET_EXACT"]=1,
	["TARGET_MARKER"]=1,
	["TARGET_NEAREST_ENEMY"]=2,
	["TARGET_NEAREST_ENEMY_PLAYER"]=2,
	["TARGET_NEAREST_FRIEND"]=2,
	["TARGET_NEAREST_FRIEND_PLAYER"]=2,
	["TARGET_NEAREST_PARTY"]=2,
	["TARGET_NEAREST_RAID"]=2,
	["TEAM_CAPTAIN"]=1,
	["TEAM_DISBAND"]=1,
	["TEAM_INVITE"]=1,
	["TEAM_QUIT"]=1,
	["TEAM_UNINVITE"]=1,
	["UNIGNORE"]=1,
	["UNINVITE"]=1,
	["USE"]=1,
	["USERANDOM"]=1,
	["USE_TALENT_SPEC"]=1,
	["WARGAME"]=1,
	["WHO"]=1,
	["WORLD_MARKER"]=1,
	["YELL"]=1,
}

MT.emoteinfo={}

StaticPopupDialogs.MACROTOOLKIT_TOOLONG = {
	text = "",
	button1 = _G.OKAY,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
	showAlert = 1,
}

StaticPopupDialogs.MACROTOOLKIT_BACKUPNAME = {
	text = "",
	button1 = _G.ACCEPT,
	button2 = _G.CANCEL,
	hasEditBox = 1,
	OnAccept = function(this) MT:SetBackupName(this) end,
	EditBoxOnEnterPressed = function(this) MT:SetBackupName(this:GetParent()) end,
	EditBoxOnEscapePressed = function(this) this:GetParent():Hide()	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

local function slashOnAccept(this)
	local slashname = string.lower(this.editBox:GetText())
	this:Hide()
	if string.sub(slashname, 1, 1) == MT.slash then slashname = string.sub(slashname, 2) end
	for c, info in pairs(MT.commands) do
		if c == slashname  and not info[4] then
			StaticPopupDialogs.MACROTOOLKIT_TOOLONG.text = L["Command already defined elsewhere"]
			StaticPopup_Show("MACROTOOLKIT_TOOLONG")
			return
		end
	end
	MT.newslash = slashname
	MacroToolkitFrame:Hide()
	if not MT.MTSF then MT.MTSF = MT:CreateScriptFrame() end
	MT.MTSF:Show()
end

StaticPopupDialogs.MACROTOOLKIT_SLASHNAME = {
	text = L["Enter the name of the slash command"],
	button1 = _G.ACCEPT,
	button2 = _G.CANCEL,
	hasEditBox = 1,
	OnAccept = function(this) slashOnAccept(this) end,
	EditBoxOnEnterPressed = function(this) slashOnAccept(this:GetParent()) end,
	EditBoxOnEscapePressed = function(this) this:GetParent():Hide()	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs.MACROTOOLKIT_DELETEBACKUP = {
	text = "",
	button1 = _G.YES,
	button2 = _G.NO,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
	showAlert = 1,
}

StaticPopupDialogs.MACROTOOLKIT_ALERT = {
	text = "",
	button1 = _G.OKAY,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs.MACROTOOLKIT_CONFIRM_DELETING_CHARACTER_SPECIFIC_BINDINGS = {
	text = _G.CONFIRM_DELETING_CHARACTER_SPECIFIC_BINDINGS,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function()
		SaveBindings(MacroToolkitBindingFrame.which)
		MacroToolkitBindingFrame.outputtext:SetText("")
		MacroToolkitBindingFrame.selected = nil
		MacroToolkitBindingFrame:Hide()
		MT.CONFIRMED_DELETING_CHARACTER_SPECIFIC_BINDINGS = true
	end,
	timeout = 0,
	whileDead = 1,
	showAlert = 1,
}
