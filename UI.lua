-- UI.lua
-- UI Construction, Contact rows

function MessageBox:CreateContactRow(parent)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetWidth(105)
    frame:SetHeight(16)
    frame:EnableMouse(true)
    
    local statusIcon = frame:CreateFontString(nil, "ARTWORK")
    statusIcon:SetFont("Interface\\AddOns\\MessageBox\\font\\OpenSans.ttf", 16)
    statusIcon:SetPoint("LEFT", frame, "LEFT", -5, -2)
    frame.statusIcon = statusIcon
    
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", statusIcon, "RIGHT", 3, 1)
    frame.text = text

    local pinIcon = frame:CreateTexture(nil, "OVERLAY")
    pinIcon:SetWidth(10)
    pinIcon:SetHeight(10)
    pinIcon:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    pinIcon:SetTexture("Interface\\AddOns\\MessageBox\\img\\pin.tga")
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
        local c = MessageBox.settings.textColor or {1, 1, 1, 1}
        this.text:SetTextColor(unpack(c)) 
    end)
    frame:Hide()
    
    return frame
end

function MessageBox:EnsureRows(scrollChild, rowTable, count)
    local current = table.getn(rowTable)
    if current < count then
        for i = current + 1, count do
            local row = self:CreateContactRow(MessageBox.contactFrame)
            table.insert(rowTable, row)
        end
    end
end

