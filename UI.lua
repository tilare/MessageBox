-- UI.lua
-- UI Construction, Contact rows

function MessageBox:CreateContactRow(parent)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetWidth(105)
    frame:SetHeight(16)
    frame:EnableMouse(true)
    
    local statusIcon = frame:CreateFontString(nil, "ARTWORK")
    statusIcon:SetFont(MessageBox.fonts.openSans, 16)
    statusIcon:SetPoint("LEFT", frame, "LEFT", -5, -2)
    frame.statusIcon = statusIcon
    
    local pinIcon = frame:CreateTexture(nil, "OVERLAY")
    pinIcon:SetWidth(10)
    pinIcon:SetHeight(10)
    pinIcon:SetPoint("RIGHT", frame, "RIGHT", -2, 0)

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", statusIcon, "RIGHT", 3, 1)
    text:SetJustifyH("LEFT")
    frame.text = text
    pinIcon:SetTexture(MessageBox.textures.pin)
    pinIcon:Hide()
    frame.pinIcon = pinIcon
    
    frame:SetScript("OnMouseDown", function() 
        if arg1 == "RightButton" then
            MessageBox:OpenContextMenu(this.contactName)
        else
            MessageBox:SelectContact(this.contactName)
        end
    end)
    
    frame:SetScript("OnEnter", function() 
        this.isHovered = true
        this.text:SetTextColor(0.82, 0.82, 0.82, 1) 
    end)
    frame:SetScript("OnLeave", function() 
        this.isHovered = false
        local c = MessageBox.settings.textColor or MessageBox.defaultSettings.textColor
        this.text:SetTextColor(unpack(c)) 
    end)
    frame:Hide()
    
    return frame
end

function MessageBox:EnsureRows(scrollChild, rowTable, count)
    local current = table.getn(rowTable)
    if current < count then
        for i = current + 1, count do
            local row = self:CreateContactRow(MessageBox.clipChild or MessageBox.contactFrame)
            table.insert(rowTable, row)
        end
    end
end

function MessageBox:CreateHeaderFrame(parent, onClickCallback, plusName, minusName)
    local header = CreateFrame("Button", nil, parent)
    header:SetWidth(120)
    header:SetHeight(20)
    header:SetScript("OnClick", onClickCallback)

    local plusButton = CreateFrame("Button", plusName, header)
    plusButton:SetWidth(16)
    plusButton:SetHeight(16)
    plusButton:SetPoint("LEFT", 0, 0)
    plusButton:SetScript("OnClick", onClickCallback)
    
    plusButton.text = plusButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    plusButton.text:SetPoint("CENTER", 0, 1)
    plusButton.text:SetText("+")
    plusButton.text:Hide()

    local minusButton = CreateFrame("Button", minusName, header)
    minusButton:SetWidth(16)
    minusButton:SetHeight(16)
    minusButton:SetPoint("LEFT", 0, 0)
    minusButton:SetScript("OnClick", onClickCallback)
    
    minusButton.text = minusButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minusButton.text:SetPoint("CENTER", 0, 1)
    minusButton.text:SetText("-")
    minusButton.text:Hide()
    
    local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerText:SetPoint("LEFT", plusButton, "RIGHT", 2, 0)
    headerText:SetTextColor(1, 1, 0)
    
    header.text = headerText

    header:SetScript("OnEnter", function()
        if this.text then
            this.text:SetTextColor(0.82, 0.82, 0.82, 1)
        end
    end)
    
    header:SetScript("OnLeave", function()
        if this.text then
            local c = MessageBox.settings.textColor or MessageBox.defaultSettings.textColor
            this.text:SetTextColor(unpack(c))
        end
    end)
    
    return {
        frame = header,
        plusButton = plusButton,
        minusButton = minusButton,
        text = headerText
    }
end

function MessageBox:CreateChatHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(50)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    
    header:SetBackdrop({
        bgFile = MessageBox.textures.tooltipBg,
        tile = true, tileSize = 16,
        insets = {left = 0, right = 0, top = 0, bottom = -1}
    })
    header:SetBackdropColor(0, 0, 0, 0.3)

    local avatarBtn = CreateFrame("Button", nil, header)
    avatarBtn:SetWidth(36)
    avatarBtn:SetHeight(36)
    avatarBtn:SetPoint("LEFT", header, "LEFT", 8, 0)
    
    avatarBtn:SetBackdrop({
        bgFile = MessageBox.textures.white8x8, 
        edgeFile = MessageBox.textures.tooltipBorder,
        tile = false, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    avatarBtn:SetBackdropColor(0,0,0,1) 
    avatarBtn:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    local icon = avatarBtn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", avatarBtn, "TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", avatarBtn, "BOTTOMRIGHT", -3, 3)
    avatarBtn.icon = icon
    
    avatarBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Left-Click: Target\nRight-Click: Menu")
        GameTooltip:Show()
    end)
    avatarBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    avatarBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    avatarBtn:SetScript("OnClick", function()
         if arg1 == "LeftButton" and MessageBox.selectedContact then
             TargetByName(MessageBox.selectedContact, true)
         elseif arg1 == "RightButton" and MessageBox.selectedContact then
             MessageBox:OpenContextMenu(MessageBox.selectedContact)
         end
    end)
    header.avatarBtn = avatarBtn

    local nameText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameText:SetPoint("TOPLEFT", avatarBtn, "TOPRIGHT", 10, -4)
    nameText:SetJustifyH("LEFT")
    header.nameText = nameText

    local guildText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    guildText:SetPoint("LEFT", nameText, "RIGHT", 6, 0)
    guildText:SetJustifyH("LEFT")
    guildText:SetTextColor(0.5, 0.5, 0.5)
    header.guildText = guildText

    local infoText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    infoText:SetPoint("RIGHT", header, "RIGHT", -35, 0)
    infoText:SetJustifyH("LEFT")
    infoText:SetTextColor(0.8, 0.8, 0.8)
    header.infoText = infoText

    local metaTopText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    metaTopText:SetPoint("TOPRIGHT", header, "TOPRIGHT", -10, -8)
    metaTopText:SetJustifyH("RIGHT")
    metaTopText:SetTextColor(0.7, 0.7, 0.7)
    header.metaTopText = metaTopText

    -- Search button
    local searchBtn = CreateFrame("Button", nil, header)
    searchBtn:SetWidth(16)
    searchBtn:SetHeight(16)
    searchBtn:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -8, 2)
    searchBtn:SetNormalTexture(MessageBox.textures.search)
    searchBtn:SetHighlightTexture(MessageBox.textures.minimizeBtnHi)
    searchBtn:SetAlpha(0.7)
    
    searchBtn:SetScript("OnEnter", function()
        this:SetAlpha(1.0)
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Search Chat Log")
        GameTooltip:Show()
    end)
    searchBtn:SetScript("OnLeave", function()
        this:SetAlpha(0.7)
        GameTooltip:Hide()
    end)
    searchBtn:SetScript("OnClick", function()
        if MessageBox.searchBarFrame and MessageBox.searchBarFrame:IsVisible() then
            MessageBox:CloseSearchBar()
        else
            MessageBox:OpenSearchBar()
        end
    end)
    header.searchBtn = searchBtn

    -- Pin button
    local pinBtn = CreateFrame("Button", nil, header)
    pinBtn:SetWidth(16)
    pinBtn:SetHeight(16)
    pinBtn:SetPoint("RIGHT", searchBtn, "LEFT", -5, 0)
    pinBtn:SetHighlightTexture(MessageBox.textures.minimizeBtnHi)
    
    pinBtn:SetScript("OnClick", function()
        if MessageBox.selectedContact then
            local c = MessageBox.conversations[MessageBox.selectedContact]
            if c then
                c.pinned = not c.pinned
                MessageBox.conversationOrderDirty = true
                MessageBox:UpdateChatHeader()
                MessageBox:UpdateContactList()

                if GameTooltip:IsOwned(this) then
                    this:GetScript("OnEnter")()
                end
            end
        end
    end)
    
    pinBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        if MessageBox.selectedContact and MessageBox.conversations[MessageBox.selectedContact] and MessageBox.conversations[MessageBox.selectedContact].pinned then
             GameTooltip:SetText("Unpin Conversation")
             GameTooltip:AddLine("Allow this conversation to be deleted.", 0.8, 0.8, 0.8, 1)
        else
             GameTooltip:SetText("Pin Conversation")
             GameTooltip:AddLine("Prevents this conversation from being deleted.", 0.8, 0.8, 0.8, 1)
        end
        GameTooltip:Show()
    end)
    pinBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    header.pinBtn = pinBtn

    MessageBox.chatHeader = header
    return header
