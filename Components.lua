-- Components.lua
-- Minimap, Settings, Popups, Notifications

MessageBox.minimapButton = nil
MessageBox.minimapPos = 45

function MessageBox:CreateMinimapButton()
    if self.minimapButton then return end

    local button = CreateFrame("Button", "MessageBoxMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("LOW")
    button:SetToplevel(true)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT") 

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Letter_15")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(52)
    border:SetHeight(52)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    -- Badge
    local badge = button:CreateTexture(nil, "OVERLAY")
    badge:SetTexture("Interface\\WorldMap\\WorldMapPartyIcon") 
    badge:SetVertexColor(1, 0, 0)
    badge:SetWidth(16)
    badge:SetHeight(16)
    badge:SetPoint("TOPRIGHT", button, "TOPRIGHT", -4, -4)
    badge:Hide()
    button.badge = badge

    local countText = button:CreateFontString(nil, "OVERLAY")
    countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    countText:SetPoint("CENTER", badge, "CENTER", 0, 0)
    countText:SetTextColor(1, 1, 1)
    countText:Hide()
    button.countText = countText

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetMovable(true)

    button:SetScript("OnClick", function() end)

    button:SetScript("OnMouseDown", function()
        if IsShiftKeyDown() then
            this.isMoving = true
            this:SetScript("OnUpdate", function() MessageBox:UpdateMinimapPosition() end)
        end
    end)

    button:SetScript("OnMouseUp", function()
        if this.isMoving then
            this.isMoving = false
            this:SetScript("OnUpdate", nil)
        elseif arg1 == "LeftButton" then
            MessageBox:ToggleFrame()
        end
    end)
    
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("MessageBox")
        GameTooltip:AddLine("Left-Click to Open", 1, 1, 1)
        GameTooltip:AddLine("Shift-Drag to Move", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.minimapButton = button
    self:UpdateMinimapPosition()
    self:UpdateMinimapBadge()
    
    if self.settings.showMinimapButton then
        button:Show()
    else
        button:Hide()
    end
end

function MessageBox:UpdateMinimapButtonVisibility()
    if not self.minimapButton then return end
    if self.settings.showMinimapButton then
        self.minimapButton:Show()
    else
        self.minimapButton:Hide()
    end
end

function MessageBox:UpdateMinimapPosition()
    if not self.minimapButton then return end
    
    if self.minimapButton.isMoving then
        local xpos, ypos = GetCursorPosition()
        local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
        xpos = xmin - xpos / UIParent:GetScale() + 70
        ypos = ypos / UIParent:GetScale() - ymin - 70
        self.minimapPos = math.deg(math.atan2(ypos, xpos))
    end

    local angle = math.rad(self.minimapPos or 45)
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    local radius = 80
    
    self.minimapButton:SetPoint("CENTER", "Minimap", "CENTER", -1 * radius * cos, -1 * radius * sin)
end

function MessageBox:UpdateMinimapBadge()
    -- Sync counts on button and popup
    local totalUnread = 0
    if MessageBox.unreadCounts then
        for contact, count in pairs(MessageBox.unreadCounts) do
            totalUnread = totalUnread + count
        end
    end
    
    -- Minimap button
    if self.minimapButton then
        if totalUnread > 0 then
            self.minimapButton.badge:Show()
            self.minimapButton.countText:SetText(totalUnread)
            self.minimapButton.countText:Show()
        else
            self.minimapButton.badge:Hide()
            self.minimapButton.countText:Hide()
        end
    end

    -- Notification popup
    if self.notificationPopup then
        if totalUnread > 0 and self.settings.popupNotificationsEnabled then
            self.notificationPopup:Show()
            self.notificationPopup.badge:Show()
            self.notificationPopup.countText:SetText(totalUnread)
            self.notificationPopup.countText:Show()
            self:UpdateNotificationVisuals()
        else
            self.notificationPopup:Hide()
            if self.notificationList and self.notificationList:IsVisible() then
                self.notificationList:Hide()
            end
        end
    end
end

-- Settings

function MessageBox:ShowSettingsFrame()
    if not self.settingsFrame then
        if not self.themeBlocker then
            local blocker = CreateFrame("Frame", "MessageBoxThemeBlocker", self.frame)
            blocker:SetAllPoints(self.frame)
            blocker:SetFrameStrata("DIALOG")
            blocker:EnableMouse(true)
            blocker:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
            blocker:SetBackdropColor(0, 0, 0, 0.4)
            blocker:Hide()
            self.themeBlocker = blocker
        end
        
        local f = CreateFrame("Frame", "MessageBoxSettingsFrame", UIParent)
        f:SetWidth(200)
        f:SetHeight(290)
        
        if self.settingsButton and self.settingsButton:IsVisible() then
             f:SetPoint("BOTTOMLEFT", self.settingsButton, "TOPLEFT", 0, 5)
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
        title:SetText("Settings")
        
        -- Checkbox helper
        local function CreateCheck(label, settingKey, yOffset, func)
            local check = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            check:SetPoint("TOPLEFT", 20, yOffset)
            check:SetWidth(24)
            check:SetHeight(24)
            
            local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("LEFT", check, "RIGHT", 5, 0)
            text:SetText(label)
            
            check:SetScript("OnClick", function()
                if this:GetChecked() then
                    MessageBox.settings[settingKey] = true
                else
                    MessageBox.settings[settingKey] = false
                end
                if func then func() end
            end)
            
            check:SetScript("OnShow", function()
                check:SetChecked(MessageBox.settings[settingKey])
            end)
            
            return check
        end
        
        local yStart = -40
        local yStep = -30
        
        f.checks = {}
        
        f.checks["interceptWhispers"] = CreateCheck("Intercept Whispers (/w)", "interceptWhispers", yStart, nil)
        f.checks["backgroundWho"] = CreateCheck("Background WHO Lookup", "backgroundWho", yStart + yStep, nil)
        f.checks["showMinimapButton"] = CreateCheck("Show Minimap Button", "showMinimapButton", yStart + (yStep*2), function() MessageBox:UpdateMinimapButtonVisibility() end)
        f.checks["hideOffline"] = CreateCheck("Hide Offline Friends", "hideOffline", yStart + (yStep*3), function() MessageBox:UpdateContactList() end)
        f.checks["use12HourFormat"] = CreateCheck("Use 12-Hour Format", "use12HourFormat", yStart + (yStep*4), function() MessageBox:UpdateChatHistory() end)
        
        -- Theme toggle
        local themeCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        themeCheck:SetPoint("TOPLEFT", 20, yStart + (yStep*5))
        themeCheck:SetWidth(24)
        themeCheck:SetHeight(24)
        local themeText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        themeText:SetPoint("LEFT", themeCheck, "RIGHT", 5, 0)
        themeText:SetText("Classic Theme")
        
        themeCheck:SetScript("OnClick", function()
            MessageBox.settings.modernTheme = not this:GetChecked()
            MessageBox:ApplyTheme()
            MessageBox:SkinScrollbar(MessageBoxFriendsScroll)
            MessageBox:SkinScrollbar(MessageBoxConversationsScroll)
        end)
        themeCheck:SetScript("OnShow", function()
            themeCheck:SetChecked(not MessageBox.settings.modernTheme)
        end)
        f.checks["theme"] = themeCheck
        
        -- Font Size Slider
        local fontSlider = CreateFrame("Slider", "MessageBoxFontSlider", f, "OptionsSliderTemplate")
        fontSlider:SetWidth(160)
        fontSlider:SetHeight(16)
        fontSlider:SetPoint("TOPLEFT", 20, yStart + (yStep*6) - 10)
        fontSlider:SetMinMaxValues(8, 24)
        fontSlider:SetValueStep(1)
        
        getglobal(fontSlider:GetName().."Low"):SetText("8")
        getglobal(fontSlider:GetName().."High"):SetText("24")
        getglobal(fontSlider:GetName().."Text"):SetText("Chat Font Size: " .. (MessageBox.settings.chatFontSize or 12))
        
        fontSlider:SetScript("OnValueChanged", function()
             local val = math.floor(arg1)
             MessageBox.settings.chatFontSize = val
             getglobal(this:GetName().."Text"):SetText("Chat Font Size: " .. val)
             MessageBox:ApplyChatFontSize()
        end)
        
        fontSlider:SetValue(MessageBox.settings.chatFontSize or 12)
        f.fontSlider = fontSlider

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -5, -5)
        close:SetScript("OnClick", function() this:GetParent():Hide() end)
        f.closeBtn = close
        
        self.settingsFrame = f
        MessageBox:ApplyTheme()
    end
    
    if self.themeBlocker then self.themeBlocker:Show() end
    self.settingsFrame:Show()
    
    -- Force update checks
    if self.settingsFrame.checks then
        self.settingsFrame.checks["interceptWhispers"]:SetChecked(MessageBox.settings.interceptWhispers)
        self.settingsFrame.checks["backgroundWho"]:SetChecked(MessageBox.settings.backgroundWho)
        self.settingsFrame.checks["showMinimapButton"]:SetChecked(MessageBox.settings.showMinimapButton)
        self.settingsFrame.checks["hideOffline"]:SetChecked(MessageBox.settings.hideOffline)
        self.settingsFrame.checks["use12HourFormat"]:SetChecked(MessageBox.settings.use12HourFormat)
        self.settingsFrame.checks["theme"]:SetChecked(not MessageBox.settings.modernTheme)
    end
end

-- Popups and Menus

function MessageBox:ShowCopyPopup(url)
    if not MessageBox.copyPopup then
        local f = CreateFrame("Frame", "MessageBoxCopyFrame", UIParent)
        f:SetWidth(400)
        f:SetHeight(100)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function() this:StartMoving() end)
        f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
        
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        
        local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOP", f, "TOP", 0, -15)
        header:SetText("Press Ctrl+C to copy link:")

        local eb = CreateFrame("EditBox", nil, f)
        eb:SetWidth(330)
        eb:SetHeight(32)
        eb:SetPoint("CENTER", f, "CENTER", 0, 5) 
        eb:SetFontObject(GameFontHighlight)
        eb:SetAutoFocus(false)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        f.editBox = eb
        
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetWidth(90)
        btn:SetHeight(24)
        btn:SetPoint("BOTTOM", f, "BOTTOM", 0, 15)
        btn:SetText("Done")
        btn:SetScript("OnClick", function() f:Hide() end)
        
        MessageBox.copyPopup = f
    end
    
    MessageBox.copyPopup:Show()
    MessageBox.copyPopup.editBox:SetText(url)
    MessageBox.copyPopup.editBox:SetFocus()
    MessageBox.copyPopup.editBox:HighlightText()
