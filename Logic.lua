-- Logic.lua
-- Who lookups, Hooks, Message storage

-- Who lookups
function MessageBox:AddToWhoQueue(name)
    if not MessageBox.settings.backgroundWho then return end
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].class and MessageBox.playerCache[name].guild ~= nil then return end
    local nameLower = string.lower(name)
    for _, entry in ipairs(MessageBox.whoQueue) do
        if string.lower(entry.name) == nameLower then return end
    end
    -- Cap queue size
    if table.getn(MessageBox.whoQueue) >= MessageBox.WHO_QUEUE_MAX then
        table.remove(MessageBox.whoQueue, 1)
    end
    table.insert(MessageBox.whoQueue, { name = name, nameLower = nameLower, attempts = 0 })
end

function MessageBox:ProcessWhoQueue()
    if not MessageBox.settings.backgroundWho then return end
    
    local now = GetTime()
    
    -- Timeout: if we've been waiting too long for a WHO result, reset
    if MessageBox.waitingForWhoResult then
        if (now - MessageBox.waitingForWhoSince) > MessageBox.WHO_TIMEOUT then
            -- Re-queue the entry if it has attempts left
            if MessageBox.currentWhoEntry then
                MessageBox.currentWhoEntry.attempts = MessageBox.currentWhoEntry.attempts + 1
                if MessageBox.currentWhoEntry.attempts < 5 then
                    table.insert(MessageBox.whoQueue, MessageBox.currentWhoEntry)
                end
            end
            MessageBox.waitingForWhoResult = false
            MessageBox.currentWhoEntry = nil
            -- Reset the cooldown timer so it doesnt immediately fire again
            MessageBox.whoTimer = now
        end
        return
    end
    
    if table.getn(MessageBox.whoQueue) == 0 then return end
    if FriendsFrame and FriendsFrame:IsVisible() then return end
    if WhoFrame and WhoFrame:IsVisible() then return end
    
    if (now - MessageBox.whoTimer) < MessageBox.WHO_INTERVAL then return end
    
    local entry = MessageBox.whoQueue[1]
    local name = entry.name
    
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].class and MessageBox.playerCache[name].guild ~= nil then 
        table.remove(MessageBox.whoQueue, 1)
        return 
    end
    
    table.remove(MessageBox.whoQueue, 1)
    
    MessageBox.whoTimer = now
    MessageBox.waitingForWhoResult = true
    MessageBox.waitingForWhoSince = now
    MessageBox.currentWhoEntry = entry
    SendWho("n-" .. name)
end

function MessageBox:HandleWhoResult()
    if not MessageBox.waitingForWhoResult then return end
    
    local numWhos, totalCount = GetNumWhoResults()
    local found = false
    
    for i = 1, numWhos do
        local name, guild, level, race, class, zone, group = GetWhoInfo(i)
        
        if name then
            if not MessageBox.playerCache[name] then MessageBox.playerCache[name] = {} end
            
            MessageBox.playerCache[name].level = level
            MessageBox.playerCache[name].class = class
            MessageBox.playerCache[name].classUpper = class and string.upper(class) or nil
            MessageBox.playerCache[name].race = race
            MessageBox.playerCache[name].guild = guild
            MessageBox.playerCache[name].zone = zone
            
            if MessageBox.currentWhoEntry then
                local targetLower = MessageBox.currentWhoEntry.nameLower or string.lower(MessageBox.currentWhoEntry.name)
                if string.lower(name) == targetLower then
                    found = true
                end
            end
        end
    end
    
    if not found and MessageBox.currentWhoEntry then
        MessageBox.currentWhoEntry.attempts = MessageBox.currentWhoEntry.attempts + 1
        if MessageBox.currentWhoEntry.attempts < 5 then
            table.insert(MessageBox.whoQueue, MessageBox.currentWhoEntry)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Failed to find info for " .. MessageBox.currentWhoEntry.name .. " after 5 attempts.")
        end
    end
    
    MessageBox.waitingForWhoResult = false
    MessageBox.currentWhoEntry = nil
    
    if MessageBox.frame and MessageBox.frame:IsVisible() then
        MessageBox:MarkContactListDirty()
        if MessageBox.selectedContact then
            MessageBox:UpdateChatHeader()
        end
    end
end

function MessageBox:PrintWhoQueue()
    local count = table.getn(MessageBox.whoQueue)
    if count == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO Queue is empty.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO Queue (" .. count .. "):")
        for i, entry in ipairs(MessageBox.whoQueue) do
            DEFAULT_CHAT_FRAME:AddMessage(i .. ". " .. entry.name .. " (Attempts: " .. entry.attempts .. ")")
        end
    end
end

function MessageBox:ClearWhoQueue()
    MessageBox.whoQueue = {}
    DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO Queue cleared.")
end

-- Hooks

