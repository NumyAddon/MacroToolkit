--- @class MacroToolkit
local MT = MacroToolkit
MT.skinned = {}

-- credits for reviving the elvui skin: MechaZao @ discord
function MT:ApplyElvSkin()
	if not C_AddOns.IsAddOnLoaded("ElvUI") then return end
	if MT.db.profile.noskin then return end

	local E = unpack(ElvUI)
	local S = E and E:GetModule("Skins", true)
	if not S or type(S.HandleFrame) ~= "function" then return end

	-- Frames to Skin
	local framesToSkin = {
		"MacroToolkitFrame",
		"MacroToolkitCopyFrame",
		"MacroToolkitBuilderFrame",
		"MacroToolkitButtonScroll",
		"MacroToolkitErrorBg",
	}

	-- Buttons to Skin
	local buttonsToSkin = {
		"MacroToolkitSave",
		"MacroToolkitCancel",
		"MacroToolkitDelete",
		"MacroToolkitNew",
		"MacroToolkitExit",
		"MacroToolkitEdit",
		"MacroToolkitBackup",
		"MacroToolkitBind",
		"MacroToolkitRestore",
		"MacroToolkitClear",
		"MacroToolkitShare",
		"MacroToolkitOptionsButton",
		"MacroToolkitCustom",
		"MacroToolkitAddScript",
		"MacroToolkitAddSlot",
		"MacroToolkitExtend",
		"MacroToolkitShorten",
		"MacroToolkitConditions",
		"MacroToolkitBuilderCancel",
		"MacroToolkitBuilderInsert",
		"MacroToolkitCExit",
		"MacroToolkitCopy",
	}

	-- Tabs to Skin
	local tabsToSkin = {
		"MacroToolkitFrameTab1",
		"MacroToolkitFrameTab2",
		"MacroToolkitFrameTab3",
	}

	-- Icon Grid Buttons
	for i = 1, max(_G.MAX_ACCOUNT_MACROS, _G.MAX_CHARACTER_MACROS, MT.MAX_EXTRA_MACROS) do
		local buttonName = "MacroToolkitButton" .. i
		local button = _G[buttonName]
		if button and not self.skinned[button] then
		    self.skinned[button] = true
			S:HandleButton(button)
		end
	end

	-- Skin frames
	for _, frameName in ipairs(framesToSkin) do
		local frame = _G[frameName]
		if frame and not self.skinned[frame] then
		    self.skinned[frame] = true
			S:HandleFrame(frame, true)
			frame:SetTemplate("Transparent")
		end
	end

	-- Skin buttons
	for _, buttonName in ipairs(buttonsToSkin) do
		local button = _G[buttonName]
		if button and not self.skinned[button] then
            self.skinned[button] = true
			S:HandleButton(button)
		end
	end

	-- Skin tabs
	for _, tabName in ipairs(tabsToSkin) do
		local tab = _G[tabName]
		if tab and not self.skinned[tab] then
            self.skinned[tab] = true
			S:HandleTab(tab)
		end
	end

	-- Skin scrollbars with consistent style
	local scrollBars = {
		"MacroToolkitErrorScrollFrameScrollBar",
		"MacroToolkitScrollFrameScrollBar",
		"MacroToolkitButtonScrollScrollBar",
		"MacroToolkitFauxScrollFrameScrollBar",
	}
	for _, scrollBarName in ipairs(scrollBars) do
	    local scrollBar = _G[scrollBarName]
		if scrollBar and not self.skinned[scrollBar] then
            self.skinned[scrollBar] = true
			S:HandleScrollBar(scrollBar)
			scrollBar:SetTemplate("Transparent")
		end
	end

	-- Arrow Button (Flyout)
	local flyoutButton = _G["MacroToolkitFlyout"]
	if flyoutButton and not self.skinned[flyoutButton] then
        self.skinned[flyoutButton] = true
		S:HandleNextPrevButton(flyoutButton)
	end
end