end

-- Right click menu
function MessageBox:InitializeMenu(level)
    if not MessageBox.menuContact then return end
    local name = MessageBox.menuContact
    local info = {}

    info = {}
    info.text = name
    info.isTitle = 1
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info, level)

    info = {}
    info.text = "Pop Out Window"
    info.notCheckable = 1
    info.func = function() MessageBox:OpenDetachedWindow(name) end
    UIDropDownMenu_AddButton(info, level)
    
    info = {}
    info.text = "Invite"
    info.notCheckable = 1
    info.func = function() InviteByName(name) end
    UIDropDownMenu_AddButton(info, level)

    info = {}
    info.text = "Target"
    info.notCheckable = 1
    info.func = function() TargetByName(name, true) end
    UIDropDownMenu_AddButton(info, level)

    info = {}
    info.text = "Add Friend"
    info.notCheckable = 1
    info.func = function() AddFriend(name) end
    UIDropDownMenu_AddButton(info, level)

    info = {}
    info.text = "Ignore"
    info.notCheckable = 1
    info.func = function() AddIgnore(name) end
    UIDropDownMenu_AddButton(info, level)

    info = {}
    info.disabled = 1
    UIDropDownMenu_AddButton(info, level)

    info = {}
    if MessageBox.conversations[name] and MessageBox.conversations[name].pinned then
        info.text = "Unpin Conversation"
    else
        info.text = "Pin Conversation"
    end
    info.notCheckable = 1
    info.func = function() 
        if MessageBox.conversations[name] then
            MessageBox.conversations[name].pinned = not MessageBox.conversations[name].pinned
            if MessageBox.selectedContact == name then
                MessageBox:UpdateChatHeader()
            end
            MessageBox:UpdateContactList()
        end
    end
    UIDropDownMenu_AddButton(info, level)

    info = {}
    info.text = "|cffff0000Delete Conversation|r"
    info.notCheckable = 1
    info.func = function() 
        MessageBox.selectedContact = name
        MessageBox:ShowDeleteConfirmation()
    end
    UIDropDownMenu_AddButton(info, level)
    
    info = {}
    info.text = "Cancel"
    info.notCheckable = 1
    info.func = function() end
    UIDropDownMenu_AddButton(info, level)
