local _G = _G
local format, unpack, string = format, unpack, string
local MT = MacroToolkit
MT.skinned = {}

function MT:Skin(frame)
	if true then return end -- disabled for now
	if not IsAddOnLoaded("ElvUI") then return end
	if MT.db.profile.noskin then return end
	if not MT.skinned[frame:GetName()] then
		MT:LoadElvSkin(frame)
		MT.skinned[frame:GetName()] = true
	end
end

function MT:LoadElvSkin(frame)
	if true then return end -- disabled for now
	local E, L, V, P, G, _ = unpack(ElvUI)
	local S = E:GetModule("Skins")

	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.macro ~= true then return end
	local buttons

	if frame == MacroToolkitFrame then
		S:HandleCloseButton(MacroToolkitFrameCloseButton)
		S:HandleScrollBar(MacroToolkitButtonScrollScrollBar)
		S:HandleScrollBar(MacroToolkitScrollFrameScrollBar)
		S:HandleScrollBar(MacroToolkitFauxScrollFrameScrollBar)
		S:HandleScrollBar(MacroToolkitErrorScrollFrameScrollBar)
		MacroToolkitFrame:Width(648)
		MacroToolkitFlyout:Size(MacroToolkitFlyout:GetWidth() - 7, MacroToolkitFlyout:GetHeight() - 7)
		S:HandleNextPrevButton(MacroToolkitFlyout)
		MacroToolkitFlyout:ClearAllPoints()
		MacroToolkitFlyout:SetPoint("TOPRIGHT", MacroToolkitFrame, "TOPRIGHT", -4, -34)
		MacroToolkitCustom:SetPoint("TOPRIGHT", MacroToolkitFlyout, "TOPLEFT", -4, 2)

		for i = 1, 3 do
			local tab = _G[string.format("MacroToolkitFrameTab%s", i)]
			tab:Height(22)
		end

		MacroToolkitFrameTab1:SetPoint("TOPLEFT", MacroToolkitFrame, "TOPLEFT", 85, -39)
		MacroToolkitFrameTab2:SetPoint("LEFT", MacroToolkitFrameTab1, "RIGHT", 4, 0)
		MacroToolkitFrameTab3:SetPoint("LEFT", MacroToolkitFrameTab2, "RIGHT", 4, 0)
		MacroToolkitFrame:StripTextures()
		MacroToolkitFrame:SetTemplate("Transparent")
		MacroToolkitFrameInset:Kill()
		MacroToolkitTextBg:StripTextures()
		MacroToolkitTextBg:SetTemplate("Default")
		MacroToolkitErrorBg:StripTextures()
		MacroToolkitErrorBg:SetTemplate("Default")
		MacroToolkitButtonScroll:StripTextures()
		MacroToolkitButtonScroll:CreateBackdrop()
		MacroToolkitEdit:ClearAllPoints()
		MacroToolkitEdit:SetPoint("BOTTOMLEFT", MacroToolkitSelMacroButton, "BOTTOMRIGHT", 10, 0)
		MacroToolkitNew:ClearAllPoints()
		MacroToolkitNew:SetPoint("BOTTOMRIGHT", -90, 4)
		MacroToolkitExtend:ClearAllPoints()
		MacroToolkitExtend:SetPoint("LEFT", MacroToolkitDelete, "RIGHT", 80, 0)
		MacroToolkitShorten:ClearAllPoints()
		MacroToolkitShorten:SetPoint("LEFT", MacroToolkitExtend, "RIGHT", 4, 0)
		MacroToolkitErrorBg:ClearAllPoints()
		MacroToolkitErrorBg:SetPoint("TOPLEFT", 338, -289)
		MacroToolkitErrorBg:SetPoint("BOTTOMRIGHT", -6, 40)
		MacroToolkitEnterText:ClearAllPoints()
		MacroToolkitEnterText:SetPoint("TOPLEFT", MacroToolkitSelBg, "BOTTOMLEFT", 8, 8)
		MacroToolkitErrorLabel:ClearAllPoints()
		MacroToolkitErrorLabel:SetPoint("BOTTOMLEFT", MacroToolkitErrorScrollFrame, "TOPLEFT", -3, 10)
		S:HandleScrollBar(MacroToolkitButtonScroll)
		MacroToolkitOptionsButton:ClearAllPoints()
		MacroToolkitOptionsButton:SetPoint("LEFT", MacroToolkitConditions, "RIGHT", 23, 0)
		MacroToolkitSelMacroButton:StripTextures()
		MacroToolkitSelMacroButton:StyleButton(true)
		MacroToolkitSelMacroButton:GetNormalTexture():SetTexture(nil)
		MacroToolkitSelMacroButton:SetTemplate("Default")
		MacroToolkitSelMacroButton.Icon:SetTexCoord(unpack(E.TexCoords))
		MacroToolkitSelMacroButton.Icon:SetInside()
		MacroToolkitLimit:ClearAllPoints()
		MacroToolkitLimit:SetPoint("BOTTOM", MacroToolkitTextBg, 0, -12)
		buttons = {"MacroToolkitSave", "MacroToolkitCancel", "MacroToolkitDelete", "MacroToolkitNew", "MacroToolkitExit", "MacroToolkitEdit",
		"MacroToolkitFrameTab1", "MacroToolkitFrameTab2", "MacroToolkitFrameTab3", "MacroToolkitShorten", "MacroToolkitAddScript", "MacroToolkitAddSlot", "MacroToolkitBackup",
		"MacroToolkitRestore", "MacroToolkitClear",	"MacroToolkitShare", "MacroToolkitCustom", "MacroToolkitExtend", "MacroToolkitOpen", "MacroToolkitConditions",
		"MacroToolkitOptionsButton", "MacroToolkitMacroBox", "MacroToolkitBind"}
	end

	if frame == MacroToolkitScriptFrame then
		S:HandleCloseButton(MacroToolkitScriptFrameCloseButton)
		S:HandleScrollBar(MacroToolkitScriptScrollScrollBar)
		S:HandleScrollBar(MacroToolkitScriptErrorsScrollBar)
		MacroToolkitScriptFrame:Height(428)
		MacroToolkitScriptFrame:StripTextures()
		MacroToolkitScriptFrame:SetTemplate("Transparent")
		MacroToolkitScriptFrameInset:Kill()
		MacroToolkitScriptScrollBg:StripTextures()
		MacroToolkitScriptScrollBg:SetTemplate("Default")
		MacroToolkitScriptErrorBg:StripTextures()
		MacroToolkitScriptErrorBg:SetTemplate("Default")
		MacroToolkitScriptScroll:StripTextures()
		MacroToolkitScriptScroll:CreateBackdrop()
		MacroToolkitScriptErrors:StripTextures()
		MacroToolkitScriptErrors:CreateBackdrop()
		MacroToolkitScriptSave:ClearAllPoints()
		MacroToolkitScriptSave:SetPoint("BOTTOMRIGHT", -92, 4)
		MacroToolkitScriptExit:ClearAllPoints()
		MacroToolkitScriptExit:SetPoint("BOTTOMRIGHT", -7, 4)
		MacroToolkitScriptDelete:ClearAllPoints()
		MacroToolkitScriptDelete:SetPoint("BOTTOMLEFT", 7, 4)
		MacroToolkitScriptEnter:SetPoint("TOPLEFT", 10, -44)
		MacroToolkitScriptErrorBg:ClearAllPoints()
		MacroToolkitScriptErrorBg:SetPoint("BOTTOMLEFT", 7, 31)
		buttons = {"MacroToolkitScriptExit", "MacroToolkitScriptDelete", "MacroToolkitScriptSave"}
	end

	if frame == MacroToolkitBuilderFrame then
		S:HandleCloseButton(MacroToolkitBuilderFrameCloseButton)
		MacroToolkitBuilderFrame:StripTextures()
		MacroToolkitBuilderFrame:SetTemplate("Transparent")
		MacroToolkitBuilderFrameInset:Kill()
		MacroToolkitBuilderInsert:ClearAllPoints()
		MacroToolkitBuilderInsert:SetPoint("RIGHT", MacroToolkitBuilderCancel, "LEFT", -4, 0)
		buttons = {"MacroToolkitBuilderCancel", "MacroToolkitBuilderInsert"}
	end

	if frame == MacroToolkitCopyFrame then
		S:HandleCloseButton(MacroToolkitCopyFrameCloseButton)
		S:HandleScrollBar(MacroToolkitCScrollFrameScrollBar)
		S:HandleScrollBar(MacroToolkitCFauxScrollFrameScrollBar)
		MacroToolkitCopyFrame:StripTextures()
		MacroToolkitCopyFrame:SetTemplate("Transparent")
		MacroToolkitCopyFrameInset:Kill()
		MacroToolkitCTextBg:StripTextures()
		MacroToolkitCTextBg:SetTemplate("Default")
		MacroToolkitCSelMacroButton:StripTextures()
		MacroToolkitCSelMacroButton:StyleButton(true)
		MacroToolkitCSelMacroButton:GetNormalTexture():SetTexture(nil)
		MacroToolkitCSelMacroButton:SetTemplate("Default")
		MacroToolkitCSelMacroButton.Icon:SetTexCoord(unpack(E.TexCoords))
		MacroToolkitCSelMacroButton.Icon:SetInside()
		buttons = {"MacroToolkitCExit", "MacroToolkitCopy"}
	end

	if frame == MacroToolkitPopup then
		S:HandleCheckBox(MacroToolkitSpellCheck)
		--S:HandleScrollBar(MacroToolkitPopupScrollScrollBar)
		S:HandleScrollBar(MacroToolkitPopupIcons.scrollFrame.ScrollBar)
		MacroToolkitPopup:StripTextures()
		MacroToolkitPopup:SetTemplate("Transparent")
		--MacroToolkitPopupScroll:StripTextures()
		--MacroToolkitPopupScroll:CreateBackdrop()
		--MacroToolkitPopupScroll.backdrop:SetPoint("TOPLEFT", 51, 2)
		--MacroToolkitPopupScroll.backdrop:SetPoint("BOTTOMRIGHT", -4, 4)
		MacroToolkitPopupIcons:StripTextures()
		MacroToolkitPopupIcons:CreateBackdrop()
		MacroToolkitPopupIcons.backdrop:SetPoint("TOPLEFT", 10, 2)
		MacroToolkitPopupIcons.backdrop:SetPoint("BOTTOMRIGHT", -4, -16)
		MacroToolkitFramePopupL:SetTexture(nil)
		MacroToolkitFramePopupM:SetTexture(nil)
		MacroToolkitFramePopupR:SetTexture(nil)
		S:HandleEditBox(MacroToolkitPopupEdit)
		S:HandleEditBox(MacroToolkitSearchBox)
		MacroToolkitPopupCancel:ClearAllPoints()
		MacroToolkitPopupCancel:SetPoint("BOTTOMRIGHT", -11, 9)
		MacroToolkitPopupOk:ClearAllPoints()
		MacroToolkitPopupOk:SetPoint("RIGHT", MacroToolkitPopupCancel, "LEFT", -6, 0)
		MacroToolkitPopupGoLarge:ClearAllPoints()
		MacroToolkitPopupGoLarge:SetPoint("TOPRIGHT", -13, -59)
		MacroToolkitPopup:HookScript("OnShow",
			function(this)
				this:ClearAllPoints()
				this:SetPoint("TOPLEFT", MacroToolkitFrame, "TOPRIGHT", 5, -2)
			end)
		buttons = {"MacroToolkitPopupOk", "MacroToolkitPopupCancel", "MacroToolkitPopupGoLarge"}
	end

	if frame == MacroToolkitBindingFrame then
		S:HandleCheckBox(MacroToolkitBindingFrame.profile)
		MacroToolkitBindingFrame:StripTextures()
		MacroToolkitBindingFrame:SetTemplate("Transparent")
		buttons = {"MacroToolkitBindButton1", "MacroToolkitBindButton2", "MacroToolkitBindingCancel", "MacroToolkitBindingOk", "MacroToolkitUnbind"}
	end

	if frame == MacroToolkitRestoreFrame then
		MacroToolkitRestoreFrame:StripTextures()
		MacroToolkitRestoreFrame:SetTemplate("Transparent")
		MacroToolkitRestoreFrame:HookScript("OnShow",
			function(this)
				this:ClearAllPoints()
				this:SetPoint("TOPLEFT", MacroToolkitFrame, "TOPRIGHT", 5, -2)
			end)
		buttons = {"MacroToolkitRestoreRestore", "MacroToolkitRestoreCancel", "MacroToolkitRestoreDelete"}
	end

	if frame == MacroToolkitSharePopup then
		MacroToolkitSharePopup:StripTextures()
		MacroToolkitSharePopup:SetTemplate("Transparent")
		S:HandleEditBox(MacroToolkitShareEdit)
		buttons = {"MacroToolkitShareOK", "MacroToolkitShareCancel"}
	end

