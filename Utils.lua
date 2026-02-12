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
            thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
            
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
            thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
            thumb:SetVertexColor(1, 1, 1, 1)
            thumb:SetWidth(18)
        end
    end
end

function MessageBox:IsFriend(name)
    for i = 1, GetNumFriends() do
        local fName = GetFriendInfo(i)
        if fName and string.lower(fName) == string.lower(name) then
            return true
        end
    end
    return false
end

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
