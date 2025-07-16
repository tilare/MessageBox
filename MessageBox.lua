MessageBox = {}
MessageBox.conversations = {}
MessageBox.settings = {}
MessageBox.unreadCounts = {}
MessageBox.transientMessages = {}

MessageBox.contactFramePool = {}
MessageBox.activeContactFrames = {}

function MessageBox:OnLoad()
    if not MessageBoxSavedData then
        MessageBoxSavedData = {}
    end
    if not MessageBoxSettings then
        MessageBoxSettings = {}
    end

    MessageBox.transientMessages = {}

    this:RegisterEvent("CHAT_MSG_WHISPER")
    this:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
    this:RegisterEvent("PLAYER_LOGIN")
    this:RegisterEvent("FRIENDLIST_UPDATE")
    this:RegisterEvent("CHAT_MSG_SYSTEM")

    SLASH_MESSAGEBOX1 = "/messagebox"
    SLASH_MESSAGEBOX2 = "/mb"
    SLASH_MESSAGEBOX3 = "/mbox"
    SlashCmdList["MESSAGEBOX"] = function(msg)
        MessageBox:ToggleFrame()
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff[|cff00ff00MessageBox|cffffffff]|r loaded! Use /messagebox, /mb, or /mbox to open.")
end

function MessageBox:OnEvent(event)
    if event == "PLAYER_LOGIN" then
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        local characterKey = playerName .. "-" .. realmName

        if not MessageBoxSavedData[characterKey] then
            MessageBoxSavedData[characterKey] = {}
        end
        MessageBox.conversations = MessageBoxSavedData[characterKey]
        MessageBox.transientMessages = {}

        local defaultSettings = {
            friendsListCollapsed = false,
            conversationsListCollapsed = false,
            unreadCounts = {}
        }
        if not MessageBoxSettings[characterKey] then
            MessageBoxSettings[characterKey] = defaultSettings
        end
        for key, value in pairs(defaultSettings) do
            if MessageBoxSettings[characterKey][key] == nil then
                MessageBoxSettings[characterKey][key] = value
            end
        end
        MessageBox.settings = MessageBoxSettings[characterKey]
        MessageBox.unreadCounts = MessageBox.settings.unreadCounts

    elseif event == "CHAT_MSG_WHISPER" then
        -- Incoming whisper
        local message = arg1
        local sender = arg2
        MessageBox:AddMessage(sender, message, false)

    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local message = arg1
        local recipient = arg2

        local conversation = MessageBox.conversations[recipient]
        if conversation and table.getn(conversation) > 0 then
            local lastMessage = conversation[table.getn(conversation)]
            if lastMessage.outgoing and lastMessage.message == message then
                return
            end
        end
        
        MessageBox:AddMessage(recipient, message, true)
        
    elseif event == "CHAT_MSG_SYSTEM" then
        local sysMessage = arg1
        local _, _, playerName = string.find(sysMessage, "No player named '(.+)' is currently playing.")
        
        if playerName then
            local conversation = MessageBox.conversations[playerName]
            if conversation and table.getn(conversation) > 0 then
                local lastMessage = conversation[table.getn(conversation)]
                
                if lastMessage.outgoing then
                    MessageBox:RemoveLastMessage(playerName)
                    MessageBox:AddSystemMessage(playerName, playerName .. " is offline.", true)
                end
            end
        end

    elseif event == "FRIENDLIST_UPDATE" then
        -- Update contact list when friend list changes
        if MessageBox.frame and MessageBox.frame:IsVisible() then
            MessageBox:UpdateContactList()
        end
    end
end

function MessageBox:GetContactFrame()
    if table.getn(MessageBox.contactFramePool) > 0 then
        local frame = table.remove(MessageBox.contactFramePool)
        frame:Show()
        return frame
    else
        local frame = CreateFrame("Frame", nil, MessageBox.contactList)
        frame:SetWidth(105)
        frame:SetHeight(16)
        frame:EnableMouse(true)
        
        local statusIcon = frame:CreateFontString(nil, "ARTWORK")
        statusIcon:SetFont("Fonts\\FRIZQT__.TTF", 16)
        statusIcon:SetPoint("LEFT", frame, "LEFT", -5, -2)
        frame.statusIcon = statusIcon
        
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", statusIcon, "RIGHT", 3, 1)
        frame.text = text
        
        return frame
    end
end

