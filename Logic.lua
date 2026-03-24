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
    return cache.class and cache.level and cache.race and cache.guild ~= nil
end

function MessageBox:WhoSendQueryString(shortName, style)
    style = style or 1
    if style == 2 then
        return "n-" .. shortName
    end
    if style == 3 then
        return shortName
    end
    return 'n-"' .. shortName .. '"'
end

function MessageBox:StopWhoResultPoll()
    if MessageBox.whoPollFrame then
        MessageBox.whoPollFrame:SetScript("OnUpdate", nil)
    end
end

local WHO_POLL_INTERVAL = 0.08

function MessageBox:StartWhoResultPoll()
    if not MessageBox.whoPollFrame then
        MessageBox.whoPollFrame = CreateFrame("Frame", "MessageBoxWhoPollFrame")
    end
    local f = MessageBox.whoPollFrame
    MessageBox.whoPollAccum = 0
    MessageBox:StopWhoResultPoll()
    f:SetScript("OnUpdate", function()
        if not MessageBox.whoScanInProgress then
            MessageBox:StopWhoResultPoll()
            return
        end
        MessageBox.whoPollAccum = (MessageBox.whoPollAccum or 0) + arg1
        if MessageBox.whoPollAccum < WHO_POLL_INTERVAL then
            return
        end
        MessageBox.whoPollAccum = 0
        local n = GetNumWhoResults and GetNumWhoResults()
        if n and n > 0 then
            MessageBox:ApplyWhoListUpdate()
        end
    end)
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

    local q = MessageBox.whoPlayerQueue[name]
    if not q then
        while MessageBox:WhoQueueCount() >= MessageBox.WHO_QUEUE_MAX do
            MessageBox:WhoQueueDropOne()
        end
        q = { attempts = 0, callbacks = {}, queryStyle = 1 }
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

    local function persistWhoCache(key, guild, level, race, class)
        if not MessageBox.settings.classCache or not class then return end
        if not MessageBox.settings.classCache[key] then
            MessageBox.settings.classCache[key] = {}
        end
        local s = MessageBox.settings.classCache[key]
        s.class = class
        s.classUpper = string.upper(class)
        if level then s.level = level end
        if race then s.race = race end
        if guild ~= nil then s.guild = guild end
    end

    local function applyWhoRow(cacheKey, guild, level, race, class, zone)
        if not MessageBox.playerCache[cacheKey] then MessageBox.playerCache[cacheKey] = {} end
        local p = MessageBox.playerCache[cacheKey]
        p.level = level
        p.class = class
        p.classUpper = class and string.upper(class) or nil
        p.race = race
        p.guild = guild
        p.zone = zone
    end

    local resolutions = {}
    local seenQName = {}

    for i = 1, numWhos do
        local wName, guild, level, race, class, zone = GetWhoInfo(i)
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
                        zone = zone,
                    })
                end
            end
        end
    end

    if table.getn(resolutions) > 0 then
        MessageBox.whoPendingName = nil
    end

    for _, r in ipairs(resolutions) do
        applyWhoRow(r.qName, r.guild, r.level, r.race, r.class, r.zone)
        persistWhoCache(r.qName, r.guild, r.level, r.race, r.class)
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
    MessageBox:StopWhoResultPoll()
end

function MessageBox:ProcessWhoQueue()
    if not MessageBox.settings then return end

    if not MessageBox.settings.backgroundWho then
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
        MessageBox:StopWhoResultPoll()
        if MessageBox.whoPendingName and MessageBox.whoPlayerQueue[MessageBox.whoPendingName] then
            local ent = MessageBox.whoPlayerQueue[MessageBox.whoPendingName]
            local qs = tonumber(ent.queryStyle) or 1
            if qs < 1 or qs > 3 then qs = 1 end
            local nextStyle = qs + 1
            if nextStyle > 3 then nextStyle = 1 end
            ent.queryStyle = nextStyle
        end
        MessageBox.whoPendingName = nil
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
    local q = MessageBox:PlayerNameWithoutRealm(nextPlayer)
    if not q or q == "" then q = nextPlayer end
    local style = info.queryStyle or 1
    local query = MessageBox:WhoSendQueryString(q, style)

    MessageBox.whoPendingName = nextPlayer
    MessageBox.whoSuppressChat = true
    MessageBox:SetWhoResultsQuietMode()
    MessageBox.whoScanInProgress = true
    SendWho(query)
    info.attempts = info.attempts + 1
    MessageBox.whoLastSent = now
    MessageBox:StartWhoResultPoll()

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
    MessageBox:StopWhoResultPoll()
    MessageBox.whoPlayerQueue = {}
    MessageBox.whoScanInProgress = false
    MessageBox.whoLastSent = nil
    MessageBox.whoPendingName = nil
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
        FriendsFrame_OnEvent = function(event)
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
