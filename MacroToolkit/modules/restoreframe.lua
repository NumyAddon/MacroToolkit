local MT = MacroToolkit
local L = MT.L
local AceGUI = MT.LS("AceGUI-3.0")
local PlaySound, format = PlaySound, format
local CreateFrame, UIParent = CreateFrame, UIParent
local ipairs, table = ipairs, table
local PanelTemplates_GetSelectedTab = PanelTemplates_GetSelectedTab
local CreateMacro, EditMacro, GetMacroInfo = CreateMacro, EditMacro, GetMacroInfo

function MT:CreateRestoreFrame()
	local mtrf = CreateFrame("Frame", "MacroToolkitRestoreFrame", UIParent, "BackdropTemplate")
	mtrf:SetMovable(true)
	mtrf:EnableMouse(true)
	if MT.db.profile.scale then mtrf:SetScale(MT.db.profile.scale) end
	mtrf:SetSize(297, 298)
	mtrf:SetPoint("TOPLEFT", MacroToolkitFrame, "TOPRIGHT", 0, 0)
	mtrf:Hide()

	local mtrftl = mtrf:CreateTexture("BACKGROUND")
	mtrftl:SetTexture("Interface\\MacroFrame\\MacroPopup-TopLeft")
	mtrftl:SetTexCoord(0, 1, 0.234375, 1)
	mtrftl:SetSize(256, 256)
	mtrftl:SetPoint("TOPLEFT")

	local mtrftr = mtrf:CreateTexture("BACKGROUND")
	mtrftr:SetTexture("Interface\\MacroFrame\\MacroPopup-TopRight")
	mtrftr:SetTexCoord(0, 1, 0.234375, 1)
	mtrftr:SetSize(64, 256)
	mtrftr:SetPoint("TOPLEFT", 256, 0)
	
	local mtrfbl = mtrf:CreateTexture("BACKGROUND")
	mtrfbl:SetTexture("Interface\\MacroFrame\\MacroPopup-BotLeft")
	mtrfbl:SetSize(256, 64)
	mtrfbl:SetPoint("TOPLEFT", 0, -256)
	
	local mtrfbr = mtrf:CreateTexture("BACKGROUND")
	mtrfbr:SetTexture("Interface\\MacroFrame\\MacroPopup-BotRight")
	mtrfbr:SetSize(64, 64)
	mtrfbr:SetPoint("TOPLEFT", 256, -256)
	
	local mtrftitle = mtrf:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	mtrftitle:SetText(L["Manage Backups"])
	mtrftitle:SetPoint("CENTER", 0, 120)

	local mtrftype = mtrf:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	mtrftype:SetPoint("CENTER", 0, 105)
	mtrftype:SetTextColor(0.5, 0.5, 0.5, 1)

	local mtrfdesc = mtrf:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	mtrfdesc:SetPoint("CENTER", 0, -20)

	local mtrfdd = AceGUI:Create("Dropdown")
	mtrfdd.frame:SetParent(mtrf)
	mtrfdd.label:SetTextColor(1, 1, 1, 0.75)
	mtrfdd:SetWidth(200)
	mtrfdd:SetLabel(format("%s:", L["Backup"]))
	mtrfdd:SetCallback("OnValueChanged",
		function(info, name, key)
			MT.backup = key
			mtrfdesc:SetText(MT:GetBackupTitle(key))
			MacroToolkitRestoreRestore:Enable()
			MacroToolkitRestoreDelete:Enable()
		end)
	mtrfdd:SetPoint("CENTER", 0, 60)
	
	local mtrfrestore = CreateFrame("Button", "MacroToolkitRestoreRestore", mtrf, "BackdropTemplate,UIPanelButtonTemplate")
	mtrfrestore:SetText(L["Restore"])
	mtrfrestore:SetSize(115, 22)
	mtrfrestore:SetPoint("BOTTOMLEFT", 11, 13)
	mtrfrestore:Disable()
	mtrfrestore:SetScript("OnClick",
		function()
			local tab = PanelTemplates_GetSelectedTab(MacroToolkitFrame)
			local mtype = _G[format("MacroToolkitFrameTab%d", tab)]:GetText()
			StaticPopupDialogs.MACROTOOLKIT_DELETEBACKUP.text = format("|cffeedd82%s|r\n\n|cffff0000%s|r", mtype, L["Are you sure? This operation cannot be undone."])
			StaticPopupDialogs.MACROTOOLKIT_DELETEBACKUP.OnAccept = function() MT:RestoreBackup() end
			StaticPopup_Show("MACROTOOLKIT_DELETEBACKUP")
		end)
		
	local mtrfcancel = CreateFrame("Button", "MacroToolkitRestoreCancel", mtrf, "BackdropTemplate,UIPanelButtonTemplate")
	mtrfcancel:SetText(_G.CANCEL)
	mtrfcancel:SetSize(78, 22)
	mtrfcancel:SetPoint("BOTTOMRIGHT", -11, 13)
	mtrfcancel:SetScript("OnClick",
		function()
			--PlaySound("gsTitleOptionOK")
			PlaySound(798)
			mtrf:Hide()
			MT:MacroFrameUpdate()
		end)

	local mtrfdelete = CreateFrame("Button", "MacroToolkitRestoreDelete", mtrf, "BackdropTemplate,UIPanelButtonTemplate")
	mtrfdelete:SetText(_G.DELETE)
	mtrfdelete:SetSize(78, 22)
	mtrfdelete:SetPoint("RIGHT", mtrfcancel, "LEFT", -2, 0)
	mtrfdelete:Disable()
	mtrfdelete:SetScript("OnClick",
		function()
			local tab = PanelTemplates_GetSelectedTab(MacroToolkitFrame)
			local mtype = _G[format("MacroToolkitFrameTab%d", tab)]:GetText()
			StaticPopupDialogs.MACROTOOLKIT_DELETEBACKUP.text = format("|cffeedd82%s|r\n\n|cffff0000%s|r\n\n%s", mtype, L["Delete Backup"], L["Are you sure? This operation cannot be undone."])
			StaticPopupDialogs.MACROTOOLKIT_DELETEBACKUP.OnAccept = function() MT:DeleteBackup(mtrfdd, mtrfdesc) end
			StaticPopup_Show("MACROTOOLKIT_DELETEBACKUP")
		end)

	mtrf:SetScript("OnShow", 
		function(this)
			--PlaySound("igCharacterInfoOpen")
			PlaySound(839)
			local tab = PanelTemplates_GetSelectedTab(MacroToolkitFrame)
			mtrftype:SetText(_G[format("MacroToolkitFrameTab%d", tab)]:GetText())
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
			MacroToolkitSave:Disable()
			MacroToolkitCancel:Disable()
			MacroToolkitFlyout:Disable()
			MacroToolkitCustom:Disable()
			MacroToolkitConditions:Disable()
			mtrfdd:SetList(MT:GetBackups())
			if MT.backup then
				mtrfrestore:Enable()
				mtrfdelete:Enable()
			end
			MT:Skin(mtrf)
		end)

	mtrf:SetScript("OnHide", 
		function(this)
			--PlaySound("igCharacterInfoClose")
			PlaySound(840)
			MacroToolkitEdit:Enable()
			MacroToolkitDelete:Enable()
			MacroToolkitShorten:Enable()
			MacroToolkitExtend:Enable()
			MacroToolkitBackup:Enable()
			MacroToolkitClear:Enable()
			MacroToolkitShare:Enable()
			MacroToolkitBind:Enable()
			MacroToolkitFrameTab1:Enable()
			MacroToolkitFrameTab2:Enable()
			MacroToolkitSave:Enable()
			MacroToolkitCancel:Enable()
			MacroToolkitConditions:Enable()
			MT:GetLastBackupDate()
			if #MT.db.global.custom > 0 then MacroToolkitFlyout:Enable() end
			MacroToolkitCustom:Enable()
		end)
	return mtrf
