========================================================================================
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
========================================================================================

========================================================================================
    Please notify me if you wish to make use of this library in your addon!
    I need to know for testing purposes - to make sure that any changes I make
    aren't going to break someone else's addon!
========================================================================================

    Official website for AdvancedIconSelector:
    http://www.curse.com/addons/wow/advancediconselector
    
    Official website for LibAdvancedIconSelector-1.0:
    http://www.curse.com/addons/wow/libadvancediconselector-1-0
    
    Original author: Darthyl of Bronzebeard-US  <darthyl@hotmail.com>

========================================================================================

Setup work:  (to use LibAdvancedIconSelector-1.0 in your addon)

    1) Please LET ME KNOW that you will be using my library in your addon.  If I don't
       know you're dependent on my library, I might accidentally break your addon!

    2) Copy the "LibAdvancedIconSelector-1.0" directory into a "Libs" subdirectory of
       your addon.

    3) Add Libs\LibAdvancedIconSelector-1.0\LibAdvancedIconSelector-1.0.xml to your TOC.

    4) You should also add LibAdvancedIconSelector-1.0 to OptionalDeps and X-Embeds.
       (This step is technically only required if your addon can run disembedded, but
       it's a good idea to do it even if not):

          ## OptionalDeps: LibAdvancedIconSelector-1.0
          ## X-Embeds: LibAdvancedIconSelector-1.0

            If you are loading LibAdvancedIconSelector-1.0 on-demand, however
            (via LoadAddOn()), do NOT add it to OptionalDeps - otherwise it will
            load immediately instead of on-demand.

 ==== IMPORTANT ====
  When you distribute your addon, note that the user will NOT be able to search by
  keywords unless (a) you package a copy of the keyword library alongside your addon (see
  instructions at top of AdvancedIconSelector-KeywordData.lua), or (b) the user has installed
  AdvancedIconSelector alongside your addon.  Packaging the keyword library is not required,
  however (users will be able to search by filename even if keyword data is not present),
  but it is recommended.

  As of version 1.0.4 of this library, there is also a new technique to load the keyword data.
  Instead of calling LoadAddOn("MyAddon_KeywordData"), simply specify the addon name as an
  option to Create<...>() as follows:

    local options = {
      . . . 
      keywordAddonName = "MyAddon_KeywordData"
    }

  Or, you can programmatically load the library with:
    lib:LoadKeywords("MyAddon_KeywordData")
  (but the first approach is preferred)

  Both of these techniques provide the following behavior:
    If your keyword library is not available, or is older than the default keyword library
    (AdvancedIconSelector-KeywordData), the default one will be loaded instead (assuming it's
    available).

  *Do NOT simply bundle AdvancedIconSelector-KeywordData with your addon - you must rename it!*
    (see instructions at top of AdvancedIconSelector-KeywordData.lua)

  (The keyword library is packaged in this strange manner so that it doesn't get loaded until
   it's actually needed, and so multiple addons bundling the library don't have conflicting
   directory names that may cause download managers to get confused and replace newer versions
   with older ones.)

========================================================================================

There are 3 ways to use LibAdvancedIconSelector-1.0:

    a) Standard window mode.  A window is created that contains an icon selector, search box,
       okay button, cancel button, etc.

    b) Frame-only mode.  Only the icon selector frame is created (the part where you pick
       the icons plus the scroll bar); no search box, window, or buttons are included, and
       you must specify the search parameter programmatically.

    c) Search-only mode.  No GUI elements are created.  This mode allows you to use the keyword
       and search features of AdvancedIconSelector, while providing your own GUI to display the
       icons.

Standard window mode example:

    local lib = LibStub("LibAdvancedIconSelector-1.0")    -- (ideally, this would be loaded on-demand)
    local options = { }
    local myIconWindow = lib:CreateIconSelectorWindow("MyIconWindow", UIParent, options)
    myIconWindow:SetPoint("CENTER")
    myIconWindow:Show()

Frame-only mode example:

    local lib = LibStub("LibAdvancedIconSelector-1.0")
    local options = { }
    local myIconFrame = lib:CreateIconSelectorFrame("MyIconFrame", UIParent, options)
    myIconFrame:SetSize(400, 300)
    myIconFrame:SetPoint("CENTER")
    myIconFrame:SetSearchParameter(nil)    -- (begin the search!)

