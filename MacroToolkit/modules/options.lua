local _G = _G
local MT = MacroToolkit
local AceConfig = MT.LS("AceConfig-3.0")
local AceConfigDialog = MT.LS("AceConfigDialog-3.0")
local AceDBOptions = MT.LS("AceDBOptions-3.0")
local LSM = MT.LS("LibSharedMedia-3.0")
local L = MT.L
local CreateFrame, ipairs, pairs, string, tonumber = CreateFrame, ipairs, pairs, string, tonumber

--First visible frame
local function createMainPanel()
	local frame = CreateFrame("Frame", "MacroToolkitOptionsMain", nil, "BackdropTemplate")
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	local version = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	local author = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetFormattedText("|T%s:%d|t %s", "Interface\\AddOns\\MacroToolkit\\mtsm", 48, "Macro Toolkit")
	title:SetPoint("CENTER", frame, "CENTER", 0, 170)
	version:SetFormattedText("%s %s", _G.GAME_VERSION_LABEL, GetAddOnMetadata("MacroToolkit", "Version"))
	version:SetPoint("CENTER", frame, "CENTER", 0, 130)
	author:SetFormattedText("%s: Deepac", L["Author"])
	author:SetPoint("CENTER", frame, "CENTER", 0, 100)
	return frame
end

local function removeCharMacros()
	MT.db.global.allcharmacros = false
	for ch, chd in pairs(MacroToolkitDB.char) do
		if chd.macros then chd.macros = nil end
	end
	MT.OptionsFrame:Hide()
	MT.OptionsFrame:Show()
end

function MT:SetScale(value)
	if not value then return end
	MT.db.profile.scale = value
	MacroToolkitFrame:SetScale(value)
	if MacroToolkitRestoreFrame then MacroToolkitRestoreFrame:SetScale(value) end
	if MacroTtoolkitPopup then MacroToolkitPopup:SetScale(value) end
	if MacroToolkitScriptFrame then MacroToolkitScriptFrame:SetScale(value) end
	if MacroTookitBuilderFrame then MacroToolkitBuilderFrame:SetScale(value) end
	MacroToolkitFrame:SetSize(638, MT.db.profile.height)
end

local function addCharMacros()
	MT.db.global.allcharmacros = true
	local numMacros = select(2, GetNumMacros())
	MT.db.char.macros = {}
	for m = _G.MAX_ACCOUNT_MACROS + 1, _G.MAX_ACCOUNT_MACROS + numMacros do
		local name, texture, body = GetMacroInfo(m)
		if not string.find(body, "MTSB") then
			MT.db.char.macros[m] = {name = name, icon = string.gsub(string.upper(texture), "INTERFACE\\ICONS\\", ""), body = body}
		end
	end
	MT.OptionsFrame:Hide()
	MT.OptionsFrame:Show()
end

