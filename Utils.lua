-- Utils.lua
-- Utilities, Link formatting

MessageBox.URLFuncs = {
    ["WWW"] = function(a1,a2,a3) return MessageBox:FormatLink(MessageBox.URLPattern.WWW.fm,a1,a2,a3) end,
    ["PROTOCOL"] = function(a1,a2) return MessageBox:FormatLink(MessageBox.URLPattern.PROTOCOL.fm,a1,a2) end,
    ["EMAIL"] = function(a1,a2,a3,a4) return MessageBox:FormatLink(MessageBox.URLPattern.EMAIL.fm,a1,a2,a3,a4) end,
    ["IP"] = function(a1,a2,a3,a4) return MessageBox:FormatLink(MessageBox.URLPattern.IP.fm,a1,a2,a3,a4) end,
}

function MessageBox:FormatLink(formatter, a1, a2, a3, a4, a5)
    if not (formatter and a1) then return end
    local newtext = string.format(formatter, a1, a2, a3, a4, a5)

    local invalidtld
    for _, arg in pairs({a5,a4,a3,a2,a1}) do
      if arg and string.find(arg, "(%.%.)$") then
        invalidtld = true
        break
      end
    end

    if (invalidtld) then return newtext end
    return " |cff00ccff|Hurl:" .. newtext .. "|h[" .. newtext .. "]|h|r "
end

function MessageBox:HandleLink(text)
    if type(text) ~= "string" then return text or "" end
    
    local URLPattern = self.URLPattern
    local URLFuncs = self.URLFuncs
    text = string.gsub(text, URLPattern.WWW.rx, URLFuncs.WWW)
    text = string.gsub(text, URLPattern.PROTOCOL.rx, URLFuncs.PROTOCOL)
    text = string.gsub(text, URLPattern.EMAIL.rx, URLFuncs.EMAIL)
    text = string.gsub(text, URLPattern.IP.rx, URLFuncs.IP)
    return text
end

function MessageBox:SkinScrollbar(frame)
    if not frame then return end
    
    local sb
    if frame:GetObjectType() == "Slider" then
        sb = frame
    else
        sb = getglobal(frame:GetName().."ScrollBar")
    end
    
    if not sb then return end

    local name = sb:GetName()

    local buttons = {
        getglobal(name.."ScrollUpButton"),
        getglobal(name.."ScrollDownButton"),
    }
    
    local backgroundRegions = {
        getglobal(name.."Top"),
        getglobal(name.."Middle"),
        getglobal(name.."Bottom"),
    }
    
    local thumb = getglobal(name.."ThumbTexture")

    if MessageBox.settings.modernTheme then
        for _, btn in ipairs(buttons) do
            if btn then btn:Hide() end
        end
        for _, region in ipairs(backgroundRegions) do
            if region then region:Hide() end
        end
        
        if thumb then 
            thumb:SetTexture(MessageBox.textures.white8x8)
            
            local r, g, b, a = 0.8, 0.8, 0.8, 1 
            if MessageBox.settings.highlightColor then
                r, g, b, a = unpack(MessageBox.settings.highlightColor)
            end
            
            thumb:SetVertexColor(r, g, b, a)
            thumb:SetWidth(4)
        end
    else
        for _, btn in ipairs(buttons) do
            if btn then btn:Show() end
        end
        for _, region in ipairs(backgroundRegions) do
            if region then region:Show() end
        end
        
        if thumb then 
            thumb:SetTexture(MessageBox.textures.scrollKnob)
            thumb:SetVertexColor(1, 1, 1, 1)
            thumb:SetWidth(18)
        end
    end
end

function MessageBox:IsFriend(name)
    if MessageBox.friendSet then
        return MessageBox.friendSet[string.lower(name)] or false
    end
    for i = 1, GetNumFriends() do
        local fName = GetFriendInfo(i)
        if fName and string.lower(fName) == string.lower(name) then
            return true
        end
    end
    return false
end

function MessageBox:IsPlayerOnline(playerName)
    if MessageBox.onlineStatus then
        local status = MessageBox.onlineStatus[string.lower(playerName)]
        if status ~= nil then return status end
    end
    return nil
end

function MessageBox:CalculateDisplayLimit(historyFrame)
    if not historyFrame then return 50 end
    local frameHeight = historyFrame:GetHeight()
    if not frameHeight or frameHeight <= 0 then return 50 end
    
    local fontSize = self.settings.chatFontSize or self.defaultSettings.chatFontSize
    local lineHeight = fontSize + 2
    local visibleLines = math.ceil(frameHeight / lineHeight)
    -- Buffer for wrapped lines, date headers, and the unread separator
    local buffer = 10
    return visibleLines + buffer
