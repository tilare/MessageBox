-- MessageBox.lua
-- Main events, Slash commands, Init hooks

function MessageBox:OnLoad()

    MessageBox.eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    MessageBox.eventFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
    MessageBox.eventFrame:RegisterEvent("PLAYER_LOGIN")
    MessageBox.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    MessageBox.eventFrame:RegisterEvent("FRIENDLIST_UPDATE")
    MessageBox.eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    MessageBox.eventFrame:RegisterEvent("WHO_LIST_UPDATE")
    MessageBox.eventFrame:RegisterEvent("CHAT_MSG_AFK")
    MessageBox.eventFrame:RegisterEvent("CHAT_MSG_DND")
    
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
            elseif string.find(cmd, "^stress") then
                local _, _, arg1, arg2 = string.find(msg, "^%S+%s+(%d+)%s+(%d+)")
                local numContacts = tonumber(arg1) or 1000
                local numMessages = tonumber(arg2) or 1000
                MessageBox:RunStressTest(numContacts, numMessages)
                return
            end
        end
        MessageBox:ToggleFrame()
    end

    MessageBox:SetupHooks()
    
    MessageBox.whoElapsed = 0
    MessageBox.eventFrame:SetScript("OnUpdate", function()
        MessageBox.whoElapsed = MessageBox.whoElapsed + arg1
        if MessageBox.whoElapsed < 1 then return end
        MessageBox.whoElapsed = 0
        MessageBox:ProcessWhoQueue()

        -- Periodic crash save flush
        if MessageBox.hasNampower then
            MessageBox.flushElapsed = (MessageBox.flushElapsed or 0) + 1
            if MessageBox.flushElapsed >= MessageBox.FLUSH_INTERVAL then
                MessageBox.flushElapsed = 0
                if MessageBox.crashSaveDirty then
                    MessageBox:FlushToDisk()
                end
            end
        end
    end)

    DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: loaded! Use /messagebox, /mb, or /mbox to open.")
end