function MessageBox:ReturnContactFrame(frame)
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetScript("OnMouseDown", nil)
    frame:SetScript("OnEnter", nil)
    frame:SetScript("OnLeave", nil)
    frame.contactName = nil
    frame.statusIcon:SetText("")
    frame.statusIcon:SetTextColor(1, 1, 1)
    table.insert(MessageBox.contactFramePool, frame)
end

function MessageBox:ClearActiveContactFrames()
    for i = 1, table.getn(MessageBox.activeContactFrames) do
        MessageBox:ReturnContactFrame(MessageBox.activeContactFrames[i])
    end
    MessageBox.activeContactFrames = {}
end

-- Check if a player is online by checking friends list
function MessageBox:IsPlayerOnline(playerName)
    local numFriends = GetNumFriends()
    for i = 1, numFriends do
        local name, _, _, _, connected = GetFriendInfo(i)
        if name and string.lower(name) == string.lower(playerName) then
            return connected
        end
    end
    return nil
end

function MessageBox:AddMessage(contact, message, isOutgoing)
    if not MessageBox.conversations then return end

    if not MessageBox.conversations[contact] then
        MessageBox.conversations[contact] = {}
    end

    local entry = {
        message = message,
        time = time(),
        outgoing = isOutgoing
    }

    table.insert(MessageBox.conversations[contact], entry)

    -- For incoming message, increase unread count
    if not isOutgoing then
        if (not MessageBox.frame or not MessageBox.frame:IsVisible()) or (MessageBox.selectedContact ~= contact) then
            if not MessageBox.unreadCounts[contact] then
                MessageBox.unreadCounts[contact] = 0
            end
            MessageBox.unreadCounts[contact] = MessageBox.unreadCounts[contact] + 1
        end
    end

    if MessageBox.frame and MessageBox.frame:IsVisible() then
        MessageBox:UpdateContactList()
        
        if MessageBox.selectedContact == contact then
            MessageBox:UpdateChatHistory()
        end
    end
end

-- Add a system message. Can be persistent or transient.
function MessageBox:AddSystemMessage(contact, message, isTransient)
    local targetTableContainer
    if isTransient then
        targetTableContainer = self.transientMessages
    else
        targetTableContainer = self.conversations
    end

    if not targetTableContainer[contact] then
        targetTableContainer[contact] = {}
    end

    local entry = {
        message = message,
        time = time(),
        system = true
    }

    table.insert(targetTableContainer[contact], entry)

    if self.frame and self.frame:IsVisible() and self.selectedContact == contact then
        self:UpdateChatHistory()
    end
end

function MessageBox:RemoveLastMessage(contact)
    if not self.conversations or not self.conversations[contact] then return end
    
    local conversation = self.conversations[contact]
    if table.getn(conversation) > 0 then
        table.remove(conversation)
    end
end

function MessageBox:CreateHeaderFrame(parent, onClickCallback)
    local header = CreateFrame("Button", nil, parent)
    header:SetWidth(120)
    header:SetHeight(20)
    header:SetScript("OnClick", onClickCallback)
    header:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

    local plusButton = CreateFrame("Button", nil, header)
    plusButton:SetWidth(16)
    plusButton:SetHeight(16)
    plusButton:SetPoint("LEFT", 0, 0)
    plusButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    plusButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
    plusButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Highlight")
    plusButton:SetScript("OnClick", onClickCallback)

    local minusButton = CreateFrame("Button", nil, header)
    minusButton:SetWidth(16)
    minusButton:SetHeight(16)
    minusButton:SetPoint("LEFT", 0, 0)
    minusButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    minusButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    minusButton:SetHighlightTexture("Interface\\Buttons\\UI-MinusButton-Highlight")
    minusButton:SetScript("OnClick", onClickCallback)
    
    local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerText:SetPoint("LEFT", plusButton, "RIGHT", 2, 0)
    headerText:SetTextColor(1, 1, 0)
    
    return {
        frame = header,
        plusButton = plusButton,
        minusButton = minusButton,
        text = headerText
    }
end