function MessageBox:CreateHeaderFrame(parent, onClickCallback)
    local header = CreateFrame("Button", nil, parent)
    header:SetWidth(120)
    header:SetHeight(20)
    header:SetScript("OnClick", onClickCallback)

    local plusButton = CreateFrame("Button", nil, header)
    plusButton:SetWidth(16)
    plusButton:SetHeight(16)
    plusButton:SetPoint("LEFT", 0, 0)
    plusButton:SetScript("OnClick", onClickCallback)
    
    plusButton.text = plusButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    plusButton.text:SetPoint("CENTER", 0, 1)
    plusButton.text:SetText("+")
    plusButton.text:Hide()

    local minusButton = CreateFrame("Button", nil, header)
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
            local c = MessageBox.settings.textColor or {1, 1, 1, 1}
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
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true, tileSize = 16,
        insets = {left = 0, right = 0, top = 0, bottom = -1}
    })
    header:SetBackdropColor(0, 0, 0, 0.3)

    local avatarBtn = CreateFrame("Button", nil, header)
    avatarBtn:SetWidth(36)
    avatarBtn:SetHeight(36)
    avatarBtn:SetPoint("LEFT", header, "LEFT", 8, 0)
    
    avatarBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
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
    
    local pinBtn = CreateFrame("Button", nil, header)
    pinBtn:SetWidth(16)
    pinBtn:SetHeight(16)
    pinBtn:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
    pinBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    
    pinBtn:SetScript("OnClick", function()
        if MessageBox.selectedContact then
            local c = MessageBox.conversations[MessageBox.selectedContact]
            if c then
                c.pinned = not c.pinned
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

    local infoText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    infoText:SetJustifyH("LEFT")
    infoText:SetTextColor(0.8, 0.8, 0.8)
    header.infoText = infoText

    local metaTopText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    metaTopText:SetPoint("TOPRIGHT", header, "TOPRIGHT", -10, -8)
    metaTopText:SetJustifyH("RIGHT")
    metaTopText:SetTextColor(0.7, 0.7, 0.7)
    header.metaTopText = metaTopText

    local metaBottomText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    metaBottomText:SetPoint("TOPRIGHT", metaTopText, "BOTTOMRIGHT", 0, -12)
    metaBottomText:SetJustifyH("RIGHT")
    metaBottomText:SetTextColor(0.5, 0.5, 0.5)
    header.metaBottomText = metaBottomText

    MessageBox.chatHeader = header
    return header
end

-- This only exists in GlueXML so we need to copy it over
local CLASS_ICON_TCOORDS = {
	["WARRIOR"]	= {0, 0.25, 0, 0.25},
	["MAGE"]	= {0.25, 0.49609375, 0, 0.25},
	["ROGUE"]	= {0.49609375, 0.7421875, 0, 0.25},
	["DRUID"]	= {0.7421875, 0.98828125, 0, 0.25},
	["HUNTER"]	= {0, 0.25, 0.25, 0.5},
	["SHAMAN"]	= {0.25, 0.49609375, 0.25, 0.5},
	["PRIEST"]	= {0.49609375, 0.7421875, 0.25, 0.5},
	["WARLOCK"]	= {0.7421875, 0.98828125, 0.25, 0.5},
	["PALADIN"]	= {0, 0.25, 0.5, 0.75}
}
function MessageBox:UpdateChatHeader()
    if not self.chatHeader then return end
    
    if not self.selectedContact then
        self.chatHeader.nameText:SetText("Whisper Conversation")
        self.chatHeader.infoText:SetText("Select a contact")
        self.chatHeader.avatarBtn:Hide()
        self.chatHeader.pinBtn:Hide()
        self.chatHeader.metaTopText:Hide()
        self.chatHeader.metaBottomText:Hide()
        return
    end

    self.chatHeader.avatarBtn:Show()
    self.chatHeader.pinBtn:Show()
    self.chatHeader.metaTopText:Show()
    self.chatHeader.metaBottomText:Show()

    local name = self.selectedContact
    local displayTitle = name
    
    local c = self.conversations[name]
    if c and c.pinned then
        self.chatHeader.pinBtn:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\pin-slash.tga")
    else
        self.chatHeader.pinBtn:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\pin.tga")
    end
    
    local cache = self.playerCache[name]
    
    if not cache then
         for i = 1, GetNumFriends() do
             local fName, fLevel, fClass, fArea, fConnected, fStatus = GetFriendInfo(i)
             if fName and string.lower(fName) == string.lower(name) then
                 cache = {
                     level = fLevel,
                     class = fClass,
                     zone = fArea,
                     status = fStatus
                 }
                 self.playerCache[name] = cache
                 break
             end
         end
    end

    if cache and cache.class then
        local color = RAID_CLASS_COLORS[string.upper(cache.class)]
        if color then
            displayTitle = string.format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, name)
        end
    end

    if cache and cache.status and cache.status ~= "" then
        displayTitle = displayTitle .. " |cffaaaaaa" .. cache.status .. "|r"
    end
    
    self.chatHeader.nameText:SetText(displayTitle)

    local infoString = ""
    local coords = {0, 0.25, 0, 0.25} 

    if cache then
        if cache.level and cache.level > 0 then
            infoString = "Level " .. cache.level
        else
            infoString = "Unknown Level"
        end
        
        if cache.zone and cache.zone ~= "" and cache.zone ~= "Unknown" then
             infoString = infoString .. " • " .. cache.zone
        end

        if cache.class and CLASS_ICON_TCOORDS[string.upper(cache.class)] then
            coords = CLASS_ICON_TCOORDS[string.upper(cache.class)]
            self.chatHeader.avatarBtn.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            self.chatHeader.avatarBtn.icon:SetTexCoord(unpack(coords))
        else
             self.chatHeader.avatarBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
             self.chatHeader.avatarBtn.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        end
    else
        infoString = "Offline or Unknown"
        self.chatHeader.avatarBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.chatHeader.avatarBtn.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    end
    
    self.chatHeader.infoText:SetText(infoString)

    local msgCount = 0
    local lastDateStr = "Never"
    
    if c and c.messages then
        msgCount = table.getn(c.messages)
        if msgCount > 0 then
            local lastTime = c.times[msgCount]
            if lastTime and type(lastTime) == "number" then
                lastDateStr = date("%d/%m/%y", lastTime)
            end
        end
    end
    
    self.chatHeader.metaTopText:SetText("Total Messages: " .. msgCount)
    self.chatHeader.metaBottomText:SetText("Last Messaged: " .. lastDateStr)
end