end

local CLASS_ICON_TCOORDS = {
    ["WARRIOR"] = {0, 0.25, 0, 0.25},
    ["MAGE"]    = {0.25, 0.49609375, 0, 0.25},
    ["ROGUE"]   = {0.49609375, 0.7421875, 0, 0.25},
    ["DRUID"]   = {0.7421875, 0.98828125, 0, 0.25},
    ["HUNTER"]  = {0, 0.25, 0.25, 0.5},
    ["SHAMAN"]  = {0.25, 0.49609375, 0.25, 0.5},
    ["PRIEST"]  = {0.49609375, 0.7421875, 0.25, 0.5},
    ["WARLOCK"] = {0.7421875, 0.98828125, 0.25, 0.5},
    ["PALADIN"] = {0, 0.25, 0.5, 0.75}
}

function MessageBox:UpdateChatHeader()
    if not self.chatHeader then return end
    
    if not self.selectedContact then
        self.chatHeader.nameText:SetText("Whisper Conversation")
        self.chatHeader.infoText:SetText("Select a contact")
        self.chatHeader.avatarBtn:Hide()
        self.chatHeader.pinBtn:Hide()
        self.chatHeader.searchBtn:Hide()
        self.chatHeader.guildText:Hide()
        self.chatHeader.metaTopText:Hide()
        return
    end

    self.chatHeader.avatarBtn:Show()
    self.chatHeader.pinBtn:Show()
    self.chatHeader.searchBtn:Show()
    self.chatHeader.guildText:Show()
    self.chatHeader.metaTopText:Show()


    local name = self.selectedContact
    local displayTitle = name
    
    local c = self.conversations[name]
    if c and c.pinned then
        self.chatHeader.pinBtn:SetNormalTexture(MessageBox.textures.pinSlash)
    else
        self.chatHeader.pinBtn:SetNormalTexture(MessageBox.textures.pin)
    end
    
    local cache = self.playerCache[name]
    
    if not cache then
         for i = 1, GetNumFriends() do
             local fName, fLevel, fClass, fArea, fConnected, fStatus = GetFriendInfo(i)
             if fName and string.lower(fName) == string.lower(name) then
                 cache = {
                     level = fLevel,
                     class = fClass,
                     classUpper = fClass and string.upper(fClass) or nil,
                     zone = fArea,
                     status = fStatus,
                     guild = nil
                 }
                 self.playerCache[name] = cache
                 break
             end
         end
    end

    if cache and cache.isGM then
        -- GM: special display — skip level/guild, show GM badge
        displayTitle = "|cff00ccffGM " .. name .. "|r"
        self.chatHeader.nameText:SetText(displayTitle)
        
        self.chatHeader.guildText:SetText("|cff00ccff<Game Master>|r")
        self.chatHeader.guildText:Show()
        
        self.chatHeader.avatarBtn.icon:SetTexture(MessageBox.textures.gmBadge)
        self.chatHeader.avatarBtn.icon:SetTexCoord(0, 1, 0, 1)
        
        self.chatHeader.infoText:SetText("")
    else
        if cache and cache.class then
            local color = RAID_CLASS_COLORS[cache.classUpper]
            if color then
                displayTitle = string.format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, name)
            end
        end
        
        self.chatHeader.nameText:SetText(displayTitle)

        -- AFK/DND status display
        if cache and cache.status and cache.status ~= "" then
            self.chatHeader.guildText:SetText("|cffaaaaaa" .. cache.status .. "|r")
            self.chatHeader.guildText:Show()
        else
            self.chatHeader.guildText:SetText("")
            self.chatHeader.guildText:Hide()
        end

        local infoString = ""
        local coords = {0, 0.25, 0, 0.25} 

        if cache then
            if cache.guild and cache.guild ~= "" then
                infoString = "<" .. cache.guild .. "> • "
            end
            
            if cache.level and cache.level > 0 then
                infoString = infoString .. "Level " .. cache.level
            else
                infoString = infoString .. "Unknown Level"
            end
            
            if cache.zone and cache.zone ~= "" and cache.zone ~= "Unknown" then
                 infoString = infoString .. " • " .. cache.zone
            end

            if cache.class and CLASS_ICON_TCOORDS[cache.classUpper] then
                coords = CLASS_ICON_TCOORDS[cache.classUpper]
                self.chatHeader.avatarBtn.icon:SetTexture(MessageBox.textures.classIcons)
                self.chatHeader.avatarBtn.icon:SetTexCoord(unpack(coords))
            else
                 self.chatHeader.avatarBtn.icon:SetTexture(MessageBox.textures.iconQuestion)
                 self.chatHeader.avatarBtn.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
            end
        else
            infoString = "Offline or Unknown"
            self.chatHeader.avatarBtn.icon:SetTexture(MessageBox.textures.iconQuestion)
            self.chatHeader.avatarBtn.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        end
        
        self.chatHeader.infoText:SetText(infoString)
    end

    local msgCount = 0
    
    if c and c.messages then
        msgCount = MessageBox:GetCount(c)
    end
    
    self.chatHeader.metaTopText:SetText("Total Messages: " .. msgCount)
end

