-- Logic.lua
-- Who lookups, Hooks, Message storage

-- Who lookups
function MessageBox:AddToWhoQueue(name)
    if not MessageBox.settings.backgroundWho then return end
    if MessageBox:IsFriend(name) then return end
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].class then return end
    for _, entry in ipairs(MessageBox.whoQueue) do
        if string.lower(entry.name) == string.lower(name) then return end
    end
    table.insert(MessageBox.whoQueue, { name = name, attempts = 0 })
end

function MessageBox:ProcessWhoQueue()
    if not MessageBox.settings.backgroundWho then return end
    if table.getn(MessageBox.whoQueue) == 0 or MessageBox.waitingForWhoResult then return end
    if FriendsFrame and FriendsFrame:IsVisible() then return end
    
    local now = GetTime()
    if (now - MessageBox.whoTimer) < MessageBox.WHO_INTERVAL then return end
    
    local entry = MessageBox.whoQueue[1]
    local name = entry.name
    
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].class then 
        table.remove(MessageBox.whoQueue, 1)
        return 
    end
    
    table.remove(MessageBox.whoQueue, 1)
    
    MessageBox.whoTimer = now
    MessageBox.waitingForWhoResult = true
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
            MessageBox.playerCache[name].race = race
            MessageBox.playerCache[name].guild = guild
            MessageBox.playerCache[name].zone = zone
            
            if MessageBox.currentWhoEntry and string.lower(name) == string.lower(MessageBox.currentWhoEntry.name) then
                found = true
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
        MessageBox:UpdateContactList()
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
    if not MessageBox.conversations then return end

    if not MessageBox.conversations[contact] then
        MessageBox.conversations[contact] = {
            messages = {},
            times = {},
            outgoing = {},
            system = {},
            pinned = false
        }
    end

    local c = MessageBox.conversations[contact]
    
    table.insert(c.messages, message)
    table.insert(c.times, time())
    table.insert(c.outgoing, isOutgoing)
    table.insert(c.system, false)

    -- Update popouts
    if MessageBox.detachedWindows[contact] and MessageBox.detachedWindows[contact]:IsVisible() then
        local win = MessageBox.detachedWindows[contact]
        local total = table.getn(c.messages)
        win.scrollBar:SetMinMaxValues(1, total)
        win.scrollBar:SetValue(total) 
    end

    if not isOutgoing then
        local detachedOpen = (MessageBox.detachedWindows[contact] and MessageBox.detachedWindows[contact]:IsVisible())
        local mainOpen = (MessageBox.frame and MessageBox.frame:IsVisible() and MessageBox.selectedContact == contact)
        
        if not mainOpen and not detachedOpen then
            if not MessageBox.unreadCounts[contact] then
                MessageBox.unreadCounts[contact] = 0
            end
            MessageBox.unreadCounts[contact] = MessageBox.unreadCounts[contact] + 1
            MessageBox:UpdateMinimapBadge()
            
            if self.settings.popupNotificationsEnabled and (not self.frame or not self.frame:IsVisible()) then
                self:ShowNotificationPopup()
            end
        end
    end

    if MessageBox.frame and MessageBox.frame:IsVisible() then
        MessageBox:UpdateContactList()
        if MessageBox.selectedContact == contact then
            local timeFmt = MessageBox.settings.use12HourFormat and "%I:%M %p" or "%H:%M"
            local lastIdx = table.getn(c.times)
            local timeString = "|cff808080[" .. date(timeFmt, c.times[lastIdx]) .. "]|r"
            local nameColor = isOutgoing and "|cff8080ff" or "|cffff80ff"
            local name = isOutgoing and "You" or MessageBox.selectedContact

            local cleanMessage = MessageBox:HandleLink(message)
            local formattedMessage = string.format("%s %s%s:|r %s%s|r", timeString, nameColor, name, "|cffffffff", cleanMessage)
            
            MessageBox.chatHistory:AddMessage(formattedMessage)
            MessageBox.chatHistory:ScrollToBottom()
            MessageBox:UpdateChatHeader()
        end
    end
end

function MessageBox:AddSystemMessage(contact, message, isTransient)
    if not self.conversations[contact] then
        self.conversations[contact] = {
            messages = {},
            times = {},
            outgoing = {},
            system = {},
            pinned = false
        }
    end

    local c = self.conversations[contact]
    table.insert(c.messages, message)
    table.insert(c.times, time())
    table.insert(c.outgoing, false)
    table.insert(c.system, true)

    if self.detachedWindows[contact] and self.detachedWindows[contact]:IsVisible() then
        local win = self.detachedWindows[contact]
        local total = table.getn(c.messages)
        win.scrollBar:SetMinMaxValues(1, total)
        win.scrollBar:SetValue(total)
    end

    if self.frame and self.frame:IsVisible() and self.selectedContact == contact then
        self:UpdateChatHistory()
    end
end

function MessageBox:RemoveLastMessage(contact)
    if not self.conversations or not self.conversations[contact] then return end
    
    local c = self.conversations[contact]
    if c.messages then
        local count = table.getn(c.messages)
        if count > 0 then
            table.remove(c.messages)
            table.remove(c.times)
            table.remove(c.outgoing)
            table.remove(c.system)
        end
    end
end