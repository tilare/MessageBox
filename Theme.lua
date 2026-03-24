-- Theme.lua
-- Theme logic, Apply colors

-- When pfUI's MessageBox skin is active, MessageBox_pfUI.lua styles the contact search, chat search bar,
-- and friends/conversations section expand toggles (SkinCollapseButton).
-- If pfUI is loaded but that skin is disabled, ApplyTheme must paint those (same rule as pfUI_config.disabled["skin_MessageBox"]).
local function MessageBoxTheme_PfUISkinStylesSearchChrome()
    if not IsAddOnLoaded("pfUI") then return false end
    if not pfUI_config then return true end
    if pfUI_config.disabled and pfUI_config.disabled["skin_MessageBox"] == "1" then return false end
    return true
end

-- button for modern or classic theme
function MessageBox:SkinCloseButton(btn, isModern, size)
    if not btn then return end
    size = size or (isModern and 18 or 28)
    btn:SetWidth(size)
    btn:SetHeight(size)
    if isModern then
        btn:SetNormalTexture(MessageBox.textures.closeOutline)
        btn:SetPushedTexture(MessageBox.textures.closeSolid)
        btn:SetHighlightTexture(MessageBox.textures.closeSolid)
        btn:SetAlpha(0.7)
        btn:SetScript("OnEnter", function() this:SetAlpha(1.0) end)
        btn:SetScript("OnLeave", function() this:SetAlpha(0.7) end)
    else
        btn:SetNormalTexture(MessageBox.textures.minimizeBtnUp)
        btn:SetPushedTexture(MessageBox.textures.minimizeBtnDown)
        btn:SetHighlightTexture(MessageBox.textures.minimizeBtnHi)
        btn:SetAlpha(1.0)
        btn:SetScript("OnEnter", nil)
        btn:SetScript("OnLeave", nil)
    end
end

-- small icon button's highlight for modern or classic theme
function MessageBox:SkinIconButton(btn, isModern, selectionColor)
    if not btn then return end
    if isModern then
        btn:SetHighlightTexture(MessageBox.textures.listHighlight)
        local hl = btn:GetHighlightTexture()
        if hl then
            hl:SetVertexColor(unpack(selectionColor))
            hl:SetAlpha(0.4)
        end
    else
        btn:SetHighlightTexture(MessageBox.textures.minimizeBtnHi)
        local hl = btn:GetHighlightTexture()
        if hl then hl:SetVertexColor(1, 1, 1, 1) end
    end
end