-- Main frame
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
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function()
        frame:StartMoving()
        frame:SetFrameStrata("HIGH")
    end)
    frame:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
    frame:Hide()

    MessageBox.frame = frame

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("MessageBox")

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() MessageBox:HideFrame() end)

    -- Contact list frame
    local contactFrame = CreateFrame("Frame", nil, frame)
    contactFrame:SetWidth(140)
    contactFrame:SetHeight(280)
    contactFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    contactFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    contactFrame:SetBackdropColor(0, 0, 0, 0.8)

    local contactTitle = contactFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    contactTitle:SetPoint("TOP", contactFrame, "TOP", 0, -10)
    contactTitle:SetText("Contacts")

    local contactScroll = CreateFrame("ScrollFrame", "MessageBoxContactScroll", contactFrame)
    contactScroll:SetPoint("TOPLEFT", contactFrame, "TOPLEFT", 8, -30)
    contactScroll:SetPoint("BOTTOMRIGHT", contactFrame, "BOTTOMRIGHT", -8, 8)

    -- Enable mouse wheel scrolling
    contactScroll:EnableMouseWheel(true)
    contactScroll:SetScript("OnMouseWheel", function()
        local scrollStep = 18
        local currentOffset = this:GetVerticalScroll()
        local newOffset

        if arg1 > 0 then
            newOffset = currentOffset - scrollStep
        else
            newOffset = currentOffset + scrollStep
        end

        local maxScroll = this:GetVerticalScrollRange()
        if newOffset < 0 then
            newOffset = 0
        elseif newOffset > maxScroll then
            newOffset = maxScroll
        end

        this:SetVerticalScroll(newOffset)
    end)

    local contactContent = CreateFrame("Frame", nil, contactScroll)
    contactContent:SetWidth(110)
    contactContent:SetHeight(1)
    contactScroll:SetScrollChild(contactContent)

    MessageBox.contactList = contactContent

    MessageBox.friendsHeader = MessageBox:CreateHeaderFrame(MessageBox.contactList, function()
        MessageBox.settings.friendsListCollapsed = not MessageBox.settings.friendsListCollapsed
        MessageBox:UpdateContactList()
    end)
    MessageBox.friendsHeader.text:SetText("Friends")
    
    MessageBox.conversationsHeader = MessageBox:CreateHeaderFrame(MessageBox.contactList, function()
        MessageBox.settings.conversationsListCollapsed = not MessageBox.settings.conversationsListCollapsed
        MessageBox:UpdateContactList()
    end)
    MessageBox.conversationsHeader.text:SetText("Conversations")

    local chatFrame = CreateFrame("Frame", nil, frame)
    chatFrame:SetWidth(305)
    chatFrame:SetHeight(280)
    chatFrame:SetPoint("TOPLEFT", contactFrame, "TOPRIGHT", 5, 0)
    chatFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    chatFrame:SetBackdropColor(0, 0, 0, 0.8)

    local chatTitle = chatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatTitle:SetPoint("TOP", chatFrame, "TOP", 0, -10)
    chatTitle:SetText("Whisper Conversation")
    MessageBox.chatTitle = chatTitle

    local chatHistory = CreateFrame("ScrollingMessageFrame", "MessageBoxChatHistory", chatFrame)
    chatHistory:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", 8, -30)
    chatHistory:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", -8, 40)
    chatHistory:SetFontObject(GameFontNormalSmall)
    chatHistory:SetJustifyH("LEFT")
    chatHistory:SetMaxLines(100)
    chatHistory:SetFading(false)
    chatHistory:EnableMouseWheel(true)
    chatHistory:SetScript("OnMouseWheel", function()
        if arg1 > 0 then
            this:ScrollUp()
        else
            this:ScrollDown()
        end
    end)

    MessageBox.chatHistory = chatHistory

    MessageBox.tempFontString = chatHistory:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    MessageBox.tempFontString:Hide()

    -- Whisper input box
    local whisperInput = CreateFrame("EditBox", "MessageBoxWhisperInput", chatFrame, "InputBoxTemplate")
    whisperInput:SetWidth(215)
    whisperInput:SetHeight(20)
    whisperInput:SetPoint("BOTTOMLEFT", chatFrame, "BOTTOMLEFT", 15, 10)
    whisperInput:SetAutoFocus(false)
    whisperInput:SetScript("OnEnterPressed", function()
        MessageBox:SendWhisper()
    end)
    whisperInput:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    MessageBox.whisperInput = whisperInput

    -- Send button
    local sendButton = CreateFrame("Button", nil, chatFrame, "UIPanelButtonTemplate")
    sendButton:SetWidth(60)
    sendButton:SetHeight(20)
    sendButton:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", -10, 10)
    sendButton:SetText("Send")
    sendButton:SetScript("OnClick", function() MessageBox:SendWhisper() end)

    -- Delete button
    local deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteButton:SetWidth(80)
    deleteButton:SetHeight(20)
    deleteButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 12)
    deleteButton:SetText("Delete")
    deleteButton:SetScript("OnClick", function() MessageBox:ShowDeleteConfirmation() end)
    MessageBox.deleteButton = deleteButton

    -- Delete All button
    local deleteAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteAllButton:SetWidth(80)
    deleteAllButton:SetHeight(20)
    deleteAllButton:SetPoint("LEFT", deleteButton, "RIGHT", 5, 0)
    deleteAllButton:SetText("Delete All")
    deleteAllButton:SetScript("OnClick", function() MessageBox:ShowDeleteAllConfirmation() end)

    -- Make frame closable with ESC
    tinsert(UISpecialFrames, "MessageBoxFrame")

    MessageBox:UpdateContactList()
