--[[========================================================================================
      LibAdvancedIconSelector provides a searchable icon selection GUI to World
      of Warcraft addons.
      
      Copyright (c) 2011 David Forrester  (Darthyl of Bronzebeard-US)
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

local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale("LibAdvancedIconSelector-MTK", "enUS", true)
if not L then return end

-- Note: Although the icon selector may be localized, the search feature will still operate on english filenames and keywords.

-- Main window
L["FRAME_TITLE"] = "Icon Browser"
L["Search:"] = true
L["Okay"] = true
L["Cancel"] = true
L["Close"] = true

-- Tooltips
L["Macro texture:"] = true
L["Item texture:"] = true
L["Equipped item texture:"] = true
L["Spell texture:"] = true
L["Default / dynamic texture:"] = true
L["Additional keywords: "] = true
L["Spell: "] = true
L["Companion: "] = true
L["Mount: "] = true
L["Talent: "] = true
L["Tab: "] = true
L["Passive: "] = true
L["Racial: "] = true
L["Racial Passive: "] = true
L["Mastery: "] = true
L["Professions: "] = true
L["Pet Command: "] = true
L["Pet Stance: "] = true