function MessageBox:CreateFrame()
    if MessageBox.frame then
        return
    end

    local frame = CreateFrame("Frame", "MessageBoxFrame", UIParent)
    frame:SetWidth(480)
    frame:SetHeight(350)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetResizable(true)
    frame:SetMinResize(480, 350)
    frame:SetMaxResize(1000, 800)
    frame:SetScript("OnMouseDown", function()
        frame:StartMoving()
        frame:SetFrameStrata("HIGH")
    end)
    frame:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
    frame:SetScript("OnSizeChanged", function() 
        MessageBox:UpdateContactList() 
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
    closeButton:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-outline.tga")
    closeButton:SetPushedTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
    closeButton:SetHighlightTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
    closeButton:SetAlpha(0.7)
    closeButton:SetScript("OnEnter", function() this:SetAlpha(1.0) end)
    closeButton:SetScript("OnLeave", function() this:SetAlpha(0.7) end)
    closeButton:SetScript("OnClick", function() MessageBox:HideFrame() end)
    MessageBox.closeButton = closeButton

    local dropDown = CreateFrame("Frame", "MessageBoxContextMenu", frame, "UIDropDownMenuTemplate")

    local contactFrame = CreateFrame("Frame", nil, frame)
    contactFrame:SetWidth(140)
    contactFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -26)
    contactFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 40)
    
    MessageBox.contactFrame = contactFrame

    local searchBox = CreateFrame("EditBox", "MessageBoxContactSearch", contactFrame, "InputBoxTemplate")
    searchBox:SetWidth(120)
    searchBox:SetHeight(20)
    searchBox:SetPoint("TOP", contactFrame, "TOP", 0, -6)
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
    end)
    MessageBox.friendsHeader.text:SetText("Friends")
    
    MessageBox.conversationsHeader = MessageBox:CreateHeaderFrame(contactFrame, function()
        MessageBox.settings.conversationsListCollapsed = not MessageBox.settings.conversationsListCollapsed
        MessageBox:UpdateContactList()
    end)
    MessageBox.conversationsHeader.text:SetText("Conversations")

    local friendsScroll = CreateFrame("ScrollFrame", "MessageBoxFriendsScroll", contactFrame, "FauxScrollFrameTemplate")
    friendsScroll:SetScript("OnVerticalScroll", function() 
        FauxScrollFrame_OnVerticalScroll(16, function() MessageBox:UpdateScrollViews() end) 
    end)
    MessageBox.friendsScroll = friendsScroll
    
    local convosScroll = CreateFrame("ScrollFrame", "MessageBoxConversationsScroll", contactFrame, "FauxScrollFrameTemplate")
    convosScroll:SetScript("OnVerticalScroll", function() 
        FauxScrollFrame_OnVerticalScroll(16, function() MessageBox:UpdateScrollViews() end) 
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
    resizeButton:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\sizegrabber-up.tga")
    resizeButton:SetPushedTexture("Interface\\AddOns\\MessageBox\\img\\sizegrabber-down.tga")
    resizeButton:SetHighlightTexture("Interface\\AddOns\\MessageBox\\img\\sizegrabber-highlight.tga")
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

    local chatHistory = CreateFrame("ScrollingMessageFrame", "MessageBoxChatHistory", chatFrame)
    chatHistory:SetPoint("TOPLEFT", MessageBox.chatHeader, "BOTTOMLEFT", 8, -10)
    chatHistory:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", -25, 43)
    
    chatHistory:SetFont("Interface\\AddOns\\MessageBox\\font\\OpenSans.ttf", MessageBox.settings.chatFontSize or 12, "OUTLINE")
    chatHistory:SetShadowOffset(1, -1)
    
    chatHistory:SetJustifyH("LEFT")
    chatHistory:SetMaxLines(500)
    chatHistory:SetFading(false)
    chatHistory:EnableMouseWheel(true)
    
    MessageBox.CHAT_DISPLAY_LIMIT = 100
    
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
        MessageBox:UpdateChatHistory()
    end)
    MessageBox.chatScrollBar = chatScrollBar
    
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
    themeButton:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\palette.tga")
    themeButton:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
    
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
    bellButton:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\bell-on.tga") 
    bellButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    
    bellButton.UpdateState = function()
        if MessageBox.settings.popupNotificationsEnabled then
            bellButton:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\bell-on.tga")
            bellButton:SetAlpha(1.0) 
            bellButton:GetNormalTexture():SetVertexColor(1, 1, 1) 
        else
            bellButton:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\bell-off-slash.tga")
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
    
    local settingsDropDown = CreateFrame("Frame", "MessageBoxSettingsDropDown", frame, "UIDropDownMenuTemplate")

    tinsert(UISpecialFrames, "MessageBoxFrame")
    MessageBox:UpdateContactList()
    MessageBox:ApplyTheme()
