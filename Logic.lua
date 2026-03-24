-- Logic.lua
-- Who lookups, Hooks, Message storage

-- Who lookups
function MessageBox:AddToWhoQueue(name)
    if not MessageBox.settings.backgroundWho then return end
    -- Never send WHO to Game Masters
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].isGM then return end
    -- Already have complete data (class + guild resolved, even if guild is empty string)
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].class and MessageBox.playerCache[name].guild ~= nil then return end
    -- Already in progresss WHO is currently running for this name
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].whoInProgress then return end
    local nameLower = string.lower(name)
    -- Check if already the current in progress WHO target
    if MessageBox.currentWhoEntry and MessageBox.currentWhoEntry.nameLower == nameLower then return end
    -- Check if already in the queue
    for _, entry in ipairs(MessageBox.whoQueue) do
        if entry.nameLower == nameLower then return end
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
    
    -- Timeout: if waiting too long for a WHO result, reset
    if MessageBox.waitingForWhoResult then
        if (now - MessageBox.waitingForWhoSince) > MessageBox.WHO_TIMEOUT then
            local entry = MessageBox.currentWhoEntry
            -- Clear the in progress
            if entry then
                if MessageBox.playerCache[entry.name] then
                    MessageBox.playerCache[entry.name].whoInProgress = nil
                end
                entry.attempts = entry.attempts + 1
                -- Only requeue if under max attempts and not already cached
                if entry.attempts < 3 then
                    local cache = MessageBox.playerCache[entry.name]
                    if not (cache and cache.class and cache.guild ~= nil) then
                        table.insert(MessageBox.whoQueue, entry)
                    end
                end
            end
            MessageBox.waitingForWhoResult = false
            MessageBox.currentWhoEntry = nil
            MessageBox.whoTimer = now
        end
        return
    end
    
    if table.getn(MessageBox.whoQueue) == 0 then return end
    if FriendsFrame and FriendsFrame:IsVisible() then return end
    if WhoFrame and WhoFrame:IsVisible() then return end
    
    if (now - MessageBox.whoTimer) < MessageBox.WHO_INTERVAL then return end
    
    -- Skip entries that have already been resolved while waiting in queue
    while table.getn(MessageBox.whoQueue) > 0 do
        local peek = MessageBox.whoQueue[1]
        local cache = MessageBox.playerCache[peek.name]
        if cache and cache.class and cache.guild ~= nil then
            table.remove(MessageBox.whoQueue, 1)
        else
            break
        end
    end
    
    if table.getn(MessageBox.whoQueue) == 0 then return end
    
    local entry = MessageBox.whoQueue[1]
    table.remove(MessageBox.whoQueue, 1)
    
    if not MessageBox.playerCache[entry.name] then
        MessageBox.playerCache[entry.name] = {}
    end
    MessageBox.playerCache[entry.name].whoInProgress = true
    
    MessageBox.whoTimer = now
    MessageBox.waitingForWhoResult = true
    MessageBox.waitingForWhoSince = now
    MessageBox.currentWhoEntry = entry
    SendWho("n-" .. entry.name)
end

