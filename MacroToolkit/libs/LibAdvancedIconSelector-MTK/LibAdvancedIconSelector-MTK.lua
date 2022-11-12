--[[========================================================================================
      LibAdvancedIconSelector provides a searchable icon selection GUI to World
      of Warcraft addons.

      Copyright (c) 2011 - 2012 David Forrester  (Darthyl of Bronzebeard-US)
        Email: darthyl@hotmail.com

      Permission is hereby granted, free of charge, to any person obtaining a copy
      of this software and associated documentation files (the "Software"), to deal
      in the Software without restriction, including without limitation the rights
      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
      copies of the Software, and to permit persons to whom the Software is
      furnished to do so, subject to the following conditions:

      The above copyright notice and this permission notice shall be included in
      all copies or substantial portions of the Software.

      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
      THE SOFTWARE.
    ========================================================================================]]

--[[========================================================================================
      Please notify me if you wish to make use of this library in your addon!
      I need to know for testing purposes - to make sure that any changes I make
      aren't going to break someone else's addon!
    ========================================================================================]]

local DEBUG = false
if DEBUG and LibDebug then LibDebug() end

local MAJOR_VERSION = "LibAdvancedIconSelector-MTK"
local MINOR_VERSION = 14			-- (do not call GetAddOnMetaData)

if not LibStub then error(MAJOR_VERSION .. " requires LibStub to operate") end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end
local L = LibStub("AceLocale-3.0"):GetLocale(MAJOR_VERSION, true)
LibStub("AceTimer-3.0"):Embed(lib)

local ICON_WIDTH = 36
local ICON_HEIGHT = 36
local ICON_SPACING = 4	-- Minimum spacing between icons
local ICON_PADDING = 4	-- Padding around the icon display
local INITIATE_SEARCH_DELAY = 0.3	-- The delay between pressing a key and the start of the search
local SCAN_TICK = 0.1				-- The interval between each search "tick"
local SCAN_PER_TICK = 1000			-- How many icons to scan per tick?

local initialized = false
local MACRO_ICON_FILENAMES = { }
local ITEM_ICON_FILENAMES = { }

local keywordLibrary = nil			-- The currently loaded keyword library

-- List of prepositions that aren't re-capitalized when displaying keyword data.  Not all prepositions; just the ones that stand out.
local PREPS = { a = true, an = true, ["and"] = true, by = true, de = true, from = true, ["in"] = true, of = true, on = true, the = true, to = true, ["vs."] = true }

local defaults = {
	width = 419,
	height = 343,
	enableResize = true,
	enableMove = true,
	okayCancel = true,
	minResizeWidth = 300,
	minResizeHeight = 200,
	insets = { left = 11, right = 11, top = 11, bottom = 10 },
	contentInsets = {
		left = 11 + 8, right = 11 + 8,
		top = 11 + 20, bottom = 10 + 8 },
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	tile = false,
	tileSize = 32,
	edgeSize = 32,
	headerWidth = 256,
	headerTexture = "Interface\\DialogFrame\\UI-DialogBox-Header",
	headerFont = "GameFontNormal",
	headerOffsetX = 0,
	headerOffsetY = -14,
	headerText = L["FRAME_TITLE"],

	sectionOrder = { "MacroIcons", "ItemIcons" },
	sections = { },				-- (will be filled in automatically, if not set by user)
	sectionVisibility = { },	-- (will be filled in automatically, if not set by user)
}

-- ========================================================================================
-- OBJECT MODEL IMPLEMENTATION

local ObjBase = { }

-- Derives a new object using "self" as the prototype.
function ObjBase:Derive(o)
	o = o or { }
	assert(o ~= self and o.superType == nil)
	setmetatable(o, self)	-- (self = object / prototype being derived from, not necessarily ObjBase!)
	self.__index = self
	o.superType = self
	return o
end