end

function MessageBox:UpdateContactList()
    if not MessageBox.contactFrame then return end
    
    local searchQuery = string.lower(MessageBox.searchQuery or "")
    local hideOffline = MessageBox.settings.hideOffline
    
    MessageBox.visibleFriends = {}
    for i = 1, GetNumFriends() do
        local name, level, class, area, connected, status = GetFriendInfo(i)
        if name then
            local matchesSearch = (searchQuery == "") or string.find(string.lower(name), searchQuery)
            local showContact = matchesSearch
            if hideOffline and not connected then showContact = false end
            
            if showContact then
                 if not MessageBox.playerCache[name] then MessageBox.playerCache[name] = {} end
                 MessageBox.playerCache[name].class = class
                 MessageBox.playerCache[name].level = level
                 MessageBox.playerCache[name].zone = area
                 MessageBox.playerCache[name].status = status
                 
                 table.insert(MessageBox.visibleFriends, {
                     name = name,
                     class = class,
                     connected = connected,
                     unread = MessageBox.unreadCounts[name] or 0
                 })
            end
        end
    end

    MessageBox.visibleConversations = {}
    if MessageBox.conversations then
        local sortedContacts = {}
        for contact, data in pairs(MessageBox.conversations) do
            if data and data.times and table.getn(data.times) > 0 then
                table.insert(sortedContacts, contact)
            end
        end
        table.sort(sortedContacts, function(a, b)
            local convoA = MessageBox.conversations[a]
            local convoB = MessageBox.conversations[b]
            local lastTimeA = convoA.times[table.getn(convoA.times)]
            local lastTimeB = convoB.times[table.getn(convoB.times)]
            if type(lastTimeA) ~= "number" then return false end
            if type(lastTimeB) ~= "number" then return true end
            return lastTimeA > lastTimeB
        end)
        
        for i = 1, table.getn(sortedContacts) do
            local contact = sortedContacts[i]
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
    
    MessageBox:UpdateScrollViews()
end