function MessageBox:SetupHooks()
    if not self.original_ChatFrame_SendTell then
        self.original_ChatFrame_SendTell = ChatFrame_SendTell
        ChatFrame_SendTell = function(name, chatFrame)
            if MessageBox.settings.interceptWhispers then
                MessageBox:SelectContact(name)
                MessageBox:ShowFrame()
                return
            end
            MessageBox.original_ChatFrame_SendTell(name, chatFrame)
        end
    end

    if not self.original_ChatEdit_ParseText then
        self.original_ChatEdit_ParseText = ChatEdit_ParseText
        ChatEdit_ParseText = function(editBox, send)
            if MessageBox.settings.interceptWhispers and send == 0 then
                local text = editBox:GetText()
                if text and string.len(text) > 0 then
                    local s, e, cmd, target = string.find(text, "^/([wWtT]%S*)%s+([^%s]+)%s*$")
                    if s then
                        cmd = string.lower(cmd)
                        if cmd == "w" or cmd == "t" or cmd == "whisper" or cmd == "tell" then
                            editBox:SetText("")
                            editBox:Hide()
                            MessageBox:SelectContact(target)
                            MessageBox:ShowFrame()
                            return
                        end
                    end
                end
            end
            return MessageBox.original_ChatEdit_ParseText(editBox, send)
        end
    end
end

-- Message storage

function MessageBox:AddMessage(contact, message, isOutgoing)
    if not self.conversations then return end

    if not self.conversations[contact] then
        self.conversations[contact] = self:NewConversation()
    end

    local c = self.conversations[contact]
    
    table.insert(c.messages, message)
    table.insert(c.times, time())
    table.insert(c.outgoing, isOutgoing)
    table.insert(c.system, false)
    c.count = (c.count or 0) + 1
    
    MessageBox.conversationOrderDirty = true

    -- Update popouts
    if self.detachedWindows[contact] and self.detachedWindows[contact]:IsVisible() then
        local win = self.detachedWindows[contact]
        win.scrollBar:SetMinMaxValues(1, c.count)
        win.scrollBar:SetValue(c.count) 
    end

    if not isOutgoing then
        local detachedOpen = (self.detachedWindows[contact] and self.detachedWindows[contact]:IsVisible())
        local mainOpen = (self.frame and self.frame:IsVisible() and self.selectedContact == contact)
        
        if not mainOpen and not detachedOpen then
            if not self.unreadCounts[contact] then
                self.unreadCounts[contact] = 0
            end
            self.unreadCounts[contact] = self.unreadCounts[contact] + 1
            self:UpdateMinimapBadge()
            
            if self.settings.popupNotificationsEnabled and (not self.frame or not self.frame:IsVisible()) then
                self:ShowNotificationPopup()
            end
        end
    end

    if self.frame and self.frame:IsVisible() then
        self:MarkContactListDirty()
        if self.selectedContact == contact then
            local timeFmt = self.settings.use12HourFormat and "%I:%M %p" or "%H:%M"
            local lastIdx = c.count
            local timeString = "|cff808080[" .. date(timeFmt, c.times[lastIdx]) .. "]|r"
            local nameColor = isOutgoing and "|cff8080ff" or "|cffff80ff"
            local name = isOutgoing and "You" or self.selectedContact

            local cleanMessage = self:HandleLink(message)
            local formattedMessage = string.format("%s %s%s:|r %s%s|r", timeString, nameColor, name, "|cffffffff", cleanMessage)
            
            self.chatHistory:AddMessage(formattedMessage)
            self.chatHistory:ScrollToBottom()
            self:UpdateChatHeader()
        end
    end
end

function MessageBox:AddSystemMessage(contact, message, isTransient)
    if not self.conversations[contact] then
        self.conversations[contact] = self:NewConversation()
    end

    local c = self.conversations[contact]
    table.insert(c.messages, message)
    table.insert(c.times, time())
    table.insert(c.outgoing, false)
    table.insert(c.system, true)
    c.count = (c.count or 0) + 1

    -- New message changes sort order
    MessageBox.conversationOrderDirty = true

    if self.detachedWindows[contact] and self.detachedWindows[contact]:IsVisible() then
        local win = self.detachedWindows[contact]
        win.scrollBar:SetMinMaxValues(1, c.count)
        win.scrollBar:SetValue(c.count)
    end

    if self.frame and self.frame:IsVisible() and self.selectedContact == contact then
        local timeFmt = self.settings.use12HourFormat and "%I:%M %p" or "%H:%M"
        local lastIdx = c.count
        local timeString = "|cff808080[" .. date(timeFmt, c.times[lastIdx]) .. "]|r"
        local formattedMessage = string.format("%s %s%s|r", timeString, "|cffffcc00", message)

        self.chatHistory:AddMessage(formattedMessage)
        self.chatHistory:ScrollToBottom()

        if self.chatScrollBar then
            self.chatScrollBar.isUpdating = true
            self.chatScrollBar:SetMinMaxValues(1, c.count)
            self.chatScrollBar:SetValue(c.count)
            self.chatScrollBar.isUpdating = false
        end
    end
end

function MessageBox:RemoveLastMessage(contact)
    if not self.conversations or not self.conversations[contact] then return end
    
    local c = self.conversations[contact]
    local count = c.count or table.getn(c.messages)
    if count > 0 then
        table.remove(c.messages)
        table.remove(c.times)
        table.remove(c.outgoing)
        table.remove(c.system)
        c.count = count - 1
    end

end