function MessageBox:SkinCheckbox(check, isModern, textColor, inputColor, panelBorderColor)
    if not check then return end

    if isModern then
        check:SetNormalTexture("")
        check:SetPushedTexture("")
        check:SetHighlightTexture(MessageBox.textures.listHighlight)
        local hl = check:GetHighlightTexture()
        if hl then
            hl:SetVertexColor(1, 1, 1, 0.15)
        end

        check:SetCheckedTexture(MessageBox.textures.white8x8)
        local ct = check:GetCheckedTexture()
        if ct then
            local highlightColor = MessageBox.settings.highlightColor or MessageBox.defaultSettings.highlightColor
            ct:SetVertexColor(unpack(highlightColor))
            ct:ClearAllPoints()
            ct:SetPoint("CENTER", 0, 0)
            ct:SetWidth(12)
            ct:SetHeight(12)
        end

        check:SetBackdrop({
            bgFile = MessageBox.textures.chatBg,
            edgeFile = MessageBox.textures.chatBg,
            tile = false, tileSize = 0, edgeSize = 1,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        check:SetBackdropColor(unpack(inputColor))
        check:SetBackdropBorderColor(unpack(panelBorderColor))
    else
        check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

        local ct = check:GetCheckedTexture()
        if ct then
            ct:SetVertexColor(1, 1, 1, 1)
            ct:ClearAllPoints()
            ct:SetAllPoints(check)
        end

        check:SetBackdrop(nil)
    end

    if check.label then
        check.label:SetTextColor(unpack(textColor))
    end
end

function MessageBox:UpdateThemeFrameSwatches()
    if self.themeFrame and self.themeFrame.swatches then
        for _, swatch in ipairs(self.themeFrame.swatches) do
            local c = MessageBox.settings[swatch.colorKey] or {1,1,1,1}
            swatch.bg:SetVertexColor(unpack(c))
        end
    end
end

function MessageBox:ApplyTheme()
    local themeDef = self.settings.modernTheme and self.themes.modern or self.themes.classic
    
    -- Colors
    local mainColor, panelColor, inputColor, buttonColor, textColor, selectionColor
    
    if self.settings.modernTheme then
        local d = MessageBox.defaultSettings
        mainColor = self.settings.mainColor or d.mainColor
        panelColor = self.settings.panelColor or d.panelColor
        inputColor = self.settings.inputColor or d.inputColor
        buttonColor = self.settings.buttonColor or d.buttonColor
        textColor = self.settings.textColor or d.textColor
        selectionColor = self.settings.selectionColor or d.selectionColor
    else
        mainColor = self.themes.classic.mainColor
        panelColor = self.themes.classic.panelColor
        inputColor = self.themes.classic.inputColor
        buttonColor = {0.2, 0.2, 0.2, 1} 
        textColor = {1, 1, 1, 1} 
        selectionColor = {1, 0.82, 0, 0.5}
    end

    -- Detached windows
    if self.detachedWindows then
        for contact, win in pairs(self.detachedWindows) do
            if win then
                win:SetBackdrop(themeDef.mainBackdrop)
                win:SetBackdropColor(unpack(mainColor))
                win:SetBackdropBorderColor(unpack(themeDef.mainBorderColor))
                
                if win.scrollBar then
                    MessageBox:SkinScrollbar(win.scrollBar)
                    
                    if win.scrollBar.track then
                        if self.settings.modernTheme then
                            win.scrollBar.track:Show()
                        else
                            win.scrollBar.track:Hide()
                        end
                    end
                end
                
                if win.closeBtn then
                    MessageBox:SkinCloseButton(win.closeBtn, themeDef.flatButtons, themeDef.flatButtons and 18 or 32)
                end
                
                if win.inputBackdrop then
                    win.inputBackdrop:SetBackdrop(themeDef.inputBackdrop)
                    win.inputBackdrop:SetBackdropColor(unpack(inputColor))
                    win.inputBackdrop:SetBackdropBorderColor(unpack(themeDef.panelBorderColor))
                end
            end
        end
    end

    if not self.frame then return end
    
    self.frame:SetBackdrop(themeDef.mainBackdrop)
    self.frame:SetBackdropColor(unpack(mainColor))
    self.frame:SetBackdropBorderColor(unpack(themeDef.mainBorderColor))

    local regions = { self.frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" and region:GetText() == "MessageBox" then
            region:SetTextColor(unpack(textColor))
            region:ClearAllPoints()
            if self.settings.modernTheme then
                region:SetPoint("TOP", self.frame, "TOP", 0, -5)
            else
                region:SetPoint("TOP", self.frame, "TOP", 0, -12)
            end
            break
        end
    end

    if self.contactFrame then
        self.contactFrame:SetBackdrop(themeDef.panelBackdrop)
        self.contactFrame:SetBackdropColor(unpack(panelColor))
        self.contactFrame:SetBackdropBorderColor(unpack(themeDef.panelBorderColor))
        
        if self.UpdateScrollViews then self:UpdateScrollViews() end
    end

    if not MessageBoxTheme_PfUISkinStylesSearchChrome() then
        local searchBox = getglobal("MessageBoxContactSearch")
        if searchBox then
            local left = getglobal(searchBox:GetName() .. "Left")
            local middle = getglobal(searchBox:GetName() .. "Middle")
            local right = getglobal(searchBox:GetName() .. "Right")

            if self.settings.modernTheme then
                if left then left:Hide() end
                if middle then middle:Hide() end
                if right then right:Hide() end

                searchBox:SetBackdrop(themeDef.inputBackdrop)
                searchBox:SetBackdropColor(unpack(inputColor))
                searchBox:SetBackdropBorderColor(unpack(themeDef.panelBorderColor))
            else
                if left then left:Show() end
                if middle then middle:Show() end
                if right then right:Show() end

                searchBox:SetBackdrop(nil)
            end

            searchBox:SetTextColor(unpack(textColor))
        end
    end

    if self.chatFrame then
        self.chatFrame:SetBackdrop(themeDef.panelBackdrop)
        self.chatFrame:SetBackdropColor(unpack(panelColor))
        self.chatFrame:SetBackdropBorderColor(unpack(themeDef.panelBorderColor))
    end

    if self.inputBackdrop then
        self.inputBackdrop:SetBackdrop(themeDef.inputBackdrop)
        self.inputBackdrop:SetBackdropColor(unpack(inputColor))
        self.inputBackdrop:SetBackdropBorderColor(unpack(themeDef.panelBorderColor))
    end

    local buttons = {self.sendButton, self.deleteButton, self.deleteAllButton, self.settingsButton}
    
    if self.themeFrame and self.themeFrame.resetBtn then
        table.insert(buttons, self.themeFrame.resetBtn)
    end
    
    for _, btn in ipairs(buttons) do
        if btn then
            if themeDef.flatButtons then
                btn:SetNormalTexture("")
                btn:SetPushedTexture("")
                btn:SetHighlightTexture(MessageBox.textures.listHighlight)
                
                btn:SetBackdrop(themeDef.panelBackdrop)
                btn:SetBackdropColor(unpack(buttonColor))
                btn:SetBackdropBorderColor(0, 0, 0, 1)
                btn.flatBg = true
                
                local hl = btn:GetHighlightTexture()
                if hl then
                    hl:SetVertexColor(unpack(selectionColor))
                    local r, g, b, a = unpack(selectionColor)
                    hl:SetAlpha(0.4) 
                end
            else
                btn:SetNormalTexture(MessageBox.textures.panelBtnUp)
                btn:SetPushedTexture(MessageBox.textures.panelBtnDown)
                btn:SetHighlightTexture(MessageBox.textures.minimizeBtnHi)
                btn:SetBackdrop(nil)
                btn.flatBg = false
                
                local hl = btn:GetHighlightTexture()
                if hl then hl:SetVertexColor(1, 1, 1, 1) end
            end
            
            local btnText = btn:GetFontString()
            if btnText then
                btnText:SetTextColor(unpack(textColor))
            end
        end
    end

    MessageBox:SkinIconButton(self.themeButton, themeDef.flatButtons, selectionColor)

    MessageBox:SkinIconButton(self.bellButton, themeDef.flatButtons, selectionColor)

    if self.chatHeader then
        MessageBox:SkinIconButton(self.chatHeader.pinBtn, themeDef.flatButtons, selectionColor)
        MessageBox:SkinIconButton(self.chatHeader.searchBtn, themeDef.flatButtons, selectionColor)
    end

    if not MessageBoxTheme_PfUISkinStylesSearchChrome() and self.searchBarFrame then
        if self.settings.modernTheme then
            self.searchBarFrame:SetBackdrop(themeDef.panelBackdrop)
            self.searchBarFrame:SetBackdropColor(unpack(panelColor))
            self.searchBarFrame:SetBackdropBorderColor(unpack(themeDef.panelBorderColor))

            if self.searchBarFrame.searchInput then
                self.searchBarFrame.searchInput:SetBackdrop(themeDef.inputBackdrop)
                self.searchBarFrame.searchInput:SetBackdropColor(unpack(inputColor))
                self.searchBarFrame.searchInput:SetBackdropBorderColor(unpack(themeDef.panelBorderColor))
            end

            if self.searchBarFrame.prevBtn then
                local btn = self.searchBarFrame.prevBtn
                btn:SetNormalTexture(MessageBox.textures.caretUp)
                btn:SetPushedTexture(MessageBox.textures.caretUp)
                btn:SetHighlightTexture(MessageBox.textures.caretUpHi)
                btn:SetBackdrop(nil)
                btn:SetAlpha(0.7)
                btn:SetScript("OnEnter", function()
                    this:SetAlpha(1.0)
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Previous Match")
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function()
                    this:SetAlpha(0.7)
                    GameTooltip:Hide()
                end)
                if btn.arrowText then btn.arrowText:Hide() end
            end

            if self.searchBarFrame.nextBtn then
                local btn = self.searchBarFrame.nextBtn
                btn:SetNormalTexture(MessageBox.textures.caretDown)
                btn:SetPushedTexture(MessageBox.textures.caretDown)
                btn:SetHighlightTexture(MessageBox.textures.caretDownHi)
                btn:SetBackdrop(nil)
                btn:SetAlpha(0.7)
                btn:SetScript("OnEnter", function()
                    this:SetAlpha(1.0)
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Next Match")
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function()
                    this:SetAlpha(0.7)
                    GameTooltip:Hide()
                end)
                if btn.arrowText then btn.arrowText:Hide() end
            end

            MessageBox:SkinCloseButton(self.searchBarFrame.closeBtn, true, 14)
        else
            self.searchBarFrame:SetBackdrop({
                bgFile = MessageBox.textures.tooltipBg,
                tile = true, tileSize = 16,
                insets = {left = 0, right = 0, top = 0, bottom = 0}
            })
            self.searchBarFrame:SetBackdropColor(0, 0, 0, 0.5)

            if self.searchBarFrame.searchInput then
                self.searchBarFrame.searchInput:SetBackdrop({
                    bgFile = MessageBox.textures.tooltipBg,
                    edgeFile = MessageBox.textures.tooltipBorder,
                    tile = true, tileSize = 16, edgeSize = 12,
                    insets = {left = 3, right = 3, top = 3, bottom = 3}
                })
                self.searchBarFrame.searchInput:SetBackdropColor(0, 0, 0, 0.6)
                self.searchBarFrame.searchInput:SetBackdropBorderColor(1, 1, 1, 1)
            end

            if self.searchBarFrame.prevBtn then
                local btn = self.searchBarFrame.prevBtn
                btn:SetNormalTexture(MessageBox.textures.scrollUpUp)
                btn:SetPushedTexture(MessageBox.textures.scrollUpDown)
                btn:SetHighlightTexture(MessageBox.textures.scrollUpHi)
                btn:SetBackdrop(nil)
                btn:SetAlpha(1.0)
                btn:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Previous Match")
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                if btn.arrowText then btn.arrowText:Hide() end
            end

            if self.searchBarFrame.nextBtn then
                local btn = self.searchBarFrame.nextBtn
                btn:SetNormalTexture(MessageBox.textures.scrollDownUp)
                btn:SetPushedTexture(MessageBox.textures.scrollDownDown)
                btn:SetHighlightTexture(MessageBox.textures.scrollDownHi)
                btn:SetBackdrop(nil)
                btn:SetAlpha(1.0)
                btn:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Next Match")
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                if btn.arrowText then btn.arrowText:Hide() end
            end

            MessageBox:SkinCloseButton(self.searchBarFrame.closeBtn, false, 18)
        end
    end

    if self.closeButton then
        MessageBox:SkinCloseButton(self.closeButton, themeDef.flatButtons)
        if not themeDef.flatButtons then
            self.closeButton:SetDisabledTexture(MessageBox.textures.minimizeBtnDisabled)
        end
    end

    -- Theme frame
    if self.themeFrame then
        if self.settings.modernTheme then
            self.themeFrame:SetBackdrop(themeDef.mainBackdrop)
            self.themeFrame:SetBackdropColor(unpack(mainColor))
            self.themeFrame:SetBackdropBorderColor(unpack(themeDef.mainBorderColor))
            
            MessageBox:SkinCloseButton(self.themeFrame.closeBtn, true)
        else
            self.themeFrame:SetBackdrop({
                bgFile = MessageBox.textures.dialogBg,
                edgeFile = MessageBox.textures.dialogBorder,
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 }
            })
            self.themeFrame:SetBackdropColor(1,1,1,1)
            self.themeFrame:SetBackdropBorderColor(1,1,1,1)

            MessageBox:SkinCloseButton(self.themeFrame.closeBtn, false)
        end
    end

    -- Settings frame
    if self.settingsFrame then
        if self.settings.modernTheme then
            self.settingsFrame:SetBackdrop(themeDef.mainBackdrop)
            self.settingsFrame:SetBackdropColor(unpack(mainColor))
            self.settingsFrame:SetBackdropBorderColor(unpack(themeDef.mainBorderColor))
            
            MessageBox:SkinCloseButton(self.settingsFrame.closeBtn, true)
        else
            self.settingsFrame:SetBackdrop({
                bgFile = MessageBox.textures.dialogBg,
                edgeFile = MessageBox.textures.dialogBorder,
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 }
            })
            self.settingsFrame:SetBackdropColor(1,1,1,1)
            self.settingsFrame:SetBackdropBorderColor(1,1,1,1)

            MessageBox:SkinCloseButton(self.settingsFrame.closeBtn, false)
        end

        if self.settingsFrame.sectionHeaders then
            for _, h in ipairs(self.settingsFrame.sectionHeaders) do
                if self.settings.modernTheme then
                    h.text:SetTextColor(0.7, 0.7, 0.7, 1)
                    h.line:SetTexture(0.4, 0.4, 0.4, 0.3)
                else
                    h.text:SetTextColor(1, 0.82, 0, 1)
                    h.line:SetTexture(1, 0.82, 0, 0.3)
                end
            end
        end

        -- Skin settings checkboxes
        if self.settingsFrame.checks then
            for key, check in pairs(self.settingsFrame.checks) do
                MessageBox:SkinCheckbox(check, self.settings.modernTheme, textColor, inputColor, themeDef.panelBorderColor)
            end
        end

        -- Skin font size slider
        if self.settingsFrame.fontSlider then
            local slider = self.settingsFrame.fontSlider
            local name = slider:GetName()

            if self.settings.modernTheme then
                slider:SetHeight(10)
                slider:SetBackdrop({
                    bgFile = MessageBox.textures.chatBg,
                    edgeFile = MessageBox.textures.chatBg,
                    edgeSize = 1,
                    insets = {left = 0, right = 0, top = 0, bottom = 0}
                })
                slider:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
                slider:SetBackdropBorderColor(0, 0, 0, 0)

                local thumb = getglobal(name.."Thumb")
                if thumb then
                    thumb:SetTexture(MessageBox.textures.white8x8)
                    local r, g, b, a = unpack(self.settings.highlightColor or {0.8, 0.8, 0.8, 1})
                    thumb:SetVertexColor(r, g, b, a)
                    thumb:SetWidth(10)
                    thumb:SetHeight(10)
                end

                local textLabel = getglobal(name.."Text")
                if textLabel then textLabel:SetTextColor(unpack(self.settings.textColor or {1,1,1,1})) end
                local low = getglobal(name.."Low")
                if low then
                    low:SetTextColor(0.5, 0.5, 0.5, 1)
                    low:ClearAllPoints()
                    low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
                end
                local high = getglobal(name.."High")
                if high then
                    high:SetTextColor(0.5, 0.5, 0.5, 1)
                    high:ClearAllPoints()
                    high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
                end
            else
                slider:SetHeight(16)
                slider:SetBackdrop({
                    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
                    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
                    tile = true, tileSize = 8, edgeSize = 8,
                    insets = {left = 3, right = 3, top = 6, bottom = 6}
                })
                slider:SetBackdropColor(1, 1, 1, 1)
                slider:SetBackdropBorderColor(1, 1, 1, 1)

                local thumb = getglobal(name.."Thumb")
                if thumb then
                    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
                    thumb:SetVertexColor(1, 1, 1, 1)
                    thumb:SetWidth(32)
                    thumb:SetHeight(32)
                end

                local textLabel = getglobal(name.."Text")
                if textLabel then textLabel:SetTextColor(1, 0.82, 0, 1) end
                local low = getglobal(name.."Low")
                if low then
                    low:SetTextColor(1, 1, 1, 1)
                    low:ClearAllPoints()
                    low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, 3)
                end
                local high = getglobal(name.."High")
                if high then
                    high:SetTextColor(1, 1, 1, 1)
                    high:ClearAllPoints()
                    high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, 3)
                end
            end
        end
    end

    local headers = {self.friendsHeader, self.conversationsHeader}
    for _, header in ipairs(headers) do
        if header then
            if header.text then
                header.text:SetTextColor(unpack(textColor))
            end

            -- pfUI MessageBox skin uses SkinCollapseButton on these (Blizzard +/- paths); skip theme textures.
            if not MessageBoxTheme_PfUISkinStylesSearchChrome() then
                local plus = header.plusButton
                if themeDef.flatButtons then
                    plus:SetNormalTexture("")
                    plus:SetPushedTexture("")
                    plus:SetHighlightTexture("")
                    plus:SetBackdrop(themeDef.panelBackdrop)
                    plus:SetBackdropColor(unpack(buttonColor))
                    plus:SetBackdropBorderColor(0.3,0.3,0.3,1)
                    plus.flatBg = true
                    if plus.text then
                        plus.text:Show()
                        plus.text:SetTextColor(unpack(textColor))
                    end
                else
                    plus:SetNormalTexture(MessageBox.textures.plusUp)
                    plus:SetPushedTexture(MessageBox.textures.plusDown)
                    plus:SetHighlightTexture(MessageBox.textures.plusHi)
                    plus:SetBackdrop(nil)
                    plus.flatBg = false
                    if plus.text then plus.text:Hide() end
                end

                local minus = header.minusButton
                if themeDef.flatButtons then
                    minus:SetNormalTexture("")
                    minus:SetPushedTexture("")
                    minus:SetHighlightTexture("")
                    minus:SetBackdrop(themeDef.panelBackdrop)
                    minus:SetBackdropColor(unpack(buttonColor))
                    minus:SetBackdropBorderColor(0.3,0.3,0.3,1)
                    minus.flatBg = true
                    if minus.text then
                        minus.text:Show()
                        minus.text:SetTextColor(unpack(textColor))
                    end
                else
                    minus:SetNormalTexture(MessageBox.textures.minusUp)
                    minus:SetPushedTexture(MessageBox.textures.minusDown)
                    minus:SetHighlightTexture(MessageBox.textures.minusHi)
                    minus:SetBackdrop(nil)
                    minus.flatBg = false
                    if minus.text then minus.text:Hide() end
                end
            end
        end
    end
    
    -- Scrollbars
    local scrollbars = { getglobal("MessageBoxFriendsScrollScrollBar"), getglobal("MessageBoxConversationsScrollScrollBar"), getglobal("MessageBoxChatHistoryScrollBar") }
    for _, sb in ipairs(scrollbars) do
        if sb then
            if not sb.track then
                sb.track = sb:CreateTexture(nil, "BACKGROUND")
                sb.track:SetTexture(0.15, 0.15, 0.15, 0.5) 
                sb.track:SetWidth(4)
                sb.track:SetPoint("TOP", sb, "TOP", 0, 0)
                sb.track:SetPoint("BOTTOM", sb, "BOTTOM", 0, 0)
            end
            
            if self.settings.modernTheme then
                sb.track:Show()
            else
                sb.track:Hide()
            end
        end
    end
    
    MessageBox:SkinScrollbar(MessageBoxFriendsScroll)
    MessageBox:SkinScrollbar(MessageBoxConversationsScroll)
    MessageBox:SkinScrollbar(MessageBoxChatHistoryScrollBar)
    
    if self.settings.modernTheme then
        if self.themeButton then self.themeButton:Show() end
        if self.bellButton and self.themeButton then 
             self.bellButton:ClearAllPoints()
             self.bellButton:SetPoint("LEFT", self.themeButton, "RIGHT", 5, 0)
        end
    else
        if self.themeButton then self.themeButton:Hide() end
        if self.themeFrame then self.themeFrame:Hide() end
        
        if self.bellButton then 
             self.bellButton:ClearAllPoints()
             self.bellButton:SetPoint("LEFT", self.settingsButton, "RIGHT", 8, 0)
        end
    end

    if self.UpdateThemeFrameSwatches then
        self:UpdateThemeFrameSwatches()
    end