function MessageBox:UpdateScrollViews()
    if not MessageBox.contactFrame then return end

    local friendsCollapsed = MessageBox.settings.friendsListCollapsed
    local conversationsCollapsed = MessageBox.settings.conversationsListCollapsed
    
    local ROW_HEIGHT = 16
    local SEARCH_AREA_HEIGHT = 30
    local HEADER_HEIGHT = 20
    local PADDING = 10
    
    local containerHeight = MessageBox.contactFrame:GetHeight()
    local availableHeight = containerHeight - SEARCH_AREA_HEIGHT - (HEADER_HEIGHT * 2) - (PADDING * 2)
    
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
        convosHeight = availableHeight - friendsHeight - PADDING

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
        MessageBox.conversationsHeader.frame:SetPoint("TOPLEFT", MessageBox.friendsHeader.frame, "BOTTOMLEFT", 0, -PADDING)
    else
        MessageBox.conversationsHeader.frame:SetPoint("TOPLEFT", MessageBox.friendsScroll, "BOTTOMLEFT", 0, -PADDING)
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
        MessageBox.conversationsScroll:SetPoint("BOTTOM", MessageBox.contactFrame, "BOTTOM", 0, PADDING)
    end

    if not friendsCollapsed then
        local listSize = table.getn(MessageBox.visibleFriends)
        local numRows = math.ceil(friendsHeight / 16)
        
        MessageBox:EnsureRows(MessageBox.contactFrame, MessageBox.friendRows, numRows + 1)
        FauxScrollFrame_Update(MessageBoxFriendsScroll, listSize, numRows, 16)
        
        local offset = FauxScrollFrame_GetOffset(MessageBoxFriendsScroll)
        for i = 1, table.getn(MessageBox.friendRows) do
            local row = MessageBox.friendRows[i]
            if i <= numRows then
                local dataIndex = offset + i
                if dataIndex <= listSize then
                    local data = MessageBox.visibleFriends[dataIndex]
                    
                    local displayName = data.name
                    if data.class and RAID_CLASS_COLORS[string.upper(data.class)] then
                        local color = RAID_CLASS_COLORS[string.upper(data.class)]
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
                        local c = MessageBox.settings.textColor or {1, 1, 1, 1}
                        row.text:SetTextColor(unpack(c))
                    end
                    
                    row.pinIcon:Hide()

                    row.contactName = data.name
                    
                    row:SetPoint("TOPLEFT", MessageBox.friendsScroll, "TOPLEFT", 8, -((i-1)*16))
                    row:SetWidth(MessageBox.friendsScroll:GetWidth())
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
        
        local scrollHeight = MessageBox.conversationsScroll:GetHeight()
        if scrollHeight < 16 then scrollHeight = convosHeight end

        local numRows = math.ceil(scrollHeight / 16)
        
        MessageBox:EnsureRows(MessageBox.contactFrame, MessageBox.conversationRows, numRows + 1)
        FauxScrollFrame_Update(MessageBoxConversationsScroll, listSize, numRows, 16)
        
        local offset = FauxScrollFrame_GetOffset(MessageBoxConversationsScroll)
        for i = 1, table.getn(MessageBox.conversationRows) do
            local row = MessageBox.conversationRows[i]
            if i <= numRows then
                local dataIndex = offset + i
                if dataIndex <= listSize then
                    local data = MessageBox.visibleConversations[dataIndex]
                    
                    local displayName = data.name
                    local cache = MessageBox.playerCache[data.name]
                    if cache and cache.class and RAID_CLASS_COLORS[string.upper(cache.class)] then
                        local color = RAID_CLASS_COLORS[string.upper(cache.class)]
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
                        local c = MessageBox.settings.textColor or {1, 1, 1, 1}
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
    local hasUnread = MessageBox.unreadCounts and MessageBox.unreadCounts[contact] and MessageBox.unreadCounts[contact] > 0
    if not contact then return end
    
    local unreadToPass = 0
    if MessageBox.unreadCounts and MessageBox.unreadCounts[contact] then
        unreadToPass = MessageBox.unreadCounts[contact]
    end

    if unreadToPass > 0 then
        local c = MessageBox.conversations[contact]
        if c and c.messages then
            MessageBox.currentSplitIndex = table.getn(c.messages) - unreadToPass + 1
        end
    else
        MessageBox.currentSplitIndex = 0
    end

    MessageBox.selectedContact = contact
    
    if not MessageBox.conversations[contact] then 
        MessageBox.conversations[contact] = {
            messages = {},
            times = {},
            outgoing = {},
            system = {},
            pinned = false
        }
    end
    
    MessageBox:UpdateChatHeader()
    
    if MessageBox.unreadCounts then MessageBox.unreadCounts[contact] = 0 end
    MessageBox:UpdateMinimapBadge()
    MessageBox:UpdateContactList()
    
    MessageBox:UpdateChatHistory(unreadToPass, true)
    
    if MessageBox.whisperInput then
        MessageBox.whisperInput:SetFocus()
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

    if not MessageBox.selectedContact or not MessageBox.chatHistory then return end
    
    local c = self.conversations[self.selectedContact]
    if not c or not c.messages then return end
    
    MessageBox.chatHistory:Clear()
    
    local totalMessages = table.getn(c.messages)
    
    if totalMessages == 0 then
        if MessageBox.chatScrollBar then
            MessageBox.chatScrollBar:Hide()
        end
        return
    end
    
    local displayLimit = MessageBox.CHAT_DISPLAY_LIMIT or 100
    
    local anchorIndex = totalMessages
    
    if not resetToBottom and MessageBox.chatScrollBar and MessageBox.chatScrollBar:IsVisible() then
        local val = MessageBox.chatScrollBar:GetValue()
        if val > totalMessages then val = totalMessages end
        if val < 1 then val = 1 end
        anchorIndex = val
    end
    
    local startIndex = anchorIndex - displayLimit
    if startIndex < 1 then startIndex = 1 end
    
    local splitIndex = 0
    if unreadCount and unreadCount > 0 then
        splitIndex = totalMessages - unreadCount + 1
    end

    local lastMessageDate = nil
    local timeFmt = MessageBox.settings.use12HourFormat and "%I:%M %p" or "%H:%M"
    
    for i = startIndex, anchorIndex do
        if i == splitIndex then
            MessageBox.chatHistory:AddMessage(" ")
            MessageBox.chatHistory:AddMessage("|cff888888------------------------------ New Messages ------------------------------|r")
            MessageBox.chatHistory:AddMessage(" ")
        end

        local msg = c.messages[i]
        local timeVal = c.times[i]
        local isOutgoing = c.outgoing[i]
        local isSystem = c.system[i]
        
        local formattedMessage, timeString
        
        if type(timeVal) == "number" then
            local currentMessageDate = date("%Y%m%d", timeVal)
            if lastMessageDate ~= currentMessageDate then
                if lastMessageDate ~= nil then MessageBox.chatHistory:AddMessage(" ") end
                local dateText = "|cff666666— " .. date("%A, %B %d", timeVal) .. " —|r"
                MessageBox.chatHistory:AddMessage(dateText)
                lastMessageDate = currentMessageDate
            end
            timeString = "|cff808080[" .. date(timeFmt, timeVal) .. "]|r"
        else
            timeString = "|cff808080[" .. tostring(timeVal) .. "]|r"
        end

        if isSystem then
            formattedMessage = string.format("%s %s%s|r", timeString, "|cffffcc00", msg)
        else
            local cleanMessage = MessageBox:HandleLink(msg)
            local nameColor = isOutgoing and "|cff8080ff" or "|cffff80ff"
            local name = isOutgoing and "You" or MessageBox.selectedContact
            formattedMessage = string.format("%s %s%s:|r %s%s|r", timeString, nameColor, name, "|cffffffff", cleanMessage)
        end
        MessageBox.chatHistory:AddMessage(formattedMessage)
    end
    
    MessageBox.chatHistory:ScrollToBottom()
    
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

    local isOnline = MessageBox:IsPlayerOnline(MessageBox.selectedContact)
    if isOnline == false then
        MessageBox:AddSystemMessage(MessageBox.selectedContact, MessageBox.selectedContact .. " is offline.", true)
        MessageBox.whisperInput:SetText("")
        return
    end

    MessageBox:AddMessage(MessageBox.selectedContact, message, true)
    SendChatMessage(message, "WHISPER", nil, MessageBox.selectedContact)
    
    MessageBox.whisperInput:SetText("")
    MessageBox.whisperInput:SetScript("OnUpdate", function()
        this:SetText("")
        this:SetScript("OnUpdate", nil)
    end)

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

