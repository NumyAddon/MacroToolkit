local MT = MacroToolkit
local L = MT.L
local AceGUI = MT.LS("AceGUI-3.0")
local string, format, ipairs, table = string, format, ipairs, table
local CreateFrame = CreateFrame

local function updatepreview()
	local conditions = MT:BuildConditions()
	local fakemacro = format("%s %s", _G.SLASH_USE1, conditions)
	local parsed = MT:FormatMacro(fakemacro)
	local cstart = string.find(parsed, " ") + 1
	parsed = string.sub(parsed, cstart)
	MacroToolkitPreview:SetText(parsed)
end

function MT:CreateBuilderFrame()
	local mtbf = CreateFrame("Frame", "MacroToolkitBuilderFrame", UIParent, "BackdropTemplate,ButtonFrameTemplate")

	local function frameMouseUp()
		mtbf:StopMovingOrSizing()
		MT.db.profile.x = mtbf:GetLeft()
		MT.db.profile.y = mtbf:GetBottom()
	end

	mtbf:SetMovable(true)
	mtbf:EnableMouse(true)
	mtbf:EnableKeyboard(true)
	if MT.db.profile.scale then mtbf:SetScale(MT.db.profile.scale) end
	mtbf:SetSize(638, 424)
	mtbf:SetPoint("BOTTOMLEFT", MT.db.profile.x, MT.db.profile.y)
	mtbf:SetScript("OnMouseDown", function() mtbf:StartMoving() end)
	mtbf:SetScript("OnMouseUp", frameMouseUp)
	--[[
	mtbf:SetScript("OnKeyDown",
		function(this, key)
			if GetBindingFromClick(key) == "TOGGLEGAMEMENU" then this:Hide()
			else
				local action = GetBindingAction(key)
				if not MT:IsSecureAction(action) then RunBinding(action) end
			end
		end)
	]]--
	mtbf:Hide()

	local mtstitle = mtbf:CreateFontString(nil, "BORDER", "GameFontNormal")
	mtstitle:SetText(L["Condition Builder"])
	mtstitle:SetPoint("TOP", 0, -5)

	local mtbfportrait = mtbf:CreateTexture(nil, "OVERLAY", nil, -1)
	mtbfportrait:SetTexture("Interface\\TUTORIALFRAME\\UI-HELP-PORTRAIT")
	mtbfportrait:SetSize(60, 60)
	mtbfportrait:SetPoint("TOPLEFT", -5, 5)

	local ddtargets = {
		["zero"] = "",
		["target"] = L["target"], ["targettarget"] = L["targettarget"],
		["targetlasttarget"] = L["targetlasttarget"],
		["player"] = L["player"], ["playertargettarget"] = L["playertargettarget"],
		["pet"] = L["pet"], ["pettarget"] = L["pettarget"],
		["pettargettarget"] = L["pettargettarget"],
		["focus"] = L["focus"], ["focustarget"] = L["focustarget"],
		["focustargettarget"] = L["focustargettarget"],
		["mouseover"] = L["mouseover"], ["mouseovertarget"] = L["mouseovertarget"],
		["npc"] = L["npc"], ["none"] = L["none"], ["other"] = L["other"]
	}
	local ddtorder = {"zero","player","playertargettarget","target",
		"targettarget","targetlasttarget","pet","pettarget","pettargettarget","focus","focustarget",
		"focustargettarget","mouseover","mouseovertarget","npc","none","other"}

	local mtbfother
	local mtbftarget = AceGUI:Create("Dropdown")
	mtbftarget.frame:SetParent(mtbf)
	mtbftarget.label:SetTextColor(1, 1, 1, 1)
	mtbftarget:SetList(ddtargets, ddtorder)
	mtbftarget:SetWidth(200)
	mtbftarget:SetLabel(format("%s:", _G.TARGET))
	mtbftarget:SetCallback("OnValueChanged",
		function(info, name, key)
			if key == "other" then mtbfother.frame:Show()
			else mtbfother.frame:Hide() end
			MT.builder.target = key
			updatepreview()
		end)
	mtbftarget:SetPoint("TOPLEFT", 15, -65)

	mtbfother = AceGUI:Create("EditBox")
	mtbfother.frame:SetParent(mtbf)
	mtbfother.label:SetTextColor(1, 1, 1, 1)
	mtbfother:SetWidth(200)
	mtbfother:SetLabel(format("%s:", L["Enter target"]))
	mtbfother:SetCallback("OnEnterPressed",
		function(info, target)
			MT.builder.othertarget = target
			updatepreview()
		end)
	mtbfother:SetPoint("LEFT", mtbftarget.frame, "RIGHT", 10, 0)
	mtbfother.frame:Hide()

	local ddtoptions = {
		["zero"] = "",
		["dead"] = L["dead"], ["nodead"] = L["nodead"],
		["exists"] = L["exists"], ["noexists"] = L["noexists"], ["harm"] = L["harm"],
		["help"] = L["help"], ["party"] = L["party"], ["raid"] = L["raid"],
		["unithasvehicleui"] = L["unithasvehicleui"]
	}
	local ddoorder = {"zero","nodead","dead","exists","noexists","harm","help","party","raid","unithasvehicleui"}
	local function tovaluechanged(key, index)
		MT.builder[format("targetoption%d", index)] = (key == "zero") and "" or key
		updatepreview()
	end

	local mtbftopts1 = AceGUI:Create("Dropdown")
	mtbftopts1.frame:SetParent(mtbf)
	mtbftopts1:SetList(ddtoptions, ddoorder)
	mtbftopts1:SetWidth(150)
	mtbftopts1:SetLabel(L["Status of target"])
	mtbftopts1.label:SetTextColor(1, 1, 1, 1)
	mtbftopts1:SetCallback("OnValueChanged", function(info, name, key) tovaluechanged(key, 1) end)
	mtbftopts1:SetPoint("TOPLEFT", mtbftarget.frame, "BOTTOMLEFT", 0, -5)

	local mtbftopts2 = AceGUI:Create("Dropdown")
	mtbftopts2.frame:SetParent(mtbf)
	mtbftopts2:SetList(ddtoptions, ddoorder)
	mtbftopts2:SetWidth(150)
	mtbftopts2:SetCallback("OnValueChanged", function(info, name, key) tovaluechanged(key, 2) end)
	mtbftopts2:SetPoint("LEFT", mtbftopts1.frame, "RIGHT", 3, -9)

	local mtbftopts3 = AceGUI:Create("Dropdown")
	mtbftopts3.frame:SetParent(mtbf)
	mtbftopts3:SetList(ddtoptions, ddoorder)
	mtbftopts3:SetWidth(150)
	mtbftopts3:SetCallback("OnValueChanged", function(info, name, key) tovaluechanged(key, 3) end)
	mtbftopts3:SetPoint("LEFT", mtbftopts2.frame, "RIGHT", 3, 0)

	local mtbftopts4 = AceGUI:Create("Dropdown")
	mtbftopts4.frame:SetParent(mtbf)
	mtbftopts4:SetList(ddtoptions, ddoorder)
	mtbftopts4:SetWidth(150)
	mtbftopts4:SetCallback("OnValueChanged", function(info, name, key) tovaluechanged(key, 4) end)
	mtbftopts4:SetPoint("LEFT", mtbftopts3.frame, "RIGHT", 3, 0)

	local ddotherorder = {"zero",
		"bar", "bonusbar", "btn", "channeling", "nochanneling", "combat", "nocombat", "cursor",
		"extrabar", "flyable", "noflyable", "flying", "noflying", "form", "indoors",
		"outdoors", "mod", "nomod", "known", "noknown", "mounted", "nomounted", "overridebar", "party", "raid",
		"pet", "nopet", "petbattle", "possessbar", "spec", "stealth", "nostealth",
		"swimming", "noswimming", "pvptalent", "talent", "vehicleui", "novehicleui", "worn",
	}
	L["zero"] = ""
	local ddother = {}
	for _, o in ipairs(ddotherorder) do ddother[o] = L[o] end

	local function addvaluechanged(key, row, pdd, eb, ed)
		local realkey = key
		local negate
		local ddvals = {}
		local edvals = {}
		if string.sub(key, 1, 2) == "no" then
			realkey = string.sub(key, 3)
			negate = true
		end
		local ctype = negate and 0 or (MT.conditions[realkey] or 0)
		if ctype == 1 then
			ddvals.zero = ""
			local cap = 7
			if realkey == "spec" then cap = 4 end
			for n = 1, cap do ddvals[tostring(n)] = n end
			pdd:SetList(ddvals)
			pdd.frame:Show()
			eb.frame:Hide()
			ed.frame:Hide()
		elseif ctype == 2 or ctype == 3 or ctype == 8 then
			pdd.frame:Hide()
			eb.frame:Show()
			ed.frame:Hide()
		elseif ctype == 4 then
			local b = {"zero","party","raid"}
			for _, bt in ipairs(b) do ddvals[bt] = L[bt] end
			pdd:SetList(ddvals, b)
			pdd.frame:Show()
			eb.frame:Hide()
			ed.frame:Hide()
		elseif ctype == 5 then
			local b = {"zero","alt","shift","ctrl"}
			for _, bt in ipairs(b) do ddvals[bt] = L[bt] end
			pdd:SetList(ddvals, b)
			pdd.frame:Show()
			eb.frame:Hide()
			ed.frame:Hide()
		elseif ctype == 6 then
			local b = {"zero","LeftButton","MiddleButton","RightButton","Button4","Button5"}
			for _, bt in ipairs(b) do ddvals[bt] = L[bt] end
			pdd:SetList(ddvals, b)
			pdd.frame:Show()
			eb.frame:Hide()
			ed.frame:Hide()
		elseif ctype == 7 then
			ddvals.zero = ""
			for n = 1, 7 do ddvals[tostring(n)] = n end
			pdd:SetList(ddvals)
			pdd.frame:Show()
			eb.frame:Hide()
			edvals.zero = ""
			for n = 1, 3 do edvals[tostring(n)] = n end
			ed:SetList(edvals)
			ed.frame:Show()
		else
			pdd.frame:Hide()
			eb.frame:Hide()
			ed.frame:Hide()
		end
		MT.builder[format("add%d", row)] = (key == "zero") and "" or key
		MT.builder[format("addp%d", row)] = nil
		updatepreview()
	end

	local function addpvaluechanged(value, row)
		MT.builder[format("addp%d", row)] = (value == "zero") and "" or value
		updatepreview()
	end

	local function addsvaluechanged(value, row)
		if MT.builder[format("addp%d", row)] or "" ~= "" then
			MT.builder[format("adds%d", row)] = (value == "zero") and "" or (format("/%s", value))
			updatepreview()
		end
	end

	local mtbfaddp1 = AceGUI:Create("Dropdown")
	local mtbfadde1 = AceGUI:Create("EditBox")
	local mtbfadds1 = AceGUI:Create("Dropdown")
	local mtbfaddp2 = AceGUI:Create("Dropdown")
	local mtbfadde2 = AceGUI:Create("EditBox")
	local mtbfadds2 = AceGUI:Create("Dropdown")
	local mtbfaddp3 = AceGUI:Create("Dropdown")
	local mtbfadde3 = AceGUI:Create("EditBox")
	local mtbfadds3 = AceGUI:Create("Dropdown")
	local mtbfaddp4 = AceGUI:Create("Dropdown")
	local mtbfadde4 = AceGUI:Create("EditBox")
	local mtbfadds4 = AceGUI:Create("Dropdown")
	local mtbfaddp5 = AceGUI:Create("Dropdown")
	local mtbfadde5 = AceGUI:Create("EditBox")
	local mtbfadds5 = AceGUI:Create("Dropdown")
	local mtbfadd1 = AceGUI:Create("Dropdown")
	mtbfadd1.frame:SetParent(mtbf)
	mtbfadd1:SetList(ddother, ddotherorder)
	mtbfadd1:SetWidth(200)
	mtbfadd1:SetLabel(L["Additional conditions"])
	mtbfadd1.label:SetTextColor(1, 1, 1, 1)
	mtbfadd1:SetCallback("OnValueChanged", function(info, name, key) addvaluechanged(key, 1, mtbfaddp1, mtbfadde1, mtbfadds1) end)
	mtbfadd1:SetPoint("TOPLEFT", mtbftopts1.frame, "BOTTOMLEFT", 0, -5)

	mtbfaddp1.frame:SetParent(mtbf)
	mtbfaddp1:SetWidth(150)
	mtbfaddp1:SetCallback("OnValueChanged", function(info, name, key) addpvaluechanged(key, 1) end)
	mtbfaddp1:SetPoint("LEFT", mtbfadd1.frame, "RIGHT", 3, -9)
	mtbfaddp1.frame:Hide()

	mtbfadde1.frame:SetParent(mtbf)
	mtbfadde1:SetWidth(150)
	mtbfadde1:SetCallback("OnEnterPressed", function(info, name, value) addpvaluechanged(value, 1) end)
	mtbfadde1:SetPoint("LEFT", mtbfadd1.frame, "RIGHT", 3, -9)
	mtbfadde1.frame:Hide()

	mtbfadds1.frame:SetParent(mtbf)
	mtbfadds1:SetWidth(150)
	mtbfadds1:SetCallback("OnValueChanged", function(info, name, key) addsvaluechanged(key, 1) end)
	mtbfadds1:SetPoint("LEFT", mtbfadde1.frame, "RIGHT", 3, 0)
	mtbfadds1.frame:Hide()

	local mtbfadd2 = AceGUI:Create("Dropdown")
	mtbfadd2.frame:SetParent(mtbf)
	mtbfadd2:SetList(ddother, ddotherorder)
	mtbfadd2:SetWidth(200)
	mtbfadd2:SetCallback("OnValueChanged", function(info, name, key) addvaluechanged(key, 2, mtbfaddp2, mtbfadde2, mtbfadds2) end)
	mtbfadd2:SetPoint("TOPLEFT", mtbfadd1.frame, "BOTTOMLEFT", 0, -10)

	mtbfaddp2.frame:SetParent(mtbf)
	mtbfaddp2:SetWidth(150)
	mtbfaddp2:SetCallback("OnValueChanged", function(info, name, key) addpvaluechanged(key, 2) end)
	mtbfaddp2:SetPoint("LEFT", mtbfadd2.frame, "RIGHT", 3, 0)
	mtbfaddp2.frame:Hide()

	mtbfadde2.frame:SetParent(mtbf)
	mtbfadde2:SetWidth(150)
	mtbfadde2:SetCallback("OnEnterPressed", function(info, name, value) addpvaluechanged(value, 2) end)
	mtbfadde2:SetPoint("LEFT", mtbfadd2.frame, "RIGHT", 3, 0)
	mtbfadde2.frame:Hide()

	mtbfadds2.frame:SetParent(mtbf)
	mtbfadds2:SetWidth(150)
	mtbfadds2:SetCallback("OnValueChanged", function(info, name, key) addsvaluechanged(key, 2) end)
	mtbfadds2:SetPoint("LEFT", mtbfadde2.frame, "RIGHT", 3, 0)
	mtbfadds2.frame:Hide()

	local mtbfadd3 = AceGUI:Create("Dropdown")
	mtbfadd3.frame:SetParent(mtbf)
	mtbfadd3:SetList(ddother, ddotherorder)
	mtbfadd3:SetWidth(200)
	mtbfadd3:SetCallback("OnValueChanged", function(info, name, key) addvaluechanged(key, 3, mtbfaddp3, mtbfadde3, mtbfadds3) end)
	mtbfadd3:SetPoint("TOPLEFT", mtbfadd2.frame, "BOTTOMLEFT", 0, -10)

	mtbfaddp3.frame:SetParent(mtbf)
	mtbfaddp3:SetWidth(150)
	mtbfaddp3:SetCallback("OnValueChanged", function(info, name, key) addpvaluechanged(key, 3) end)
	mtbfaddp3:SetPoint("LEFT", mtbfadd3.frame, "RIGHT", 3, 0)
	mtbfaddp3.frame:Hide()

	mtbfadde3.frame:SetParent(mtbf)
	mtbfadde3:SetWidth(150)
	mtbfadde3:SetCallback("OnEnterPressed", function(info, name, value) addpvaluechanged(value, 3) end)
	mtbfadde3:SetPoint("LEFT", mtbfadd2.frame, "RIGHT", 3, 0)
	mtbfadde3.frame:Hide()

	mtbfadds3.frame:SetParent(mtbf)
	mtbfadds3:SetWidth(150)
	mtbfadds3:SetCallback("OnValueChanged", function(info, name, key) addsvaluechanged(key, 3) end)
	mtbfadds3:SetPoint("LEFT", mtbfadde3.frame, "RIGHT", 3, 0)
	mtbfadds3.frame:Hide()

	local mtbfadd4 = AceGUI:Create("Dropdown")
	mtbfadd4.frame:SetParent(mtbf)
	mtbfadd4:SetList(ddother, ddotherorder)
	mtbfadd4:SetWidth(200)
	mtbfadd4:SetCallback("OnValueChanged", function(info, name, key) addvaluechanged(key, 4, mtbfaddp4, mtbfadde4, mtbfadds4) end)
	mtbfadd4:SetPoint("TOPLEFT", mtbfadd3.frame, "BOTTOMLEFT", 0, -10)

	mtbfaddp4.frame:SetParent(mtbf)
	mtbfaddp4:SetWidth(150)
	mtbfaddp4:SetCallback("OnValueChanged", function(info, name, key) addpvaluechanged(key, 4) end)
	mtbfaddp4:SetPoint("LEFT", mtbfadd4.frame, "RIGHT", 3, 0)
	mtbfaddp4.frame:Hide()

	mtbfadde4.frame:SetParent(mtbf)
	mtbfadde4:SetWidth(150)
	mtbfadde4:SetCallback("OnEnterPressed", function(info, name, value) addpvaluechanged(value, 4) end)
	mtbfadde4:SetPoint("LEFT", mtbfadd4.frame, "RIGHT", 3, 0)
	mtbfadde4.frame:Hide()

	mtbfadds4.frame:SetParent(mtbf)
	mtbfadds4:SetWidth(150)
	mtbfadds4:SetCallback("OnValueChanged", function(info, name, key) addsvaluechanged(key, 4) end)
	mtbfadds4:SetPoint("LEFT", mtbfadde4.frame, "RIGHT", 3,0)
	mtbfadds4.frame:Hide()

	local mtbfadd5 = AceGUI:Create("Dropdown")
	mtbfadd5.frame:SetParent(mtbf)
	mtbfadd5:SetList(ddother, ddotherorder)
	mtbfadd5:SetWidth(200)
	mtbfadd5:SetCallback("OnValueChanged", function(info, name, key) addvaluechanged(key, 5, mtbfaddp5, mtbfadde5, mtbfadds5) end)
	mtbfadd5:SetPoint("TOPLEFT", mtbfadd4.frame, "BOTTOMLEFT", 0, -10)

	mtbfaddp5.frame:SetParent(mtbf)
	mtbfaddp5:SetWidth(150)
	mtbfaddp5:SetCallback("OnValueChanged", function(info, name, key) addpvaluechanged(key, 5) end)
	mtbfaddp5:SetPoint("LEFT", mtbfadd5.frame, "RIGHT", 3,0)
	mtbfaddp5.frame:Hide()

	mtbfadde5.frame:SetParent(mtbf)
	mtbfadde5:SetWidth(150)
	mtbfadde5:SetCallback("OnEnterPressed", function(info, name, value) addpvaluechanged(value, 5) end)
	mtbfadde5:SetPoint("LEFT", mtbfadd5.frame, "RIGHT", 3, 0)
	mtbfadde5.frame:Hide()

	mtbfadds5.frame:SetParent(mtbf)
	mtbfadds5:SetWidth(150)
	mtbfadds5:SetCallback("OnValueChanged", function(info, name, key) addsvaluechanged(key, 5) end)
	mtbfadds5:SetPoint("LEFT", mtbfadde5.frame, "RIGHT", 3, 0)
	mtbfadds5.frame:Hide()

	local mtbpreview = mtbf:CreateFontString("MacroToolkitPreview", "ARTWORK", "GameFontHighlightSmall")
	mtbpreview:SetTextColor(1, 1, 1, 0.7)
	mtbpreview:SetPoint("TOPLEFT", mtbfadd5.frame, "BOTTOMLEFT", 5, -20)

	local mtbcancel = CreateFrame("Button", "MacroToolkitBuilderCancel", mtbf, "BackdropTemplate,UIPanelButtonTemplate")
	mtbcancel:SetText(_G.CANCEL)
	mtbcancel:SetSize(80, 22)
	mtbcancel:SetPoint("BOTTOMRIGHT", -5, 4)
	mtbcancel:SetScript("OnClick", HideParentPanel)

	local mtbinsert = CreateFrame("Button", "MacroToolkitBuilderInsert", mtbf, "BackdropTemplate,UIPanelButtonTemplate")
	mtbinsert:SetText(_G.KEY_INSERT)
	mtbinsert:SetSize(80, 22)
	mtbinsert:SetPoint("RIGHT", mtbcancel, "LEFT")
	mtbinsert:SetScript("OnClick",	function() MT:InsertConditions(MT:BuildConditions()) end)

	mtbf:SetScript("OnShow",
		function()
			mtbf:ClearAllPoints()
			mtbf:SetPoint("BOTTOMLEFT", MT.db.profile.x, MT.db.profile.y)
			MT.builder = {}
			local ddobjs1 = {mtbftarget, mtbftopts1, mtbftopts2, mtbftopts3, mtbftopts4, mtbfadd1, mtbfadd2, mtbfadd3, mtbfadd4, mtbfadd5}
			local ddobjs2 = {mtbfaddp1, mtbfaddp2, mtbfaddp3, mtbfaddp4, mtbfaddp5}
			local ebobjs = {mtbfother, mtbfadde1, mtbfadde2, mtbfadde3, mtbfadde4, mtbfadde5}
			local edobjs = {mtbfadds1, mtbfadds2, mtbfadds3, mtbfadds4, mtbfadds5}
			for _, dd in ipairs(ddobjs1) do dd:SetValue("zero") end
			for _, dd in ipairs(ddobjs2) do dd:SetValue("zero"); dd.frame:Hide() end
			for _, eb in ipairs(ebobjs) do eb:SetText(""); eb.frame:Hide() end
			for _, ed in ipairs(edobjs) do ed:SetValue("zero"); ed.frame:Hide() end
			mtbpreview:SetText("")
			MT:Skin(mtbf)
		end)

	mtbf:SetScript("OnHide", function() MacroToolkitFrame:Show() end)
	return mtbf
