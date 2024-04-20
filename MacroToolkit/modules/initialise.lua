local _G = _G
--- @class MacroToolkit
local MT = MacroToolkit
MT.LS = LibStub
MT.L = MT.LS("AceLocale-3.0"):GetLocale("MacroToolkit")
MT.AIS = MT.LS("LibAdvancedIconSelector-MTK")
MT.LDB = MT.LS("LibDataBroker-1.1")
MT.slash = string.sub(_G.SLASH_CAST1, 1, 1)
MT.click = _G.SLASH_CLICK1
MT.target = _G.SLASH_TARGET1
MT.MAX_EXTRA_MACROS = 1000 -- I'd like to see you try to hit this limit :P
local L = MT.L
local SendChatMessage, format = SendChatMessage, format

MT.frame:RegisterEvent("ADDON_LOADED")
MT.frame:RegisterEvent("PLAYER_LOGIN")
MT.frame:SetScript("OnEvent", function(...) MT:eventHandler(...) end)
MT.commands = {
	cancelmacro = {"stopmacro", 0},
}

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

MT.CONDITION_TYPE_NONE = 0
MT.CONDITION_TYPE_NUMERIC = 1
MT.CONDITION_TYPE_TEXTUAL = 2
MT.CONDITION_TYPE_ALPHANUMERIC = 3
MT.CONDITION_TYPE_PARTY_RAID = 4
MT.CONDITION_TYPE_MOD_KEYS = 5
MT.CONDITION_TYPE_MOUSEBUTTONS = 6
MT.CONDITION_TYPE_NUMERIC_WITH_SLASH = 7
MT.CONDITION_TYPE_ALPHANUMERIC_WITH_SPACES = 8
MT.conditions = {
	["actionbar"] = MT.CONDITION_TYPE_NUMERIC,
	["advflyable"] = MT.CONDITION_TYPE_NONE,
	["bar"] = MT.CONDITION_TYPE_NUMERIC,
	["bonusbar"] = MT.CONDITION_TYPE_NUMERIC,
	["btn"] = MT.CONDITION_TYPE_MOUSEBUTTONS,
	["button"] = MT.CONDITION_TYPE_MOUSEBUTTONS,
	["canexitvehicle"] = MT.CONDITION_TYPE_NONE,
	["channeling"] = MT.CONDITION_TYPE_ALPHANUMERIC,
	["channelling"] = MT.CONDITION_TYPE_ALPHANUMERIC,
	["combat"] = MT.CONDITION_TYPE_NONE,
	["cursor"] = MT.CONDITION_TYPE_TEXTUAL,
	["dead"] = MT.CONDITION_TYPE_NONE,
	["equipped"] = MT.CONDITION_TYPE_TEXTUAL,
	["exists"] = MT.CONDITION_TYPE_NONE,
	["extrabar"] = MT.CONDITION_TYPE_NUMERIC,
	["flyable"] = MT.CONDITION_TYPE_NONE,
	["flying"] = MT.CONDITION_TYPE_NONE,
	["form"] = MT.CONDITION_TYPE_NUMERIC,
	["group"] = MT.CONDITION_TYPE_PARTY_RAID,
	["harm"] = MT.CONDITION_TYPE_NONE,
	["help"] = MT.CONDITION_TYPE_NONE,
	["indoors"] = MT.CONDITION_TYPE_NONE,
	["known"] = MT.CONDITION_TYPE_ALPHANUMERIC_WITH_SPACES,
	["mod"] = MT.CONDITION_TYPE_MOD_KEYS,
	["modifier"] = MT.CONDITION_TYPE_MOD_KEYS,
	["mounted"] = MT.CONDITION_TYPE_NONE,
	["none"] = MT.CONDITION_TYPE_NONE,
	["outdoors"] = MT.CONDITION_TYPE_NONE,
	["overridebar"] = MT.CONDITION_TYPE_NUMERIC,
	["party"] = MT.CONDITION_TYPE_NONE,
	["pet"] = MT.CONDITION_TYPE_TEXTUAL,
	["petbattle"] = MT.CONDITION_TYPE_NONE,
	["possessbar"] = MT.CONDITION_TYPE_NUMERIC,
	["pvptalent"] = MT.CONDITION_TYPE_NUMERIC_WITH_SLASH,
	["raid"] = MT.CONDITION_TYPE_NONE,
	["spec"] = MT.CONDITION_TYPE_NUMERIC,
	["stance"] = MT.CONDITION_TYPE_NUMERIC,
	["stealth"] = MT.CONDITION_TYPE_NONE,
	["swimming"] = MT.CONDITION_TYPE_NONE,
	["talent"] = MT.CONDITION_TYPE_NUMERIC_WITH_SLASH,
	["unithasvehicleui"] = MT.CONDITION_TYPE_NONE,
	["vehicleui"] = MT.CONDITION_TYPE_NONE,
	["worn"] = MT.CONDITION_TYPE_TEXTUAL,
}