function MessageBox:ShowFrame()
    if not self.frame then self:CreateFrame() end
    self.frame:Show()
    self:HideNotificationPopup() 
    self:UpdateContactList()
    if self.selectedContact then 
        self:UpdateChatHeader()
        self:UpdateChatHistory() 
    end
    if self.whisperInput then self.whisperInput:SetFocus() end
end

function MessageBox:HideFrame()
    if self.frame then self.frame:Hide() end
end

function MessageBox:ToggleFrame()
    if self.frame and self.frame:IsVisible() then self:HideFrame() else self:ShowFrame() end
end

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
    title:SetPoint("TOP", 0, -8)
    
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

    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetWidth(18)
    closeBtn:SetHeight(18)
    closeBtn:SetPoint("TOPRIGHT", -6, -5)
    closeBtn:SetNormalTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-outline.tga")
    closeBtn:SetPushedTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
    closeBtn:SetHighlightTexture("Interface\\AddOns\\MessageBox\\img\\rectangle-xmark-solid.tga")
    closeBtn:SetAlpha(0.7)
    closeBtn:SetScript("OnEnter", function() this:SetAlpha(1.0) end)
    closeBtn:SetScript("OnLeave", function() this:SetAlpha(0.7) end)
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
    history:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -26)
    history:SetPoint("BOTTOMRIGHT", inputBackdrop, "TOPRIGHT", -22, 5)
    
    history:SetFont("Interface\\AddOns\\MessageBox\\font\\OpenSans.ttf", MessageBox.settings.chatFontSize or 12, "OUTLINE")
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
    track:SetPoint("TOP", sb, "TOP", 0, 16)
    track:SetPoint("BOTTOM", sb, "BOTTOM", 0, -16)
    track:SetWidth(4)
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

function MessageBox:ApplyChatFontSize()
    local size = self.settings.chatFontSize or 12
    local font = "Interface\\AddOns\\MessageBox\\font\\OpenSans.ttf"
    
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
                if win.UpdateDisplay then win:UpdateDisplay() end -- Refresh content
            end
        end
    end
end
