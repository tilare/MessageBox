-- Logic.lua
-- Who lookups, Hooks, Message storage

local function mbSetWhoToUi(on)
    if SetWhoToUI then
        SetWhoToUI(on)
    elseif SetWhoToUi then
        SetWhoToUi(on)
    end
end

function MessageBox:SetWhoResultsQuietMode()
    mbSetWhoToUi(1)
end

function MessageBox:RestoreWhoUiMode()
    MessageBox.whoSuppressChat = false
    mbSetWhoToUi(0)
end

function MessageBox:WhoPlayerQueueEmpty()
    for _, info in pairs(MessageBox.whoPlayerQueue) do
        if info.attempts <= MessageBox.WHO_MAX_ATTEMPTS then
            return false
        end
    end
    return true
end

function MessageBox:RestoreWhoUiModeIfIdle()
    if not MessageBox:WhoPlayerQueueEmpty() or MessageBox.whoScanInProgress then
        return
    end
    MessageBox:RestoreWhoUiMode()
end

function MessageBox:IsBackgroundWhoSilent()
    return MessageBox.settings and MessageBox.settings.backgroundWho
        and (MessageBox.whoScanInProgress or MessageBox.whoSuppressChat)
end

function MessageBox:IsLikelyWhoResultLine(text)
    if not text or text == "" then return false end
    local plain = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    plain = string.gsub(plain, "|r", "")
    local lower = string.lower(plain)
    if string.find(lower, "player total") or string.find(lower, "players total") then return true end
    if string.find(lower, "players online") or string.find(lower, "players found") then return true end
    if string.find(lower, "player%s+found") or string.find(lower, "players%s+matching") then return true end
    if string.find(plain, "%]:") and string.find(lower, "level") then return true end
    return false
end

function MessageBox:IsWhoCacheComplete(cache)
    if not cache then return false end
    return cache.class and cache.guild ~= nil
end

function MessageBox:WhoQueueCount()
    local n = 0
    for _ in pairs(MessageBox.whoPlayerQueue) do
        n = n + 1
    end
    return n
end

function MessageBox:WhoQueueDropOne()
    local k = next(MessageBox.whoPlayerQueue)
    if k then MessageBox.whoPlayerQueue[k] = nil end
end

function MessageBox:AddToWhoQueue(name, callback)
    if not MessageBox.settings or not MessageBox.settings.backgroundWho then
        return
    end
    if not name or name == "" then
        return
    end
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].isGM then
        return
    end

    local cache = MessageBox.playerCache[name]
    if MessageBox:IsWhoCacheComplete(cache) then
        if callback then callback(cache) end
        return
    end

    if MessageBox:IsPlayerOnline(name) == false then
        return
    end

    local q = MessageBox.whoPlayerQueue[name]
    if not q then
        while MessageBox:WhoQueueCount() >= MessageBox.WHO_QUEUE_MAX do
            MessageBox:WhoQueueDropOne()
        end
        q = { attempts = 0, callbacks = {} }
        MessageBox.whoPlayerQueue[name] = q
    end
    if callback then
        table.insert(q.callbacks, callback)
    end
end

function MessageBox:WhoRowMatchesQueuedName(whoName, queuedName)
    if not whoName or not queuedName then return false end
    local qLower = string.lower(queuedName)
    local whoLower = string.lower(whoName)
    if whoLower == qLower then return true end
    local qShort = MessageBox:PlayerNameWithoutRealm(queuedName)
    local qShortLower = qShort and string.lower(qShort)
    if qShortLower and whoLower == qShortLower then return true end
    local whoShort = MessageBox:PlayerNameWithoutRealm(whoName)
    if whoShort and qShortLower and string.lower(whoShort) == qShortLower then return true end
    return false
end