-- Overlays the entries of "self" over the inherited entries of "o".
-- This is very useful for adding methods to an existing object, such as one created by CreateFrame().
-- (Note: replaces o's metatable, and only retains __index of the original metatable)
function ObjBase:MixInto(o)
	assert(o ~= nil and o ~= self and o.superType == nil)
	local superType = { }	-- (indexing this object will index the super type instead)
	o.superType = superType
	setmetatable(superType, getmetatable(o))
	setmetatable(o, {
		__index = function(t, k)	-- (note: do NOT index t from __index or it may loop)
			local r = self[k]		-- (mixed-in prototype)
			if r ~= nil then		-- (don't use "self[k] or superType[k]" or false won't work)
				return r
			else
				return superType[k]	-- (super type)
			end
		end
	})
	return o
end

-- ========================================================================================
-- OBJECT DEFINITIONS

local SearchObject = ObjBase:Derive()
local IconSelectorWindow = ObjBase:Derive()
local IconSelectorFrame = ObjBase:Derive()
local Helpers = ObjBase:Derive()

-- ================================================================
-- LIB IMPLEMENTATION

-- If DEBUG == true, then prints a console message.
function lib:Debug(...)
	if DEBUG then
		local prefix = "|cff00ff00[LAIS] [Debug]|r"
		if LibDebug then	-- (get  around LibDebug's print replacement)
			getmetatable(_G).__index.print(prefix, ...)
		else
			print(prefix, ...)
		end
	end
end

lib:Debug("Addon loaded.")

-- Embeds this library's functions into an addon for ease of use.
function lib:Embed(addon)
	addon.CreateIconSelectorWindow = lib.CreateIconSelectorWindow
	addon.CreateIconSelectorFrame = lib.CreateIconSelectorFrame
	addon.CreateSearch = lib.CreateSearch
	addon.GetNumMacroIcons = lib.GetNumMacroIcons
	addon.GetNumItemIcons = lib.GetNumItemIcons
	addon.GetRevision = lib.GetRevision
	addon.LoadKeywords = lib.LoadKeywords
	addon.LookupKeywords = lib.LookupKeywords
end

-- Creates and returns a new icon selector window.
function lib:CreateIconSelectorWindow(name, parent, options)
	Helpers.InitialInit()
	return IconSelectorWindow:Create(name, parent, options)
end

-- Creates and returns a new icon selector frame (i.e., no window, search box, or buttons).
function lib:CreateIconSelectorFrame(name, parent, options)
	Helpers.InitialInit()
	return IconSelectorFrame:Create(name, parent, options)
end

-- Creates and returns a new search object.
function lib:CreateSearch(options)
	Helpers.InitialInit()
	return SearchObject:Create(options)
end

-- Returns the number of "macro" icons.  This may go slow the first time it is run if icon filenames aren't yet loaded.
function lib:GetNumMacroIcons()	-- (was removed from the API, but can still be useful when you don't need filenames)
	Helpers.InitialInit()
	return #MACRO_ICON_FILENAMES
end

-- Returns the number of "item" icons.  This may go slow the first time it is run if icon filenames aren't yet loaded.
function lib:GetNumItemIcons()	-- (was removed from the API, but can still be useful when you don't need filenames)
	Helpers.InitialInit()
	return #ITEM_ICON_FILENAMES
end

-- Returns the revision # of the loaded library instance.
function lib:GetRevision()
	return MINOR_VERSION
end

-- Attempts to load the keyword library contained in the addon with the specified name.  BUT - it will load the one
-- at "AdvancedIconSelector-KeywordData" instead if (a) it's newer, or (b) the addon with the specified name cannot
-- be found / loaded.
--
-- You don't necessarily need to do this manually - it will automatically be done when an icon window / icon frame /
-- search object is first used, assuming a keywordAddonName field is specified in options.
function lib:LoadKeywords(addonName)

	-- Get the revision # of the specified addon (if it's enabled and loadable).
	local addonRevision = nil
	local addonLoadable = addonName and select(5, GetAddOnInfo(addonName))
	if addonLoadable then
		addonRevision = tonumber(GetAddOnMetadata(addonName, "X-Revision"))
	end

	-- Then, get the revision # of the default library (if it's enabled and loadable).
	local defaultRevision = nil
	local defaultLoadable = select(5, GetAddOnInfo("AdvancedIconSelector-KeywordData"))
	if defaultLoadable then
		defaultRevision = tonumber(GetAddOnMetadata("AdvancedIconSelector-KeywordData", "X-Revision"))
	end

	-- Finally, get the revision that is already loaded.
	keywordLibrary = LibStub("LibAdvancedIconSelector-KeywordData-1.0", true)
	local currentRevision = keywordLibrary and tonumber(keywordLibrary:GetRevision())	-- (old revisions may yield a string)

	-- Load the specified addon if it's newer than the current library and at least as new as the default library.
	local source = nil
	if addonRevision and (not currentRevision or addonRevision > currentRevision) and (not defaultRevision or addonRevision >= defaultRevision) then
		LoadAddOn(addonName)
		source = addonName

	-- Otherwise, load the default library if it's newer than the current library.
	elseif defaultRevision and (not currentRevision or defaultRevision > currentRevision) then
		LoadAddOn("AdvancedIconSelector-KeywordData")
		source = "AdvancedIconSelector-KeywordData"
	end

	-- Whatever happens, update keywordLibrary to point to the currently loaded instance.
	keywordLibrary = LibStub("LibAdvancedIconSelector-KeywordData-1.0", true)

	if source then
		lib:Debug("Loaded keyword library revision:", keywordLibrary and keywordLibrary:GetRevision(), "source:", source)
	end
end

-- Looks up keywords for the given icon.  Returns nil if no keywords exist, or the keyword library has not been loaded
-- yet using LoadKeywords().
function lib:LookupKeywords(texture)
	return keywordLibrary and keywordLibrary:GetKeywords(texture)
end

-- ================================================================
-- ICON WINDOW IMPLEMENTATION

-- Creates a new icon selector window, which includes an icon selector frame, search box, etc.
-- See Readme.txt for a list of all supported options.
function IconSelectorWindow:Create(name, parent, options)
	assert(name, "The icon selector window must have a name")
	if not parent then parent = UIParent end
	options = Helpers.ApplyDefaults(options, defaults)

	self = self:MixInto(CreateFrame("Frame", name, parent, BackdropTemplateMixin and "BackdropTemplate"))
	self:Hide()
	self:SetFrameStrata("MEDIUM")
	self:SetSize(options.width, options.height)
	self:SetMinResize(options.minResizeWidth, options.minResizeHeight)
	self:SetToplevel(true)
	self.options = options

	if options.customFrame then options.customFrame:SetParent(self) end

	self:SetBackdrop({
		edgeFile = options.edgeFile,
		bgFile = options.bgFile,
		tile = options.tile,
		tileSize = options.tileSize,
		edgeSize = options.edgeSize,
		insets = options.insets })

	if not options.noHeader then
		self.header = self:CreateTexture()
		self.header:SetTexture(options.headerTexture)
		self.header:SetWidth(options.headerWidth, 64)
		self.header:SetPoint("TOP", 0, 12)

		self.headerText = self:CreateFontString()
		self.headerText:SetFontObject(options.headerFont)
		self.headerText:SetPoint("TOP", self.header, "TOP", options.headerOffsetX, options.headerOffsetY)
		self.headerText:SetText(options.headerText)
	end

	if not options.noCloseButton then
		self.closeButton = CreateFrame("Button", nil, self, "UIPanelCloseButton", BackdropTemplateMixin and "BackdropTemplate")
		self.closeButton:SetPoint("TOPRIGHT", 0, 0)

		self.closeButton:SetScript("OnClick", function(...)
			if self.OnCancel then
				self:OnCancel(...)
			else
				self:Hide()
			end
		end)
	end

	if options.enableResize then self:SetResizable(true) end
	if options.enableMove then self:SetMovable(true) end
	if not options.allowOffscreen then self:SetClampedToScreen(true) end
	if options.enableResize or options.enableMove then self:EnableMouse(true) end

	self:RegisterForDrag("LeftButton")

	self:SetScript("OnDragStart", function(self, button)
		local x, y = self.mouseDownX, self.mouseDownY
		if x and y then
			local scale = UIParent:GetEffectiveScale()
			x = x / scale
			y = y / scale
			y = (y - self:GetBottom()) * scale
			x = (self:GetRight() - x) * scale

			-- (set anchorTo if you want your frame to conditionally be moveable / resizeable)
			if not options.anchorFrame or not options.anchorFrame:IsShown() then
				if options.enableResize and x < 20 and y < 20 then
					self:StartSizing()
				elseif options.enableMove then
					self:StartMoving()
				end
			end
		end
	end)

	self:SetScript("OnDragStop", function(self, button)
		self:StopMovingOrSizing()
	end)

	self:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self.mouseDownX, self.mouseDownY = GetCursorPosition()
		end
	end)

	self:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self.mouseDownX, self.mouseDownY = nil, nil
		end
	end)

	self.iconsFrame = lib:CreateIconSelectorFrame(name .. "_IconsFrame", self, options)

	self.searchLabel = self:CreateFontString()
	self.searchLabel:SetFontObject("GameFontNormal")
	self.searchLabel:SetText(L["Search:"])
	self.searchLabel:SetHeight(22)

	self.searchBox = CreateFrame("EditBox", name .. "_SearchBox", self, "BackdropTemplate,InputBoxTemplate")
	self.searchBox:SetAutoFocus(false)
	self.searchBox:SetHeight(22)
	self.searchBox:SetScript("OnTextChanged", function(editBox, userInput)
		if userInput then
			self.iconsFrame:SetSearchParameter(editBox:GetText())
		end
	end)

	self.cancelButton = CreateFrame("Button", name .. "_Cancel", self, "BackdropTemplate,UIPanelButtonTemplate")
	if options.okayCancel then
		self.cancelButton:SetText(L["Cancel"])
	else
		self.cancelButton:SetText(L["Close"])
	end
	self.cancelButton:SetSize(78, 22)
	self.cancelButton:SetScript("OnClick", function(...)
		if self.OnCancel then
			self:OnCancel(...)
		else
			self:Hide()
		end
	end)

	if options.okayCancel then
		self.okButton = CreateFrame("Button", name .. "_OK", self, "BackdropTemplate,UIPanelButtonTemplate")
		self.okButton:SetText(L["Okay"])
		self.okButton:SetSize(78, 22)
		self.okButton:SetScript("OnClick", function(...)
			if self.OnOkay then
				self:OnOkay(...)
			end
		end)
	end

	if options.visibilityButtons then
		self.visibilityButtons = { }
		for _, buttonInfo in ipairs(options.visibilityButtons) do
			local sectionName, buttonText = unpack(buttonInfo)
			local buttonName = name .. "_" .. sectionName .. "_Visibility"
			local button = CreateFrame("CheckButton", buttonName, self, "BackdropTemplate,UICheckButtonTemplate")
			_G[buttonName .. "Text"]:SetText(buttonText)
			button:SetChecked(self.iconsFrame:GetSectionVisibility(sectionName))
			button:SetSize(24, 24)
			button:SetScript("OnClick", function(button, mouseButton, down)
				self.iconsFrame:SetSectionVisibility(sectionName, button:GetChecked())
			end)
			tinsert(self.visibilityButtons, button)
		end
	end

	self:SetScript("OnSizeChanged", self.private_OnWindowSizeChanged)

	return self
end

-- Provides additional script types for the icon selector WINDOW (not frame).
function IconSelectorWindow:SetScript(scriptType, handler)
	if scriptType == "OnOkayClicked" then
		self.OnOkay = handler
	elseif scriptType == "OnCancelClicked" then
		self.OnCancel = handler
	else
		return self.superType.SetScript(self, scriptType, handler)
	end
end

-- Specifies a new search parameter, setting the text of the search box and starting the search.
-- Setting immediateResults to true will eliminate the delay before the search actually starts.
function IconSelectorWindow:SetSearchParameter(searchText, immediateResults)
	if searchText then
		self.searchBox:SetText(searchText)
	else
		self.searchBox:SetText("")
	end
	self.iconsFrame:SetSearchParameter(searchText, immediateResults)
end

-- Called when the size of the icon selector window changes.
function IconSelectorWindow:private_OnWindowSizeChanged(width, height)
	local spacing = 4
	local options = self.options
	local contentInsets = options.contentInsets

	if options.customFrame then
		options.customFrame:SetPoint("TOPLEFT", contentInsets.left, -contentInsets.top)
		options.customFrame:SetPoint("RIGHT", -contentInsets.right, 0)
		self.iconsFrame:SetPoint("TOPLEFT", options.customFrame, "BOTTOMLEFT", 0, -spacing)
	else
		self.iconsFrame:SetPoint("TOPLEFT", contentInsets.left, -contentInsets.top)
	end
	self.iconsFrame:SetPoint("RIGHT", -contentInsets.right, 0)
	self.cancelButton:SetPoint("BOTTOMRIGHT", -contentInsets.right, contentInsets.bottom)
	if self.okButton then
		self.okButton:SetPoint("BOTTOMRIGHT", self.cancelButton, "BOTTOMLEFT", -2, 0)
	end
	self.searchLabel:SetPoint("BOTTOMLEFT", contentInsets.left, contentInsets.bottom)
	self.searchBox:SetPoint("LEFT", self.searchLabel, "RIGHT", 6, 0)
	self.searchBox:SetPoint("RIGHT", self.okButton or self.cancelButton, "LEFT", -spacing, 0)

	local lastButton = nil

	-- Lay out the visibility buttons in a row
	if self.visibilityButtons then
		for _, button in ipairs(self.visibilityButtons) do
			if lastButton then
				button:SetPoint("LEFT", _G[lastButton:GetName() .. "Text"], "RIGHT", 2, 0)
			else
				button:SetPoint("BOTTOMLEFT", self.searchLabel, "TOPLEFT", -2, 0)
			end
			lastButton = button
		end
	end

	-- Attach the bottom of the icons frame
	if lastButton then
		self.iconsFrame:SetPoint("BOTTOM", lastButton, "TOP", 0, spacing)
	else
		self.iconsFrame:SetPoint("BOTTOM", self.cancelButton, "TOP", 0, spacing)
	end
end

-- ================================================================
-- ICON FRAME IMPLEMENTATION

-- Creates a new icon selector frame (no window, search box, etc.)
-- See Readme.txt for a list of all supported options.
function IconSelectorFrame:Create(name, parent, options)
	assert(name, "The icon selector frame must have a name")
	options = Helpers.ApplyDefaults(options, defaults)

	self = self:MixInto(CreateFrame("Frame", name, parent, BackdropTemplateMixin and "BackdropTemplate"))
	self.scrollOffset = 0
	self.iconsX = 1
	self.iconsY = 1
	self.fauxResults = 0	-- (fake results to keep top-left icon stationary when resizing)
	self.searchResults = { }
	self.icons = { }
	self.showDynamicText = options.showDynamicText

	self:SetScript("OnSizeChanged", self.private_OnIconsFrameSizeChanged)

	self:SetScript("OnShow", function(self)
		-- Call the BeforeShow handler (useful for replacing icon sections, etc.)
		if self.BeforeShow then self:BeforeShow() end

		-- Restart the search, since we stopped it when the frame was hidden.
		self.search:RestartSearch()
	end)

	-- Create the scroll bar
	self.scrollFrame = CreateFrame("ScrollFrame", name .. "_ScrollFrame", self, "BackdropTemplate,FauxScrollFrameTemplate")
	self.scrollFrame:SetScript("OnVerticalScroll", function(scrollFrame, offset)
		if offset == 0 then self.fauxResults = 0 end	-- Remove all faux results when the top of the list is hit.
		FauxScrollFrame_OnVerticalScroll(self.scrollFrame, offset, ICON_HEIGHT + ICON_SPACING, function() self:private_UpdateScrollFrame() end)
	end)

	-- Create the internal frame to display the icons
	self.internalFrame = CreateFrame("Frame", name .. "_Internal", self, BackdropTemplateMixin and "BackdropTemplate")
	self.internalFrame.parent = self
	self.internalFrame:SetScript("OnSizeChanged", self.private_OnInternalFrameSizeChanged)

	self.internalFrame:SetScript("OnHide", function(internalFrame)
		-- When the frame is hidden, immediately stop the search.
		self.search:Stop()

		-- Release any textures that were being displayed.
		for i = 1, #self.icons do
			local button = self.icons[i]
			if button then
				--button:SetNormalTexture(nil)
				button.Icon:SetTexture(nil)
			end
		end
	end)

	self.search = lib:CreateSearch(options)
	self.search.owner = self
	self.search:SetScript("OnSearchStarted", self.private_OnSearchStarted)
	self.search:SetScript("OnSearchResultAdded", self.private_OnSearchResultAdded)
	self.search:SetScript("OnSearchComplete", self.private_OnSearchComplete)
	self.search:SetScript("OnSearchTick", self.private_OnSearchTick)
	self.search:SetScript("OnIconScanned", self.private_OnIconScanned)

	-- Set the visibility of all sections
	for sectionName, _ in pairs(options.sections) do
		if options.sectionVisibility[sectionName] == false then		-- FALSE ONLY, not nil.  Sections are visible by default.
			self.search:ExcludeSection(sectionName, true)
		end
	end

	-- NOTE: Do not start the search until the frame is shown!  Some addons may choose to create
	-- the frame early and not display it until later, and we don't want to load the keyword library early!

	return self
end

-- Called when a new search is started.
function IconSelectorFrame.private_OnSearchStarted(search)
	local self = search.owner
	wipe(self.searchResults)
	self.updateNeeded = true
	self.resetScroll = true
end

-- Called each time a search result is found.
function IconSelectorFrame.private_OnSearchResultAdded(search, texture, globalID, localID, kind)
	local self = search.owner
	tinsert(self.searchResults, globalID)
	self.updateNeeded = true
end

-- Called when the search is completed.
function IconSelectorFrame.private_OnSearchComplete(search)
	local self = search.owner
	lib:Debug("Found " .. #self.searchResults .. " results")
	self.initialSelection = nil	-- (if we didn't find the initial selection first time, we're not going to find it next time)
end

-- Called after each search tick.
function IconSelectorFrame.private_OnSearchTick(search)
	local self = search.owner

	-- Update the icon display if new results have been found
	if self.updateNeeded then
		self.updateNeeded = false

		-- To reduce flashing, scroll to top JUST before calling private_UpdateScrollFrame() on the first search tick.
		if self.resetScroll then
			self.resetScroll = false
			self.fauxResults = 0
			FauxScrollFrame_Update(self.scrollFrame, 1, 1, 1)	-- (scroll to top)
		end

		self:private_UpdateScrollFrame()
	end
end

-- Called as each icon is passed in the search.
function IconSelectorFrame.private_OnIconScanned(search, texture, globalID, localID, kind)
	local self = search.owner

	if self.initialSelection then

		assert(self.selectedID == nil)	-- (user selection should have cleared the initial selection)

		-- If we find the texture we're looking for...
		if texture and strupper(texture) == strupper(self.initialSelection) then

			-- Set the selection.
			lib:Debug("Found selected texture at global index", globalID)
			self:SetSelectedIcon(globalID)

			assert(self.initialSelection == nil)	-- (should have been cleared by SetSelectedIcon)
		end
	end
end

-- Updates the scroll frame and refreshes the main display based on current parameters.
function IconSelectorFrame:private_UpdateScrollFrame()
	local maxLines = ceil((self.fauxResults + #self.searchResults) / self.iconsX)
	local displayedLines = self.iconsY
	local lineHeight = ICON_HEIGHT + ICON_SPACING
	FauxScrollFrame_Update(self.scrollFrame, maxLines, displayedLines, lineHeight)

	self.scrollOffset = FauxScrollFrame_GetOffset(self.scrollFrame)

	-- Update the icon display to match the new scroll offset
	self:private_UpdateIcons()
end

-- Specifies a new search parameter, restarting the search.
-- Setting immediateResults to true will eliminate the delay before the search actually starts.
function IconSelectorFrame:SetSearchParameter(searchText, immediateResults)
	self.search:SetSearchParameter(searchText, immediateResults)
end

-- Selects the icon at the given global index.  Does not trigger an OnSelectedIconChanged event.
function IconSelectorFrame:SetSelectedIcon(index)
	if self.selectedID ~= index then
		self.selectedID = index
		self.initialSelection = nil

		-- Fire an event.
		if self.OnSelectedIconChanged then self:OnSelectedIconChanged() end

		-- Update the icon display
		self:private_UpdateIcons()
	end
end

-- Selects the icon with the given filename (without the INTERFACE\\ICONS\\ prefix)
-- (NOTE: the icon won't actually be selected until it's found)
function IconSelectorFrame:SetSelectionByName(texture)
	self:SetSelectedIcon(nil)
	self.initialSelection = texture
	if texture then
		self.search:RestartSearch()
	else
		self:private_UpdateIcons()
	end
end

-- Returns information about the icon at the given global index, or nil if out of range.
-- (Returns a tuple of id (within section), kind, texture)
function IconSelectorFrame:GetIconInfo(index)
	return self.search:GetIconInfo(index, self)
end

-- Returns the ID of the selected icon.
function IconSelectorFrame:GetSelectedIcon()
	return self.selectedID
end

-- Provides additional script types for the icon selector FRAME (not window).
function IconSelectorFrame:SetScript(scriptType, handler)
	if scriptType == "OnSelectedIconChanged" then	-- Called when the selected icon is changed
		self.OnSelectedIconChanged = handler
	elseif scriptType == "OnButtonUpdated" then		-- Hook for the icon keyword editor (IKE) button overlays
		self.OnButtonUpdated = handler
	elseif scriptType == "BeforeShow" then			-- Called just before the window is shown - useful for replacing icon sections, etc.
		self.BeforeShow = handler
	else
		return self.superType.SetScript(self, scriptType, handler)
	end
end

-- Selects the next icon.  Used by the icon keyword editor, and not intended for external use.
-- (i.e., it doesn't take the current search filter into account)
-- If you'd like me to officially include such a feature, please email me.
function IconSelectorFrame:unofficial_SelectNextIcon()
	if self.selectedID then
		self:SetSelectedIcon(self.search:private_Skip(self.selectedID + 1))
		self:private_UpdateIcons()
	end
end

-- Replaces the specified section of icons.  Useful to change the icons within a custom section.
-- Also, causes the search to start over.
-- (see CreateDefaultSection for example section definitions)
-- (also, see EquipmentSetPopup.lua and MacroPopup.lua of AdvancedIconSelector for an example of actual use)
function IconSelectorFrame:ReplaceSection(sectionName, section)
	self.search:ReplaceSection(sectionName, section)
end

-- Shows or hides the icon section with the given name.
function IconSelectorFrame:SetSectionVisibility(sectionName, visible)
	self.search:ExcludeSection(sectionName, not visible)
	self.search:RestartSearch()
end

-- Returns true if the icon section with the given name is visible, or false otherwise.
function IconSelectorFrame:GetSectionVisibility(sectionName)
	return not self.search:IsSectionExcluded(sectionName)
end

-- (private) Called when the icon frame's size has changed.
function IconSelectorFrame:private_OnIconsFrameSizeChanged(width, height)
	self.scrollFrame:SetPoint("TOP", self)
	self.scrollFrame:SetPoint("BOTTOMRIGHT", self, -21, 0)

	self.internalFrame:SetPoint("TOPLEFT", self)
	self.internalFrame:SetPoint("BOTTOMRIGHT", self, -16, 0)
end

-- (private) Called when the internal icon frame's size has changed (i.e., the part without the scroll bar)
function IconSelectorFrame.private_OnInternalFrameSizeChanged(internalFrame, width, height)
	local self = internalFrame.parent

	local oldFirstIcon = 1 + self.scrollOffset * self.iconsX - self.fauxResults
	self.iconsX = floor((floor(width + 0.5) - 2 * ICON_PADDING + ICON_SPACING) / (ICON_WIDTH + ICON_SPACING))
	self.iconsY = floor((floor(height + 0.5) - 2 * ICON_PADDING + ICON_SPACING) / (ICON_HEIGHT + ICON_SPACING))

	-- Center the icons
	local leftPadding = (width - 2 * ICON_PADDING - (self.iconsX * (ICON_WIDTH + ICON_SPACING) - ICON_SPACING)) / 2
	local topPadding = (height - 2 * ICON_PADDING - (self.iconsY * (ICON_HEIGHT + ICON_SPACING) - ICON_SPACING)) / 2

	local lastIconY = nil
	for y = 1, self.iconsY do
		local lastIconX = nil
		for x = 1, self.iconsX do
			local i = (y - 1) * self.iconsX + x

			-- Create the button if it doesn't exist (but don't set its normal texture yet)
			local button = self.icons[i]
			if not button then
				button = CreateFrame("Button", format("MTAISButton%d", i), self.internalFrame, "BackdropTemplate,SelectorButtonTemplate")
				button.icon = button.Icon -- _G[format("MTAISButton%dIcon", i)]
				self.icons[i] = button
				button:SetSize(36, 36)
				--button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
				--button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")

				button:SetScript("OnClick", function(button, mouseButton, down)
					if button.textureKind and button.textureID then
						if self.selectedButton then
							self.selectedButton.SelectedTexture:Hide()
						end
						button.SelectedTexture:Show()
						self.selectedButton = button
						self:SetSelectedIcon(button.globalID)
					else
						button.SelectedTexture:Hide()
					end
					--print(button.textureKind)
					--print(button.textureID)
					--print(button.globalID)
				end)

				button:SetScript("OnEnter", function(button, motion)
					if button.texture then
						local tex = button.texture
						if MacroToolkit.usingiconlib then
							if type(button.texture) == "number" then
								if MacroToolkit.TextureNames[button.texture] then
									tex = MacroToolkit.TextureNames[button.texture]
								end
							end
						end
						local keywordString = lib:LookupKeywords(tex)
						local keywords = Helpers.GetTaggedStrings(keywordString, nil)
						local spells = Helpers.GetTaggedStrings(keywordString, "spell")

						GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT")
						GameTooltip:ClearLines()
						--[[
						if button.textureKind == "Equipment" then
							GameTooltip:AddDoubleLine(NORMAL_FONT_COLOR_CODE .. L["Equipped item texture:"] .. FONT_COLOR_CODE_CLOSE, GRAY_FONT_COLOR_CODE .. tostring(button.textureID) .. FONT_COLOR_CODE_CLOSE)
						elseif button.textureKind == "Macro" then
							GameTooltip:AddDoubleLine(NORMAL_FONT_COLOR_CODE .. L["Macro texture:"] .. FONT_COLOR_CODE_CLOSE, GRAY_FONT_COLOR_CODE .. tostring(button.textureID) .. FONT_COLOR_CODE_CLOSE)
						elseif button.textureKind == "Item" then
							GameTooltip:AddDoubleLine(NORMAL_FONT_COLOR_CODE .. L["Item texture:"] .. FONT_COLOR_CODE_CLOSE, GRAY_FONT_COLOR_CODE .. tostring(button.textureID) .. FONT_COLOR_CODE_CLOSE)
						elseif button.textureKind == "Spell" then
							GameTooltip:AddDoubleLine(NORMAL_FONT_COLOR_CODE .. L["Spell texture:"] .. FONT_COLOR_CODE_CLOSE, GRAY_FONT_COLOR_CODE .. tostring(button.textureID) .. FONT_COLOR_CODE_CLOSE)
						elseif button.textureKind == "Dynamic" then
							GameTooltip:AddLine(NORMAL_FONT_COLOR_CODE .. L["Default / dynamic texture:"] .. FONT_COLOR_CODE_CLOSE)
						end
						]]--
						GameTooltip:AddDoubleLine(NORMAL_FONT_COLOR_CODE .. _G.EMBLEM_SYMBOL ..  FONT_COLOR_CODE_CLOSE)
						GameTooltip:AddLine(tostring(tex), 1, 1, 1)
						if type(button.texture) == "number" and MacroToolkit.usingiconlib then GameTooltip:AddLine(tostring(button.texture), 0.5, 0.5, 0.5) end
						--[[
						Helpers.AddTaggedInformationToTooltip(keywordString, "spell", L["Spell: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "companion", L["Companion: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "mount", L["Mount: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "talent", L["Talent: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "tab", L["Tab: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "passive", L["Passive: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "racial", L["Racial: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "racial_passive", L["Racial Passive: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "mastery", L["Mastery: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "professions", L["Professions: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "pet_command", L["Pet Command: "], NORMAL_FONT_COLOR)
						Helpers.AddTaggedInformationToTooltip(keywordString, "pet_stance", L["Pet Stance: "], NORMAL_FONT_COLOR)
						if keywords and strlen(keywords) > 0 then
							GameTooltip:AddLine(GRAY_FONT_COLOR_CODE .. L["Additional keywords: "] .. tostring(keywords) .. FONT_COLOR_CODE_CLOSE, 1, 1, 1, true)
						end
						]]--
						GameTooltip:Show()
					end
				end)

				button:SetScript("OnLeave", function(button, motion)
					GameTooltip:Hide()
				end)
			end
			button:Show()	-- (yes, this is necessary; we hide excess buttons)

			if not lastIconX then
				if not lastIconY then
					button:SetPoint("TOPLEFT", self.internalFrame, leftPadding + ICON_PADDING, -topPadding - ICON_PADDING)
				else
					button:SetPoint("TOPLEFT", lastIconY, "BOTTOMLEFT", 0, -ICON_SPACING)
				end
				lastIconY = button
			else
				button:SetPoint("TOPLEFT", lastIconX, "TOPRIGHT", ICON_SPACING, 0)
			end

			lastIconX = button
		end
	end

	-- Hide any excess buttons.  Release the textures, but keep the buttons 'til the window is closed.
	for i = self.iconsY * self.iconsX + 1, #self.icons do
		local button = self.icons[i]
		if button then
			--button:SetNormalTexture(nil)
			button.Icon:SetTexture(nil)
			button:Hide()
		end
	end

	-- Add padding at the top to make the old and new first icon constant
	local newFirstIcon = 1 + self.scrollOffset * self.iconsX - self.fauxResults
	self.fauxResults = self.fauxResults + newFirstIcon - oldFirstIcon

	-- Increase faux results if below 0
	if self.fauxResults < 0 then
		local scrollDown = -ceil((self.fauxResults + 1) / self.iconsX) + 1	-- careful!  Lots of OBOBs here if not done right.
		self.fauxResults = self.fauxResults + scrollDown * self.iconsX
		assert(self.fauxResults >= 0)
		local newOffset = max(FauxScrollFrame_GetOffset(self.scrollFrame) + scrollDown, 0)
		FauxScrollFrame_SetOffset(self.scrollFrame, newOffset)
	end

	-- Decrease faux results if above iconsX
	if self.fauxResults > self.iconsX and self.iconsX > 0 then
		local scrollUp = floor(self.fauxResults / self.iconsX)
		self.fauxResults = self.fauxResults - scrollUp * self.iconsX
		assert(self.fauxResults < self.iconsX)
		local newOffset = max(FauxScrollFrame_GetOffset(self.scrollFrame) - scrollUp, 0)
		FauxScrollFrame_SetOffset(self.scrollFrame, newOffset)
	end

	self:private_UpdateScrollFrame()
end

-- Refreshes the icon display.
function IconSelectorFrame:private_UpdateIcons()
	if self:IsShown() then
		local firstIcon = 1 + self.scrollOffset * self.iconsX - self.fauxResults
		local last = self.iconsX * self.iconsY

		if self.selectedButton then
			self.selectedButton.SelectedTexture:Hide()
			self.selectedButton = nil
		end

		for i = 1, last do
			local button = self.icons[i]
			if button then
				local resultIndex = firstIcon + i - 1
				if self.searchResults[resultIndex] then
					button.globalID = self.searchResults[resultIndex]
					button.textureID, button.textureKind, button.texture = self:GetIconInfo(button.globalID)
					if button.globalID == self.selectedID then
						button.SelectedTexture:Show()
						self.selectedButton = button
					end

					if self.showDynamicText then
						if button.textureKind == "Dynamic" then
							if not button.dynamicText then
								button.dynamicText = button:CreateFontString()
								button.dynamicText:SetFontObject("GameFontNormalSmall")
								button.dynamicText:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
								button.dynamicText:SetText("(dynamic)")
							end
							button.dynamicText:Show()
						else
							if button.dynamicText then button.dynamicText:Hide() end
						end
					end
				else
					button.globalID = nil
					button.textureID = nil
					button.texture = nil
					button.textureKind = nil
					button.SelectedTexture:Hide()
					if button.dynamicText then button.dynamicText:Hide() end
				end

				if button.texture then
					if type(button.texture) == "number" then
						button.Icon:SetTexture(button.texture)
					else
						--button:SetNormalTexture("Interface\\Icons\\" .. button.texture)
						button.Icon:SetTexture("Interface\\Icons\\" .. button.texture)
					end
				else
					--button:SetNormalTexture(nil)
					button.Icon:SetTexture(nil)
				end

				-- Hook for the icon keyword editor (IKE) overlay
				if self.OnButtonUpdated then self.OnButtonUpdated(button) end
			end
		end
	end
end

-- ========================================================================================
-- HELPER FUNCTIONS

-- To prevent slow loading time, don't have WoW traverse the icons directory until an
-- icon selector is actually created.
function Helpers.InitialInit()
	if not initialized then
		initialized = true
		GetMacroIcons(MACRO_ICON_FILENAMES)
		GetMacroItemIcons(ITEM_ICON_FILENAMES)
	end
end

-- Creates a new object that is the overlay of "options" onto "defaults", and applies
-- a few dynamic defaults as well.
function Helpers.ApplyDefaults(options, defaults)
	if not options then options = { } end	-- (yes, some addons pass no options)

	local result = { }
	setmetatable(result, {
		__index = function(t, k)	-- (note: do NOT index t from __index or it may loop)
			local r = options[k]
			if r ~= nil then		-- (don't use "options[k] or defaults[k]" or false won't work)
				return r
			else
				return defaults[k]
			end
		end
	})

	-- Create any sections that weren't explicitly defined by the user.
	for _, sectionName in ipairs(result.sectionOrder) do
		if not result.sections[sectionName] then
			result.sections[sectionName] = Helpers.CreateDefaultSection(sectionName)
		end
	end

	-- 2012-03-20 COMPATIBILITY ISSUE: LibAdvancedIconSelector-1.0 revision 7 (v1.0.4) and above vs. AdvancedIconSelector v1.0.3 and below
	-- Old versions of AdvancedIconSelector relied on options.width and options.height being set to the default width / height upon return.
	-- THIS BEHAVIOR WILL BE REMOVED IN THE FUTURE, so don't rely on it or your addon WILL break.
	if not options.width then options.width = defaults.width end
	if not options.height then options.height = defaults.height end

	return result
end

-- Returns the strings that have the given tag (filters out the tags if nil)
function Helpers.GetTaggedStrings(str, tag)
	if not str then return nil end
	if not tag then
		return gsub(str, "[^ ]+:[^ ]+[ ]*", "")
	else
		local result = nil	-- (nil is by far the most common result - so don't return an empty table)
		for match in gmatch(" " .. str, " " .. tag .. ":([^ ]+)") do if not result then result = { match } else tinsert(result, match) end end
		return result
	end
end

-- Re-capitalizes each word of a string, excluding certain prepositions.  This is needed 'cause
-- all keyword data is lowercase (for quick searching).
function Helpers.Capitalize(str)
	local s, e, cap = 0, 0
	repeat
		s, e, cap = strfind(str, "([^ %-%.%(%)]+)[ %-%.%(%)]*", e + 1)
		if e then
			if s == 1 or not PREPS[cap] then
				str = strsub(str, 1, s - 1) .. strupper(strsub(str, s, s)) .. strsub(str, s + 1)
			end
		end
	until not e
	return str
end

-- Converts a keyword string like "ice_lance(mage)" into "Ice Lance (Mage)", r, g, b
function Helpers.MakeSpellTooltipString(str, defaultColor)
	str = gsub(str, "_", " ")	-- Re-insert spaces
	local spellName, className = strmatch(str, "^(.+)%(([^%)]+)%)$")
	if not className then spellName = str end	-- Sometimes class isn't specified.
	if spellName then
		-- Capitalize the first letter of each word, excluding certain prepositions.
		spellName = Helpers.Capitalize(spellName)

		if className then	-- (note: class name is sometimes also a profession name, race name, etc.)
			className = Helpers.Capitalize(className)
			local classColorIndex = strupper(className)
			if classColorIndex == "DEATH KNIGHT" then classColorIndex = "DEATHKNIGHT" end
			local classColor = RAID_CLASS_COLORS[classColorIndex]
			if classColor then
				return spellName .. " (" .. className .. ")", classColor.r, classColor.g, classColor.b
			else
				return spellName .. " (" .. className .. ")", defaultColor.r, defaultColor.g, defaultColor.b	-- invalid / multiple classes
			end
		end
		return spellName, defaultColor.r, defaultColor.g, defaultColor.b
	end
end

function Helpers.AddTaggedInformationToTooltip(keywordString, tag, tooltipTag, defaultColor)
	local spellNames = Helpers.GetTaggedStrings(keywordString, tag)
	if spellNames then
		for _,spellBundle in ipairs(spellNames) do
			local spellName, classR, classG, classB = Helpers.MakeSpellTooltipString(spellBundle, defaultColor)
			GameTooltip:AddLine(tooltipTag .. tostring(spellName), classR, classG, classB, false)
		end
	end
end

-- Creates one of several sections that don't have to be defined by the user.
function Helpers.CreateDefaultSection(name)
	if name == "DynamicIcon" then
		return { count = 1, GetIconInfo = function(index) return index, "Dynamic", "INV_Misc_QuestionMark" end }
	elseif name == "MacroIcons" then
		return { count = #MACRO_ICON_FILENAMES, GetIconInfo = function(index) return index, "Macro", MACRO_ICON_FILENAMES[index] end }
	elseif name == "ItemIcons" then
		return { count = #ITEM_ICON_FILENAMES, GetIconInfo = function(index) return index, "Item", ITEM_ICON_FILENAMES[index] end }
	end
end

-- ================================================================
-- SEARCH OBJECT IMPLEMENTATION

-- Creates a new search object based on the specified options.
function SearchObject:Create(options)
	options = Helpers.ApplyDefaults(options, defaults)

	local search = SearchObject:Derive()
	search.options = options
	search.sections = options.sections
	search.sectionOrder = options.sectionOrder
	search.firstSearch = true
	search.shouldSkip = { }

	return search
end

-- Provides a callback for an event, with error checking.
function SearchObject:SetScript(script, callback)
	if script == "BeforeSearchStarted" then			-- Called just before the search is (re)started.  Parameters: (search)
		self.BeforeSearchStarted = callback
	elseif script == "OnSearchStarted" then			-- Called when the search is (re)started.  Parameters: (search)
		self.OnSearchStarted = callback
	elseif script == "OnSearchResultAdded" then		-- Called for each search result found.  Parameters: (search, texture, globalID, localID, kind)
		self.OnSearchResultAdded = callback
	elseif script == "OnSearchComplete" then		-- Called when the search is completed.  Parameters: (search)
		self.OnSearchComplete = callback
	elseif script == "OnIconScanned" then			-- Called for each icon scanned.  Parameters: (search, texture, globalID, localID, kind)
		self.OnIconScanned = callback
	elseif script == "OnSearchTick" then			-- Called after each search tick (or at a constant rate, if the search is not tick-based).  Parameters: (search)
		self.OnSearchTick = callback
	else
		error("Unsupported script type")
	end
end

-- Sets the search parameter and restarts the search.  Since this is generally called many times in a row
-- (whenever a textbox is changed), the search is delayed by about half a second unless immediateResults is
-- set to true, except for the first search performed with this search object.
function SearchObject:SetSearchParameter(searchText, immediateResults)
	self.searchParameter = searchText
	if self.initiateSearchTimer then lib:CancelTimer(self.initiateSearchTimer) end
	local delay = (immediateResults or self.firstSearch) and 0 or INITIATE_SEARCH_DELAY
	self.firstSearch = false
	self.initiateSearchTimer = lib:ScheduleTimer(self.private_OnInitiateSearchTimerElapsed, delay, self)
end

-- Returns the current search parameter.
function SearchObject:GetSearchParameter()
	return self.searchParameter
end

-- Replaces the specified section of icons.  Useful to change the icons within a custom section.
-- Also, causes the search to start over.
-- (see CreateDefaultSection for example section definitions)
-- (also, see EquipmentSetPopup.lua and MacroPopup.lua of AdvancedIconSelector for an example of actual use)
function SearchObject:ReplaceSection(sectionName, section)
	self.sections[sectionName] = section
	self:RestartSearch()
end

-- Sets whether or not icons of the given section will be skipped.  This does not restart the search, so you
-- may wish to call RestartSearch() afterward.
function SearchObject:ExcludeSection(sectionName, exclude)
	self.shouldSkip[sectionName] = exclude
end

-- Returns whether or not the icons of the given section will be skipped.
function SearchObject:IsSectionExcluded(sectionName)
	return self.shouldSkip[sectionName]
end

-- Called when the search actually starts - usually about half a second after the search parameter is changed.
function SearchObject:private_OnInitiateSearchTimerElapsed()
	self.initiateSearchTimer = nil	-- (single-shot timer handles become invalid IMMEDIATELY after elapsed)
	self:RestartSearch()
end

-- Restarts the search.
function SearchObject:RestartSearch()

	if self.BeforeSearchStarted then self.BeforeSearchStarted(self) end

	-- Load / reload the keyword library.
	-- (if keywordAddonName isn't specified, the default will be loaded)
	lib:LoadKeywords(self.options.keywordAddonName)

	-- Cancel any pending restart; we don't want to start twice.
	if self.initiateSearchTimer then
		lib:CancelTimer(self.initiateSearchTimer)
		self.initiateSearchTimer = nil
	end

	-- Parse the search parameter
	if self.searchParameter then
		local tmp = self:private_FixSearchParameter(self.searchParameter)
		local parts = { strsplit(";", tmp) }
		for i = 1, #parts do
			local tmp = strtrim(parts[i])
			parts[i] = { }
			for v in gmatch(tmp, "[^ ,]+") do
				tinsert(parts[i], v)
			end
		end
		self.parsedParameter = parts
	else
		self.parsedParameter = nil
	end

	-- Start at the icon with global ID of 1
	self.searchIndex = 0

	if self.OnSearchStarted then self.OnSearchStarted(self) end

	if not self.searchTimer then
		self.searchTimer = lib:ScheduleRepeatingTimer(self.private_OnSearchTick, SCAN_TICK, self)
	end
end

-- Immediately terminates any running search.  You can restart the search by calling RestartSearch(),
-- but it will start at the beginning.
function SearchObject:Stop()
	-- Stop any pending search.
	if self.initiateSearchTimer then
		lib:CancelTimer(self.initiateSearchTimer)
		self.initiateSearchTimer = nil	-- (timer handles are invalid once canceled)
	end

	-- Cancel any occurring search.
	if self.searchTimer then
		lib:CancelTimer(self.searchTimer)
		self.searchTimer = nil			-- (timer handles are invalid once canceled)
	end
end

-- Called on every tick of a search.
function SearchObject:private_OnSearchTick()
	for entriesScanned = 0,SCAN_PER_TICK do
		self.searchIndex = self.searchIndex + 1
		self.searchIndex = self:private_Skip(self.searchIndex)

		-- Is the search complete?
		if not self.searchIndex then
			lib:CancelTimer(self.searchTimer)
			self.searchTimer = nil  -- timer handles are invalid once canceled
			if self.OnSearchComplete then self:OnSearchComplete() end
			break
		end

		local id, kind, texture = self:GetIconInfo(self.searchIndex)
		if MacroToolkit.SpellCheck ~= true then
			if type(texture) == "number" and MacroToolkit.usingiconlib then
				if MacroToolkit.TextureNames[texture] then texture = MacroToolkit.TextureNames[texture] end
			end
		end
		if self.OnIconScanned then self:OnIconScanned(texture, self.searchIndex, id, kind) end

		if texture then
			local keywordString = lib:LookupKeywords(texture)
			if self:private_Matches(texture, keywordString, self.parsedParameter) then
				if self.OnSearchResultAdded then self:OnSearchResultAdded(texture, self.searchIndex, id, kind) end
			end
		end
	end

	-- Notify that a search tick has occurred.
	if self.OnSearchTick then self:OnSearchTick() end
end

-- Returns the given global ID after skipping the designated categories, or nil if past the max global id.
function SearchObject:private_Skip(id)
	local origID = id

	if not id or id < 1 then
		return nil
	end

	local sectionStart = 1
	for _, sectionName in ipairs(self.sectionOrder) do
		local section = self.sections[sectionName]
		if section then
			if id >= 1 and id <= section.count then
				if self.shouldSkip[sectionName] then
					id = section.count + 1
				else
					return sectionStart + (id - 1)
				end
			end

			id = id - section.count
			sectionStart = sectionStart + section.count
		end
	end

	return nil
end

-- Lowercases a string, but preserves the case of any characters after a %.
function SearchObject:private_StrlowerPattern(str)
	local lastE = -1	-- (since -1 + 2 = 1)
	local result = ""

	repeat
		local s, e = strfind(str, "%", lastE + 2, true)
		if e then
			local nextLetter = strsub(str, e + 1, e + 1)
			result = result .. strlower(strsub(str, lastE + 2, e - 1)) .. "%" .. nextLetter
		else
			result = result .. strlower(strsub(str, lastE + 2))
		end
		lastE = e
	until not e
	return result
end

-- This function makes up for LUA's primitive string matching support and replaces all occurrances of a word
-- in a string, regardless of whether it's at the beginning, middle, or end.  This is extremely inefficient, so you
-- should only do it once: when the search parameter changes.
function SearchObject:private_ReplaceWord(str, word, replacement)
	local n
	str = gsub(str, "^" .. word .. "$", replacement)			-- (entire string)
	str = gsub(str, "^" .. word .. " ", replacement .. " ")		-- (beginning of string)
	str = gsub(str, " " .. word .. "$", " " .. replacement)		-- (end of string)
	repeat
		str, n = gsub(str, " " .. word .. " ", " " .. replacement .. " ")	-- (middle of string)
	until not n or n == 0
	return str
end

-- Coerces a search parameter to something useable.  Replaces NOT with !, etc.
function SearchObject:private_FixSearchParameter(parameter)

	-- Trim the parameter
	parameter = strtrim(parameter)

	-- Lowercase the string except for stuff after % signs. (since you can search by pattern)
	parameter = self:private_StrlowerPattern(parameter)

	-- Replace all "NOT" with !
	parameter = self:private_ReplaceWord(parameter, "not", "!")

	-- Replace all "AND" with ,
	parameter = self:private_ReplaceWord(parameter, "and", " ")

	-- Replace all "OR" with ;
	parameter = self:private_ReplaceWord(parameter, "or", ";")

	-- Join any !s to the word that follows it. (but only if the ! is standing on it's own)
	repeat
		local n1, n2
		parameter, n1 = gsub(parameter, "^(!+) +", "%1")
		parameter, n2 = gsub(parameter, " (!+) +", " %1")
	until n1 == 0 and n2 == 0

	-- Get rid of quotes; they have no meaning as of now and are used only to allow searching for "AND", "OR", and "NOT".
	parameter = gsub(parameter, '"+', "")

	-- Finally, get rid of any extra spaces
	parameter = gsub(strtrim(parameter), "  +", " ")

	return parameter
end

-- Returns true if the given texture / keywords matches the search parameter
function SearchObject:private_Matches(texture, keywords, parameter)
	if not parameter then return true end
	texture = strlower(texture)
	keywords = keywords and strlower(keywords)
	for i = 1, #parameter do		-- OR parameters
		local p_i = parameter[i]
		local termFailed = false

		for j = 1, #p_i do			-- AND parameters
			local s = p_i[j]
			if #s > 0 then
				local xor = 0
				local plainText = true

				while strsub(s, 1, 1) == "!" do	-- ! indicates negation of this term
					s = strsub(s, 2)
					xor = bit.bxor(xor, 1)
				end

				if strsub(s, 1, 1) == "=" then	-- = indicates pattern matching for this term
					s = strsub(s, 2)
					plainText = false
				end

				local ok1, result1 = pcall(strfind, texture, s, 1, plainText)
				local result2 = false
				if keywords then result2 = select(2, pcall(strfind, keywords, s, 1, plainText)) end
				if not ok1 or bit.bxor((result1 or result2) and 1 or 0, xor) == 0 then
					termFailed = true
					break
				end
			end
		end

		if not termFailed then
			return true
		end
	end
end

-- Returns information about the icon at the given global index, or nil if out of range.
-- (Returns a tuple of id (within section), kind, texture)
function SearchObject:GetIconInfo(id)
	if not id or id < 1 then
		return nil
	end

	for _, sectionName in ipairs(self.sectionOrder) do
		local section = self.sections[sectionName]
		if section then
			if id >= 1 and id <= section.count then
				return section.GetIconInfo(id)	-- (returns 3 values: id, kind, texture)
			else
				id = id - section.count
			end
		end
	end

	return nil
end