end

function MessageBox:OpenColorPicker(colorKey)
    local r, g, b, a = unpack(MessageBox.settings[colorKey] or {1, 1, 1, 1})
    
    ColorPickerFrame.func = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = 1 - OpacitySliderFrame:GetValue()
        MessageBox.settings[colorKey] = {r, g, b, a}
        MessageBox:ApplyTheme()
        if colorKey == "highlightColor" then
            MessageBox:SkinScrollbar(MessageBoxFriendsScroll)
            MessageBox:SkinScrollbar(MessageBoxConversationsScroll)
            MessageBox:SkinScrollbar(MessageBoxChatHistoryScrollBar) 
        end
    end
    
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
    ColorPickerFrame.cancelFunc = function(prevVals)
        local r, g, b, a = unpack(prevVals)
        MessageBox.settings[colorKey] = {r, g, b, a}
        MessageBox:ApplyTheme()
        if colorKey == "highlightColor" then
            MessageBox:SkinScrollbar(MessageBoxFriendsScroll)
            MessageBox:SkinScrollbar(MessageBoxConversationsScroll)
            MessageBox:SkinScrollbar(MessageBoxChatHistoryScrollBar)
        end
    end
    
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacity = 1 - a
    ColorPickerFrame.previousValues = {r, g, b, a}
    
    ColorPickerFrame:SetFrameStrata("TOOLTIP")
    ColorPickerFrame:Raise()
    
    ColorPickerFrame:Show()
