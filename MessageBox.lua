-- MessageBox.lua
-- Main events, Slash commands, Init hooks

function MessageBox:OnLoad()
    MessageBox.transientMessages = nil 

    MessageBox.eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    MessageBox.eventFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
    MessageBox.eventFrame:RegisterEvent("PLAYER_LOGIN")
    MessageBox.eventFrame:RegisterEvent("FRIENDLIST_UPDATE")
    MessageBox.eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    MessageBox.eventFrame:RegisterEvent("WHO_LIST_UPDATE")
    
    SLASH_MESSAGEBOX1 = "/messagebox"
    SLASH_MESSAGEBOX2 = "/mb"
    SLASH_MESSAGEBOX3 = "/mbox"
    
    SlashCmdList["MESSAGEBOX"] = function(msg)
        if msg then
            local cmd = string.lower(msg)
            if cmd == "queue" then
                MessageBox:PrintWhoQueue()
                return
            elseif cmd == "clear" then
                MessageBox:ClearWhoQueue()
                return
            elseif cmd == "stress" then
                MessageBox:RunStressTest()
                return
            end
        end
        MessageBox:ToggleFrame()
    end

    MessageBox:SetupHooks()
    
    MessageBox.eventFrame:SetScript("OnUpdate", function()
        MessageBox:ProcessWhoQueue()
    end)

    DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: loaded! Use /messagebox, /mb, or /mbox to open.")
end

function MessageBox:OnEvent(event)
    if event == "PLAYER_LOGIN" then
        
        if not MessageBoxDB then
            MessageBoxDB = {}
        end

        local playerName = UnitName("player")
        local realmName = GetRealmName()
        local oldKey = playerName .. "-" .. realmName

        if MessageBoxSavedData and MessageBoxSavedData[oldKey] then
            DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Upgrading database for " .. playerName .. "...")
            
            local oldConversations = MessageBoxSavedData[oldKey]
            
            for contact, messages in pairs(oldConversations) do
                if type(messages) == "table" and table.getn(messages) > 0 then
                    local soa = {
                        messages = {},
                        times = {},
                        outgoing = {},
                        system = {},
                        pinned = false 
                    }
                    
                    for i, msg in ipairs(messages) do
                        table.insert(soa.messages, msg.message or "")
                        table.insert(soa.times, msg.time or time())
                        table.insert(soa.outgoing, msg.outgoing or false)
                        table.insert(soa.system, msg.system or false)
                    end
                    
                    MessageBoxDB[contact] = soa
                end
            end
            
            MessageBoxSavedData[oldKey] = nil
            DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Migration complete! Old data removed from global cache.")
        end

        MessageBox.conversations = MessageBoxDB

        local defaultSettings = {
            friendsListCollapsed = false,
            conversationsListCollapsed = false,
            unreadCounts = {},
            popupNotificationsEnabled = true,
            notificationPopupPosition = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -200 },
            modernTheme = true,
            hideOffline = false,
            use12HourFormat = false,
            showMinimapButton = true,
            interceptWhispers = true,
            backgroundWho = true,
            chatFontSize = 10,
            
            mainColor = {0.08, 0.08, 0.1, 0.95},
            panelColor = {0.15, 0.15, 0.17, 0.6},
            inputColor = {0.1, 0.1, 0.1, 0.8},
            highlightColor = {0.8, 0.8, 0.8, 1}, 
        }
        
        if not MessageBoxSettings then
            MessageBoxSettings = defaultSettings
        else
            for key, value in pairs(defaultSettings) do
                if MessageBoxSettings[key] == nil then
                    MessageBoxSettings[key] = value
                end
            end
        end
        
        MessageBox.settings = MessageBoxSettings
        MessageBox.unreadCounts = MessageBox.settings.unreadCounts

        MessageBox.searchQuery = "" 
        MessageBox:CreateMinimapButton()

    elseif event == "CHAT_MSG_WHISPER" then
        local message = arg1
        local sender = arg2
        MessageBox:AddToWhoQueue(sender)
        MessageBox:AddMessage(sender, message, false)

    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local message = arg1
        local recipient = arg2
        
        MessageBox:AddToWhoQueue(recipient) 

        local convo = MessageBox.conversations[recipient]
        if convo and convo.messages then
            local count = table.getn(convo.messages)
            if count > 0 then
                if convo.outgoing[count] and convo.messages[count] == message then
                    return
                end
            end
        end
        
        MessageBox:AddMessage(recipient, message, true)
        
    elseif event == "CHAT_MSG_SYSTEM" then
        local sysMessage = arg1
        local _, _, playerName = string.find(sysMessage, "No player named '(.+)' is currently playing.")
        
        if playerName then
            local convo = MessageBox.conversations[playerName]
            if convo and convo.messages and table.getn(convo.messages) > 0 then
                local count = table.getn(convo.messages)
                if convo.outgoing[count] then
                    MessageBox:RemoveLastMessage(playerName)
                    MessageBox:AddSystemMessage(playerName, playerName .. " is offline.", true)
                end
            end
        end

    elseif event == "FRIENDLIST_UPDATE" then
        if MessageBox.frame and MessageBox.frame:IsVisible() then
            MessageBox:UpdateContactList()
        end
        
    elseif event == "WHO_LIST_UPDATE" then
        MessageBox:HandleWhoResult()
    end