end

function MT:GetBackupTitle(key)
	local tab = PanelTemplates_GetSelectedTab(MacroToolkitFrame)
	local var = (tab == 1) and "global" or "char"
	local backup = (tab == 3) and MT.db.global.ebackups or MT.db[var].backups
	for _, d in ipairs(backup) do if d.d == key then return d.n end end
end

local function createextended(name, icon, body, tab)
	local holder = "#MacroToolkitHolder"
	CreateMacro(name, icon, holder, tab == 2)
	local mid, mindex
	local var = (tab == 1) and "global" or "char"
	local start = (tab == 1) and 1 or (_G.MAX_ACCOUNT_MACROS + 1)
	local finish = (tab == 1) and _G.MAX_ACCOUNT_MACROS or (_G.MAX_ACCOUNT_MACROS + _G.MAX_CHARACTER_MACROS)
	for i, m in pairs(MT.db[var].extended) do
		if m.body == body then
			mindex = i
			break
		end
	end
	mindex = mindex or MT:GetNextIndex()
	for m = start, finish do
		local _, _, mbody = GetMacroInfo(m)
		if mbody == holder then
			mid = m
			break
		end
	end
	local securebutton = _G[format("MTSB%d", mindex)]
	MT:UpdateExtended(start, body, mindex)
	securebutton:SetAttribute("macrotext", body)
	local newbody = format("%s %s", MT.click, securebutton:GetName())
	EditMacro(mid, nil, nil, newbody)