end

function MT:BuildConditions()
	local b = MT.builder or {}
	local cargs = {}
	local failed
	local conditions =  b.target or ""
	if string.len(conditions) > 0 then conditions = format("@%s,", conditions) end
	for to = 1, 4 do
		local opt = b[format("targetoption%d", to)]
		if opt then conditions = format("%s%s,", conditions, opt) end
	end
	for o = 1, 5 do
		local opt = b[format("add%d", o)]
		local arg = b[format("addp%d", o)] or ""
		local arg2 = b[format("adds%d", o)] or ""
		if opt then
			if (MT.conditions[opt] or 0 > 0) and (string.len(arg) > 0) then
				table.insert(cargs, {o = opt, a = arg, a2=arg2})
			else conditions = format("%s%s,", conditions, opt) end
		end
	end
	table.sort(cargs, function(a, b) return a.o < b.o end)
	local lastarg
	for _, o in ipairs(cargs) do
		if o.o ~= lastarg then conditions = format("%s%s:%s%s,", conditions, o.o, o.a, o.a2)
		else conditions = format("%s/%s,", conditions, o.a) end
		lastarg = o.o
	end
	conditions = string.gsub(conditions, ",+", ",")
	conditions = string.gsub(conditions, ",/", "/")
	local clen = string.len(conditions)
	if string.sub(conditions, clen, clen) == "," then conditions = string.sub(conditions, 1, clen - 1) end
	conditions = format("[%s]", conditions)

	return conditions
end

function MT:InsertConditions(conditions)
	local failed
	local clen = strlenutf8(conditions)
	local mlen = strlenutf8(MacroToolkitText:GetText())
	if not MacroToolkitText.extended then
		if clen + mlen > 255 then
			StaticPopupDialogs["MACROTOOLKIT_TOOLONG"].text = string.format(L["Not enough space. Command requires %d characters (%d available)"], clen, 255 - mlen)
			StaticPopup_Show("MACROTOOLKIT_TOOLONG")
			failed = true
		end
	end
	if not failed then
		MacroToolkitText:Insert(conditions)
		MacroToolkitText:GetScript("OnTextChanged")(MacroToolkitText)
		MacroToolkitFrame.textChanged = 1
		MT:SaveMacro()
		MacroToolkitBuilderFrame:Hide()
	end
end