end

function MessageBox:RenderMessages(historyFrame, contact, anchorIndex, unreadCount)
    if not historyFrame or not contact then return end
    
    local c = self.conversations[contact]
    if not c or not c.messages then
        historyFrame:Clear()
        return
    end
    
    local totalMessages = self:GetCount(c)
    if totalMessages == 0 then
        historyFrame:Clear()
        return
    end
    
    if anchorIndex > totalMessages then anchorIndex = totalMessages end
    if anchorIndex < 1 then anchorIndex = 1 end
    
    local displayLimit = self:CalculateDisplayLimit(historyFrame)
    
    local startIndex = anchorIndex - displayLimit
    if startIndex < 1 then startIndex = 1 end
    
    local splitIndex = 0
    if unreadCount and unreadCount > 0 then
        splitIndex = totalMessages - unreadCount + 1
    end
    
    -- Search highlight state
    local searchTerm = nil
    local currentMatchMsgIndex = 0
    if self.chatSearchActive and self.chatSearchTerm and self.chatSearchTerm ~= "" then
        searchTerm = string.lower(self.chatSearchTerm)
        if self.chatSearchResults and self.chatSearchCurrentIndex > 0 
           and self.chatSearchCurrentIndex <= table.getn(self.chatSearchResults) then
            currentMatchMsgIndex = self.chatSearchResults[self.chatSearchCurrentIndex]
        end
    end
    
    historyFrame:Clear()
    
    local lastMessageDate = nil
    local timeFmt = self.settings.use12HourFormat and "%I:%M %p" or "%H:%M"
    local timeFmtKey = self.settings.use12HourFormat and "12h" or "24h"
    
    if not c._fmtCache then c._fmtCache = {} end
    if not c._fmtTimeFmt then c._fmtTimeFmt = "" end
    if c._fmtTimeFmt ~= timeFmtKey then
        c._fmtCache = {}
        c._fmtTimeFmt = timeFmtKey
    end
    
    local fmtCache = c._fmtCache
    
    for i = startIndex, anchorIndex do
        if i == splitIndex then
            historyFrame:AddMessage("|cff444444———|r  |cffffffffNew Messages|r  |cff444444———|r")
        end
        
        local msg = c.messages[i]
        local timeVal = c.times[i]
        local isOutgoing = c.outgoing[i]
        local isSystem = c.system[i]
        
        local formattedMessage
        
        if type(timeVal) == "number" then
            local currentMessageDate = date("%Y%m%d", timeVal)
            if lastMessageDate ~= currentMessageDate then
                if lastMessageDate ~= nil then historyFrame:AddMessage(" ") end
                local dateText = "|cff666666— " .. date("%A, %B %d", timeVal) .. " —|r"
                historyFrame:AddMessage(dateText)
                lastMessageDate = currentMessageDate
            end
        end
        
        local cached = fmtCache[i]
        if cached and not searchTerm then
            formattedMessage = cached
        else
            local timeString
            if type(timeVal) == "number" then
                timeString = "|cff808080[" .. date(timeFmt, timeVal) .. "]|r"
            else
                timeString = "|cff808080[" .. tostring(timeVal) .. "]|r"
            end
            
            if isSystem then
                formattedMessage = string.format("%s %s%s|r", timeString, "|cffffcc00", msg)
            else
                local cleanMessage = self:HandleLink(msg)
                
                -- Apply search highlighting to the message text
                if searchTerm and string.find(string.lower(msg), searchTerm, 1, true) then
                    local highlightColor = (i == currentMatchMsgIndex) and "|cffFF8800" or "|cffFFFF00"
                    cleanMessage = self:HighlightSearchTerm(cleanMessage, searchTerm, highlightColor)
                end
                
                local nameColor = isOutgoing and "|cff8080ff" or "|cffff80ff"
                local displayName = isOutgoing and "You" or contact
                formattedMessage = string.format("%s %s%s:|r %s%s|r", timeString, nameColor, displayName, "|cffffffff", cleanMessage)
            end
            
            if not searchTerm then
                fmtCache[i] = formattedMessage
            end
        end
        
        historyFrame:AddMessage(formattedMessage)
    end
    
    historyFrame:ScrollToBottom()
end

