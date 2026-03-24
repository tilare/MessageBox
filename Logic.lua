-- Logic.lua
-- Who lookups, Hooks, Message storage

-- Background WHO: SendWho + GetWhoInfo (WIM-style). SetWhoToUI(1), hooks, chat filter.

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

function MessageBox:RestoreWhoUiModeIfIdle()
    if table.getn(MessageBox.whoQueue) > 0 or MessageBox.waitingForWhoResult then
        return
    end
    MessageBox:RestoreWhoUiMode()
end

function MessageBox:IsBackgroundWhoSilent()
    return MessageBox.settings and MessageBox.settings.backgroundWho
        and (MessageBox.waitingForWhoResult or MessageBox.whoSuppressChat)
end

function MessageBox:IsLikelyWhoResultLine(text)
    if not text or text == "" then return false end
    local plain = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    plain = string.gsub(plain, "|r", "")
    local lower = string.lower(plain)
    if string.find(lower, "player total") or string.find(lower, "players total") then return true end
    if string.find(lower, "players online") or string.find(lower, "players found") then return true end
    if string.find(lower, "player%s+found") or string.find(lower, "players%s+matching") then return true end
    -- [Name]: Level … (common WHO result line)
    if string.find(plain, "%]:") and string.find(lower, "level") then return true end
    return false
end

-- fmt 1 = n-Name, fmt 2 = n-"Name" (WIM). Plain SendWho(name) omitted — too broad on many servers.
function MessageBox:WhoSendQueryString(shortName, fmt)
    fmt = fmt or 1
    if fmt == 2 then
        return 'n-"' .. shortName .. '"'
    end
    return "n-" .. shortName
end

-- Some clients update chat before WHO_LIST_UPDATE / GetNumWhoResults(); poll until list fills or we stop waiting.
local WHO_POLL_INTERVAL = 0.06
local WHO_POLL_MAX_AGE = 3

function MessageBox:StartWhoResultPoll()
    if not MessageBox.whoPollFrame then
        MessageBox.whoPollFrame = CreateFrame("Frame", "MessageBoxWhoPollFrame")
    end
    local f = MessageBox.whoPollFrame
    MessageBox.whoPollAccum = 0
    MessageBox.whoPollStart = GetTime()
    f:SetScript("OnUpdate", function()
        if not MessageBox.waitingForWhoResult then
            f:SetScript("OnUpdate", nil)
            return
        end
        if (GetTime() - (MessageBox.whoPollStart or 0)) > WHO_POLL_MAX_AGE then
            f:SetScript("OnUpdate", nil)
            return
        end
        MessageBox.whoPollAccum = MessageBox.whoPollAccum + arg1
        if MessageBox.whoPollAccum < WHO_POLL_INTERVAL then return end
        MessageBox.whoPollAccum = 0
        local numWhos = GetNumWhoResults()
        if numWhos and numWhos > 0 then
            f:SetScript("OnUpdate", nil)
            MessageBox:HandleWhoResult()
        end
    end)
end

-- Who lookups
function MessageBox:AddToWhoQueue(name)
    if not MessageBox.settings.backgroundWho then return end
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].isGM then return end
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].class and MessageBox.playerCache[name].guild ~= nil then return end
    if MessageBox.playerCache[name] and MessageBox.playerCache[name].whoInProgress then return end
    local nameLower = string.lower(name)
    if MessageBox.currentWhoEntry and MessageBox.currentWhoEntry.nameLower == nameLower then return end
    for _, entry in ipairs(MessageBox.whoQueue) do
        if entry.nameLower == nameLower then return end
    end
    if table.getn(MessageBox.whoQueue) >= MessageBox.WHO_QUEUE_MAX then
        table.remove(MessageBox.whoQueue, 1)
    end
    table.insert(MessageBox.whoQueue, { name = name, nameLower = nameLower, attempts = 0, whoFmt = 1 })
end

function MessageBox:ProcessWhoQueue()
    if not MessageBox.settings.backgroundWho then return end
    
    local now = GetTime()
    
    -- Timeout: if waiting too long for a WHO result, reset
    if MessageBox.waitingForWhoResult then
        if (now - MessageBox.waitingForWhoSince) > MessageBox.WHO_TIMEOUT then
            -- Chat can show WHO results while WHO_LIST_UPDATE never fires or fires before GetNumWhoResults() is ready.
            local nPending = GetNumWhoResults()
            if nPending and nPending > 0 and MessageBox.currentWhoEntry then
                if MessageBox.whoPollFrame then
                    MessageBox.whoPollFrame:SetScript("OnUpdate", nil)
                end
                MessageBox:HandleWhoResult()
                return
            end
            local entry = MessageBox.currentWhoEntry
            -- Clear the in progress
            if entry then
                if MessageBox.playerCache[entry.name] then
                    MessageBox.playerCache[entry.name].whoInProgress = nil
                end
                entry.attempts = entry.attempts + 1
                if entry.attempts < 3 then
                    local cache = MessageBox.playerCache[entry.name]
                    if not (cache and cache.class and cache.guild ~= nil) then
                        table.insert(MessageBox.whoQueue, entry)
                    end
                end
            end
            MessageBox.waitingForWhoResult = false
            MessageBox.currentWhoEntry = nil
            MessageBox:RestoreWhoUiModeIfIdle()
            MessageBox.whoTimer = now
        end
        return
    end
    
    if table.getn(MessageBox.whoQueue) == 0 then return end
    if FriendsFrame and FriendsFrame:IsVisible() then return end
    if WhoFrame and WhoFrame:IsVisible() then return end

    if MessageBox.whoTimer > 0 and (now - MessageBox.whoTimer) < MessageBox.WHO_INTERVAL then
        return
    end
    
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
    local q = MessageBox:PlayerNameWithoutRealm(entry.name)
    if not q or q == "" then q = entry.name end
    MessageBox.whoSuppressChat = true
    MessageBox:SetWhoResultsQuietMode()
    local fmt = entry.whoFmt or 1
    local query = MessageBox:WhoSendQueryString(q, fmt)
    SendWho(query)
    if WhoFrame and WhoFrame.Hide then
        WhoFrame:Hide()
    end
    MessageBox:StartWhoResultPoll()