Search-only mode example:

    local lib = LibStub("LibAdvancedIconSelector-1.0")
    local options = { }
    local search = lib:CreateSearch(options)
    search:SetScript("OnSearchStarted", function(search) print("Search started") end)
    search:SetScript("OnSearchResultAdded", function(search, texture) print("Found icon:", texture) end)
    search:SetScript("OnSearchComplete", function(search) print("Search finished") end)
    search:SetSearchParameter(nil)    -- (begin the search!)

    Note: This search object should be reused if possible - just call SetSearchParameter()
    or RestartSearch() to begin the enumeration again!

========================================================================================

Library functionality:

  function lib:Embed(addon)
    Embeds this library's functions into your addon.  Calling this is not necessary.

  function lib:CreateIconSelectorWindow(name, parent, options)
    Creates a new icon selector WINDOW, including search box, buttons, etc.

  function lib:CreateIconSelectorFrame(name, parent, options)
    Creates a new icon selector FRAME, which includes only the icon display
    and its scroll bar.

  function lib:CreateSearch(options)
    Creates and returns a new search object.

  function lib:GetRevision()
    Returns the revision # of the library.

  function lib:LoadKeywords(addonName)
    Loads the keyword library with the given name, defaulting to AdvancedIconSelector-KeywordData
    (if available) if the given addon can't be found.  It's not normally necessary to call this,
    as it's done automatically when an icon scan is started, using keywordAddonName from options.

    (This function is only necessary if you want to access keyword data without starting an icon search)

  function lib:LookupKeywords(texture)
    Using the currently loaded keyword library.  Returns a string of keywords corresponding
    to the given icon texture.  Note that the filename should NOT include the INTERFACE\\ICONS\\
    prefix.  Returns nil if there is no keyword library loaded, or if the given icon can't
    be found or doesn't have any keywords associated with it.

========================================================================================

IconSelectorWindow functionality:

  ** Note: You can always access the icon frame contained within an icon window through
  iconsWindow.iconsFrame **

  function IconSelectorWindow:SetScript(scriptType, handler)
    The usual SetScript() for a frame, but with the following additional script types:
      OnOkayClicked(self) - fired when the Okay button is clicked
      OnCancelClicked(self) - fired when the Cancel, Close, or X button is clicked

  function IconSelectorWindow:SetSearchParameter(searchText, immediateResults)
    Sets the search parameter, also updating the search field's text.

========================================================================================

IconSelectorFrame functionality:

  function IconSelectorFrame:SetSearchParameter(searchText, immediateResults)
    Sets the search parameter used to filter the icons displayed in the frame,
    and begins the search after a short delay (in case the user is still typing),
    unless immediateResults is set to true, in which case the search begins
    immediately.

  function IconSelectorFrame:SetSelectedIcon(index)
    Sets the selection to the icon with the given (global) index.

  function IconSelectorFrame:SetSelectionByName(name)
    Sets the selection to the icon with the given texture filename,
    *BUT* only once it has been found, unless a new icon has been selected by
    the user before then.

  function IconSelectorFrame:GetSelectedIcon()
    Returns the global index of the currently selected icon, or nil if nothing
    is currently selected.

  function IconSelectorFrame:GetIconInfo(index)
    (Returns id, kind, texture)
    Returns information about the icon at the given (global) index.
      - id is the index of the icon within its section (local index).
      - kind is a section-defined string such as "Macro", or "Item"
      - texture is the icon's texture
    If index is out of range or nil, nil is returned.

  function IconSelectorFrame:ReplaceSection(sectionName, section)
    Replaces a named section of icons with the given one.  See "custom icon sections"
    below for details.

  function IconSelectorFrame:SetSectionVisibility(sectionName, visibility)
    Shows or hides a named section of icons.

  function IconSelectorFrame:GetSectionVisibility(sectionName)
    Returns whether or not the given named icon section is currently shown.

  function IconSelectorFrame:SetScript(scriptType, handler)
    New script types have been added to the iconsFrame:
      OnSelectedIconChanged(self) - fired when the selection changes
      BeforeShow(self) - like OnShow, but fired just BEFORE the frame is shown.
        (helpful if updating custom icon sections)

========================================================================================