function MessageBox:HighlightSearchTerm(text, searchTerm, highlightColor)
    if not text or not searchTerm or searchTerm == "" then return text end
    
    local parts = {}
    local partCount = 0
    local pos = 1
    local textLen = string.len(text)
    local termLen = string.len(searchTerm)
    
    while pos <= textLen do
        if string.sub(text, pos, pos) == "|" then
            local nextChar = string.sub(text, pos + 1, pos + 1)
            if nextChar == "c" then
                partCount = partCount + 1
                parts[partCount] = string.sub(text, pos, pos + 9)
                pos = pos + 10
            elseif nextChar == "r" then
                partCount = partCount + 1
                parts[partCount] = "|r"
                pos = pos + 2
            elseif nextChar == "H" or nextChar == "h" then
                local endPos = string.find(text, "|", pos + 1)
                if endPos then
                    partCount = partCount + 1
                    parts[partCount] = string.sub(text, pos, endPos + 1)
                    pos = endPos + 2
                else
                    partCount = partCount + 1
                    parts[partCount] = string.sub(text, pos)
                    break
                end
            else
                partCount = partCount + 1
                parts[partCount] = string.sub(text, pos, pos)
                pos = pos + 1
            end
        else
            local chunk = string.sub(text, pos, pos + termLen - 1)
            if string.lower(chunk) == searchTerm then
                partCount = partCount + 1
                parts[partCount] = highlightColor .. chunk .. "|r|cffffffff"
                pos = pos + termLen
            else
                local batchStart = pos
                pos = pos + 1
                while pos <= textLen do
                    local ch = string.sub(text, pos, pos)
                    if ch == "|" then break end
                    local ahead = string.sub(text, pos, pos + termLen - 1)
                    if string.lower(ahead) == searchTerm then break end
                    pos = pos + 1
                end
                partCount = partCount + 1
                parts[partCount] = string.sub(text, batchStart, pos - 1)
            end
        end
    end
    
    return table.concat(parts)
end

function MessageBox:SearchConversation(contact, searchTerm)
    local results = {}
    if not contact or not searchTerm or searchTerm == "" then return results end
    
    local c = self.conversations[contact]
    if not c or not c.messages then return results end
    
    local lowerTerm = string.lower(searchTerm)
    local totalMessages = self:GetCount(c)
    
    for i = 1, totalMessages do
        if not c.system[i] then
            local msg = c.messages[i]
            if msg and string.find(string.lower(msg), lowerTerm, 1, true) then
                table.insert(results, i)
            end
        end
    end
    
    return results
end

function MessageBox:ChatSearchNavigate(delta)
    if not self.chatSearchActive then return end
    local count = table.getn(self.chatSearchResults)
    if count == 0 then return end
    
    self.chatSearchCurrentIndex = self.chatSearchCurrentIndex + delta
    if self.chatSearchCurrentIndex > count then
        self.chatSearchCurrentIndex = 1
    elseif self.chatSearchCurrentIndex < 1 then
        self.chatSearchCurrentIndex = count
    end
    
    -- Jump scrollbar to the matched message
    local msgIndex = self.chatSearchResults[self.chatSearchCurrentIndex]
    if self.chatScrollBar then
        self.chatScrollBar.isUpdating = true
        self.chatScrollBar:SetMinMaxValues(1, self:GetCount(self.conversations[self.selectedContact]))
        self.chatScrollBar:SetValue(msgIndex)
        self.chatScrollBar.isUpdating = false
    end
    
    self:UpdateChatHistory()
    self:UpdateSearchCountLabel()
end

function MessageBox:UpdateSearchCountLabel()
    if not self.searchCountText then return end
    local count = table.getn(self.chatSearchResults)
    if not self.chatSearchActive or self.chatSearchTerm == "" then
        self.searchCountText:SetText("")
    elseif count == 0 then
        self.searchCountText:SetText("|cffff4444No matches|r")
    else
        self.searchCountText:SetText(self.chatSearchCurrentIndex .. "/" .. count)
    end
end

function MessageBox:CloseSearchBar()
    self.chatSearchActive = false
    self.chatSearchTerm = ""
    self.chatSearchResults = {}
    self.chatSearchCurrentIndex = 0
    
    if self.searchBarFrame then
        self.searchBarFrame:Hide()
    end
    
    if self.chatHistory and self.chatHeader then
        self.chatHistory:SetPoint("TOPLEFT", self.chatHeader, "BOTTOMLEFT", 8, -10)
    end
    
    if self.selectedContact and self.conversations[self.selectedContact] then
        self.conversations[self.selectedContact]._fmtCache = nil
    end
    
    self:UpdateChatHistory()

end