end

function MessageBox:OpenContextMenu(name)
    MessageBox.menuContact = name
    UIDropDownMenu_Initialize(MessageBoxContextMenu, MessageBox.InitializeMenu, "MENU")
    ToggleDropDownMenu(1, nil, MessageBoxContextMenu, "cursor", 0, 0)
end

function MessageBox:InitializeSettingsMenu(level)
    local info = {}
    
    info.text = "Settings"
    info.isTitle = 1
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info, level)
    
    info = {}
    info.text = "Intercept Whisper Commands"
    info.checked = MessageBox.settings.interceptWhispers
    info.func = function()
        MessageBox.settings.interceptWhispers = not MessageBox.settings.interceptWhispers
    end
    UIDropDownMenu_AddButton(info, level)

    info = {}
    info.text = "Minimap Button"
    info.checked = MessageBox.settings.showMinimapButton
    info.func = function()
        MessageBox.settings.showMinimapButton = not MessageBox.settings.showMinimapButton
        MessageBox:UpdateMinimapButtonVisibility()
    end
    UIDropDownMenu_AddButton(info, level)

    info = {}
    info.text = "Hide Offline"
    info.checked = MessageBox.settings.hideOffline
    info.func = function()
        MessageBox.settings.hideOffline = not MessageBox.settings.hideOffline
        MessageBox:UpdateContactList()
    end
    UIDropDownMenu_AddButton(info, level)

    info = {}
    info.text = "12hr Mode"
    info.checked = MessageBox.settings.use12HourFormat
    info.func = function()
        MessageBox.settings.use12HourFormat = not MessageBox.settings.use12HourFormat
        MessageBox:UpdateChatHistory()
    end
    UIDropDownMenu_AddButton(info, level)

    info = {}
    info.text = "Classic Theme"
    info.checked = not MessageBox.settings.modernTheme
    info.func = function()
        MessageBox.settings.modernTheme = not MessageBox.settings.modernTheme
        MessageBox:ApplyTheme()
        MessageBox:SkinScrollbar(MessageBoxFriendsScroll)
        MessageBox:SkinScrollbar(MessageBoxConversationsScroll)
    end
    UIDropDownMenu_AddButton(info, level)