MT.optionalConditions = {
	group = true,
	mod = true,
	modifier = true,
	pet = true,
	channeling = true,
	channelling = true,
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

MT.COMMAND_PARAM_REQUIRED = 1;
MT.COMMAND_PARAM_OPTIONAL = 2;
MT.COMMAND_REMOVED = 5;
MT.commandinfo={
	["SHOW"] = MT.COMMAND_PARAM_OPTIONAL,
	["SHOWTOOLTIP"] = MT.COMMAND_PARAM_OPTIONAL,
	["ASSIST"] = MT.COMMAND_PARAM_OPTIONAL,
	["BATTLEGROUND"] = MT.COMMAND_PARAM_REQUIRED,
	["BENCHMARK"] = MT.COMMAND_PARAM_OPTIONAL,
	["CANCELAURA"] = MT.COMMAND_PARAM_REQUIRED,
	["CAST"] = MT.COMMAND_PARAM_REQUIRED,
	["CASTHLYPH"] = MT.COMMAND_PARAM_REQUIRED,
	["CASTRANDOM"] = MT.COMMAND_PARAM_REQUIRED,
	["CASTSEQUENCE"] = MT.COMMAND_PARAM_REQUIRED,
	["CHANGEACTIONBAR"] = MT.COMMAND_PARAM_REQUIRED,
	["CHANNEL"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_AFK"] = MT.COMMAND_PARAM_OPTIONAL,
	["CHAT_ANNOUNCE"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_BAN"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_CINVITE"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_DND"] = MT.COMMAND_PARAM_OPTIONAL,
	["CHAT_KICK"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_MODERATE"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_MODERATOR"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_MUTE"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_OWNER"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_PASSWORD"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_UNBAN"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_UNMODERATOR"] = MT.COMMAND_PARAM_REQUIRED,
	["CHAT_UNMUTE"] = MT.COMMAND_PARAM_REQUIRED,
	["CLEAR_WORLD_MARKER"] = MT.COMMAND_PARAM_OPTIONAL,
	["CLICK"] = MT.COMMAND_PARAM_REQUIRED,
	["CONSOLE"] = MT.COMMAND_PARAM_REQUIRED,
	["DUEL"] = MT.COMMAND_PARAM_OPTIONAL,
	["DUMP"] = MT.COMMAND_PARAM_OPTIONAL,
	["EMOTE"] = MT.COMMAND_PARAM_REQUIRED,
	["EQUIP"] = MT.COMMAND_PARAM_REQUIRED,
	["EQUIP_SET"] = MT.COMMAND_PARAM_REQUIRED,
	["EQUIP_TO_SLOT"] = MT.COMMAND_PARAM_REQUIRED,
	["EVENTTRACE"] = MT.COMMAND_PARAM_OPTIONAL,
	["FOCUS"] = MT.COMMAND_PARAM_OPTIONAL,
	["FOLLOW"] = MT.COMMAND_PARAM_OPTIONAL,
	["FRAMESTACK"] = MT.COMMAND_PARAM_OPTIONAL,
	["FRIENDS"] = MT.COMMAND_PARAM_REQUIRED,
	["GUILD"] = MT.COMMAND_PARAM_REQUIRED,
	["GUILD_DEMOTE"] = MT.COMMAND_PARAM_REQUIRED,
	["GUILD_INVITE"] = MT.COMMAND_PARAM_REQUIRED,
	["GUILD_LEADER"] = MT.COMMAND_PARAM_REQUIRED,
	["GUILD_MOTD"] = MT.COMMAND_PARAM_OPTIONAL,
	["GUILD_PROMOTE"] = MT.COMMAND_PARAM_REQUIRED,
	["GUILD_UNINVITE"] = MT.COMMAND_PARAM_REQUIRED,
	["IGNORE"] = MT.COMMAND_PARAM_REQUIRED,
	["INVITE"] = MT.COMMAND_PARAM_REQUIRED,
	["JOIN"] = MT.COMMAND_PARAM_REQUIRED,
	["LEAVE"] = MT.COMMAND_PARAM_REQUIRED,
	["LIST_CHANNEL"] = MT.COMMAND_PARAM_OPTIONAL,
	["SETTHRESHOLD"] = MT.COMMAND_PARAM_REQUIRED,
	["MAINASSISTON"] = MT.COMMAND_PARAM_REQUIRED,
	["MAINTANKON"] = MT.COMMAND_PARAM_REQUIRED,
	["OFFICER"] = MT.COMMAND_PARAM_REQUIRED,
	["PARTY"] = MT.COMMAND_PARAM_REQUIRED,
	["PET_AUTOCASTOFF"] = MT.COMMAND_PARAM_REQUIRED,
	["PET_AUTOCASTON"] = MT.COMMAND_PARAM_REQUIRED,
	["PET_AUTOCASTTOGGLE"] = MT.COMMAND_PARAM_REQUIRED,
	["PROMOTE"] = MT.COMMAND_PARAM_REQUIRED,
	["RAID"] = MT.COMMAND_PARAM_REQUIRED,
	["RAID_WARNING"] = MT.COMMAND_PARAM_REQUIRED,
	["RANDOM"] = MT.COMMAND_PARAM_OPTIONAL,
	["REMOVEFRIEND"] = MT.COMMAND_PARAM_REQUIRED,
	["REPLY"] = MT.COMMAND_PARAM_REQUIRED,
	["SAY"] = MT.COMMAND_PARAM_REQUIRED,
	["SCRIPT"] = MT.COMMAND_PARAM_REQUIRED,
	["SET_TITLE"] = MT.COMMAND_PARAM_OPTIONAL,
	["SMART_WHISPER"] = MT.COMMAND_PARAM_REQUIRED,
	["STARTATTACK"] = MT.COMMAND_PARAM_OPTIONAL,
	["STOPWATCH"] = MT.COMMAND_PARAM_OPTIONAL,
	["SWAPACTIONBAR"] = MT.COMMAND_PARAM_REQUIRED,
	["TARGET"] = MT.COMMAND_PARAM_REQUIRED,
	["TARGET_EXACT"] = MT.COMMAND_PARAM_REQUIRED,
	["TARGET_MARKER"] = MT.COMMAND_PARAM_REQUIRED,
	["TARGET_NEAREST_ENEMY"] = MT.COMMAND_PARAM_OPTIONAL,
	["TARGET_NEAREST_ENEMY_PLAYER"] = MT.COMMAND_PARAM_OPTIONAL,
	["TARGET_NEAREST_FRIEND"] = MT.COMMAND_PARAM_OPTIONAL,
	["TARGET_NEAREST_FRIEND_PLAYER"] = MT.COMMAND_PARAM_OPTIONAL,
	["TARGET_NEAREST_PARTY"] = MT.COMMAND_PARAM_OPTIONAL,
	["TARGET_NEAREST_RAID"] = MT.COMMAND_PARAM_OPTIONAL,
	["TEAM_CAPTAIN"] = MT.COMMAND_PARAM_REQUIRED,
	["TEAM_DISBAND"] = MT.COMMAND_PARAM_REQUIRED,
	["TEAM_INVITE"] = MT.COMMAND_PARAM_REQUIRED,
	["TEAM_QUIT"] = MT.COMMAND_PARAM_REQUIRED,
	["TEAM_UNINVITE"] = MT.COMMAND_PARAM_REQUIRED,
	["UNIGNORE"] = MT.COMMAND_PARAM_REQUIRED,
	["UNINVITE"] = MT.COMMAND_PARAM_REQUIRED,
	["USE"] = MT.COMMAND_PARAM_REQUIRED,
	["USERANDOM"] = MT.COMMAND_PARAM_REQUIRED,
	["USE_TALENT_SPEC"] = MT.COMMAND_PARAM_REQUIRED,
	["WARGAME"] = MT.COMMAND_PARAM_REQUIRED,
	["WHO"] = MT.COMMAND_PARAM_REQUIRED,
	["WORLD_MARKER"] = MT.COMMAND_PARAM_REQUIRED,
	["YELL"] = MT.COMMAND_PARAM_REQUIRED,
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