function MessageBox:OnEvent(event)
    if event == "PLAYER_LOGIN" then
        
        if not MessageBoxDB then
            MessageBoxDB = {}
        end

        MessageBox.conversations = MessageBoxDB

        if not MessageBoxSettings then
            MessageBoxSettings = {}
            for key, value in pairs(MessageBox.defaultSettings) do
                MessageBoxSettings[key] = value
            end
        else
            for key, value in pairs(MessageBox.defaultSettings) do
                if MessageBoxSettings[key] == nil then
                    MessageBoxSettings[key] = value
                end
            end
        end
        
        MessageBox.settings = MessageBoxSettings
        MessageBox.unreadCounts = MessageBox.settings.unreadCounts

        -- Detect Nampower file I/O and attempt crash recovery
        MessageBox.hasNampower = (WriteCustomFile ~= nil and ReadCustomFile ~= nil and CustomFileExists ~= nil)
        if MessageBox.hasNampower then
            MessageBox:AttemptCrashRecovery()
        end

        -- Register PLAYER_LOGOUT to mark a clean exit
        MessageBox.eventFrame:RegisterEvent("PLAYER_LOGOUT")

        -- Restore persistent GM flags into playerCache
        if MessageBox.settings.gmList then
            for name, _ in pairs(MessageBox.settings.gmList) do
                if not MessageBox.playerCache[name] then
                    MessageBox.playerCache[name] = {}
                end
                MessageBox.playerCache[name].isGM = true
            end
        end

        -- Restore persistent class/level data into playerCache
        if MessageBox.settings.classCache then
            for name, info in pairs(MessageBox.settings.classCache) do
                if not MessageBox.playerCache[name] then
                    MessageBox.playerCache[name] = {}
                end
                if info.class then
                    MessageBox.playerCache[name].class = info.class
                    MessageBox.playerCache[name].classUpper = info.classUpper
                end
                if info.level then
                    MessageBox.playerCache[name].level = info.level
                end
            end
        end

        MessageBox.searchQuery = "" 
        MessageBox:CreateMinimapButton()

        if MessageBox_pfUISkin then
            MessageBox_pfUISkin()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if MessageBox_pfUISkin then
            MessageBox_pfUISkin()
        end

    elseif event == "CHAT_MSG_WHISPER" then
        local message = arg1
        local sender = arg2
        
        -- arg6 == "GM" means the sender is a Game Master
        if arg6 == "GM" then
            if not MessageBox.playerCache[sender] then
                MessageBox.playerCache[sender] = {}
            end
            MessageBox.playerCache[sender].isGM = true
            -- Persist GM status
            if MessageBox.settings.gmList then
                MessageBox.settings.gmList[sender] = true
            end
        else
            MessageBox:AddToWhoQueue(sender)
        end
        
        MessageBox:AddMessage(sender, message, false)

    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local message = arg1
        local recipient = arg2
        
        -- arg6 == "GM" means the recipient is a Game Master
        if arg6 == "GM" then
            if not MessageBox.playerCache[recipient] then
                MessageBox.playerCache[recipient] = {}
            end
            MessageBox.playerCache[recipient].isGM = true
            -- Persist GM status so it survives reload/relog
            if MessageBox.settings.gmList then
                MessageBox.settings.gmList[recipient] = true
            end
        else
            MessageBox:AddToWhoQueue(recipient) 
        end

        local convo = MessageBox.conversations[recipient]
        if convo and convo.messages then
            local count = MessageBox:GetCount(convo)
            if count > 0 then
                -- Strip color codes for comparison in case the server
                -- returns a modified version (TurtleWoW GM whispers)
                local storedMsg = string.gsub(convo.messages[count], "|c%x%x%x%x%x%x%x%x", "")
                storedMsg = string.gsub(storedMsg, "|r", "")
                local incomingMsg = string.gsub(message, "|c%x%x%x%x%x%x%x%x", "")
                incomingMsg = string.gsub(incomingMsg, "|r", "")
                
                if convo.outgoing[count] and storedMsg == incomingMsg then
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
            if convo and convo.messages and MessageBox:GetCount(convo) > 0 then
                local count = MessageBox:GetCount(convo)
                if convo.outgoing[count] then
                    MessageBox:RemoveLastMessage(playerName)
                    MessageBox:AddSystemMessage(playerName, playerName .. " is offline.", true)
                end
            end
        end

    elseif event == "FRIENDLIST_UPDATE" then
        if MessageBox.frame and MessageBox.frame:IsVisible() then
            MessageBox:MarkContactListDirty()
        end
        
    elseif event == "WHO_LIST_UPDATE" then
        MessageBox:HandleWhoResult()
    
    elseif event == "CHAT_MSG_AFK" then
        local message = arg1
        local sender = arg2
        if sender and MessageBox.conversations[sender] then
            if not MessageBox.playerCache[sender] then MessageBox.playerCache[sender] = {} end
            MessageBox.playerCache[sender].status = "<AFK>"
            MessageBox:AddSystemMessage(sender, sender .. " is AFK: " .. (message or "Away from Keyboard"))
            if MessageBox.frame and MessageBox.frame:IsVisible() and MessageBox.selectedContact == sender then
                MessageBox:UpdateChatHeader()
            end
        end
    
    elseif event == "CHAT_MSG_DND" then
        local message = arg1
        local sender = arg2
        if sender and MessageBox.conversations[sender] then
            if not MessageBox.playerCache[sender] then MessageBox.playerCache[sender] = {} end
            MessageBox.playerCache[sender].status = "<DND>"
            MessageBox:AddSystemMessage(sender, sender .. " is DND: " .. (message or "Do not Disturb"))
            if MessageBox.frame and MessageBox.frame:IsVisible() and MessageBox.selectedContact == sender then
                MessageBox:UpdateChatHeader()
            end
        end
    
    elseif event == "PLAYER_LOGOUT" then
        MessageBox:FlushToDisk()
        MessageBox:WriteCrashSaveClean()
    end
end

-- Debug

function MessageBox:RunStressTest(numContacts, numMessages)
    numContacts = numContacts or 1000
    numMessages = numMessages or 1000
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Generating " .. numContacts .. " dummies with " .. numMessages .. " messages each. Screen may freeze momentarily...")
    
    local baseTime = time() - (numMessages * 60)
    
    for k = 1, numContacts do
        local name = "Dummy" .. k
        
        MessageBox.conversations[name] = MessageBox:NewConversation()
        
        local c = MessageBox.conversations[name]
        
        for i = 1, numMessages do
            local isOut = (math.mod(i, 2) == 0)
            local txt = "Stress test message #" .. i .. " - This is a somewhat long line of text to ensure wrapping works correctly in the scrolling frame."
            
            table.insert(c.messages, txt)
            table.insert(c.times, baseTime + (i*60))
            table.insert(c.outgoing, isOut)
            table.insert(c.system, false)
        end
        c.count = numMessages
        
        if math.mod(k, 10) == 0 then
            MessageBox.unreadCounts[name] = 5
        end
    end
    
    MessageBox.conversationOrderDirty = true
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