local checkPanel = {
	order = 1,
	type = "group",
	name = _G.MAIN_MENU,
	args = {
		override = {
			order = 1,
			type = "toggle",
			width = "full",
			name = L["Override built in macro UI"],
			get = function() return MT.db.profile.override end,
			set = function(info, value)
					MT.db.profile.override = value
					if value then
						MT.showmacroframe = ShowMacroFrame
						ShowMacroFrame = function() MacroToolkitFrame:Show() end
						MT.origMTText = MacroFrameText
						MacroFrameText = MacroToolkitFrameText
					elseif MT.showmacroframe then
						ShowMacroFrame = MT.showmacroframe
						MacroFrameText = MT.origMTText
					end
				end,
			},
		usecolour = {
			order = 2,
			type = "toggle",
			name = L["Use syntax highlighting"],
			width = "full",
			get = function() return MT.db.profile.usecolours end,
			set = function(info, value)
					MT.db.profile.usecolours = value
					if value then MacroToolkitFauxScrollFrame:Show()
					else MacroToolkitFauxScrollFrame:Hide() end
				end,
		},
		unknown = {
			order = 3,
			type = "toggle",
			name = L["Unknown parameter causes error"],
			width = "full",
			get = function() return MT.db.profile.unknown end,
			set = function(info, value)
					MT.db.profile.unknown = value
					if value then
						MacroToolkitErrorBg:Show()
						MacroToolkitErrorScrollFrame:Show()
					else
						MacroToolkitErrorBg:Hide()
						MacroToolkitErrorScrollFrame:Hide()
					end
				end,
		},
		replace = {
			order = 4,
			type = "toggle",
			name = L["Replace scripts with slash command"],
			desc = L["Replace known scripts with Macro Toolkit slash commands"],
			width = "full",
			get = function() return MT.db.profile.replacemt end,
			set  = function(info, value) MT.db.profile.replacemt = value end,
		},
		broker = {
			order = 5,
			type = "toggle",
			name = L["Enable data broker"],
			desc = L["Enable certain types of macro to be called via a data broker addon"],
			width = "full",
			get = function() return MT.db.profile.broker end,
			set = function(info, value) MT.db.profile.broker = value MT:MacroFrameUpdate() end,
		},
		noskin = {
			order = 6,
			type = "toggle",
			name = L["Do not skin for ElvUI"],
			desc = L["Requires a UI reload to take effect"],
			width = "full",
			hidden = not IsAddOnLoaded("ElvUI"),
			get = function() return MT.db.profile.noskin end,
			set = function(info, value) MT.db.profile.noskin = value end,
		},
		uselib = {
			order = 7,
			type = "toggle",
			name = L["Use icon name lookup library for icon search"],
			desc = L["This will enable macro icon names instead of numbers. Uses about 2MB of RAM."],
			width = "full",
			get = function() return MT.db.profile.useiconlib end,
			set = function(info, value)
				MT.db.profile.useiconlib = value
				if value and not IsAddOnLoaded("MacroToolkitIcons") then
					--Try loading the data addon
					local loaded, reason = LoadAddOn("MacroToolkitIcons")

					if not loaded then
						--load failed
						MacroToolkit.usingiconlib = nil
					else
						MacroToolkit.usingiconlib = true
					end
				else
					MacroToolkit.usingiconlib = nil
					MacroToolkit.TextureNames = nil
					collectgarbage("collect")
				end
			end,
		},
		confirmdeletion = {
			order = 8,
			type = "toggle",
			name = L["Confirm macro deletion"],
			width = "full",
			get = function() return MT.db.profile.confirmdelete end,
			set = function(info, value) MT.db.profile.confirmdelete = value end,
		},
		hidepopup = {
			order = 9,
			type = "toggle",
			name = L["Hide 'Macro shortened by n characters' popup"],
			width = "full",
			get = function() return MT.db.profile.hidepopup end,
			set = function(info, value) MT.db.profile.hidepopup = value end,
		},
		allcharmacros = {
			order = 10,
			type = "toggle",
			name = L["Make all character specific macros available to all characters"],
			width = "full",
			get = function() return MT.db.global.allcharmacros end,
			set =
				function(info, value)
					if not value then
						StaticPopupDialogs.MACROTOOLKIT_TOOLONG.text = L["This will remove Macro Toolkit's copy of all your character specific Macros. The macros themselves will not be affected."]
						StaticPopupDialogs.MACROTOOLKIT_TOOLONG.OnAccept = removeCharMacros
						StaticPopup_Show("MACROTOOLKIT_TOOLONG")
					else addCharMacros() end
				end,
			},
		allcharmacrosdesc1 = {
			order = 11,
			type = "description",
			name = L["This may impact performance and loading time on low end machines"],
		},
		allcharmacrosdesc2 = {
			order = 12,
			type = "description",
			name = L["You will need to log into each of your characters with Macro Toolkit enabled to update Macro Toolkit's copy of that character's macros"],
		},
		--[[
		escape = {
			order = 5,
			type = "toggle",
			name = L["Respond to the escape key"],
			width = "full",
			get = function() return MT.db.profile.escape end,
			set =
				function(info, value)
					MT.db.profile.escape = value
					if value then MacroToolkitFrame:SetScript("OnKeyDown", function(this, key) MT:FrameOnKeyDown(this, key) end)
					else MacroToolkitFrame:SetScript("OnKeyDown", nil) end
				end,
		},
		]]--
	},
}