end

function MessageBox:UpdateContactList()
    if not MessageBox.contactList then 
        return 
    end

    MessageBox:ClearActiveContactFrames()

    local yOffset = 0

    local friendsCollapsed = MessageBox.settings.friendsListCollapsed
    local conversationsCollapsed = MessageBox.settings.conversationsListCollapsed

    MessageBox.friendsHeader.frame:SetPoint("TOPLEFT", MessageBox.contactList, "TOPLEFT", 5, yOffset)
    MessageBox.friendsHeader.frame:Show()
    
    if friendsCollapsed then
        MessageBox.friendsHeader.plusButton:Show()
        MessageBox.friendsHeader.minusButton:Hide()
    else
        MessageBox.friendsHeader.plusButton:Hide()
        MessageBox.friendsHeader.minusButton:Show()
    end
    
    yOffset = yOffset - 20

    if not friendsCollapsed then
        local numFriends = GetNumFriends()
        for i = 1, numFriends do
            local name, _, _, _, connected = GetFriendInfo(i)
            if name then
                local friendFrame = MessageBox:GetContactFrame()
                friendFrame:SetPoint("TOPLEFT", MessageBox.contactList, "TOPLEFT", 10, yOffset)
                
                local displayText = name
                if MessageBox.unreadCounts[name] and MessageBox.unreadCounts[name] > 0 then
                    displayText = name .. " |cffff80ff[" .. MessageBox.unreadCounts[name] .. "]|r"
                end
                friendFrame.text:SetText(displayText)

                -- Set color of the status icon
                local onlineColor = {0, 1, 0} -- Green
                local offlineColor = {0.5, 0.5, 0.5} -- Grey
                local statusColor = connected and onlineColor or offlineColor
                friendFrame.statusIcon:SetText("•")
                friendFrame.statusIcon:SetTextColor(unpack(statusColor))
                friendFrame.text:SetTextColor(1, 1, 1)

                friendFrame.contactName = name
                
                friendFrame:SetScript("OnMouseDown", function()
                    MessageBox:SelectContact(this.contactName)
                end)

                friendFrame:SetScript("OnEnter", function()
                    this.text:SetTextColor(1, 0.82, 0) -- Gold
                end)
                friendFrame:SetScript("OnLeave", function()
                    this.text:SetTextColor(1, 1, 1) -- White
                end)

                table.insert(MessageBox.activeContactFrames, friendFrame)
                yOffset = yOffset - 18
            end
        end
    end

    MessageBox.conversationsHeader.frame:SetPoint("TOPLEFT", MessageBox.contactList, "TOPLEFT", 5, yOffset)
    MessageBox.conversationsHeader.frame:Show()
    
    if conversationsCollapsed then
        MessageBox.conversationsHeader.plusButton:Show()
        MessageBox.conversationsHeader.minusButton:Hide()
    else
        MessageBox.conversationsHeader.plusButton:Hide()
        MessageBox.conversationsHeader.minusButton:Show()
    end
    
    yOffset = yOffset - 20

    if not conversationsCollapsed then
        if MessageBox.conversations then
            for contact, messages in pairs(MessageBox.conversations) do
                if messages and table.getn(messages) > 0 then
                    local contactFrame = MessageBox:GetContactFrame()
                    contactFrame:SetPoint("TOPLEFT", MessageBox.contactList, "TOPLEFT", 10, yOffset)

                    local displayText = contact
                    if MessageBox.unreadCounts[contact] and MessageBox.unreadCounts[contact] > 0 then
                        displayText = contact .. " |cffff80ff[" .. MessageBox.unreadCounts[contact] .. "]|r"
                    end
                    contactFrame.text:SetText(displayText)

                    -- Set color of the status icon
                    local isOnline = MessageBox:IsPlayerOnline(contact)
                    local statusColor
                    if isOnline == true then
                        statusColor = {0, 1, 0}  -- Green for online
                    elseif isOnline == false then
                        statusColor = {0.5, 0.5, 0.5}  -- Grey for offline
                    else
                        statusColor = {0.5, 0, 0.5}  -- Purple for unknown status
                    end
                    
                    contactFrame.statusIcon:SetText("•")
                    contactFrame.statusIcon:SetTextColor(unpack(statusColor))
                    contactFrame.text:SetTextColor(1, 1, 1)
                    contactFrame.contactName = contact
                    
                    contactFrame:SetScript("OnMouseDown", function()
                        MessageBox:SelectContact(this.contactName)
                    end)

                    contactFrame:SetScript("OnEnter", function()
                        this.text:SetTextColor(1, 0.82, 0) -- Gold
                    end)
                    contactFrame:SetScript("OnLeave", function()
                        this.text:SetTextColor(1, 1, 1) -- White
                    end)

                    table.insert(MessageBox.activeContactFrames, contactFrame)
                    yOffset = yOffset - 18
                end
            end
        end
    end
    
    MessageBox.contactList:SetHeight(math.abs(yOffset) + 20)
    MessageBoxContactScroll:UpdateScrollChildRect()