end

function MessageBox:OpenSettingsMenu()
    UIDropDownMenu_Initialize(MessageBoxSettingsDropDown, MessageBox.InitializeSettingsMenu, "MENU")
    ToggleDropDownMenu(1, nil, MessageBoxSettingsDropDown, "cursor", 0, 0)
end

function MessageBox:ToggleNotificationMenu()
    if self.notificationList and self.notificationList:IsVisible() then
        self.notificationList:Hide()
        return
    end
    
    if not self.notificationList then
        local f = CreateFrame("Frame", "MessageBoxNotificationList", UIParent)
        f:SetWidth(150)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetToplevel(true)
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        f:SetBackdropColor(0,0,0,0.9)
        self.notificationList = f
    end
    
    local f = self.notificationList
    
    if not f.rows then f.rows = {} end
    for _, row in ipairs(f.rows) do row:Hide() end
    
    local index = 0
    for name, count in pairs(self.unreadCounts) do
        if count > 0 then
            index = index + 1
            local row = f.rows[index]
            if not row then
                row = CreateFrame("Button", nil, f)
                row:SetHeight(20)
                row:SetWidth(140)
                row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                
                local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                text:SetPoint("LEFT", row, "LEFT", 5, 0)
                text:SetJustifyH("LEFT")
                row.text = text
                
                local countText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                countText:SetPoint("RIGHT", row, "RIGHT", -5, 0)
                row.countText = countText
                
                row:SetScript("OnClick", function()
                    MessageBox:SelectContact(this.contactName)
                    MessageBox:ShowFrame()
                    MessageBox.notificationList:Hide()
                end)
                
                f.rows[index] = row
            end
            
            row.contactName = name
            
            local display = name
            if MessageBox.playerCache[name] and MessageBox.playerCache[name].class then
                 local c = RAID_CLASS_COLORS[string.upper(MessageBox.playerCache[name].class)]
                 if c then display = string.format("|cff%02x%02x%02x%s|r", c.r*255, c.g*255, c.b*255, name) end
            end
            
            row.text:SetText(display)
            row.countText:SetText(count)
            
            row:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -5 - ((index-1)*20))
            row:Show()
        end
    end
    
    f:SetHeight((index * 20) + 10)
    
    f:ClearAllPoints()
    local x, y = self.notificationPopup:GetCenter()
    if x and x > UIParent:GetWidth() / 2 then
        f:SetPoint("TOPRIGHT", self.notificationPopup, "TOPLEFT", -5, 0)
    else
        f:SetPoint("TOPLEFT", self.notificationPopup, "TOPRIGHT", 5, 0)
    end
    
    f:Show()