local coloursPanel = {
	order = 2,
	type = "group",
	name = L["Syntax Highlighting"],
	args = {
		defaultcolour = {
			order = 1,
			type = "color",
			width = "full",
			name = _G.DEFAULT,
			get = function() return MT:HexToRGB(MT.db.profile.defaultcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.defaultcolour = MT:RGBToHex(r, g, b, a) end
		},
		stringcolour = {
			order = 2,
			type = "color",
			width = "full",
			name = L["Text"],
			get = function() return MT:HexToRGB(MT.db.profile.stringcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.stringcolour = MT:RGBToHex(r, g, b, a) end
		},
		emotecolour = {
			order = 3,
			type = "color",
			width = "full",
			name = L["Emotes"],
			get = function() return MT:HexToRGB(MT.db.profile.emotecolour) end,
			set = function(info, r, g, b, a) MT.db.profile.emotecolour = MT:RGBToHex(r, g, b, a) end
		},
		scriptcolour = {
			order = 4,
			type = "color",
			width = "full",
			name = L["Scripts"],
			get = function() return MT:HexToRGB(MT.db.profile.scriptcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.scriptcolour = MT:RGBToHex(r, g, b, a) end
		},
		commandcolour = {
			order = 5,
			type = "color",
			width = "full",
			name = L["Commands"],
			get = function() return MT:HexToRGB(MT.db.profile.commandcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.commandcolour = MT:RGBToHex(r, g, b, a) end
		},
		spellcolour = {
			order = 6,
			type = "color",
			width = "full",
			name = _G.SPELLS,
			get = function() return MT:HexToRGB(MT.db.profile.spellcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.spellcolour = MT:RGBToHex(r, g, b, a) end
		},
		targetcolour = {
			order = 7,
			type = "color",
			width = "full",
			name = L["Targets"],
			get = function() return MT:HexToRGB(MT.db.profile.targetcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.targetcolour = MT:RGBToHex(r, g, b, a) end
		},
		conditioncolour = {
			order = 8,
			type = "color",
			width = "full",
			name = L["Conditions"],
			get = function() return MT:HexToRGB(MT.db.profile.conditioncolour) end,
			set = function(info, r, g, b, a) MT.db.profile.conditioncolour = MT:RGBToHex(r, g, b, a) end
		},
		errorcolour = {
			order = 9,
			type = "color",
			width = "full",
			name = _G.ERRORS,
			get = function() return MT:HexToRGB(MT.db.profile.errorcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.errorcolour = MT:RGBToHex(r, g, b, a) end
		},
		itemcolour = {
			order = 10,
			type = "color",
			width = "full",
			name = _G.ITEMS,
			get = function() return MT:HexToRGB(MT.db.profile.itemcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.itemcolour = MT:RGBToHex(r, g, b, a) end
		},
		mtcolour = {
			order = 11,
			type = "color",
			width = "full",
			name = L["Macro Toolkit slash commands"],
			get = function() return MT:HexToRGB(MT.db.profile.mtcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.mtcolour = MT:RGBToHex(r, g, b, a) end
		},
		seqcolour = {
			order = 12,
			type = "color",
			width = "full",
			name = format("%s reset", string.sub(_G.SLASH_CASTSEQUENCE1, 2)),
			get = function() return MT:HexToRGB(MT.db.profile.seqcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.seqcolour = MT:RGBToHex(r, g, b, a) end
		},
		comcolour = {
			order = 13,
			type ="color",
			width = "full",
			name = L["Comments"],
			get = function() return MT:HexToRGB(MT.db.profile.comcolour) end,
			set = function(info, r, g, b, a) MT.db.profile.comcolour = MT:RGBToHex(r, g, b, a) end
		},
	},
}

local iconsPanel = {
	order = 3,
	type = "group",
	name = L["Icons"],
	args = {
		override = {
			order = 1,
			type = "description",
			name = L["Control which icons are available to pick for macros"],
		},
		dynamic = {
			order = 2,
			type = "toggle",
			width = "full",
			name = L["Question mark icon"],
			get = function() return MT.db.profile.dynamicicon end,
			set = function(info, value)
					MT.db.profile.dynamicicon = value
					MacroToolkitPopupIcons:SetSectionVisibility("DynamicIcon", value)
					MT:UpdateIconCount()
				end,
		},
		abilityicons = {
			order = 3,
			type = "toggle",
			width = "full",
			name = L["Ability icons"],
			get = function() return MT.db.profile.abilityicons end,
			set = function(info, value)
					MT.db.profile.abilityicons = value
					MacroToolkitPopupIcons:SetSectionVisibility("AbilityIcons", value)
					MT:UpdateIconCount()
				end,
		},
		achicons = {
			order = 4,
			type = "toggle",
			width = "full",
			name = L["Achievement icons"],
			get = function() return MT.db.profile.achicons end,
			set = function(info, value)
					MT.db.profile.achicons = value
					MacroToolkitPopupIcons:SetSectionVisibility("AchievementIcons", value)
					MT:UpdateIconCount()
				end,
		},
		invicons = {
			order = 5,
			type = "toggle",
			width = "full",
			name = L["Inventory icons"],
			get = function() return MT.db.profile.invicons end,
			set = function(info, value)
					MT.db.profile.invicons = value
					MacroToolkitPopupIcons:SetSectionVisibility("InventoryIcons", value)
					MT:UpdateIconCount()
				end,
		},
		itemicons = {
			order = 6,
			type = "toggle",
			width = "full",
			name = L["Item icons"],
			get = function() return MT.db.profile.itemicons end,
			set = function(info, value)
					MT.db.profile.itemicons = value
					MacroToolkitPopupIcons:SetSectionVisibility("ItemIcons", value)
					MT:UpdateIconCount()
				end,
		},
		spellicons = {
			order = 7,
			type = "toggle",
			width = "full",
			name = L["Spell icons"],
			get = function() return MT.db.profile.spellicons end,
			set = function(info, value)
					MT.db.profile.spellicons = value
					MacroToolkitPopupIcons:SetSectionVisibility("SpellIcons", value)
					MT:UpdateIconCount()
				end,
		},
		miscicons = {
			order = 8,
			type = "toggle",
			width = "full",
			name = L["Miscellaneous icons"],
			get = function() return MT.db.profile.miscicons end,
			set = function(info, value)
					MT.db.profile.miscicons = value
					MacroToolkitPopupIcons:SetSectionVisibility("MiscellaneousIcons", value)
					MT:UpdateIconCount()
				end,
		},
	},
}

local interfacePanel = {
	order = 4,
	type = "group",
	name = _G.UIOPTIONS_MENU,
	childGroups = "tab",
	args = {
		buttonstab = {
			order = 1,
			type = "group",
			name = L["Buttons"],
			args = {
				note = {
					order = 0,
					type = "description",
					fontSize = "medium",
					name = format("\n%s:\n", L["Only display the following buttons"]),
				},
				conditions = {
					order = 1,
					type = "toggle",
					name = L["Conditions"],
					width = "full",
					get = function() return MT.db.profile.visconditions end,
					set = function(info, value) MT.db.profile.visconditions = value; MT:UpdateInterfaceOptions() end,
				},
				options = {
					order = 2,
					type = "toggle",
					name = _G.MAIN_MENU,
					width = "full",
					get = function() return MT.db.profile.visoptionsbutton end,
					set = function(info, value) MT.db.profile.visoptionsbutton = value; MT:UpdateInterfaceOptions() end,
				},
				custom = {
					order = 3,
					type = "toggle",
					name = _G.CUSTOM,
					width = "full",
					get = function() return MT.db.profile.viscustom end,
					set = function(info, value) MT.db.profile.viscustom = value; MT:UpdateInterfaceOptions() end,
				},
				backup = {
					order = 4,
					type = "toggle",
					name = L["Backup"],
					width = "full",
					get = function() return MT.db.profile.visbackup end,
					set =
						function(info, value)
							MT.db.profile.visbackup = value
							if value then MT.db.profile.visdrake = false
							elseif not MT.db.profile.visshare and not MT.db.profile.visclear and not MT.db.profile.viserrors and not MT.db.profile.doublewide then MT.db.profile.visdrake = true end
							MT:UpdateInterfaceOptions()
						end,
				},
				clear = {
					order = 5,
					type = "toggle",
					name = _G.CLEAR_ALL,
					width = "full",
					get = function() return MT.db.profile.visclear end,
					set =
						function(info, value)
							MT.db.profile.visclear = value
							if value then MT.db.profile.visdrake = false
							elseif not MT.db.profile.visbackup and not MT.db.profile.visshare and not MT.db.profile.viserrors and not MT.db.profile.doublewide then MT.db.profile.visdrake = true end
							MT:UpdateInterfaceOptions()
						end,
				},
				share = {
					order = 6,
					type = "toggle",
					name = _G.SHARE_QUEST_ABBREV,
					width = "full",
					get = function() return MT.db.profile.visshare end,
					set =
						function(info, value)
							MT.db.profile.visshare = value
							if value then MT.db.profile.visdrake = false
							elseif not MT.db.profile.visbackup and not MT.db.profile.visclear and not MT.db.profile.viserrors and not MT.db.profile.doublewide then MT.db.profile.visdrake = true end
							MT:UpdateInterfaceOptions()
						end,
				},
				macrobox = {
					order = 7,
					type = "toggle",
					name = "MacroBox",
					width = "full",
					hidden = function() return not MacroBox end,
					get = function() return MT.db.profile.vismacrobox end,
					set =
						function(info, value)
							MT.db.profile.vismacrobox = value
							if value then MacroToolkitMacroBox:Show() else MacroToolkitMacroBox:Hide() end
							MT:UpdateInterfaceOptions()
						end,
				},
				extend = {
					order = 8,
					type = "toggle",
					name = L["Extend"],
					width = "full",
					get = function() return MT.db.profile.visextend end,
					set = function(info, value) MT.db.profile.visextend = value; MT:UpdateInterfaceOptions() end,
				},
				shorten = {
					order = 9,
					type = "toggle",
					name = L["Shorten"],
					width = "full",
					get = function() return MT.db.profile.visshorten end,
					set = function(info, value) MT.db.profile.visshorten = value; MT:UpdateInterfaceOptions() end,
				},
				bindings = {
					order = 10,
					type = "toggle",
					name = _G.KEY_BINDINGS_MAC,
					width = "full",
					get = function() return MT.db.profile.visbind end,
					set = function(info, value) MT.db.profile.visbind = value; MT:UpdateInterfaceOptions() end,
				},
			},
		},
		inserttab = {
			order = 2,
			type = "group",
			name = _G.KEY_INSERT,
			args = {
				special = {
					order = 1,
					type = "toggle",
					name = L["Insert special"],
					width = "full",
					get = function() return MT.db.profile.visaddscript end,
					set =
						function(info, value)
							MT.db.profile.visaddscript = value
							if value then MT.db.profile.viscrest = false
							elseif not MT.db.profile.visaddslot then MT.db.profile.viscrest = true end
							MT:UpdateInterfaceOptions()
						end,
				},
				slot = {
					order = 2,
					type = "toggle",
					name = L["Insert slot"],
					width = "full",
					get = function() return MT.db.profile.visaddslot end,
					set =
						function(info, value)
							MT.db.profile.visaddslot = value
							if value then MT.db.profile.viscrest = false
							elseif not MT.db.profile.visaddscript then MT.db.profile.viscrest = true end
							MT:UpdateInterfaceOptions()
						end,
				},
			},
		},
		errorstab = {
			order = 3,
			type = "group",
			name = _G.ERRORS,
			args = {
				showerrors = {
					order = 1,
					type = "toggle",
					name = L["Display errors"],
					width = "full",
					get = function() return MT.db.profile.viserrors end,
					set =
						function(info, value)
							MT.db.profile.viserrors = value
							if value then
								MT.db.profile.visdrake = false
								MT.db.profile.doublewide = false
								MT.dwfunc()
								MacroToolkitErrorBg:Show()
								MacroToolkitErrorScrollFrame:Show()
							else
								if not MT.db.profile.visbackup and not MT.db.profile.visclear and not MT.db.profile.visshare then MT.db.profile.visdrake = true end
								MacroToolkitErrorBg:Hide()
								MacroToolkitErrorScrollFrame:Hide()
							end
							MT:UpdateInterfaceOptions()
						end,
				},
			},
		},
		fontstab = {
			order = 4,
			type = "group",
			name = L["Fonts"],
			args = {
				editorfontface = {
					order = 1,
					type = "select",
					name = L["Editor font"],
					dialogControl = "LSM30_Font",
					values = LSM:HashTable(LSM.MediaType.FONT),
					get = function() return MT.db.profile.fonts.edfont end,
					set =
						function(info, name)
							local font = LSM:Fetch(LSM.MediaType.FONT, name)
							MT.db.profile.fonts.edfont = name
							MacroToolkitText:SetFont(font, MT.db.profile.fonts.edsize, '')
							MacroToolkitFauxText:SetFont(font, MT.db.profile.fonts.edsize, '')
						end,
				},
				editorfontsize = {
					order = 2,
					type = "range",
					width = "full",
					min = 4,
					softMin = 4,
					max = 28,
					softMax = 28,
					step = 1,
					bigStep = 1,
					name = L["Size"],
					get = function() return MT.db.profile.fonts.edsize end,
					set =
						function(info, value)
							MT.db.profile.fonts.edsize = value
							local font = MacroToolkitText:GetFont()
							MacroToolkitText:SetFont(font, value, '')
							MacroToolkitFauxText:SetFont(font, value, '')
						end,
				},
				errorfontface = {
					order = 3,
					type = "select",
					hidden = function() return not MT.db.profile.viserrors end,
					name = L["Errors font"],
					dialogControl = "LSM30_Font",
					values = LSM:HashTable(LSM.MediaType.FONT),
					get = function() return MT.db.profile.fonts.errfont end,
					set =
						function(info, name)
							local font = LSM:Fetch(LSM.MediaType.FONT, name)
							MT.db.profile.fonts.errfont = name
							MacroToolkitErrors:SetFont(font, MT.db.profile.fonts.errsize, '')
						end,
				},
				errorfontsize = {
					order = 4,
					type = "range",
					width = "full",
					hidden = function() return not MT.db.profile.viserrors end,
					min = 4,
					softMin = 4,
					max = 28,
					softMax = 28,
					step = 1,
					bigStep = 1,
					name = L["Size"],
					get = function() return MT.db.profile.fonts.errsize end,
					set =
						function(info, value)
							MT.db.profile.fonts.errsize = value
							local font = MacroToolkitErrors:GetFont()
							MacroToolkitErrors:SetFont(font, value, '')
						end,
				},
				iconfontface = {
					order = 5,
					type = "select",
					name = L["Macro label font"],
					dialogControl = "LSM30_Font",
					values = LSM:HashTable(LSM.MediaType.FONT),
					get = function() return MT.db.profile.fonts.mifont end,
					set =
						function(info, name)
							MT.db.profile.fonts.mifont = name
							MT:MacroFrameUpdate()
						end,
				},
				iconfontsize = {
					order = 6,
					type = "range",
					width = "full",
					min = 4,
					softMin = 4,
					max = 28,
					softMax = 28,
					step = 1,
					bigStep = 1,
					name = L["Size"],
					get = function() return MT.db.profile.fonts.misize end,
					set =
						function(info, value)
							MT.db.profile.fonts.misize = value
							MT:MacroFrameUpdate()
						end,
				},
				macrofontface = {
					order = 7,
					type = "select",
					name = L["Macro name font"],
					dialogControl = "LSM30_Font",
					values = LSM:HashTable(LSM.MediaType.FONT),
					get = function() return MT.db.profile.fonts.mfont end,
					set =
						function(info, name)
							local font = LSM:Fetch(LSM.MediaType.FONT, name)
							MT.db.profile.fonts.mfont = name
							MacroToolkitSelMacroName:SetFont(font, 16, '')
						end,
				},
			},
		},
		othertab = {
			order = 5,
			type = "group",
			name = _G.OTHER,
			args = {
				doublewide = {
					order = 1,
					type = "toggle",
					name = L["Full width macro editor"],
					hidden = function() return MacroToolkitErrorBg:IsShown() end,
					width = "full",
					get = function() return MT.db.profile.doublewide end,
					set =
						function(info, value)
							MT.db.profile.doublewide = value
							if value then MT.db.profile.visdrake = false end
							MT.dwfunc()
							MT:UpdateInterfaceOptions()
						end,
				},
				faction = {
					order = 2,
					type = "toggle",
					name = L["Display faction emblem"],
					hidden = function() return MacroToolkitAddSlot:IsShown() or MacroToolkitAddScript:IsShown() end,
					width = "full",
					get = function() return MT.db.profile.viscrest end,
					set = function(info, value) MT.db.profile.viscrest = value; MT:UpdateInterfaceOptions() end,
				},
				drake = {
					order = 3,
					type = "toggle",
					name = L["Display drake"],
					hidden =
						function()
							local hide = MacroToolkitBackup:IsShown() or MacroToolkitClear:IsShown() or MT.db.profile.doublewide
							hide = hide or MacroToolkitShare:IsShown() or MacroToolkitErrorBg:IsShown()
							return hide
						end,
					width = "full",
					get = function() return MT.db.profile.visdrake end,
					set =
						function(info, value)
							MT.db.profile.visdrake = value
							if value then MT.db.profile.doublewide = false end
							MT.dwfunc()
							MT:UpdateInterfaceOptions()
						end,
				},
				spacer = {
					order = 4,
					type = "description",
					name = "\n",
				},
				scale = {
					order = 5,
					type = "range",
					name = _G.UI_SCALE,
					min = 0.25,
					max = 1.5,
					isPercent = true,
					step = 0.01,
					width = "double",
					get = function() return MT.db.profile.scale or MacroToolkitFrame:GetScale() end,
					set = function(info, value) MT:SetScale(value) end,
				},
				note1 = {
					order = 7,
					type = "description",
					fontSize = "medium",
					name = format("\n%s:\n\n  |cff808080%s", L["The following must be unchecked in order to use the macro editor in full width mode"], L["Display errors"]),
				},
				note2 = {
					order = 8,
					type = "description",
					fontSize = "medium",
					name = format("\n%s:\n\n  |cff808080%s\n  %s", L["The following must be unchecked in order to display the faction emblem"], L["Insert special"], L["Insert slot"]),
				},
				note3 = {
					order = 9,
					type = "description",
					fontSize = "medium",
					name = format("\n%s:\n\n  |cff808080%s\n  %s\n  %s\n  %s\n  %s", L["The following must be unchecked in order to display the drake"], L["Backup"], _G.CLEAR_ALL, _G.SHARE_QUEST_ABBREV, L["Display errors"], L["Full width macro editor"]),
				},
				note4 = {
					order = 10,
					type = "description",
					fontSize = "medium",
					name = format("\n%s", L["The macro editor height can be increased by dragging the bottom of Macro Toolkit's frame downwards"]),
				},
				spacer2 = {
					order = 11,
					type = "description",
					name = "\n",
				},
				resetpos = {
					order = 12,
					type = "execute",
					name = L["Reset position"],
					func =
						function()
							MT.db.profile.x = (UIParent:GetWidth() - 638) / 2
							MT.db.profile.y = (UIParent:GetHeight() - 424) / 2
							MacroToolkitFrame:SetPoint("BOTTOMLEFT", MT.db.profile.x, MT.db.profile.y)
						end,
				},
			},
		},
	},
}

local function resetcolours()
	for k, v in pairs(MT.defaults.profile) do
		if string.find(k, "colour") then MT.db.profile[k] = v end
	end
	MT.ColoursFrame:Hide()
	MT.ColoursFrame:Show()
end

local function resetoptions()
	for k, v in pairs(MT.defaults.profile) do
		if not string.find(k, "colour") and not string.find(k, "icon") and not string.find(k, "vis") and k ~= "fonts" and k ~= "scale" and k ~= "height" then MT.db.profile[k] = v end
	end
	if not MT.db.profile.usecolours then MacroToolkitFauxScrollFrame:Hide()
	else MacroToolkitFauxScrollFrame:Show() end
	if not MT.db.profile.showerrors then
		MacroToolkitErrorBg:Hide()
		MacroToolkitErrorScrollFrame:Hide()
	else
		MacroToolkitErrorBg:Show()
		MacroToolkitErrorScrollFrame:Show()
	end
	MT.OptionsFrame:Hide()
	MT.OptionsFrame:Show()
end

local function reseticons()
	for k, v in pairs(MT.defaults.profile) do
		if string.find(k, "icon") then MT.db.profile[k] = v end
	end
	MacroToolkitPopupIcons:SetSectionVisibility("DynamicIcon", MT.defaults.profile.dynamicicon)
	MacroToolkitPopupIcons:SetSectionVisibility("AbilityIcons", MT.defaults.profile.abilityicons)
	MacroToolkitPopupIcons:SetSectionVisibility("AchievementIcons", MT.defaults.profile.achicons)
	MacroToolkitPopupIcons:SetSectionVisibility("InventoryIcons", MT.defaults.profile.invicons)
	MacroToolkitPopupIcons:SetSectionVisibility("ItemIcons", MT.defaults.profile.itemicons)
	MacroToolkitPopupIcons:SetSectionVisibility("SpellIcons", MT.defaults.profile.spellicons)
	MacroToolkitPopupIcons:SetSectionVisibility("miscIcons", MT.defaults.profile.miscicons)
	MT:UpdateIconCount()
end

local function resetinterface()
	for k, v in pairs(MT.defaults.profile) do
		if string.sub(k, 1, 3) == "vis" or k == "fonts" or k == "scale" or k == "height" then MT.db.profile[k] = v end
	end
	MT:UpdateInterfaceOptions()
end

function MT:UpdateInterfaceOptions()
	local buttons = {"Conditions", "OptionsButton", "Custom", "AddScript", "AddSlot", "Crest", "Backup", "Clear", "Share", "Extend", "Shorten", "Bind", "Drake"}
	for _, b in ipairs(buttons) do
		local button = _G[format("MacroToolkit%s", b)]
		if MT.db.profile[format("vis%s", string.lower(b))] then button:Show() else button:Hide() end
	end
end

--Setup options
function MT:CreateOptions()
	if MT.db.profile.showerrors then MT.db.profile.viserrors = MT.db.profile.showerrors; MT.db.profile.showerrors = nil end
	local mainPanel = createMainPanel()
	mainPanel.name = "Macro Toolkit"
	InterfaceOptions_AddCategory(mainPanel)
	AceConfig:RegisterOptionsTable("MacroToolkitOptionsCheck", checkPanel)
	AceConfig:RegisterOptionsTable("MacroToolkitOptionsColours", coloursPanel)
	AceConfig:RegisterOptionsTable("MacroToolkitOptionsIcons", iconsPanel)
	AceConfig:RegisterOptionsTable("MacroToolkitOptionsInterface", interfacePanel)
	AceConfig:RegisterOptionsTable("MacroToolkitOptionsProfiles", AceDBOptions:GetOptionsTable(MT.db))
	MT.OptionsFrame = AceConfigDialog:AddToBlizOptions("MacroToolkitOptionsCheck", _G.MAIN_MENU, "Macro Toolkit")
	MT.OptionsFrame.default = function() resetoptions() end
	MT.ColoursFrame = AceConfigDialog:AddToBlizOptions("MacroToolkitOptionsColours", L["Syntax Highlighting"], "Macro Toolkit")
	MT.ColoursFrame.default = function() resetcolours() end
	MT.IconsFrame = AceConfigDialog:AddToBlizOptions("MacroToolkitOptionsIcons", L["Icons"], "Macro Toolkit")
	MT.IconsFrame.default = function() reseticons() end
	MT.InterfaceFrame = AceConfigDialog:AddToBlizOptions("MacroToolkitOptionsInterface", _G.UIOPTIONS_MENU, "Macro Toolkit")
	MT.InterfaceFrame.default = function() resetinterface() end
	AceConfigDialog:AddToBlizOptions("MacroToolkitOptionsProfiles", L["Profiles"], "Macro Toolkit")
end