end

function MessageBox:HandleWhoResult()
    if not MessageBox.waitingForWhoResult then return end

    -- First WHO_LIST_UPDATE can arrive before the client fills the result buffer.
    local numWhos = GetNumWhoResults()
    if numWhos == 0 then return end

    if SortWho then
        SortWho("name")
        numWhos = GetNumWhoResults()
    end

    local found = false
    local targetName = MessageBox.currentWhoEntry and MessageBox.currentWhoEntry.name or nil
    local targetLower = MessageBox.currentWhoEntry and MessageBox.currentWhoEntry.nameLower or nil
    local targetShortLower = targetName and string.lower(MessageBox:PlayerNameWithoutRealm(targetName)) or nil

    local function whoRowMatchesQuery(whoName)
        if not whoName or not targetLower then return false end
        local whoLower = string.lower(whoName)
        if whoLower == targetLower then return true end
        -- Whisper used "Name-Realm" but WHO list returns "Name" only
        if targetShortLower and whoLower == targetShortLower then return true end
        -- WHO may return "Name-Realm" while whisper key is short "Name" (or different realm suffix)
        local whoShort = MessageBox:PlayerNameWithoutRealm(whoName)
        if whoShort and targetShortLower and string.lower(whoShort) == targetShortLower then return true end
        return false
    end

    local function persistClassCache(key, class, level)
        if not class or not MessageBox.settings.classCache then return end
        if not MessageBox.settings.classCache[key] then
            MessageBox.settings.classCache[key] = {}
        end
        MessageBox.settings.classCache[key].class = class
        MessageBox.settings.classCache[key].classUpper = string.upper(class)
        if level and tonumber(level) == 60 then
            MessageBox.settings.classCache[key].level = level
        end
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
        p.whoInProgress = nil
    end

    for i = 1, numWhos do
        local name, guild, level, race, class, zone = GetWhoInfo(i)
        if name then
            applyWhoRow(name, guild, level, race, class, zone)
            persistClassCache(name, class, level)
            if whoRowMatchesQuery(name) then
                found = true
                if targetName and targetName ~= name then
                    applyWhoRow(targetName, guild, level, race, class, zone)
                    persistClassCache(targetName, class, level)
                end
            end
        end
    end
    
    if not found and targetName then
        -- Clear the in progress
        if MessageBox.playerCache[targetName] then
            MessageBox.playerCache[targetName].whoInProgress = nil
        end

        -- numWhos is always > 0 here (empty result batches are ignored above until timeout/retry)
        local entry = MessageBox.currentWhoEntry
        if entry then
            local v = entry.whoFmt or 1
            if v < 2 then
                entry.whoFmt = v + 1
                table.insert(MessageBox.whoQueue, entry)
                MessageBox.whoTimer = 0
            else
                entry.whoFmt = 1
                entry.attempts = entry.attempts + 1
                if entry.attempts < 2 then
                    table.insert(MessageBox.whoQueue, entry)
                end
            end
        end
    end

    MessageBox.waitingForWhoResult = false
    MessageBox.currentWhoEntry = nil
    MessageBox:RestoreWhoUiModeIfIdle()
    
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
    MessageBox:RestoreWhoUiMode()
    if MessageBox.whoPollFrame then
        MessageBox.whoPollFrame:SetScript("OnUpdate", nil)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: WHO Queue cleared.")
end

-- FriendsFrame + WhoList: suppress default Who UI during our background WHO (same idea as WIM).
function MessageBox:InstallWhoUiHooks()
    if MessageBox._whoUiHooksInstalled then return end
    if FriendsFrame_OnEvent then
        MessageBox.original_FriendsFrame_OnEvent = FriendsFrame_OnEvent
        FriendsFrame_OnEvent = function(event)
            if event == "WHO_LIST_UPDATE" and MessageBox:IsBackgroundWhoSilent() then
                return
            end
            return MessageBox.original_FriendsFrame_OnEvent(event)
        end
    end
    if WhoList_Update then
        MessageBox.original_WhoList_Update = WhoList_Update
        WhoList_Update = function()
            if MessageBox:IsBackgroundWhoSilent() then return end
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