function MessageBox:ApplyWhoListUpdate()
    if not MessageBox.whoScanInProgress then
        return
    end
    if MessageBox.whoApplyBusy then
        return
    end
    MessageBox.whoApplyBusy = true

    local numWhos = GetNumWhoResults()
    if not numWhos or numWhos == 0 then
        MessageBox.whoApplyBusy = false
        return
    end

    local function persistWhoCache(key, class, level)
        if not class or not MessageBox.settings.classCache then return end
        if not MessageBox.settings.classCache[key] then
            MessageBox.settings.classCache[key] = {}
        end
        local s = MessageBox.settings.classCache[key]
        s.class = class
        s.classUpper = string.upper(class)
        if level and tonumber(level) == 60 then
            s.level = level
        end
    end

    local function applyWhoRow(cacheKey, guild, level, race, class)
        if not MessageBox.playerCache[cacheKey] then MessageBox.playerCache[cacheKey] = {} end
        local p = MessageBox.playerCache[cacheKey]
        p.level = level
        p.class = class
        p.classUpper = class and string.upper(class) or nil
        p.race = race
        p.guild = guild
    end

    local resolutions = {}
    local seenQName = {}

    for i = 1, numWhos do
        local wName, guild, level, race, class = GetWhoInfo(i)
        if wName then
            for qName, qEntry in pairs(MessageBox.whoPlayerQueue) do
                if not seenQName[qName] and MessageBox:WhoRowMatchesQueuedName(wName, qName) then
                    seenQName[qName] = true
                    table.insert(resolutions, {
                        qName = qName,
                        qEntry = qEntry,
                        guild = guild,
                        level = level,
                        race = race,
                        class = class,
                    })
                end
            end
        end
    end

    for _, r in ipairs(resolutions) do
        applyWhoRow(r.qName, r.guild, r.level, r.race, r.class)
        persistWhoCache(r.qName, r.class, r.level)
        local cbs = r.qEntry.callbacks
        MessageBox.whoPlayerQueue[r.qName] = nil
        for _, cb in ipairs(cbs) do
            cb(MessageBox.playerCache[r.qName])
        end
    end

    if MessageBox:WhoPlayerQueueEmpty() then
        MessageBox.whoScanInProgress = false
        MessageBox:RestoreWhoUiMode()
    end

    MessageBox.conversationOrderDirty = true
    if MessageBox.frame and MessageBox.frame:IsVisible() then
        MessageBox:MarkContactListDirty()
        if MessageBox.selectedContact then
            MessageBox:UpdateChatHeader()
        end
    end

    MessageBox.whoApplyBusy = false
end

function MessageBox:ProcessWhoQueue()
    if not MessageBox.settings or not MessageBox.settings.backgroundWho then
        return
    end

    local now = GetTime()

    if FriendsFrame and FriendsFrame:IsVisible() then
        return
    end
    if WhoFrame and WhoFrame:IsVisible() then
        return
    end

    local WHO_COOLDOWN = MessageBox.WHO_INTERVAL
    local WHO_RESPONSE_WAIT = MessageBox.WHO_TIMEOUT

    if MessageBox.whoScanInProgress and MessageBox.whoLastSent then
        local elapsed = now - MessageBox.whoLastSent
        if elapsed < WHO_RESPONSE_WAIT then
            return
        end
        MessageBox.whoScanInProgress = false
        MessageBox:RestoreWhoUiMode()
    end

    if MessageBox.whoLastSent and (now - MessageBox.whoLastSent) < WHO_COOLDOWN then
        return
    end

    local toRemove = {}
    for name, info in pairs(MessageBox.whoPlayerQueue) do
        if MessageBox:IsWhoCacheComplete(MessageBox.playerCache[name]) then
            table.insert(toRemove, name)
        elseif info.attempts >= MessageBox.WHO_MAX_ATTEMPTS then
            table.insert(toRemove, name)
        end
    end
    for _, name in ipairs(toRemove) do
        MessageBox.whoPlayerQueue[name] = nil
    end

    if not next(MessageBox.whoPlayerQueue) then
        MessageBox:RestoreWhoUiModeIfIdle()
        return
    end

    local nextPlayer = nil
    local lowestAttempts = 999
    for name, info in pairs(MessageBox.whoPlayerQueue) do
        if info.attempts < lowestAttempts then
            lowestAttempts = info.attempts
            nextPlayer = name
        end
    end

    if not nextPlayer then
        return
    end

    local info = MessageBox.whoPlayerQueue[nextPlayer]
    local sendName = MessageBox:PlayerNameWithoutRealm(nextPlayer)
    if not sendName or sendName == "" then sendName = nextPlayer end

    MessageBox.whoSuppressChat = true
    MessageBox:SetWhoResultsQuietMode()
    MessageBox.whoScanInProgress = true
    SendWho('n-"' .. sendName .. '"')
    info.attempts = info.attempts + 1
    MessageBox.whoLastSent = now

    if WhoFrame and WhoFrame.Hide then
        WhoFrame:Hide()
    end
end

function MessageBox:PrintWhoQueue()
    if MessageBox.whoScanInProgress then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO scan in progress (last send " .. (MessageBox.whoLastSent and string.format("%.1fs ago", GetTime() - MessageBox.whoLastSent) or "?") .. ")")
    end
    local n = MessageBox:WhoQueueCount()
    if n == 0 and not MessageBox.whoScanInProgress then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO queue is empty.")
        return
    end
    if n > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO queue (" .. n .. "):")
        for name, info in pairs(MessageBox.whoPlayerQueue) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. name .. " attempts=" .. tostring(info.attempts))
        end
    end