function MessageBox:HandleWhoResult()
    if not MessageBox.waitingForWhoResult then return end
    
    local numWhos, totalCount = GetNumWhoResults()
    local found = false
    local targetName = MessageBox.currentWhoEntry and MessageBox.currentWhoEntry.name or nil
    local targetLower = MessageBox.currentWhoEntry and MessageBox.currentWhoEntry.nameLower or nil
    
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
            MessageBox.playerCache[name].whoInProgress = nil

             -- Persist class permanently and level if max (60)
            if class and MessageBox.settings.classCache then
                if not MessageBox.settings.classCache[name] then
                    MessageBox.settings.classCache[name] = {}
                end
                MessageBox.settings.classCache[name].class = class
                MessageBox.settings.classCache[name].classUpper = string.upper(class)
                if level and tonumber(level) == 60 then
                    MessageBox.settings.classCache[name].level = level
                end
            end
            
            if targetLower and string.lower(name) == targetLower then
                found = true
            end
        end
    end
    
    if not found and targetName then
        -- Clear the in progress
        if MessageBox.playerCache[targetName] then
            MessageBox.playerCache[targetName].whoInProgress = nil
        end
        
        if numWhos == 0 then
            -- Zero results: player is offline or doesn't exist — no point retrying
            -- Mark guild as empty string so dont queue this name endlessly
            if not MessageBox.playerCache[targetName] then
                MessageBox.playerCache[targetName] = {}
            end
            MessageBox.playerCache[targetName].guild = MessageBox.playerCache[targetName].guild or ""
        else
            local entry = MessageBox.currentWhoEntry
            entry.attempts = entry.attempts + 1
            if entry.attempts < 2 then
                table.insert(MessageBox.whoQueue, entry)
            end
        end
    end
    
    MessageBox.waitingForWhoResult = false
    MessageBox.currentWhoEntry = nil
    
    if targetName and MessageBox.conversations and MessageBox.conversations[targetName] then
        MessageBox.conversations[targetName]._fmtCache = nil
    end
    
    if MessageBox.frame and MessageBox.frame:IsVisible() then
        MessageBox:MarkContactListDirty()
        if MessageBox.selectedContact then
            MessageBox:UpdateChatHeader()
        end
    end
    
    if targetName and MessageBox.detachedWindows[targetName] and MessageBox.detachedWindows[targetName]:IsVisible() then
        if MessageBox.detachedWindows[targetName].UpdateHeader then
            MessageBox.detachedWindows[targetName]:UpdateHeader()
        end
    end
end

function MessageBox:PrintWhoQueue()
    if MessageBox.currentWhoEntry then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO in progress: " .. MessageBox.currentWhoEntry.name .. " (Attempts: " .. MessageBox.currentWhoEntry.attempts .. ")")
    end
    local count = table.getn(MessageBox.whoQueue)
    if count == 0 and not MessageBox.currentWhoEntry then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO Queue is empty.")
    elseif count > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO Queue (" .. count .. "):")
        for i, entry in ipairs(MessageBox.whoQueue) do
            DEFAULT_CHAT_FRAME:AddMessage(i .. ". " .. entry.name .. " (Attempts: " .. entry.attempts .. ")")
        end
    end
end

function MessageBox:ClearWhoQueue()
    for _, entry in ipairs(MessageBox.whoQueue) do
        if MessageBox.playerCache[entry.name] then
            MessageBox.playerCache[entry.name].whoInProgress = nil
        end
    end
    if MessageBox.currentWhoEntry and MessageBox.playerCache[MessageBox.currentWhoEntry.name] then
        MessageBox.playerCache[MessageBox.currentWhoEntry.name].whoInProgress = nil
    end
    MessageBox.whoQueue = {}
    MessageBox.waitingForWhoResult = false
    MessageBox.currentWhoEntry = nil
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

    if not self.original_ChatFrame_OnEvent then
        self.original_ChatFrame_OnEvent = ChatFrame_OnEvent
        ChatFrame_OnEvent = function(event)
            if MessageBox.settings.suppressWhispers then
                if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
                    return
                end
            end
            MessageBox.original_ChatFrame_OnEvent(event)
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

    -- Mark crash save as needing a flush; throttled immediate flush
    MessageBox.crashSaveDirty = true
    if MessageBox.hasNampower then
        local now = GetTime()
        if (now - MessageBox.lastFlushTime) >= MessageBox.FLUSH_MIN_INTERVAL then
            MessageBox:FlushToDisk()
        end
    end

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
            
            if self.settings.openWindowOnWhisper then
                self:SelectContact(contact)
                self:ShowFrame()
                if self.settings.notificationSound then
                    PlaySoundFile("Interface\\AddOns\\MessageBox\\sound\\notification.wav")
                end
                -- SelectContact already refreshed chatHistory; skip incremental AddMessage below
                return
            elseif self.settings.popupNotificationsEnabled and (not self.frame or not self.frame:IsVisible()) then
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
            if self.chatScrollBar then
                self.chatScrollBar.isUpdating = true
                self.chatScrollBar:SetMinMaxValues(1, c.count)
                self.chatScrollBar:SetValue(c.count)
                self.chatScrollBar.isUpdating = false
                self.chatScrollBar:Show()
            end
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

    -- Mark crash save as needing a flush
    MessageBox.crashSaveDirty = true

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
            self.chatScrollBar:Show()
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