end

function MessageBox:SelectContact(contact)
    if not contact or (MessageBox.selectedContact == contact and MessageBox.frame and MessageBox.frame:IsVisible()) then return end
    MessageBox.selectedContact = contact
    MessageBox.chatTitle:SetText("Whisper Conversation - " .. contact)
    if not MessageBox.conversations[contact] then MessageBox.conversations[contact] = {} end
    if MessageBox.unreadCounts then MessageBox.unreadCounts[contact] = 0 end
    MessageBox:UpdateContactList()
    MessageBox:UpdateChatHistory()
end

function MessageBox:GetCenteredString(text)
    if not self.tempFontString then return text end

    self.tempFontString:SetText(text)
    local textWidth = self.tempFontString:GetStringWidth()

    self.tempFontString:SetText(" ")
    local spaceWidth = self.tempFontString:GetStringWidth()

    local chatHistoryWidth = MessageBox.chatHistory:GetWidth()

    if textWidth >= chatHistoryWidth or spaceWidth <= 0 then
        return text
    end

    local paddingRequired = (chatHistoryWidth - textWidth) / 2
    local numSpaces = math.max(0, math.floor(paddingRequired / spaceWidth))

    local padding = string.rep(" ", numSpaces)

    return padding .. text
end

function MessageBox:UpdateChatHistory()
    if not MessageBox.selectedContact or not MessageBox.chatHistory then return end

    MessageBox.chatHistory:Clear()
    MessageBox.chatHistory:SetJustifyH("LEFT")

    local persistentMessages = self.conversations[self.selectedContact] or {}
    local transientMessages = self.transientMessages[self.selectedContact] or {}
    local allMessages = {}
    for i = 1, table.getn(persistentMessages) do
        table.insert(allMessages, persistentMessages[i])
    end
    for i = 1, table.getn(transientMessages) do
        table.insert(allMessages, transientMessages[i])
    end

    if table.getn(allMessages) == 0 then
        return
    end

    -- Sort all messages by time
    table.sort(allMessages, function(a, b)
        if type(a.time) ~= "number" or type(b.time) ~= "number" then
            -- This ensures sorting doesn't error if old/bad data exists
            return type(a.time) == "number"
        end
        return a.time < b.time
    end)

    local lastMessageDate = nil

    for i = 1, table.getn(allMessages) do
        local msg = allMessages[i]
        local formattedMessage
        local timeString

        if type(msg.time) == "number" then
            -- Check if the date has changed since the last message
            local currentMessageDate = date("%Y%m%d", msg.time)
            if lastMessageDate ~= currentMessageDate then
                if lastMessageDate ~= nil then
                    MessageBox.chatHistory:AddMessage(" ")
                end

                local dateText = date("%m/%d/%Y", msg.time)
                local centeredDateText = MessageBox:GetCenteredString(dateText)
                local dateHeaderString = "|cff808080" .. centeredDateText .. "|r"
                
                MessageBox.chatHistory:AddMessage(dateHeaderString)

                lastMessageDate = currentMessageDate
            end

            timeString = "|cff808080[" .. date("%H:%M:%S", msg.time) .. "]|r"
        else
            timeString = "|cff808080[" .. msg.time .. "]|r"
        end

        if msg.system then
            local systemColor = "|cffffcc00" -- Yellow for system text
            formattedMessage = string.format("%s %s%s|r", timeString, systemColor, msg.message)
        else
            local nameColor = msg.outgoing and "|cff8080ff" or "|cffff80ff"
            local name = msg.outgoing and "You" or MessageBox.selectedContact
            local messageColor = "|cffffffff"
            formattedMessage = string.format("%s %s%s:|r %s%s|r", timeString, nameColor, name, messageColor, msg.message)
        end

        MessageBox.chatHistory:AddMessage(formattedMessage)
    end

    MessageBox.chatHistory:ScrollToBottom()