end

function MessageBox:ClearWhoQueue()
    MessageBox.whoPlayerQueue = {}
    MessageBox.whoScanInProgress = false
    MessageBox.whoLastSent = nil
    MessageBox.whoApplyBusy = false
    MessageBox:RestoreWhoUiMode()
    DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO queue cleared.")
end

function MessageBox:InstallWhoUiHooks()
    if MessageBox._whoUiHooksInstalled then
        return
    end
    if FriendsFrame_OnEvent then
        MessageBox.original_FriendsFrame_OnEvent = FriendsFrame_OnEvent
        FriendsFrame_OnEvent = function()
            if event == "WHO_LIST_UPDATE" and MessageBox.settings and MessageBox.settings.backgroundWho and MessageBox.whoScanInProgress then
                MessageBox:ApplyWhoListUpdate()
                return
            end
            return MessageBox.original_FriendsFrame_OnEvent(event)
        end
    end
    if WhoList_Update then
        MessageBox.original_WhoList_Update = WhoList_Update
        WhoList_Update = function()
            if MessageBox.settings and MessageBox.settings.backgroundWho and MessageBox.whoScanInProgress then
                return
            end
            return MessageBox.original_WhoList_Update()
        end
    end
    MessageBox._whoUiHooksInstalled = true
end

-- Hooks

function MessageBox:SetupHooks()
    if not self.original_ChatFrame_SendTell then
        self.original_ChatFrame_SendTell = ChatFrame_SendTell
        ChatFrame_SendTell = function(name, chatFrame)
            if MessageBox.settings.interceptWhispers then
                -- Blizzard calls SendTell while handling an incoming whisper; suppress when we
                -- already marked this sender (user is viewing another conversation in the main frame).
                local suppress = MessageBox.suppressSendTellForSwitch
                if suppress and name and string.lower(suppress) == string.lower(name) then
                    MessageBox.suppressSendTellForSwitch = nil
                    return
                end
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
            -- Mark the next SendTell for this sender so we can ignore it if the main frame is
            -- open on another conversation (AddMessage may also skip SelectContact in that case).
            if event == "CHAT_MSG_WHISPER" and MessageBox.settings.interceptWhispers then
                local sender = arg2
                local sel = MessageBox.selectedContact
                if sender and sel and MessageBox.frame and MessageBox.frame:IsVisible()
                    and string.lower(sel) ~= string.lower(sender) then
                    MessageBox.suppressSendTellForSwitch = sender
                end
            end
            if MessageBox.settings and MessageBox.settings.backgroundWho and MessageBox.whoSuppressChat
                and (event == "CHAT_MSG_SYSTEM" or event == "CHAT_MSG_INFO")
                and MessageBox:IsLikelyWhoResultLine(arg1) then
                return
            end
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

    MessageBox.crashSaveDirty = true
    if MessageBox.hasNampower then
        local now = GetTime()
        if (now - MessageBox.lastFlushTime) >= MessageBox.FLUSH_MIN_INTERVAL then
            MessageBox:FlushToDisk()
        end
    end

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
                -- Only jump to the sender when we are not already focused on another conversation
                -- in an open main window (otherwise use unread counts / list like when this is off).
                local viewingOther = self.frame and self.frame:IsVisible() and self.selectedContact
                    and string.lower(self.selectedContact) ~= string.lower(contact)
                if not viewingOther then
                    self:SelectContact(contact)
                    self:ShowFrame()
                    if self.settings.notificationSound then
                        PlaySoundFile("Interface\\AddOns\\MessageBox\\sound\\notification.wav")
                    end
                    -- SelectContact already refreshed chatHistory; skip incremental AddMessage below
                    return
                end
            elseif self.settings.popupNotificationsEnabled and (not self.frame or not self.frame:IsVisible()) then
                self:ShowNotificationPopup()
            end
        end
    elseif isOutgoing and self.settings.openWindowOnWhisper then
        -- SendChatMessage(..., "WHISPER") from other addons bypasses ChatFrame_SendTell; still open the
        -- main window when "open on whisper" is enabled (same focus rules as incoming).
        local detachedOpen = (self.detachedWindows[contact] and self.detachedWindows[contact]:IsVisible())
        local mainOpen = (self.frame and self.frame:IsVisible() and self.selectedContact == contact)
        if not mainOpen and not detachedOpen then
            local viewingOther = self.frame and self.frame:IsVisible() and self.selectedContact
                and string.lower(self.selectedContact) ~= string.lower(contact)
            if not viewingOther then
                self:SelectContact(contact)
                self:ShowFrame()
                return
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

    MessageBox.conversationOrderDirty = true

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