end

function MessageBox:UpdateNotificationVisuals()
    if not self.notificationPopup then return end
    
    local popup = self.notificationPopup
    
    if self.settings.modernTheme then
        popup:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\envelope-solid.tga")
        popup:SetPushedTexture("Interface\\AddOns\\MessageBox\\img\\envelope-solid.tga")
        popup:SetWidth(40)
        popup:SetHeight(40)
        
        popup.badge:SetTexture("Interface\\AddOns\\MessageBox\\img\\square-solid.tga")
        popup.badge:SetVertexColor(0.9, 0.1, 0.1) 
        popup.badge:SetWidth(14) 
        popup.badge:SetHeight(14) 
        popup.badge:ClearAllPoints()
        popup.badge:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -4, -6) 
        
        popup.countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        popup.countText:SetTextColor(1, 1, 1)
        popup.countText:SetPoint("CENTER", popup.badge, "CENTER", 0, 0)
    else
        popup:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Up")
        popup:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Down")
        popup:SetWidth(32)
        popup:SetHeight(32)
        
        popup.badge:SetTexture("Interface\\WorldMap\\WorldMapPartyIcon")
        popup.badge:SetVertexColor(1, 0, 0)
        popup.badge:SetWidth(16)
        popup.badge:SetHeight(16)
        popup.badge:ClearAllPoints()
        popup.badge:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -2, -2)
        
        popup.countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        popup.countText:SetPoint("CENTER", popup.badge, "CENTER", 0, 0)
    end
end