end

function MessageBox:ShowThemeFrame()
    if not self.themeFrame then
        self:EnsureThemeBlocker()
        
        local f = CreateFrame("Frame", "MessageBoxThemeFrame", UIParent)
        tinsert(UISpecialFrames, "MessageBoxThemeFrame")
        f:SetWidth(200)
        f:SetHeight(320)
        
        if self.themeButton and self.themeButton:IsVisible() then
            f:SetPoint("BOTTOMLEFT", self.themeButton, "TOPLEFT", 0, 5)
        else
            f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end

        f:SetFrameStrata("FULLSCREEN_DIALOG") 
        f:SetToplevel(true)
        
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function() this:StartMoving() end)
        f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
        
        f:SetScript("OnHide", function() 
            if MessageBox.themeBlocker then MessageBox.themeBlocker:Hide() end
        end)
        
        f:SetBackdrop({
            bgFile = MessageBox.textures.dialogBg,
            edgeFile = MessageBox.textures.dialogBorder,
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Theme Colors")

        local function CreateSwatch(label, colorKey, yOffset)
            local swatch = CreateFrame("Button", nil, f)
            swatch:SetWidth(20)
            swatch:SetHeight(20)
            swatch:SetPoint("TOPLEFT", 20, yOffset)
            
            local bg = swatch:CreateTexture(nil, "BACKGROUND")
            bg:SetWidth(18)
            bg:SetHeight(18)
            bg:SetPoint("CENTER", 0, 0)
            bg:SetTexture(1, 1, 1)
            swatch.bg = bg
            
            local border = swatch:CreateTexture(nil, "OVERLAY")
            border:SetTexture(MessageBox.textures.quickslot)
            border:SetWidth(34)
            border:SetHeight(34)
            border:SetPoint("CENTER", 0, 0)

            local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("LEFT", swatch, "RIGHT", 10, 0)
            text:SetText(label)
            
            swatch:SetScript("OnClick", function()
                MessageBox:OpenColorPicker(colorKey)
            end)
            
            swatch:SetScript("OnShow", function()
                local c = MessageBox.settings[colorKey] or {1,1,1,1}
                this.bg:SetVertexColor(unpack(c))
            end)
            
            if not f.swatches then f.swatches = {} end
            table.insert(f.swatches, swatch)
            swatch.colorKey = colorKey
            
            return swatch
        end

        CreateSwatch("Outer Panel", "mainColor", -40)
        CreateSwatch("Inner Panel", "panelColor", -70)
        CreateSwatch("Text Box", "inputColor", -100)
        CreateSwatch("Scroll Bars", "highlightColor", -130)
        CreateSwatch("Buttons", "buttonColor", -160)
        CreateSwatch("Text", "textColor", -190)
        CreateSwatch("Highlight", "selectionColor", -220)
        
        local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        resetBtn:SetWidth(100)
        resetBtn:SetHeight(24)
        resetBtn:SetPoint("BOTTOM", 0, 15)
        resetBtn:SetText("Reset Colors")
        resetBtn:SetScript("OnClick", function()
            local colorKeys = {"mainColor", "panelColor", "inputColor", "highlightColor", "buttonColor", "textColor", "selectionColor"}
            for _, key in ipairs(colorKeys) do
                if MessageBox.defaultSettings[key] then
                    MessageBox.settings[key] = {unpack(MessageBox.defaultSettings[key])}
                end
            end
            
            MessageBox:ApplyTheme()
            MessageBox:SkinScrollbar(MessageBoxFriendsScroll)
            MessageBox:SkinScrollbar(MessageBoxConversationsScroll)
            MessageBox:SkinScrollbar(MessageBoxChatHistoryScrollBar)
            MessageBox:UpdateThemeFrameSwatches()
        end)
        f.resetBtn = resetBtn

        f:SetScript("OnShow", function() MessageBox:UpdateThemeFrameSwatches() end)
        
        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -5, -5)
        close:SetScript("OnClick", function() this:GetParent():Hide() end)
        f.closeBtn = close

        self.themeFrame = f
        
        MessageBox:ApplyTheme()
    end
    
    if self.themeBlocker then self.themeBlocker:Show() end
    self.themeFrame:Show()

end