end

function MT:RestoreBackup()
	local tab = PanelTemplates_GetSelectedTab(MacroToolkitFrame)
	local var = (tab == 1 or tab == 3) and "global" or "char"
	local offset = 1001
	if tab == 3 then offset = offset + MT:CountExtra() end
	for i, d in ipairs(MT.db[var].backups) do
		if d.d == MT.backup then
			MT:RefreshPlayerSpellIconInfo()
			for _, m in ipairs(d.m) do
				if tab == 3 then
					if m.index > 1000 then MT.db.global.extra[offset] = {name = m.name, texture = m.icon, body = m.body} end
					offset = offset + 1
					if offset > 1000 + _G.MAX_ACCOUNT_MACROS then break end
				elseif m.index < 1000 then
					if strlenutf8(m.body) > 255 then createextended(m.name, m.icon, m.body, tab)
					else CreateMacro(m.name, m.icon, m.body, m.index > _G.MAX_ACCOUNT_MACROS) end
				end
			end
			MT:MacroFrameUpdate()
			break
		end
	end
	MacroToolkitRestoreFrame:Hide()
end

function MT:DeleteBackup(dd, desc)
	local tab = PanelTemplates_GetSelectedTab(MacroToolkitFrame)
	local var = (tab == 1) and "global" or "char"
	local backup = (tab == 3) and MT.db.global.ebackups or MT.db[var].backups
	for i, d in ipairs(backup) do
		if d.d == MT.backup then
			table.remove(MT.db[var].backups, i)
			MT:GetLastBackupDate()
			dd:SetValue("")
			desc:SetText("")
			local blist = MT:GetBackups()
			dd:SetList(blist)
			if #blist == 0 then
				MacroToolkitRestoreRestore:Disable()
				MacroToolkitRestoreDelete:Disable()
			end
			break
		end
	end
end

function MT:GetLastBackupDate()
	local tab = PanelTemplates_GetSelectedTab(MacroToolkitFrame)
	local var = (tab == 1) and "global" or "char"
	if not MT.db[var] then MT.db[var] = {} end
	if not MT.db.global.ebackups then MT.db.global.ebackups = {} end
	if not MT.db[var].backups then MT.db[var].backups = {} end
	local backup = (tab == 3) and MT.db.global.ebackups or MT.db[var].backups
	local bd = ((tab == 3) and MT.db.global.ebackups.lastbackup or MT.db[var].lastbackup) or _G.NEVER
	if ((tab == 3) and #MT.db.global.ebackups or #MT.db[var].backups) == 0 then bd = _G.NEVER end
	if bd == _G.NEVER then MacroToolkitRestore:Disable()
	else MacroToolkitRestore:Enable() end
	MacroToolkitBL:SetText(format("%s: %s", L["Last backup"], bd))
end