end

-- Debug

function MessageBox:RunStressTest()
    DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Generating 1000 dummies with 1000 messages each. Screen may freeze momentarily...")
    
    local baseTime = time() - (1000 * 60)
    
    for k = 1, 1000 do
        local name = "Dummy" .. k
        
        MessageBox.conversations[name] = {
            messages = {},
            times = {},
            outgoing = {},
            system = {},
            pinned = false
        }
        
        local c = MessageBox.conversations[name]
        
        for i = 1, 1000 do
            local isOut = (math.mod(i, 2) == 0)
            local txt = "Stress test message #" .. i .. " - This is a somewhat long line of text to ensure wrapping works correctly in the scrolling frame."
            
            table.insert(c.messages, txt)
            table.insert(c.times, baseTime + (i*60))
            table.insert(c.outgoing, isOut)
            table.insert(c.system, false)
        end
        
        if math.mod(k, 10) == 0 then
            MessageBox.unreadCounts[name] = 5
        end
    end
    
    MessageBox:UpdateContactList()
    MessageBox:UpdateMinimapBadge()
    DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Stress test data populated. Use the Delete All button to clear them later.")
end

local original_ContainerFrameItemButton_OnClick = ContainerFrameItemButton_OnClick
function ContainerFrameItemButton_OnClick(button, ignoreModifiers)
    if button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers then
        if MessageBox.whisperInput and MessageBox.whisperInput:IsVisible() then
            local useMessageBox = false
            
            if MessageBox.isInputFocused then 
                useMessageBox = true 
            
            elseif MessageBox.lastFocusTime and (GetTime() - MessageBox.lastFocusTime) < 3.0 then 
                useMessageBox = true
            
            elseif not ChatFrameEditBox:IsVisible() then 
                useMessageBox = true 
            end

            if useMessageBox then
                local link = GetContainerItemLink(this:GetParent():GetID(), this:GetID())
                if link then
                    MessageBox.whisperInput:Insert(link)
                    MessageBox.whisperInput:SetFocus()
                    return
                end
            end
        end
    end
    return original_ContainerFrameItemButton_OnClick(button, ignoreModifiers)
end

local original_PaperDollItemSlotButton_OnClick = PaperDollItemSlotButton_OnClick
function PaperDollItemSlotButton_OnClick(button, ignoreModifiers)
    if button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers then
        if MessageBox.whisperInput and MessageBox.whisperInput:IsVisible() then
            local useMessageBox = false
            
            if MessageBox.isInputFocused then 
                useMessageBox = true 
            elseif MessageBox.lastFocusTime and (GetTime() - MessageBox.lastFocusTime) < 3.0 then 
                useMessageBox = true
            elseif not ChatFrameEditBox:IsVisible() then 
                useMessageBox = true 
            end

            if useMessageBox then
                local link = GetInventoryItemLink("player", this:GetID())
                if link then
                    MessageBox.whisperInput:Insert(link)
                    MessageBox.whisperInput:SetFocus()
                    return
                end
            end
        end
    end
    return original_PaperDollItemSlotButton_OnClick(button, ignoreModifiers)
end

if not MessageBox.original_HandleModifiedItemClick then
    MessageBox.original_HandleModifiedItemClick = HandleModifiedItemClick
end

function HandleModifiedItemClick(link)
    if MessageBox.whisperInput and MessageBox.whisperInput:IsVisible() then
        if MessageBox.isInputFocused or (MessageBox.lastFocusTime and (GetTime() - MessageBox.lastFocusTime) < 3.0) then
            MessageBox.whisperInput:Insert(link)
            MessageBox.whisperInput:SetFocus()
            return
        end
    end
    return MessageBox.original_HandleModifiedItemClick(link)
end

MessageBox.eventFrame = CreateFrame("Frame", "MessageBoxEventFrame")

MessageBox.eventFrame:SetScript("OnEvent", function() 
    MessageBox:OnEvent(event) 
end)

MessageBox:OnLoad()