--[[
	local buttons = {
		"MacroToolkitSave", "MacroToolkitCancel", "MacroToolkitDelete", "MacroToolkitNew", "MacroToolkitExit", "MacroToolkitEdit",
		"MacroToolkitFrameTab1", "MacroToolkitFrameTab2", "MacroToolkitPopupOk", "MacroToolkitPopupCancel", "MacroToolkitShorten",
		"MacroToolkitAddScript", "MacroToolkitAddSlot", "MacroToolkitBackup", "MacroToolkitRestore", "MacroToolkitClear",
		"MacroToolkitShare", "MacroToolkitRestoreRestore", "MacroToolkitRestoreCancel", "MacroToolkitRestoreDelete",
		"MacroToolkitCustom", "MacroToolkitScriptExit", "MacroToolkitScriptDelete", "MacroToolkitScriptSave", "MacroToolkitExtend",
		"MacroToolkitOpen", "MacroToolkitConditions", "MacroToolkitBuilderCancel", "MacroToolkitBuilderInsert", "MacroToolkitOptionsButton",
		"MacroToolkitMacroBox", "MacroToolkitShareOK", "MacroToolkitShareCancel", "MacroToolkitBindButton1", "MacroToolkitBindButton2",
		"MacroToolkitBindingCancel", "MacroToolkitBindingOk", "MacroToolkitUnbind", "MacroToolkitBind", "MacroToolkitCExit", "MacroToolkitCopy",
	}
]]--
	if buttons then
		for i = 1, #buttons do
			_G[buttons[i]]:StripTextures()
			S:HandleButton(_G[buttons[i]])
		end
	end

	if frame == MacroToolkitFrame or frame == MacroToolkitCopyFrame or frame == MacroToolkitPopup then
		for i = 1, _G.MAX_ACCOUNT_MACROS do
			local b = _G[format("MacroToolkitButton%d", i)]
			local c = _G[format("MacroToolkitCButton%d", i)]
			local t = _G[format("MacroToolkitButton%dIcon", i)]
			local ct = _G[format("MacroToolkitCButton%dIcon", i)]
			local pb = _G[format("MacroToolkitPopupButton%d", i)]
			local pt = _G[format("MacroToolkitPopupButton%dIcon", i)]
			if b then
				b:StripTextures()
				b:CreateBackdrop('Default')
				b:StyleButton(true)
				--b:SetTemplate("Default", true)
			end
			if c then
				c:StripTextures()
				c:CreateBackdrop('Default')
				c:StyleButton(true)
				--c:SetTemplate("Default", true)
			end
			if t then
				t:SetTexCoord(unpack(E.TexCoords))
				t:SetInside()
			end
			if ct then
				ct:SetTexCoord(unpack(E.TexCoords))
				ct:SetInside()
			end
			if pb then
				pb:StripTextures()
				pb:CreateBackdrop('Default')
				pb:StyleButton(true)
				--pb:SetTemplate("Default")
			end
			if pt then
				pt:SetTexCoord(unpack(E.TexCoords))
				pt:SetInside()
			end
		end
	end
	--S:RegisterSkin("MacroToolkit", LoadSkin)
end