function MessageBox:CreateFrame()
    if MessageBox.frame then
        return
    end

    local frame = CreateFrame("Frame", "MessageBoxFrame", UIParent)
    local L = MessageBox.layout
    frame:SetWidth(L.MAIN_WIDTH)
    frame:SetHeight(L.MAIN_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetResizable(true)
    frame:SetMinResize(L.MIN_WIDTH, L.MIN_HEIGHT)
    frame:SetMaxResize(L.MAX_WIDTH, L.MAX_HEIGHT)
    frame:SetScript("OnMouseDown", function()
        frame:StartMoving()
        frame:SetFrameStrata("HIGH")
    end)
    frame:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
    frame:SetScript("OnSizeChanged", function()
        MessageBox.relayoutDirty = true
    end)
    frame:Hide()

    MessageBox.frame = frame

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText("MessageBox")

    local closeButton = CreateFrame("Button", nil, frame)
    closeButton:SetWidth(18)
    closeButton:SetHeight(18)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -5)
    closeButton:SetNormalTexture(MessageBox.textures.closeOutline)
    closeButton:SetPushedTexture(MessageBox.textures.closeSolid)
    closeButton:SetHighlightTexture(MessageBox.textures.closeSolid)
    closeButton:SetAlpha(0.7)
    closeButton:SetScript("OnEnter", function() this:SetAlpha(1.0) end)
    closeButton:SetScript("OnLeave", function() this:SetAlpha(0.7) end)
    closeButton:SetScript("OnClick", function() MessageBox:HideFrame() end)
    MessageBox.closeButton = closeButton

    local dropDown = CreateFrame("Frame", "MessageBoxContextMenu", frame, "UIDropDownMenuTemplate")

    local contactFrame = CreateFrame("Frame", nil, frame)
    contactFrame:SetWidth(L.CONTACT_WIDTH)
    contactFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -26)
    contactFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 40)
    
    MessageBox.contactFrame = contactFrame
    MessageBox.contactListLastUpdate = 0

    -- Throttled contact list rebuild via dirty flag
    contactFrame:SetScript("OnUpdate", function()
        if not MessageBox.contactListDirty then return end
        local now = GetTime()
        if (now - MessageBox.contactListLastUpdate) < MessageBox.CONTACT_LIST_THROTTLE then return end
        MessageBox.contactListDirty = false
        MessageBox.contactListLastUpdate = now
        MessageBox:UpdateContactList()
    end)

    local clipFrame = CreateFrame("ScrollFrame", nil, contactFrame)
    clipFrame:SetPoint("TOPLEFT", contactFrame, "TOPLEFT", 0, -32) 
    clipFrame:SetPoint("BOTTOMRIGHT", contactFrame, "BOTTOMRIGHT", 0, 10) 
    local clipChild = CreateFrame("Frame", nil, clipFrame)
    clipChild:SetWidth(L.CONTACT_WIDTH)
    clipChild:SetHeight(2000)
    clipFrame:SetScrollChild(clipChild)
    MessageBox.clipChild = clipChild

    local searchBox = CreateFrame("EditBox", "MessageBoxContactSearch", contactFrame, "InputBoxTemplate")
    searchBox:SetWidth(L.CONTACT_WIDTH - 10)
    searchBox:SetHeight(20)
    searchBox:SetPoint("TOPLEFT", contactFrame, "TOPLEFT", 5, -6)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("GameFontHighlightSmall")
    
    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 5, 0)
    placeholder:SetText("Search Contacts")
    placeholder:SetTextColor(0.5, 0.5, 0.5)
    searchBox.placeholder = placeholder
    
    searchBox:SetScript("OnEditFocusGained", function() 
        this.hasFocus = true
        this:HighlightText()
        this.placeholder:Hide()
    end)
    searchBox:SetScript("OnEditFocusLost", function()
        this.hasFocus = false
        if this:GetText() == "" then
            this.placeholder:Show()
        end
    end)
    searchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    searchBox:SetScript("OnTextChanged", function()
        MessageBox.searchQuery = this:GetText()
        MessageBox:UpdateContactList()
        
        if this:GetText() ~= "" then
            this.placeholder:Hide()
        elseif not this.hasFocus then
            this.placeholder:Show()
        end
    end)
    
    MessageBox.friendsHeader = MessageBox:CreateHeaderFrame(contactFrame, function()
        MessageBox.settings.friendsListCollapsed = not MessageBox.settings.friendsListCollapsed
        MessageBox:UpdateContactList()
    end, "MessageBoxFriendsHeaderPlus", "MessageBoxFriendsHeaderMinus")
    MessageBox.friendsHeader.text:SetText("Friends")
    
    MessageBox.conversationsHeader = MessageBox:CreateHeaderFrame(contactFrame, function()
        MessageBox.settings.conversationsListCollapsed = not MessageBox.settings.conversationsListCollapsed
        MessageBox:UpdateContactList()
    end, "MessageBoxConversationsHeaderPlus", "MessageBoxConversationsHeaderMinus")
    MessageBox.conversationsHeader.text:SetText("Conversations")

    local friendsScroll = CreateFrame("ScrollFrame", "MessageBoxFriendsScroll", contactFrame, "FauxScrollFrameTemplate")
    friendsScroll:SetScript("OnVerticalScroll", function() 
        FauxScrollFrame_OnVerticalScroll(1, function() MessageBox:UpdateScrollViews() end) 
    end)
    MessageBox.friendsScroll = friendsScroll
    
    local convosScroll = CreateFrame("ScrollFrame", "MessageBoxConversationsScroll", contactFrame, "FauxScrollFrameTemplate")
    convosScroll:SetScript("OnVerticalScroll", function() 
        FauxScrollFrame_OnVerticalScroll(1, function() MessageBox:UpdateScrollViews() end) 
    end)
    MessageBox.conversationsScroll = convosScroll

    local chatFrame = CreateFrame("Frame", nil, frame)
    chatFrame:SetPoint("TOPLEFT", contactFrame, "TOPRIGHT", 5, 0)
    chatFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 40)
    MessageBox.chatFrame = chatFrame

    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetWidth(16)
    resizeButton:SetHeight(16)
    resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    resizeButton:SetNormalTexture(MessageBox.textures.sizeUp)
    resizeButton:SetPushedTexture(MessageBox.textures.sizeDown)
    resizeButton:SetHighlightTexture(MessageBox.textures.sizeHi)
    resizeButton:SetScript("OnMouseDown", function() this:GetParent():StartSizing("BOTTOMRIGHT") end)
    resizeButton:SetScript("OnMouseUp", function() this:GetParent():StopMovingOrSizing() end)

    MessageBox:CreateChatHeader(chatFrame)

    local inputBackdrop = CreateFrame("Frame", nil, chatFrame)
    inputBackdrop:SetPoint("BOTTOMLEFT", chatFrame, "BOTTOMLEFT", 10, 10)
    inputBackdrop:SetPoint("RIGHT", chatFrame, "RIGHT", -75, 0)
    inputBackdrop:SetHeight(28)
    MessageBox.inputBackdrop = inputBackdrop

    local measureFS = inputBackdrop:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    measureFS:SetWidth(inputBackdrop:GetWidth() - 12)
    measureFS:SetNonSpaceWrap(true)
    measureFS:Hide()

    local whisperInput = CreateFrame("EditBox", "MessageBoxWhisperInput", inputBackdrop)
    whisperInput:SetPoint("TOPLEFT", inputBackdrop, "TOPLEFT", 6, -6)
    whisperInput:SetPoint("BOTTOMRIGHT", inputBackdrop, "BOTTOMRIGHT", -6, 6)
    whisperInput:SetFontObject("GameFontHighlight")
    whisperInput:SetMultiLine(true)
    whisperInput:SetAutoFocus(false)
    whisperInput:EnableMouse(true)
    
    whisperInput:SetScript("OnTextChanged", function()
        if this.blockingChange then return end
        local text = this:GetText()

        if string.sub(text, -1) == "\n" and not IsShiftKeyDown() then
            this.blockingChange = true
            this:SetText(string.sub(text, 1, -2))
            this.blockingChange = false
            MessageBox:SendWhisper()
            return
        end
        
        -- Update character count
        local len = string.len(text)
        if MessageBox.charCountText then
            if len > 200 then
                local color = len > 255 and "|cffff4444" or "|cffaaaaaa"
                MessageBox.charCountText:SetText(color .. len .. "/255|r")
                MessageBox.charCountText:Show()
            else
                MessageBox.charCountText:Hide()
            end
        end
        
        if text == "" then text = " " end 
        
        measureFS:SetWidth(MessageBox.inputBackdrop:GetWidth() - 12)
        measureFS:SetText(text)
        local height = measureFS:GetHeight()
        if height < 14 then height = 14 end
        if height > 120 then height = 120 end
        
        local newBackdropHeight = height + 14
        if math.abs(MessageBox.inputBackdrop:GetHeight() - newBackdropHeight) > 1 then
            MessageBox.inputBackdrop:SetHeight(newBackdropHeight)
            MessageBox.chatHistory:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", -25, newBackdropHeight + 15)
        end
    end)

    whisperInput:SetScript("OnEditFocusGained", function()
        MessageBox.isInputFocused = true
        MessageBox.lastFocusTime = GetTime()
    end)
    whisperInput:SetScript("OnEditFocusLost", function()
        MessageBox.isInputFocused = false
        MessageBox.lastFocusTime = GetTime()
    end)
    whisperInput:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    MessageBox.whisperInput = whisperInput

    local sendButton = CreateFrame("Button", nil, chatFrame, "UIPanelButtonTemplate")
    sendButton:SetWidth(60)
    sendButton:SetHeight(28)
    sendButton:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", -10, 10)
    sendButton:SetText("Send")
    sendButton:SetScript("OnClick", function() MessageBox:SendWhisper() end)
    MessageBox.sendButton = sendButton

    -- Character count label (visible only past 200 characters)
    local charCount = chatFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    charCount:SetPoint("BOTTOM", sendButton, "TOP", 0, 2)
    charCount:SetJustifyH("CENTER")
    charCount:Hide()
    MessageBox.charCountText = charCount

    local chatHistory = CreateFrame("ScrollingMessageFrame", "MessageBoxChatHistory", chatFrame)
    chatHistory:SetPoint("TOPLEFT", MessageBox.chatHeader, "BOTTOMLEFT", 8, -10)
    chatHistory:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", -25, 43)
    
    chatHistory:SetFont(MessageBox.fonts.openSans, MessageBox.settings.chatFontSize or MessageBox.defaultSettings.chatFontSize, "OUTLINE")
    chatHistory:SetShadowOffset(1, -1)
    
    chatHistory:SetJustifyH("LEFT")
    chatHistory:SetMaxLines(500)
    chatHistory:SetFading(false)
    chatHistory:EnableMouseWheel(true)
    
    chatHistory:SetScript("OnMouseWheel", function()
        local delta = arg1
        local sb = MessageBox.chatScrollBar
        if sb and sb:IsVisible() then
            local current = sb:GetValue()
            if delta > 0 then
                sb:SetValue(current - 1)
            else
                sb:SetValue(current + 1)
            end
        else
            if delta > 0 then this:ScrollUp() else this:ScrollDown() end
        end
    end)
    MessageBox.chatHistory = chatHistory
    
    local chatScrollBar = CreateFrame("Slider", "MessageBoxChatHistoryScrollBar", chatFrame, "UIPanelScrollBarTemplate")
    chatScrollBar:SetPoint("TOPLEFT", chatHistory, "TOPRIGHT", 3, -16)
    chatScrollBar:SetPoint("BOTTOMLEFT", chatHistory, "BOTTOMRIGHT", 3, 16)
    chatScrollBar:SetMinMaxValues(1, 1)
    chatScrollBar:SetValueStep(1)
    chatScrollBar:SetWidth(16)
    
    local track = chatScrollBar:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(0.15, 0.15, 0.15, 0.5)
    track:SetWidth(4)
    track:SetPoint("TOP", chatScrollBar, "TOP", 0, 16)
    track:SetPoint("BOTTOM", chatScrollBar, "BOTTOM", 0, -16)
    chatScrollBar.track = track

    MessageBox:SkinScrollbar(chatScrollBar)
    
    chatScrollBar:SetScript("OnValueChanged", function()
        if this.isUpdating then return end
        MessageBox.chatRenderDirty = true
    end)
    MessageBox.chatScrollBar = chatScrollBar
    
    -- Throttled render via OnUpdate
    MessageBox.chatRenderDirty = false
    MessageBox.chatLastRenderTime = 0
    
    chatHistory:SetScript("OnUpdate", function()
        if not MessageBox.chatRenderDirty then return end
        local now = GetTime()
        if (now - MessageBox.chatLastRenderTime) < MessageBox.RENDER_THROTTLE then return end
        MessageBox.chatRenderDirty = false
        MessageBox.chatLastRenderTime = now
        MessageBox:UpdateChatHistory()
    end)
    
    chatHistory:EnableMouse(true)
    chatHistory:SetScript("OnHyperlinkClick", function()
        local link = arg1
        if link and string.sub(link, 1, 3) == "url" then
            MessageBox:ShowCopyPopup(string.sub(link, 5))
            return
        end
        if IsShiftKeyDown() and link then
            local name, itemString, quality = GetItemInfo(link)
            if name and itemString then
                local _, _, _, hex = GetItemQualityColor(tonumber(quality) or 1)
                local fullLink = hex .. "|H" .. itemString .. "|h[" .. name .. "]|h|r"
                if MessageBox.whisperInput:IsVisible() then
                    MessageBox.whisperInput:Insert(fullLink)
                    MessageBox.whisperInput:SetFocus()
                    return
                end
            end
        end
        ChatFrame_OnHyperlinkShow(arg1, arg2, arg3)
    end)
    
    local deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteButton:SetWidth(80)
    deleteButton:SetHeight(20)
    deleteButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 12)
    deleteButton:SetText("Delete")
    deleteButton:SetScript("OnClick", function() MessageBox:ShowDeleteConfirmation() end)
    MessageBox.deleteButton = deleteButton

    local deleteAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteAllButton:SetWidth(80)
    deleteAllButton:SetHeight(20)
    deleteAllButton:SetPoint("LEFT", deleteButton, "RIGHT", 5, 0)
    deleteAllButton:SetText("Delete All")
    deleteAllButton:SetScript("OnClick", function() MessageBox:ShowDeleteAllConfirmation() end)
    MessageBox.deleteAllButton = deleteAllButton

    local settingsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    settingsButton:SetWidth(80)
    settingsButton:SetHeight(20)
    settingsButton:SetPoint("LEFT", deleteAllButton, "RIGHT", 5, 0)
    settingsButton:SetText("Settings")
    settingsButton:SetScript("OnClick", function() 
        if MessageBox.settingsFrame and MessageBox.settingsFrame:IsVisible() then
            MessageBox.settingsFrame:Hide()
        else
            MessageBox:ShowSettingsFrame()
        end
    end)
    MessageBox.settingsButton = settingsButton

    local themeButton = CreateFrame("Button", nil, frame)
    themeButton:SetWidth(20)
    themeButton:SetHeight(20)
    themeButton:SetPoint("LEFT", settingsButton, "RIGHT", 5, 0)
    themeButton:SetNormalTexture(MessageBox.textures.palette)
    themeButton:SetHighlightTexture(MessageBox.textures.listHighlight)
    
    themeButton:SetScript("OnClick", function() 
        if MessageBox.themeFrame and MessageBox.themeFrame:IsVisible() then
            MessageBox.themeFrame:Hide()
        else
            MessageBox:ShowThemeFrame()
        end
    end)
    themeButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Edit Theme Colors")
        GameTooltip:Show()
    end)
    themeButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    MessageBox.themeButton = themeButton

    local bellButton = CreateFrame("Button", nil, frame)
    bellButton:SetWidth(20)
    bellButton:SetHeight(20)
    bellButton:SetPoint("LEFT", themeButton, "RIGHT", 5, 0)
    bellButton:SetNormalTexture(MessageBox.textures.bellOn) 
    bellButton:SetHighlightTexture(MessageBox.textures.minimizeBtnHi)
    
    bellButton.UpdateState = function()
        if MessageBox.settings.popupNotificationsEnabled then
            bellButton:SetNormalTexture(MessageBox.textures.bellOn)
            bellButton:SetAlpha(1.0) 
            bellButton:GetNormalTexture():SetVertexColor(1, 1, 1) 
        else
            bellButton:SetNormalTexture(MessageBox.textures.bellOff)
            bellButton:SetAlpha(1.0)
            bellButton:GetNormalTexture():SetVertexColor(1, 1, 1)
        end
    end
    
    bellButton:SetScript("OnClick", function() 
        MessageBox.settings.popupNotificationsEnabled = not MessageBox.settings.popupNotificationsEnabled
        this.UpdateState()
        
        if GameTooltip:IsOwned(this) then
            this:GetScript("OnEnter")()
        end
    end)
    
    bellButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Toggle Popup Notifications")
        if MessageBox.settings.popupNotificationsEnabled then
             GameTooltip:AddLine("Status: |cff00ff00Enabled|r", 1, 1, 1)
        else
             GameTooltip:AddLine("Status: |cffff0000Disabled|r", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    bellButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    bellButton.UpdateState()
    MessageBox.bellButton = bellButton

    local openWindowButton = CreateFrame("Button", nil, frame)
    openWindowButton:SetWidth(20)
    openWindowButton:SetHeight(20)
    openWindowButton:SetPoint("LEFT", bellButton, "RIGHT", 5, 0)
    openWindowButton:SetHighlightTexture(MessageBox.textures.minimizeBtnHi)

    openWindowButton.UpdateState = function()
        if MessageBox.settings.openWindowOnWhisper then
            openWindowButton:SetNormalTexture(MessageBox.textures.envelopeOpen)
            openWindowButton:SetAlpha(1.0)
            openWindowButton:GetNormalTexture():SetVertexColor(1, 1, 1)
        else
            openWindowButton:SetNormalTexture(MessageBox.textures.envelope)
            openWindowButton:SetAlpha(0.65)
            openWindowButton:GetNormalTexture():SetVertexColor(1, 1, 1)
        end
    end

    openWindowButton:SetScript("OnClick", function()
        MessageBox.settings.openWindowOnWhisper = not MessageBox.settings.openWindowOnWhisper
        this.UpdateState()
        MessageBox:UpdateMinimapBadge()
        if MessageBox.settingsFrame and MessageBox.settingsFrame.checks and MessageBox.settingsFrame.checks["openWindowOnWhisper"] then
            MessageBox.settingsFrame.checks["openWindowOnWhisper"]:SetChecked(MessageBox.settings.openWindowOnWhisper)
        end
        if GameTooltip:IsOwned(this) then
            this:GetScript("OnEnter")()
        end
    end)

    openWindowButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Open Window on New Whisper")
        if MessageBox.settings.openWindowOnWhisper then
            GameTooltip:AddLine("Status: |cff00ff00Open window|r", 1, 1, 1)
            GameTooltip:AddLine("The floating notification icon is not used.", 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine("Status: |cffffcc00Notification icon|r", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    openWindowButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    openWindowButton.UpdateState()
    MessageBox.openWindowButton = openWindowButton

    local settingsDropDown = CreateFrame("Frame", "MessageBoxSettingsDropDown", frame, "UIDropDownMenuTemplate")

    -- Throttled relayout on resize
    MessageBox.relayoutDirty = false
    MessageBox.relayoutLastUpdate = 0
    frame:SetScript("OnUpdate", function()
        if MessageBox.pendingWhisperFocusFrames then
            MessageBox.pendingWhisperFocusFrames = MessageBox.pendingWhisperFocusFrames - 1
            if MessageBox.pendingWhisperFocusFrames <= 0 then
                MessageBox.pendingWhisperFocusFrames = nil
                if MessageBox.whisperInput and MessageBox.frame and MessageBox.frame:IsVisible() then
                    MessageBox.whisperInput:SetFocus()
                end
            end
        end
        if not MessageBox.relayoutDirty then return end
        local now = GetTime()
        if (now - MessageBox.relayoutLastUpdate) < 0.05 then return end
        MessageBox.relayoutDirty = false
        MessageBox.relayoutLastUpdate = now
        MessageBox:RelayoutMainFrame()
    end)

    tinsert(UISpecialFrames, "MessageBoxFrame")
    MessageBox:UpdateContactList()
    MessageBox:ApplyTheme()
end

function MessageBox:RelayoutMainFrame()
    if not self.frame then return end

    local L = self.layout
    local frameWidth = self.frame:GetWidth()

    -- Sidebar: scale proportionally from CONTACT_WIDTH down to SIDEBAR_MIN_WIDTH
    local sidebarWidth = L.CONTACT_WIDTH
    if frameWidth < L.MAIN_WIDTH then
        local ratio = (frameWidth - L.MIN_WIDTH) / (L.MAIN_WIDTH - L.MIN_WIDTH)
        if ratio < 0 then ratio = 0 end
        if ratio > 1 then ratio = 1 end
        sidebarWidth = L.SIDEBAR_MIN_WIDTH + ratio * (L.CONTACT_WIDTH - L.SIDEBAR_MIN_WIDTH)
        sidebarWidth = math.floor(sidebarWidth)
        if sidebarWidth < L.SIDEBAR_MIN_WIDTH then sidebarWidth = L.SIDEBAR_MIN_WIDTH end
    end

    if self.contactFrame then
        self.contactFrame:SetWidth(sidebarWidth)
    end

    local searchBox = getglobal("MessageBoxContactSearch")
    if searchBox then
        searchBox:SetWidth(sidebarWidth - 10)
    end

    -- Clip child width
    if self.clipChild then
        self.clipChild:SetWidth(sidebarWidth)
    end

    -- Bottom buttons: scale from 80 down to 50
    local buttonWidth = 80
    if frameWidth < L.MAIN_WIDTH then
        local ratio = (frameWidth - L.MIN_WIDTH) / (L.MAIN_WIDTH - L.MIN_WIDTH)
        if ratio < 0 then ratio = 0 end
        if ratio > 1 then ratio = 1 end
        buttonWidth = math.floor(50 + ratio * 30)
        if buttonWidth < 50 then buttonWidth = 50 end
    end
    if self.deleteButton then self.deleteButton:SetWidth(buttonWidth) end
    if self.deleteAllButton then self.deleteAllButton:SetWidth(buttonWidth) end
    if self.settingsButton then self.settingsButton:SetWidth(buttonWidth) end

    -- Chat header: adapt to narrow widths
    self:AdaptChatHeader()

    -- Trigger contact list rebuild
    self:MarkContactListDirty()
end

function MessageBox:AdaptChatHeader()
    if not self.chatHeader or not self.chatFrame then return end

    local chatWidth = self.chatFrame:GetWidth()

    if chatWidth < 200 then
        self.chatHeader:SetHeight(36)
        self.chatHeader.avatarBtn:SetWidth(24)
        self.chatHeader.avatarBtn:SetHeight(24)
        if self.chatHeader.guildText then self.chatHeader.guildText:Hide() end
        if self.chatHeader.metaTopText then self.chatHeader.metaTopText:Hide() end
    else
        self.chatHeader:SetHeight(50)
        self.chatHeader.avatarBtn:SetWidth(36)
        self.chatHeader.avatarBtn:SetHeight(36)
        if self.chatHeader.guildText then self.chatHeader.guildText:Show() end
        if self.chatHeader.metaTopText then self.chatHeader.metaTopText:Show() end
    end
end

function MessageBox:UpdateContactList()
    if not MessageBox.contactFrame then return end
    
    local searchQuery = string.lower(MessageBox.searchQuery or "")
    local hideOffline = MessageBox.settings.hideOffline
    
    MessageBox.visibleFriends = {}
    MessageBox.onlineStatus = {}
    MessageBox.friendSet = {}
    for i = 1, GetNumFriends() do
        local name, level, class, area, connected, status = GetFriendInfo(i)
        if name then
            local nameLower = string.lower(name)
            MessageBox.onlineStatus[nameLower] = connected
            MessageBox.friendSet[nameLower] = true
            
            local matchesSearch = (searchQuery == "") or string.find(nameLower, searchQuery)
            local showContact = matchesSearch
            if hideOffline and not connected then showContact = false end
            
            if showContact then
                 if not MessageBox.playerCache[name] then MessageBox.playerCache[name] = {} end
                 MessageBox.playerCache[name].class = class
                 MessageBox.playerCache[name].classUpper = class and string.upper(class) or nil
                 MessageBox.playerCache[name].level = level
                 MessageBox.playerCache[name].zone = area
                 MessageBox.playerCache[name].status = status
                 
                 table.insert(MessageBox.visibleFriends, {
                     name = name,
                     class = class,
                     classUpper = class and string.upper(class) or nil,
                     connected = connected,
                     unread = MessageBox.unreadCounts[name] or 0
                 })
            end
        end
    end

    MessageBox.visibleConversations = {}
    if MessageBox.conversations then
        -- Only re-sort when conversation order has changed
        if MessageBox.conversationOrderDirty ~= false then
            local sortedContacts = {}
            for contact, data in pairs(MessageBox.conversations) do
                if data and data.times and MessageBox:GetCount(data) > 0 then
                    table.insert(sortedContacts, contact)
                end
            end
            table.sort(sortedContacts, function(a, b)
                local convoA = MessageBox.conversations[a]
                local convoB = MessageBox.conversations[b]
                -- Pinned conversations always come first
                local pinnedA = convoA.pinned or false
                local pinnedB = convoB.pinned or false
                if pinnedA and not pinnedB then return true end
                if not pinnedA and pinnedB then return false end
                -- Within the same pin group, sort by most recent message
                local countA = MessageBox:GetCount(convoA)
                local countB = MessageBox:GetCount(convoB)
                local lastTimeA = convoA.times[countA]
                local lastTimeB = convoB.times[countB]
                if type(lastTimeA) ~= "number" then return false end
                if type(lastTimeB) ~= "number" then return true end
                return lastTimeA > lastTimeB
            end)
            MessageBox.cachedSortedContacts = sortedContacts
            MessageBox.conversationOrderDirty = false
        end
        
        local sortedContacts = MessageBox.cachedSortedContacts or {}
        for i = 1, table.getn(sortedContacts) do
            local contact = sortedContacts[i]
            if MessageBox.conversations[contact] then
                local matchesSearch = (searchQuery == "") or string.find(string.lower(contact), searchQuery)
                
                if matchesSearch then
                    table.insert(MessageBox.visibleConversations, {
                        name = contact,
                        unread = MessageBox.unreadCounts[contact] or 0,
                        pinned = MessageBox.conversations[contact].pinned or false
                    })
                end
            end
        end
    end
    
    MessageBox:UpdateScrollViews()
end

function MessageBox:MarkContactListDirty()
    MessageBox.contactListDirty = true
end

function MessageBox:UpdateScrollViews()
    if not MessageBox.contactFrame then return end

    local friendsCollapsed = MessageBox.settings.friendsListCollapsed
    local conversationsCollapsed = MessageBox.settings.conversationsListCollapsed
    
    local L = MessageBox.layout
    local ROW_HEIGHT = L.ROW_HEIGHT
    local SEARCH_AREA_HEIGHT = L.SEARCH_AREA_HEIGHT
    local HEADER_HEIGHT = L.HEADER_HEIGHT
    local BOTTOM_PADDING = L.BOTTOM_PADDING
    local MIDDLE_PADDING = L.MIDDLE_PADDING
    
    local containerHeight = MessageBox.frame:GetHeight() - 66
    local availableHeight = containerHeight - SEARCH_AREA_HEIGHT - (HEADER_HEIGHT * 2) - BOTTOM_PADDING - MIDDLE_PADDING
    
    MessageBox.friendsHeader.frame:ClearAllPoints()
    MessageBox.friendsHeader.frame:SetPoint("TOPLEFT", MessageBox.contactFrame, "TOPLEFT", 5, -SEARCH_AREA_HEIGHT)
    MessageBox.friendsHeader.frame:SetPoint("RIGHT", MessageBox.contactFrame, "RIGHT", -5, 0)
    MessageBox.friendsHeader.frame:Show()

    local friendsHeight = 0
    local convosHeight = 0
    
    local numFriends = table.getn(MessageBox.visibleFriends)
    local friendsContentHeight = numFriends * ROW_HEIGHT
    if friendsContentHeight == 0 then friendsContentHeight = 20 end

    if not friendsCollapsed and not conversationsCollapsed then
        local splitHeight = availableHeight / 2
        
        if friendsContentHeight < splitHeight then
            friendsHeight = friendsContentHeight
        else
            friendsHeight = splitHeight
        end
        convosHeight = availableHeight - friendsHeight

    elseif not friendsCollapsed and conversationsCollapsed then
        friendsHeight = availableHeight
    elseif friendsCollapsed and not conversationsCollapsed then
        convosHeight = availableHeight
    end
    
    if friendsHeight < 16 then friendsHeight = 16 end
    if convosHeight < 16 then convosHeight = 16 end

    if friendsCollapsed then
        MessageBox.friendsHeader.plusButton:Show()
        MessageBox.friendsHeader.minusButton:Hide()
        MessageBox.friendsScroll:Hide()
        for _, row in ipairs(MessageBox.friendRows) do row:Hide() end
    else
        MessageBox.friendsHeader.plusButton:Hide()
        MessageBox.friendsHeader.minusButton:Show()
        MessageBox.friendsScroll:Show()
        
        MessageBox.friendsScroll:ClearAllPoints()
        MessageBox.friendsScroll:SetPoint("TOPLEFT", MessageBox.friendsHeader.frame, "BOTTOMLEFT", 0, 0)
        MessageBox.friendsScroll:SetPoint("RIGHT", MessageBox.contactFrame, "RIGHT", -32, 0)
        MessageBox.friendsScroll:SetHeight(friendsHeight)
    end

    MessageBox.conversationsHeader.frame:ClearAllPoints()
    if friendsCollapsed then
        MessageBox.conversationsHeader.frame:SetPoint("TOPLEFT", MessageBox.friendsHeader.frame, "BOTTOMLEFT", 0, -MIDDLE_PADDING)
    else
        MessageBox.conversationsHeader.frame:SetPoint("TOPLEFT", MessageBox.friendsScroll, "BOTTOMLEFT", 0, -MIDDLE_PADDING)
    end
    MessageBox.conversationsHeader.frame:SetPoint("RIGHT", MessageBox.contactFrame, "RIGHT", -5, 0)
    MessageBox.conversationsHeader.frame:Show()

    if conversationsCollapsed then
        MessageBox.conversationsHeader.plusButton:Show()
        MessageBox.conversationsHeader.minusButton:Hide()
        MessageBox.conversationsScroll:Hide()
        for _, row in ipairs(MessageBox.conversationRows) do row:Hide() end
    else
        MessageBox.conversationsHeader.plusButton:Hide()
        MessageBox.conversationsHeader.minusButton:Show()
        MessageBox.conversationsScroll:Show()
        
        MessageBox.conversationsScroll:ClearAllPoints()
        MessageBox.conversationsScroll:SetPoint("TOPLEFT", MessageBox.conversationsHeader.frame, "BOTTOMLEFT", 0, 0)
        MessageBox.conversationsScroll:SetPoint("RIGHT", MessageBox.contactFrame, "RIGHT", -32, 0)
        MessageBox.conversationsScroll:SetPoint("BOTTOM", MessageBox.contactFrame, "BOTTOM", 0, BOTTOM_PADDING)
    end

    if not friendsCollapsed then
        local listSize = table.getn(MessageBox.visibleFriends)
        local displayRows = math.ceil(friendsHeight / 16)
        local scrollRows = math.floor(friendsHeight / 16)
        if scrollRows < 1 then scrollRows = 1 end
        
        MessageBox:EnsureRows(MessageBox.clipChild or MessageBox.contactFrame, MessageBox.friendRows, displayRows)
        FauxScrollFrame_Update(MessageBoxFriendsScroll, listSize, scrollRows, 1)
        
        local offset = FauxScrollFrame_GetOffset(MessageBoxFriendsScroll)
        for i = 1, table.getn(MessageBox.friendRows) do
            local row = MessageBox.friendRows[i]
            if i <= displayRows then
                local dataIndex = offset + i
                if dataIndex <= listSize then
                    local data = MessageBox.visibleFriends[dataIndex]
                    
                    local displayName = data.name
                    local friendCache = MessageBox.playerCache[data.name]
                    if friendCache and friendCache.isGM then
                        displayName = "|cff00ccffGM " .. data.name .. "|r"
                    elseif data.class and RAID_CLASS_COLORS[data.classUpper] then
                        local color = RAID_CLASS_COLORS[data.classUpper]
                        displayName = string.format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, data.name)
                    end
                    if data.unread > 0 then
                         displayName = displayName .. " |cffff80ff[" .. data.unread .. "]|r"
                    end
                    
                    row.text:SetText(displayName)
                    local statusColor = data.connected and {0, 1, 0} or {0.5, 0.5, 0.5}
                    row.statusIcon:SetText("•")
                    row.statusIcon:SetTextColor(unpack(statusColor))
                    
                    if row.isHovered then
                        row.text:SetTextColor(0.82, 0.82, 0.82, 1)
                    else
                        local c = MessageBox.settings.textColor or MessageBox.defaultSettings.textColor
                        row.text:SetTextColor(unpack(c))
                    end
                    
                    row.pinIcon:Hide()

                    row.contactName = data.name

                    row:SetPoint("TOPLEFT", MessageBox.friendsScroll, "TOPLEFT", 8, -((i-1)*16))
                    row:SetWidth(MessageBox.friendsScroll:GetWidth())
                    row.text:SetWidth(row:GetWidth() - 10)
                    row:Show()
                else
                    row:Hide()
                end
            else
                row:Hide()
            end
        end
    end

    if not conversationsCollapsed then
        local listSize = table.getn(MessageBox.visibleConversations)
        
        local displayRows = math.ceil(convosHeight / 16)
        local scrollRows = math.floor(convosHeight / 16)
        if scrollRows < 1 then scrollRows = 1 end
        
        MessageBox:EnsureRows(MessageBox.clipChild or MessageBox.contactFrame, MessageBox.conversationRows, displayRows)
        FauxScrollFrame_Update(MessageBoxConversationsScroll, listSize, scrollRows, 1)
        
        local offset = FauxScrollFrame_GetOffset(MessageBoxConversationsScroll)
        for i = 1, table.getn(MessageBox.conversationRows) do
            local row = MessageBox.conversationRows[i]
            if i <= displayRows then
                local dataIndex = offset + i
                if dataIndex <= listSize then
                    local data = MessageBox.visibleConversations[dataIndex]
                    
                    local displayName = data.name
                    local cache = MessageBox.playerCache[data.name]
                    if cache and cache.isGM then
                        displayName = "|cff00ccffGM " .. data.name .. "|r"
                    elseif cache and cache.class and RAID_CLASS_COLORS[cache.classUpper] then
                        local color = RAID_CLASS_COLORS[cache.classUpper]
                        displayName = string.format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, data.name)
                    end
                    
                    if data.unread > 0 then
                        displayName = displayName .. " |cffff80ff[" .. data.unread .. "]|r"
                    end
                    row.text:SetText(displayName)
                    
                    local isOnline = MessageBox:IsPlayerOnline(data.name)
                    local statusColor = (isOnline == true) and {0, 1, 0} or ((isOnline == false) and {0.5, 0.5, 0.5} or {0.5, 0, 0.5})
                    
                    row.statusIcon:SetText("•")
                    row.statusIcon:SetTextColor(unpack(statusColor))
                    
                    if row.isHovered then
                        row.text:SetTextColor(0.82, 0.82, 0.82, 1)
                    else
                        local c = MessageBox.settings.textColor or MessageBox.defaultSettings.textColor
                        row.text:SetTextColor(unpack(c))
                    end

                    if data.pinned then
                        row.pinIcon:Show()
                    else
                        row.pinIcon:Hide()
                    end

                    row.contactName = data.name

                    row:SetPoint("TOPLEFT", MessageBox.conversationsScroll, "TOPLEFT", 8, -((i-1)*16))
                    row:SetWidth(MessageBox.conversationsScroll:GetWidth())
                    local textRight = data.pinned and 22 or 10
                    row.text:SetWidth(row:GetWidth() - textRight)
                    row:Show()
                else
                    row:Hide()
                end
            else
                row:Hide()
            end
        end
    end

    MessageBox:SkinScrollbar(MessageBoxFriendsScroll)
    MessageBox:SkinScrollbar(MessageBoxConversationsScroll)
end

function MessageBox:SelectContact(contact)
    if not contact then return end
    
    -- Close search bar when switching contacts
    if MessageBox.chatSearchActive then
        MessageBox:CloseSearchBar()
    end
    
    local unreadToPass = 0
    if MessageBox.unreadCounts and MessageBox.unreadCounts[contact] then
        unreadToPass = MessageBox.unreadCounts[contact]
    end

    if unreadToPass > 0 then
        local c = MessageBox.conversations[contact]
        if c and c.messages then
            MessageBox.currentSplitIndex = MessageBox:GetCount(c) - unreadToPass + 1
        end
    else
        MessageBox.currentSplitIndex = 0
    end

    MessageBox.selectedContact = contact
    
    if not MessageBox.conversations[contact] then 
        MessageBox.conversations[contact] = MessageBox:NewConversation()
    end
    
    MessageBox:UpdateChatHeader()
    
    if MessageBox.unreadCounts then MessageBox.unreadCounts[contact] = 0 end
    MessageBox:UpdateMinimapBadge()
    MessageBox:UpdateContactList()
    
    MessageBox:UpdateChatHistory(unreadToPass, true)
    
    if MessageBox.whisperInput then
        MessageBox:ScheduleWhisperInputFocus()
    end
end

function MessageBox:UpdateChatHistory(unreadCount, resetToBottom)
    if MessageBox.detachedWindows then
        for name, win in pairs(MessageBox.detachedWindows) do
            if win and win:IsVisible() and win.UpdateDisplay then
                win:UpdateDisplay()
            end
        end
    end

    if not MessageBox.chatHistory then return end
    
    if not MessageBox.selectedContact then 
        MessageBox.chatHistory:Clear()
        if MessageBox.chatScrollBar then MessageBox.chatScrollBar:Hide() end
        return 
    end
    
    local c = self.conversations[self.selectedContact]
    
    if not c or not c.messages then 
        MessageBox.chatHistory:Clear()
        if MessageBox.chatScrollBar then MessageBox.chatScrollBar:Hide() end
        return 
    end
    
    local totalMessages = MessageBox:GetCount(c)
    
    if totalMessages == 0 then
        MessageBox.chatHistory:Clear()
        if MessageBox.chatScrollBar then
            MessageBox.chatScrollBar:Hide()
        end
        return
    end
    
    local anchorIndex = totalMessages
    
    if not resetToBottom and MessageBox.chatScrollBar and MessageBox.chatScrollBar:IsVisible() then
        local val = MessageBox.chatScrollBar:GetValue()
        if val > totalMessages then val = totalMessages end
        if val < 1 then val = 1 end
        anchorIndex = val
    end
    
    MessageBox:RenderMessages(MessageBox.chatHistory, self.selectedContact, anchorIndex, unreadCount)
    
    if MessageBox.chatScrollBar then
        if totalMessages == 0 then
            MessageBox.chatScrollBar:Hide()
        else
            MessageBox.chatScrollBar:Show()
            if not MessageBox.chatScrollBar.isUpdating then
                MessageBox.chatScrollBar.isUpdating = true
                MessageBox.chatScrollBar:SetMinMaxValues(1, totalMessages)
                MessageBox.chatScrollBar:SetValue(anchorIndex)
                MessageBox.chatScrollBar.isUpdating = false
            end
        end
    end
end

function MessageBox:SendWhisper()
    if not MessageBox.selectedContact then 
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: No contact selected. Click a name in the list first.")
        return 
    end
    
    if not MessageBox.whisperInput then return end
    
    local message = MessageBox.whisperInput:GetText()
    message = string.gsub(message, "\n$", "")
    
    if message == "" or string.find(message, "^%s*$") then
        MessageBox.whisperInput:SetText("")
        if MessageBox.inputBackdrop then MessageBox.inputBackdrop:SetHeight(28) end
        return 
    end

    -- 255-character limit on chat messages
    if string.len(message) > 255 then
        MessageBox:AddSystemMessage(MessageBox.selectedContact, "Message too long (" .. string.len(message) .. "/255 characters). Please shorten it.", true)
        return
    end

    local isOnline = MessageBox:IsPlayerOnline(MessageBox.selectedContact)
    if isOnline == false then
        MessageBox:AddSystemMessage(MessageBox.selectedContact, MessageBox.selectedContact .. " is offline.", true)
        MessageBox.whisperInput:SetText("")
        return
    end

    SendChatMessage(message, "WHISPER", nil, MessageBox.selectedContact)
    
    MessageBox.whisperInput:SetText("")
    MessageBox.whisperInput:SetScript("OnUpdate", function()
        this:SetText("")
        this:SetScript("OnUpdate", nil)
    end)

    if MessageBox.charCountText then
        MessageBox.charCountText:Hide()
    end

    if MessageBox.inputBackdrop then
        MessageBox.inputBackdrop:SetHeight(28)
        if MessageBox.chatHistory then
            MessageBox.chatHistory:SetPoint("BOTTOMRIGHT", MessageBox.chatHistory:GetParent(), "BOTTOMRIGHT", -25, 43)
        end
    end
    
    if MessageBox.chatScrollBar then
        local min, max = MessageBox.chatScrollBar:GetMinMaxValues()
        MessageBox.chatScrollBar:SetValue(max)
        MessageBox:UpdateChatHistory(nil, true) 
    end
end

function MessageBox:ScheduleWhisperInputFocus()
    if not self.whisperInput then return end
    self.pendingWhisperFocusFrames = 2
end

function MessageBox:ShowFrame()
    if not self.frame then self:CreateFrame() end
    self.frame:Show()
    self:HideNotificationPopup() 
    self:UpdateContactList()
    self:UpdateChatHeader()

    if self.selectedContact then 
        self:UpdateChatHeader()
        self:UpdateChatHistory() 
    end
    if self.whisperInput then self:ScheduleWhisperInputFocus() end
end

function MessageBox:HideFrame()
    if self.chatSearchActive then
        self:CloseSearchBar()
    end
    self.pendingWhisperFocusFrames = nil
    if self.frame then self.frame:Hide() end
end

function MessageBox:ToggleFrame()
    if self.frame and self.frame:IsVisible() then self:HideFrame() else self:ShowFrame() end
end

function MessageBox:OpenSearchBar()
    if not self.selectedContact then return end
    
    if not self.searchBarFrame then
        local bar = CreateFrame("Frame", "MessageBoxSearchBar", self.chatFrame)
        bar:SetHeight(26)
        bar:SetPoint("TOPLEFT", self.chatHeader, "BOTTOMLEFT", 0, 0)
        bar:SetPoint("TOPRIGHT", self.chatHeader, "BOTTOMRIGHT", 0, 0)
        
        bar:SetBackdrop({
            bgFile = MessageBox.textures.tooltipBg,
            tile = true, tileSize = 16,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        })
        bar:SetBackdropColor(0, 0, 0, 0.5)
        
        local searchInput = CreateFrame("EditBox", "MessageBoxChatSearchInput", bar)
        searchInput:SetWidth(150)
        searchInput:SetHeight(18)
        searchInput:SetPoint("LEFT", bar, "LEFT", 8, 0)
        searchInput:SetFontObject("GameFontHighlightSmall")
        searchInput:SetAutoFocus(false)
        
        searchInput:SetBackdrop({
            bgFile = MessageBox.textures.chatBg,
            edgeFile = MessageBox.textures.chatBg,
            tile = false, tileSize = 0, edgeSize = 1,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        searchInput:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        searchInput:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        searchInput:SetTextInsets(4, 4, 0, 0)
        
        local placeholder = searchInput:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        placeholder:SetPoint("LEFT", searchInput, "LEFT", 5, 0)
        placeholder:SetText("Search...")
        placeholder:SetTextColor(0.5, 0.5, 0.5)
        searchInput.placeholder = placeholder
        
        searchInput:SetScript("OnEditFocusGained", function()
            this.placeholder:Hide()
        end)
        searchInput:SetScript("OnEditFocusLost", function()
            if this:GetText() == "" then
                this.placeholder:Show()
            end
        end)
        
        searchInput:SetScript("OnTextChanged", function()
            local text = this:GetText()
            if text ~= "" then
                this.placeholder:Hide()
            end
            
            MessageBox.chatSearchTerm = text
            MessageBox.chatSearchResults = MessageBox:SearchConversation(MessageBox.selectedContact, text)
            
            local count = table.getn(MessageBox.chatSearchResults)
            if count > 0 then
                MessageBox.chatSearchCurrentIndex = count
                local msgIndex = MessageBox.chatSearchResults[count]
                if MessageBox.chatScrollBar then
                    MessageBox.chatScrollBar.isUpdating = true
                    local total = table.getn(MessageBox.conversations[MessageBox.selectedContact].messages)
                    MessageBox.chatScrollBar:SetMinMaxValues(1, total)
                    MessageBox.chatScrollBar:SetValue(msgIndex)
                    MessageBox.chatScrollBar.isUpdating = false
                end
            else
                MessageBox.chatSearchCurrentIndex = 0
            end
            
            MessageBox:UpdateSearchCountLabel()
            MessageBox:UpdateChatHistory()
        end)
        
        searchInput:SetScript("OnEscapePressed", function()
            MessageBox:CloseSearchBar()
        end)
        
        bar.searchInput = searchInput
        
        -- Count label
        local countText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countText:SetPoint("LEFT", searchInput, "RIGHT", 6, 0)
        countText:SetTextColor(0.8, 0.8, 0.8)
        bar.countText = countText
        MessageBox.searchCountText = countText
        
        -- Prev button (up arrow)
        local prevBtn = CreateFrame("Button", nil, bar)
        prevBtn:SetWidth(20)
        prevBtn:SetHeight(20)
        prevBtn:SetPoint("LEFT", countText, "RIGHT", 6, 0)
        prevBtn:SetNormalTexture(MessageBox.textures.scrollUpUp)
        prevBtn:SetPushedTexture(MessageBox.textures.scrollUpDown)
        prevBtn:SetHighlightTexture(MessageBox.textures.scrollUpHi)
        prevBtn:SetScript("OnClick", function()
            MessageBox:ChatSearchNavigate(-1)
        end)
        prevBtn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Previous Match")
            GameTooltip:Show()
        end)
        prevBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        bar.prevBtn = prevBtn
        
        -- Next button (down arrow)
        local nextBtn = CreateFrame("Button", nil, bar)
        nextBtn:SetWidth(20)
        nextBtn:SetHeight(20)
        nextBtn:SetPoint("LEFT", prevBtn, "RIGHT", 2, 0)
        nextBtn:SetNormalTexture(MessageBox.textures.scrollDownUp)
        nextBtn:SetPushedTexture(MessageBox.textures.scrollDownDown)
        nextBtn:SetHighlightTexture(MessageBox.textures.scrollDownHi)
        nextBtn:SetScript("OnClick", function()
            MessageBox:ChatSearchNavigate(1)
        end)
        nextBtn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Next Match")
            GameTooltip:Show()
        end)
        nextBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        bar.nextBtn = nextBtn
        
        -- Close button
        local closeBtn = CreateFrame("Button", nil, bar)
        closeBtn:SetWidth(14)
        closeBtn:SetHeight(14)
        closeBtn:SetPoint("RIGHT", bar, "RIGHT", -6, 0)
        closeBtn:SetNormalTexture(MessageBox.textures.closeOutline)
        closeBtn:SetPushedTexture(MessageBox.textures.closeSolid)
        closeBtn:SetHighlightTexture(MessageBox.textures.closeSolid)
        closeBtn:SetAlpha(0.7)
        closeBtn:SetScript("OnEnter", function() this:SetAlpha(1.0) end)
        closeBtn:SetScript("OnLeave", function() this:SetAlpha(0.7) end)
        closeBtn:SetScript("OnClick", function()
            MessageBox:CloseSearchBar()
        end)
        bar.closeBtn = closeBtn
        
        bar:Hide()
        self.searchBarFrame = bar
    end
    
    self.chatSearchActive = true
    self.chatSearchTerm = ""
    self.chatSearchResults = {}
    self.chatSearchCurrentIndex = 0
    
    self.searchBarFrame:Show()
    self.searchBarFrame.searchInput:SetText("")
    self.searchBarFrame.searchInput:SetFocus()
    self:UpdateSearchCountLabel()
    self:ApplyTheme()
    
    -- Push chat history down below the search bar
    if self.chatHistory then
        self.chatHistory:SetPoint("TOPLEFT", self.searchBarFrame, "BOTTOMLEFT", 8, -5)
    end
end

function MessageBox:ApplyChatFontSize()
    local size = self.settings.chatFontSize or 12
    local font = MessageBox.fonts.openSans
    
    if self.chatHistory then
        self.chatHistory:SetFont(font, size, "OUTLINE")
        self.chatHistory:SetShadowOffset(1, -1)
        self:UpdateChatHistory()
    end
    
    if self.detachedWindows then
        for contact, win in pairs(self.detachedWindows) do
            if win.history then
                win.history:SetFont(font, size, "OUTLINE")
                win.history:SetShadowOffset(1, -1)
                if win.UpdateDisplay then win:UpdateDisplay() end
            end
        end
    end

end
