-- Theme.lua
-- Theme logic, Apply colors

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
        mainColor = self.settings.mainColor or {0.08, 0.08, 0.1, 0.95}
        panelColor = self.settings.panelColor or {0.15, 0.15, 0.17, 0.6}
        inputColor = self.settings.inputColor or {0.1, 0.1, 0.1, 0.8}
        buttonColor = self.settings.buttonColor or {0.2, 0.2, 0.2, 1}
        textColor = self.settings.textColor or {1, 1, 1, 1}
        selectionColor = self.settings.selectionColor or {0.8, 0.8, 0.8, 0.4}
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
                    if themeDef.flatButtons then
                        win.closeBtn:SetWidth(18)
                        win.closeBtn:SetHeight(18)
                        win.closeBtn:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-outline.tga")
                        win.closeBtn:SetPushedTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
                        win.closeBtn:SetHighlightTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
                        win.closeBtn:SetAlpha(0.7)
                        win.closeBtn:SetScript("OnEnter", function() this:SetAlpha(1.0) end)
                        win.closeBtn:SetScript("OnLeave", function() this:SetAlpha(0.7) end)
                    else
                        win.closeBtn:SetWidth(32)
                        win.closeBtn:SetHeight(32)
                        win.closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
                        win.closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
                        win.closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
                        win.closeBtn:SetAlpha(1.0)
                        win.closeBtn:SetScript("OnEnter", nil)
                        win.closeBtn:SetScript("OnLeave", nil)
                    end
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
            break
        end
    end

    if self.contactFrame then
        self.contactFrame:SetBackdrop(themeDef.panelBackdrop)
        self.contactFrame:SetBackdropColor(unpack(panelColor))
        self.contactFrame:SetBackdropBorderColor(unpack(themeDef.panelBorderColor))
        
        if self.UpdateScrollViews then self:UpdateScrollViews() end
    end

    -- Search bar
    local searchBox = getglobal("MessageBoxContactSearch")
    if searchBox then
        local left = getglobal(searchBox:GetName().."Left")
        local middle = getglobal(searchBox:GetName().."Middle")
        local right = getglobal(searchBox:GetName().."Right")

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
                btn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
                
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
                btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
                btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
                btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
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

    if self.themeButton then
        if themeDef.flatButtons then
            local hl = self.themeButton:GetHighlightTexture()
            if hl then
                 hl:SetVertexColor(unpack(selectionColor))
                 hl:SetAlpha(0.4)
            end
        else
            local hl = self.themeButton:GetHighlightTexture()
            if hl then hl:SetVertexColor(1, 1, 1, 1) end
        end
    end

    if self.bellButton then
        if themeDef.flatButtons then
            self.bellButton:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
            local hl = self.bellButton:GetHighlightTexture()
            if hl then 
                hl:SetVertexColor(unpack(selectionColor))
                hl:SetAlpha(0.4)
            end
        else
            self.bellButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
            local hl = self.bellButton:GetHighlightTexture()
            if hl then hl:SetVertexColor(1, 1, 1, 1) end
        end
    end

    if self.chatHeader and self.chatHeader.pinBtn then
        if themeDef.flatButtons then
             self.chatHeader.pinBtn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
             local hl = self.chatHeader.pinBtn:GetHighlightTexture()
             if hl then 
                 hl:SetVertexColor(unpack(selectionColor))
                 hl:SetAlpha(0.4)
             end
        else
             self.chatHeader.pinBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
             local hl = self.chatHeader.pinBtn:GetHighlightTexture()
             if hl then hl:SetVertexColor(1, 1, 1, 1) end
        end
    end

    if self.closeButton then
        if themeDef.flatButtons then
            self.closeButton:SetWidth(18)
            self.closeButton:SetHeight(18)
            self.closeButton:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-outline.tga")
            self.closeButton:SetPushedTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
            self.closeButton:SetHighlightTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
            
            self.closeButton:SetScript("OnEnter", function() this:SetAlpha(1.0) end)
            self.closeButton:SetScript("OnLeave", function() this:SetAlpha(0.7) end)
            self.closeButton:SetAlpha(0.7)
        else
            self.closeButton:SetWidth(28)
            self.closeButton:SetHeight(28)
            self.closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
            self.closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
            self.closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
            self.closeButton:SetDisabledTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled")
            
            self.closeButton:SetScript("OnEnter", nil)
            self.closeButton:SetScript("OnLeave", nil)
            self.closeButton:SetAlpha(1.0)
        end
    end

    -- Theme frame
    if self.themeFrame then
        if self.settings.modernTheme then
            self.themeFrame:SetBackdrop(themeDef.mainBackdrop)
            self.themeFrame:SetBackdropColor(unpack(mainColor))
            self.themeFrame:SetBackdropBorderColor(unpack(themeDef.mainBorderColor))
            
            if self.themeFrame.closeBtn then
                local cBtn = self.themeFrame.closeBtn
                cBtn:SetWidth(18)
                cBtn:SetHeight(18)
                cBtn:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-outline.tga")
                cBtn:SetPushedTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
                cBtn:SetHighlightTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
                cBtn:SetAlpha(0.7)
                cBtn:SetScript("OnEnter", function() this:SetAlpha(1.0) end)
                cBtn:SetScript("OnLeave", function() this:SetAlpha(0.7) end)
            end
        else
            self.themeFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 }
            })
            self.themeFrame:SetBackdropColor(1,1,1,1)
            self.themeFrame:SetBackdropBorderColor(1,1,1,1)

            if self.themeFrame.closeBtn then
                local cBtn = self.themeFrame.closeBtn
                cBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
                cBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
                cBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
                cBtn:SetAlpha(1.0)
                cBtn:SetScript("OnEnter", nil)
                cBtn:SetScript("OnLeave", nil)
            end
        end
    end

    -- Settings frame
    if self.settingsFrame then
        if self.settings.modernTheme then
            self.settingsFrame:SetBackdrop(themeDef.mainBackdrop)
            self.settingsFrame:SetBackdropColor(unpack(mainColor))
            self.settingsFrame:SetBackdropBorderColor(unpack(themeDef.mainBorderColor))
            
            if self.settingsFrame.closeBtn then
                local cBtn = self.settingsFrame.closeBtn
                cBtn:SetWidth(18)
                cBtn:SetHeight(18)
                cBtn:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-outline.tga")
                cBtn:SetPushedTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
                cBtn:SetHighlightTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
                cBtn:SetAlpha(0.7)
                cBtn:SetScript("OnEnter", function() this:SetAlpha(1.0) end)
                cBtn:SetScript("OnLeave", function() this:SetAlpha(0.7) end)
            end
        else
            self.settingsFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 }
            })
            self.settingsFrame:SetBackdropColor(1,1,1,1)
            self.settingsFrame:SetBackdropBorderColor(1,1,1,1)

            if self.settingsFrame.closeBtn then
                local cBtn = self.settingsFrame.closeBtn
                cBtn:SetWidth(28)
                cBtn:SetHeight(28)
                cBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
                cBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
                cBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
                cBtn:SetAlpha(1.0)
                cBtn:SetScript("OnEnter", nil)
                cBtn:SetScript("OnLeave", nil)
            end
        end
    end

    local headers = {self.friendsHeader, self.conversationsHeader}
    for _, header in ipairs(headers) do
        if header then
            if header.text then
                header.text:SetTextColor(unpack(textColor))
            end
            
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
                plus:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
                plus:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
                plus:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Highlight")
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
                minus:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
                minus:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
                minus:SetHighlightTexture("Interface\\Buttons\\UI-MinusButton-Highlight")
                minus:SetBackdrop(nil)
                minus.flatBg = false
                if minus.text then minus.text:Hide() end
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
        local blocker = CreateFrame("Frame", "MessageBoxThemeBlocker", self.frame)
        blocker:SetAllPoints(self.frame)
        blocker:SetFrameStrata("DIALOG")
        blocker:EnableMouse(true) 
        blocker:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
        blocker:SetBackdropColor(0, 0, 0, 0.4)
        blocker:Hide()
        self.themeBlocker = blocker
        
        local f = CreateFrame("Frame", "MessageBoxThemeFrame", UIParent)
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
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
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
            border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
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
            -- Modern defaults
            MessageBox.settings.mainColor = {0.08, 0.08, 0.1, 0.95}
            MessageBox.settings.panelColor = {0.15, 0.15, 0.17, 0.6}
            MessageBox.settings.inputColor = {0.1, 0.1, 0.1, 0.8}
            MessageBox.settings.highlightColor = {0.8, 0.8, 0.8, 1}
            MessageBox.settings.buttonColor = {0.2, 0.2, 0.2, 1}
            MessageBox.settings.textColor = {1, 1, 1, 1}
            MessageBox.settings.selectionColor = {0.8, 0.8, 0.8, 0.4}
            
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