end


-- Send a whisper from the input box
function MessageBox:SendWhisper()
    if not MessageBox.selectedContact or not MessageBox.whisperInput then return end
    local message = MessageBox.whisperInput:GetText()
    if message == "" then return end
    
    local isOnline = MessageBox:IsPlayerOnline(MessageBox.selectedContact)
    if isOnline == false then
        MessageBox:AddSystemMessage(MessageBox.selectedContact, MessageBox.selectedContact .. " is offline.", true)
        MessageBox.whisperInput:SetText("")
        MessageBox.whisperInput:ClearFocus()
        return
    end

    MessageBox:AddMessage(MessageBox.selectedContact, message, true)
    SendChatMessage(message, "WHISPER", nil, MessageBox.selectedContact)
    
    MessageBox.whisperInput:SetText("")
    MessageBox.whisperInput:ClearFocus()
end

StaticPopupDialogs["MB_DELETE_CONVO"] = {
    text = "Are you sure you want to delete this conversation with %s?",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
        MessageBox:ConfirmDelete()
    end,
    showAlert = 1,
    timeout = 0,
    hideOnEscape = 1
}

StaticPopupDialogs["MB_DELETE_ALL"] = {
    text = "Are you sure you want to delete ALL conversations for this character?\n\n|cffff0000This cannot be undone.|r",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
        MessageBox:ConfirmDeleteAll()
    end,
    showAlert = 1,
    timeout = 0,
    hideOnEscape = 1
}

-- Show confirmation dialog for single delete
function MessageBox:ShowDeleteConfirmation()
    if not MessageBox.selectedContact then 
        DEFAULT_CHAT_FRAME:AddMessage("|cffffffff[|cff00ff00MessageBox|cffffffff]|r No conversation selected.")
        return 
    end
    StaticPopup_Show("MB_DELETE_CONVO", MessageBox.selectedContact)
end

-- Show confirmation dialog for deleting all
function MessageBox:ShowDeleteAllConfirmation()
    StaticPopup_Show("MB_DELETE_ALL")
end

-- Confirm and delete single conversation
function MessageBox:ConfirmDelete()
    if not self.selectedContact then return end
    local deletedContact = self.selectedContact
    self.conversations[self.selectedContact] = nil
    self.transientMessages[self.selectedContact] = nil
    if self.unreadCounts then self.unreadCounts[self.selectedContact] = nil end
    self.selectedContact = nil
    if self.chatTitle then
        self.chatTitle:SetText("Whisper Conversation")
    end
    self:UpdateContactList()
    self:UpdateChatHistory()
    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff[|cff00ff00MessageBox|cffffffff]|r Conversation with " .. deletedContact .. " deleted.")
end

-- Confirm and delete ALL conversations for the current character
function MessageBox:ConfirmDeleteAll()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local characterKey = playerName .. "-" .. realmName

    MessageBoxSavedData[characterKey] = {}
    MessageBox.conversations = MessageBoxSavedData[characterKey]
    MessageBox.transientMessages = {}
    MessageBoxSettings[characterKey].unreadCounts = {}
    MessageBox.unreadCounts = MessageBoxSettings[characterKey].unreadCounts

    self.selectedContact = nil
    if self.chatTitle then
        self.chatTitle:SetText("Whisper Conversation")
    end
    self:UpdateContactList()
    self:UpdateChatHistory()
    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff[|cff00ff00MessageBox|cffffffff]|r All conversations for this character have been deleted.")
end

function MessageBox:ShowFrame()
    if not self.frame then 
        self:CreateFrame() 
    end
    
    self:UpdateContactList()
    
    if self.selectedContact then 
        self:UpdateChatHistory() 
    end
    
    self.frame:Show()
end

function MessageBox:HideFrame()
    if self.frame then self.frame:Hide() end
end

function MessageBox:ToggleFrame()
    if self.frame and self.frame:IsVisible() then self:HideFrame() else self:ShowFrame() end
end