function MessageBox:CreateNotificationPopup()
    if self.notificationPopup then return end

    local popup = CreateFrame("Button", "MessageBoxNotificationPopup", UIParent)
    popup:SetWidth(32)
    popup:SetHeight(32)
    popup:SetFrameStrata("HIGH")
    popup:SetToplevel(true)
    
    local pos = self.settings.notificationPopupPosition
    if pos then
        popup:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end
    
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    
    popup:SetScript("OnMouseDown", function()
        if IsShiftKeyDown() then
            this.isMoving = true
            this:StartMoving()
        end
    end)
    
    popup:SetScript("OnDragStart", function() 
        if IsShiftKeyDown() then this:StartMoving() end
    end)
    
    popup:SetScript("OnDragStop", function()
        this.isMoving = false
        this:StopMovingOrSizing()
        local point, _, relativePoint, x, y = this:GetPoint()
        MessageBox.settings.notificationPopupPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)

    popup:SetScript("OnMouseUp", function()
        if this.isMoving then
            this.isMoving = false
            this:StopMovingOrSizing()
            local point, _, relativePoint, x, y = this:GetPoint()
            MessageBox.settings.notificationPopupPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
        elseif arg1 == "LeftButton" then
            local unreadList = {}
            for name, count in pairs(MessageBox.unreadCounts) do
                if count > 0 then table.insert(unreadList, name) end
            end
            
            if table.getn(unreadList) == 1 then
                MessageBox:SelectContact(unreadList[1])
                MessageBox:ShowFrame()
            elseif table.getn(unreadList) > 1 then
                MessageBox:ToggleNotificationMenu()
            else
                MessageBox:ShowFrame()
            end
        end
    end)
    
    local highlight = popup:CreateTexture(nil, "OVERLAY") 
    highlight:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-BlinkHilight")
    highlight:SetAllPoints(popup)
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0)
    popup.highlight = highlight
    
    local badge = popup:CreateTexture(nil, "OVERLAY")
    badge:SetTexture("Interface\\WorldMap\\WorldMapPartyIcon") 
    badge:SetVertexColor(1, 0, 0)
    badge:SetWidth(16)
    badge:SetHeight(16)
    badge:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -2, -2)
    badge:Hide()
    popup.badge = badge

    local countText = popup:CreateFontString(nil, "OVERLAY")
    countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    countText:SetPoint("CENTER", badge, "CENTER", 0, 0)
    countText:SetTextColor(1, 1, 1)
    countText:Hide()
    popup.countText = countText
    
    popup:SetScript("OnEnter", function()
        this.isFlashing = false
        this.highlight:SetAlpha(0)

        if MessageBox.settings.modernTheme then
            this:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\envelope-solid-open.tga")
        end

        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Unread Messages")
        
        local hasLines = false
        for name, count in pairs(MessageBox.unreadCounts) do
            if count > 0 then
                hasLines = true
                local color = {1, 1, 1}
                if MessageBox.playerCache[name] and MessageBox.playerCache[name].class then
                    local c = RAID_CLASS_COLORS[string.upper(MessageBox.playerCache[name].class)]
                    if c then color = {c.r, c.g, c.b} end
                end
                GameTooltip:AddDoubleLine(name, count, color[1], color[2], color[3], 1, 1, 1)
            end
        end
        
        if hasLines then GameTooltip:AddLine(" ") end
        
        if MessageBox.settings.modernTheme then
             GameTooltip:AddLine("Click to read", 0.7, 0.7, 0.7)
        else
             GameTooltip:AddLine("Click to open", 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine("Shift-Drag to move", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    
    popup:SetScript("OnLeave", function()
        if MessageBox.settings.modernTheme then
            this:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\envelope-solid.tga")
        end
        GameTooltip:Hide()
    end)
    
    popup.flashTime = 0
    popup.isFlashing = false
    
    popup:SetScript("OnUpdate", function()
        if not this.isFlashing then return end
        
        if MessageBox.settings.modernTheme then
            this.highlight:SetAlpha(0)
            return
        end
        
        this.flashTime = this.flashTime + arg1
        local alpha = 0.5 + 0.5 * math.sin(this.flashTime * 4)
        this.highlight:SetAlpha(alpha)
    end)
    
    popup:Hide()
    self.notificationPopup = popup
    
    self:UpdateNotificationVisuals()
end

function MessageBox:ShowNotificationPopup()
    if not self.notificationPopup then
        self:CreateNotificationPopup()
    end
    
    self:UpdateNotificationVisuals()
    
    self.notificationPopup.isFlashing = true
    self.notificationPopup.flashTime = 0
    self.notificationPopup:Show()
    self:UpdateMinimapBadge()
end

function MessageBox:HideNotificationPopup()
    if self.notificationPopup then
        self.notificationPopup.isFlashing = false
        self.notificationPopup.highlight:SetAlpha(0)
        self.notificationPopup:Hide()
        
        if self.notificationList then self.notificationList:Hide() end
    end
end

-- Dialogs

StaticPopupDialogs["MB_DELETE_CONVO"] = {
    text = "Are you sure you want to delete this conversation with %s?",
    button1 = ACCEPT, button2 = CANCEL, OnAccept = function() MessageBox:ConfirmDelete() end,
    showAlert = 1, timeout = 0, hideOnEscape = 1
}

StaticPopupDialogs["MB_DELETE_ALL"] = {
    text = "Are you sure you want to delete ALL conversations for this character?\n\n|cffff0000Pinned conversations will be saved.|r",
    button1 = ACCEPT, button2 = CANCEL, OnAccept = function() MessageBox:ConfirmDeleteAll() end,
    showAlert = 1, timeout = 0, hideOnEscape = 1
}

function MessageBox:ShowDeleteConfirmation()
    if not MessageBox.selectedContact then 
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: No conversation selected.")
        return 
    end

    local c = MessageBox.conversations[MessageBox.selectedContact]
    if c and c.pinned then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Cannot delete pinned conversation with " .. MessageBox.selectedContact .. ". Unpin it first.")
        return
    end

    StaticPopup_Show("MB_DELETE_CONVO", MessageBox.selectedContact)
end

function MessageBox:ShowDeleteAllConfirmation()
    StaticPopup_Show("MB_DELETE_ALL")
end

function MessageBox:ConfirmDelete()
    if not self.selectedContact then return end
    local deletedContact = self.selectedContact
    self.conversations[self.selectedContact] = nil
    if self.unreadCounts then self.unreadCounts[self.selectedContact] = nil end
    self.selectedContact = nil
    self:UpdateChatHeader()
    self:UpdateContactList()
    self:UpdateChatHistory()
    DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Conversation with " .. deletedContact .. " deleted.")
end

function MessageBox:ConfirmDeleteAll()
    local deletedCount = 0
    local toDelete = {}
    
    for contact, data in pairs(MessageBox.conversations) do
        if not data.pinned then
            table.insert(toDelete, contact)
        end
    end
    
    for _, contact in ipairs(toDelete) do
        MessageBox.conversations[contact] = nil
        if MessageBox.unreadCounts then MessageBox.unreadCounts[contact] = nil end
        deletedCount = deletedCount + 1
    end
    
    if self.selectedContact and not self.conversations[self.selectedContact] then
        self.selectedContact = nil
        self:UpdateChatHeader()
        self:UpdateChatHistory()
    end
    
    self:UpdateContactList()
    
    if deletedCount > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Deleted " .. deletedCount .. " unpinned conversations.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: No unpinned conversations to delete.")
    end
end

-- Detached Windows
function MessageBox:OpenDetachedWindow(contact)
    if not contact then return end
    
    if self.detachedWindows[contact] then
        self.detachedWindows[contact]:Show()
        return
    end

    if not self.conversations[contact] then
        self.conversations[contact] = {
            messages = {},
            times = {},
            outgoing = {},
            system = {},
            pinned = false
        }
    end

    local f = CreateFrame("Frame", "MessageBoxDetached_"..contact, UIParent)
    f:SetWidth(300)
    f:SetHeight(250)
    
    local cascadeIndex = 0
    if self.detachedWindows then
        for _, win in pairs(self.detachedWindows) do
            if win and win:IsVisible() then
                cascadeIndex = cascadeIndex + 1
            end
        end
    end
    
    local xOffset = 20 + (cascadeIndex * 20)
    local yOffset = -50 - (cascadeIndex * 20)

    f:SetFrameStrata("MEDIUM")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetMinResize(200, 150)
    f:SetMaxResize(600, 600)
    
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    if MessageBox.frame and MessageBox.frame:IsVisible() then
        f:SetPoint("BOTTOMLEFT", MessageBox.frame, "TOPRIGHT", xOffset, yOffset)
    else
        local centerOffset = cascadeIndex * 20
        f:SetPoint("CENTER", UIParent, "CENTER", centerOffset, -centerOffset)
    end
    
    f:SetScript("OnMouseDown", function()
        this:StartMoving()
        this:SetFrameStrata("HIGH")
    end)
    f:SetScript("OnMouseUp", function()
        this:StopMovingOrSizing()
    end)
    
    f.contact = contact
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    
    local displayTitle = contact
    local cache = self.playerCache[contact]
    if cache and cache.class then
        local color = RAID_CLASS_COLORS[string.upper(cache.class)]
        if color then
            displayTitle = string.format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, contact)
        end
    end
    title:SetText(displayTitle)
    f.title = title

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() 
        this:GetParent():Hide() 
    end)
    f.closeBtn = closeBtn

    local resizeButton = CreateFrame("Button", nil, f)
    resizeButton:SetWidth(16)
    resizeButton:SetHeight(16)
    resizeButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resizeButton:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\sizegrabber-up.tga")
    resizeButton:SetPushedTexture("Interface\\AddOns\\MessageBox\\img\\sizegrabber-down.tga")
    resizeButton:SetHighlightTexture("Interface\\AddOns\\MessageBox\\img\\sizegrabber-highlight.tga")
    resizeButton:SetScript("OnMouseDown", function() this:GetParent():StartSizing("BOTTOMRIGHT") end)
    resizeButton:SetScript("OnMouseUp", function() this:GetParent():StopMovingOrSizing() end)

    local inputBackdrop = CreateFrame("Frame", nil, f)
    inputBackdrop:SetHeight(28)
    inputBackdrop:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
    inputBackdrop:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -25, 10)
    
    f.inputBackdrop = inputBackdrop

    local editBox = CreateFrame("EditBox", nil, inputBackdrop)
    editBox:SetPoint("TOPLEFT", inputBackdrop, "TOPLEFT", 6, -6)
    editBox:SetPoint("BOTTOMRIGHT", inputBackdrop, "BOTTOMRIGHT", -6, 6)
    editBox:SetFontObject("GameFontHighlight")
    editBox:SetAutoFocus(false)
    editBox:SetMultiLine(false)
    editBox:EnableMouse(true)
    
    editBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    editBox:SetScript("OnEnterPressed", function()
        local msg = this:GetText()
        if msg and msg ~= "" then
            MessageBox:AddMessage(contact, msg, true)
            SendChatMessage(msg, "WHISPER", nil, contact)
            this:SetText("")
            this:ClearFocus()
        end
    end)
    f.editBox = editBox

    local history = CreateFrame("ScrollingMessageFrame", nil, f)
    history:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -30)
    history:SetPoint("BOTTOMRIGHT", inputBackdrop, "TOPRIGHT", -22, 5)
    
    history:SetFont("Fonts\\FRIZQT__.TTF", MessageBox.settings.chatFontSize or 12, "OUTLINE")
    history:SetShadowOffset(1, -1)
    
    history:SetJustifyH("LEFT")
    history:SetMaxLines(500)
    history:SetFading(false)
    history:EnableMouseWheel(true)
    
    f.history = history

    local sb = CreateFrame("Slider", "MessageBoxDetachedScroll_"..contact, f, "UIPanelScrollBarTemplate")
    sb:SetPoint("TOPLEFT", history, "TOPRIGHT", 2, -14)
    sb:SetPoint("BOTTOMLEFT", history, "BOTTOMRIGHT", 2, 14)
    sb:SetWidth(16)
    sb:SetMinMaxValues(1, 1)
    sb:SetValueStep(1)
    
    local track = sb:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(0.15, 0.15, 0.15, 0.5)
    track:SetPoint("TOP", sb, "TOP", 0, 12)
    track:SetPoint("BOTTOM", sb, "BOTTOM", 0, -12)
    track:SetWidth(3) 
    
    sb.track = track

    -- Virtual scrolling logic
    f.UpdateDisplay = function(self)
        if not self.history or not self.scrollBar then return end
        
        local c = MessageBox.conversations[self.contact]
        if not c or not c.messages then return end
        
        local totalMessages = table.getn(c.messages)
        
        if totalMessages == 0 then
            self.history:Clear()
            return
        end
        
        local displayLimit = 100
        
        local anchorIndex = self.scrollBar:GetValue()
        if anchorIndex > totalMessages then anchorIndex = totalMessages end
        if anchorIndex < 1 then anchorIndex = 1 end
        
        local startIndex = anchorIndex - displayLimit
        if startIndex < 1 then startIndex = 1 end
        
        self.history:Clear()
        
        local timeFmt = MessageBox.settings.use12HourFormat and "%I:%M %p" or "%H:%M"
        
        for i = startIndex, anchorIndex do
            local msg = c.messages[i]
            local timeVal = c.times[i]
            local isOutgoing = c.outgoing[i]
            local isSystem = c.system[i]
            
            local timeString = type(timeVal) == "number" and date(timeFmt, timeVal) or tostring(timeVal)
            timeString = "|cff808080[" .. timeString .. "]|r"
            
            if isSystem then
                self.history:AddMessage(string.format("%s %s%s|r", timeString, "|cffffcc00", msg))
            else
                local cleanMessage = MessageBox:HandleLink(msg)
                local nameColor = isOutgoing and "|cff8080ff" or "|cffff80ff"
                local name = isOutgoing and "You" or self.contact
                self.history:AddMessage(string.format("%s %s%s:|r %s%s|r", timeString, nameColor, name, "|cffffffff", cleanMessage))
            end
        end
        
        self.history:ScrollToBottom()
    end

    sb:SetScript("OnValueChanged", function()
        if not this.isUpdating then
            f:UpdateDisplay()
        end
    end)
    
    history:SetScript("OnMouseWheel", function()
        local current = sb:GetValue()
        if arg1 > 0 then
            sb:SetValue(current - 1)
        else
            sb:SetValue(current + 1)
        end
    end)

    f.scrollBar = sb

    history:SetScript("OnHyperlinkClick", function()
        if arg1 and string.sub(arg1, 1, 3) == "url" then
            MessageBox:ShowCopyPopup(string.sub(arg1, 5))
            return
        end
        ChatFrame_OnHyperlinkShow(arg1, arg2, arg3)
    end)

    self.detachedWindows[contact] = f
    
    -- Init contents
    local c = self.conversations[contact]
    if c and c.messages then
        local total = table.getn(c.messages)
        if total == 0 then total = 1 end
        sb.isUpdating = true
        sb:SetMinMaxValues(1, total)
        sb:SetValue(total)
        sb.isUpdating = false
        f:UpdateDisplay()
    end

    self:ApplyTheme()
end