SearchObject functionality:

  function SearchObject:SetSearchParameter(searchText, immediateResults)
    Sets the search parameter, and then restarts the search.  Since this is generally
    called each time an editbox is changed, a small delay occurs before the search
    begins unless immediateResults is set to true, except for the first search performed
    with a search object.

  function SearchObject:GetSearchParameter()
    Returns the current search parameter.

  function SearchObject:RestartSearch()
    Restarts the search from the beginning.

  function SearchObject:Stop()
    Stops the search immediately.  Call RestartSearch() to start it again.  (This is
    generally called when a frame is hidden to prevent aimlessly searching for icons.)

  function SearchObject:SetScript(script, callback)
    BeforeSearchStarted(search) - called just before the search is (re)started
    OnSearchStarted(search) - called after the search is (re)started, but before any results are reported
    OnSearchResultAdded(search, texture, globalID, localID, kind) - called for each search result found
    OnSearchComplete(search) - called when all results have been found
    OnIconScanned(search, texture, globalID, localID, kind) - called for each icon scanned, regardless of whether it matches the search parameter
    OnSearchTick(search) - called after each search tick (or at a constant rate, if the search is ever not tick-based)
  
  function SearchObject:ReplaceSection(sectionName, section)
    Replaces a named section of icons with the given one.  See "custom icon sections"
    below for details.

  function SearchObject:ExcludeSection(sectionName, exclude)
    Excludes (or includes) a named icon section from the search, but does not restart the search.

  function SearchObject:IsSectionExcluded(sectionName)
    Returns whether or not the given icon section is excluded from the search.
  
  function SearchObject:GetIconInfo(id)
    (Returns id, kind, texture - see IconSelectorFrame:GetIconInfo())
    Returns information about the icon at the given global index.

========================================================================================

Options tables:

  You can pass an optional "options" table to the Create<...>() functions that specifies window styling
  and icon section information.  Officially supported options are as follows:

  Primary options:
     sectionOrder - a list of strings which defines which icon sections should appear, and the order
       that they should appear in.  Predefined sections include: DynamicIcon, MacroIcons, ItemIcons
       You can specify custom section names here as well.
     sections - a table of custom sections - see "custom icon sections" below for details.
     sectionVisibility - mapping from section name to whether that section is initially visible
     visibilityButtons - array of 2-element tables that maps from section name to the text of a check
       button that can be used to toggle that section's visibility. (1st element = name, 2nd = text)
     showDynamicText - shows the "(dynamic)" text under the question mark icon if true (default = false)
     okayCancel - Okay/Cancel vs. Close only (default = true => Okay/cancel)
     customFrame - a custom frame to show at the top of the icon selector window.  This is where
       the name editbox is located on the equipment set / macro replacement UIs.
  Basic window options:
     width - initial width of the window
     height - initial height of the window
     enableResize - enable resizing of the frame? (default = true)
     enableMove - enable moving of the frame? (default = true)
     headerText - title of the frame (default = L["Icon Browser"])
  Additional window customization:
     allowOffscreen - enables positioning of the window offscreen (default = false)
     minResizeWidth - minimum resize width (default = 300)
     minResizeHeight - minimum resize height (default = 200)
     anchorFrame - disables move / resize functionality while this frame is shown (default = nil)
     noCloseButton - remove the X button? (default = false)
     bgFile - override background texture, as passed to SetBackdrop()
     edgeFile - override edge texture, as passed to SetBackdrop()
     tile - override tile parameter for SetBackdrop()
     tileSize - override background tile size, as passed to SetBackdrop()
     edgeSize - override edge segment size, as passed to SetBackdrop()
     insets - override insets for the background texture, as passed to SetBackdrop()
     contentInsets - override insets for frame contents
     headerTexture - override texture used for the frame header
     headerWidth - override width of the frame header
     headerOffsetX / headerOffsetY - override offset of the header text
     headerFont - override font to use for the header text

========================================================================================

Custom icon sections:

  Custom icon sections can be defined as in the following example:

    local MACRO_ICON_FILENAMES = { }
    GetMacroIcons(MACRO_ICON_FILENAMES)
    local lib = LibStub("LibAdvancedIconSelector-1.0")    -- (ideally, this would be loaded on-demand)
    local options = {
      sectionOrder = { "MySection1", "MySection2" },
      sections = {
        MySection1 = { count = 1, GetIconInfo = function(index) return index, "Dynamic", "INV_Misc_QuestionMark" end },
        MySection2 = { count = 10, GetIconInfo = function(index) return index, "Macro", MACRO_ICON_FILENAMES[index] end }
      }
    }
    local myIconWindow = lib:CreateIconSelectorWindow("MyIconWindow", UIParent, options)
    myIconWindow:SetPoint("CENTER")
    myIconWindow:Show()

  Each section table simply has two entries - a count, and a GetIconInfo() function to
  return information about each icon (local id, kind, texture).  If the number of icons
  in a section must change after it's been specified, consider using IconSelectorFrame:ReplaceSection().
  (altering tables after handing them to L-AIS is unsupported and usually won't work -
   please do not attempt it)

========================================================================================

For the time being, the functionality provided by the library is intentionally
very limited.  Let me know if there's something you need to do that's not
possible with the current API.
