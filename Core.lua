-- Core.lua
-- Data structures

BINDING_HEADER_MESSAGEBOX = "MessageBox"
BINDING_NAME_MESSAGEBOX_TOGGLE = "Toggle MessageBox"

MessageBox = {}
MessageBox.conversations = {}
MessageBox.settings = {}
MessageBox.unreadCounts = {}

MessageBox.friendRows = {}
MessageBox.conversationRows = {}
MessageBox.visibleFriends = {}
MessageBox.visibleConversations = {}

MessageBox.playerCache = {}

-- Whisper/chat may supply "Name-Realm"; GetWhoInfo and SendWho use the bare character name.
-- If stripping would remove the whole name (e.g. malformed input), keep the original.
function MessageBox:PlayerNameWithoutRealm(fullName)
    if not fullName or fullName == "" then return nil end
    local h = string.find(fullName, "-", 1, true)
    if not h or h <= 1 then return fullName end
    local short = string.sub(fullName, 1, h - 1)
    if not short or short == "" then return fullName end
    return short
end

MessageBox.detachedWindows = {} 
MessageBox.friendSet = {}
MessageBox.conversationOrderDirty = true
MessageBox.cachedSortedContacts = {}

-- Search state
MessageBox.chatSearchActive = false
MessageBox.chatSearchTerm = ""
MessageBox.chatSearchResults = {}
MessageBox.chatSearchCurrentIndex = 0

-- Nampower crash-save state
MessageBox.hasNampower = false
MessageBox.FLUSH_INTERVAL = 60      -- seconds between periodic auto-saves
MessageBox.FLUSH_MIN_INTERVAL = 10  -- minimum seconds between event-triggered flushes
MessageBox.flushElapsed = 0
MessageBox.lastFlushTime = 0
MessageBox.crashSaveDirty = false

-- Layout constants
MessageBox.layout = {
    MAIN_WIDTH          = 500,
    MAIN_HEIGHT         = 350,
    MIN_WIDTH           = 280,
    MIN_HEIGHT          = 200,
    MAX_WIDTH           = 1000,
    MAX_HEIGHT          = 800,
    CONTACT_WIDTH       = 140,
    SIDEBAR_MIN_WIDTH   = 70,
    ROW_HEIGHT          = 16,
    HEADER_HEIGHT       = 20,
    SEARCH_AREA_HEIGHT  = 30,
    BOTTOM_PADDING      = 10,
    MIDDLE_PADDING      = 18,
    INPUT_HEIGHT        = 28,
    ICON_SIZE           = 16,
    BUTTON_HEIGHT       = 20,
    DETACHED_WIDTH      = 300,
    DETACHED_HEIGHT     = 250,
    DETACHED_MIN_W      = 200,
    DETACHED_MIN_H      = 150,
    DETACHED_MAX_W      = 600,
    DETACHED_MAX_H      = 600,
}

-- Contact list dirty flag
MessageBox.contactListDirty = false
MessageBox.CONTACT_LIST_THROTTLE = 0.1

-- Texture & font paths
local A = "Interface\\AddOns\\MessageBox\\img\\"
local B = "Interface\\Buttons\\"

MessageBox.fonts = {
    openSans        = "Interface\\AddOns\\MessageBox\\font\\OpenSans.ttf",
    frizqt          = "Fonts\\FRIZQT__.TTF",
}

MessageBox.textures = {
    -- Custom addon textures
    closeOutline        = A .. "rectangle-xmark-outline.tga",
    closeSolid          = A .. "rectangle-xmark-solid.tga",
    pin                 = A .. "pin.tga",
    pinSlash            = A .. "pin-slash.tga",
    bellOn              = A .. "bell-on.tga",
    bellOff             = A .. "bell-off-slash.tga",
    envelope            = A .. "envelope-solid.tga",
    envelopeOpen        = A .. "envelope-solid-open.tga",
    palette             = A .. "palette.tga",
    search              = A .. "magnifying-glass.tga",
    caretUp             = A .. "square-caret-up.tga",
    caretUpHi           = A .. "square-caret-up-highlight.tga",
    caretDown           = A .. "square-caret-down.tga",
    caretDownHi         = A .. "square-caret-down-highlight.tga",
    squareSolid         = A .. "square-solid.tga",
    sizeUp              = A .. "sizegrabber-up.tga",
    sizeDown            = A .. "sizegrabber-down.tga",
    sizeHi              = A .. "sizegrabber-highlight.tga",
    gmBadge             = A .. "turtle.tga",

    -- Blizzard: panel buttons
    panelBtnUp          = B .. "UI-Panel-Button-Up",
    panelBtnDown        = B .. "UI-Panel-Button-Down",
    minimizeBtnUp       = B .. "UI-Panel-MinimizeButton-Up",
    minimizeBtnDown     = B .. "UI-Panel-MinimizeButton-Down",
    minimizeBtnHi       = B .. "UI-Panel-MinimizeButton-Highlight",
    minimizeBtnDisabled = B .. "UI-Panel-MinimizeButton-Disabled",
    listHighlight       = B .. "UI-Listbox-Highlight2",
    white8x8            = B .. "WHITE8x8",

    -- Blizzard: plus/minus
    plusUp              = B .. "UI-PlusButton-Up",
    plusDown            = B .. "UI-PlusButton-Down",
    plusHi              = B .. "UI-PlusButton-Highlight",
    minusUp             = B .. "UI-MinusButton-Up",
    minusDown           = B .. "UI-MinusButton-Down",
    minusHi             = B .. "UI-MinusButton-Highlight",

    -- Blizzard: scrollbar
    scrollUpUp          = B .. "UI-ScrollBar-ScrollUpButton-Up",
    scrollUpDown        = B .. "UI-ScrollBar-ScrollUpButton-Down",
    scrollUpHi          = B .. "UI-ScrollBar-ScrollUpButton-Highlight",
    scrollDownUp        = B .. "UI-ScrollBar-ScrollDownButton-Up",
    scrollDownDown      = B .. "UI-ScrollBar-ScrollDownButton-Down",
    scrollDownHi        = B .. "UI-ScrollBar-ScrollDownButton-Highlight",
    scrollKnob          = B .. "UI-ScrollBar-Knob",
    quickslot           = B .. "UI-Quickslot2",

    -- Blizzard: dialog
    dialogBg            = "Interface\\DialogFrame\\UI-DialogBox-Background",
    dialogBorder        = "Interface\\DialogFrame\\UI-DialogBox-Border",

    -- Blizzard: tooltip
    tooltipBg           = "Interface\\Tooltips\\UI-Tooltip-Background",
    tooltipBorder       = "Interface\\Tooltips\\UI-Tooltip-Border",

    -- Blizzard: chat frame
    chatBg              = "Interface\\ChatFrame\\ChatFrameBackground",
    chatUp              = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Up",
    chatDown            = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Down",
    chatBlink           = "Interface\\ChatFrame\\UI-ChatIcon-BlinkHilight",

    -- Blizzard: minimap
    minimapZoomHi       = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight",
    minimapBorder       = "Interface\\Minimap\\MiniMap-TrackingBorder",

    -- Blizzard: icons
    iconLetter          = "Interface\\Icons\\INV_Letter_15",
    iconQuestion        = "Interface\\Icons\\INV_Misc_QuestionMark",
    classIcons          = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes",
    questHighlight      = "Interface\\QuestFrame\\UI-QuestTitleHighlight",
    partyIcon           = "Interface\\WorldMap\\WorldMapPartyIcon",
}

-- Conversation constructor
function MessageBox:NewConversation()
    return {
        messages = {},
        times = {},
        outgoing = {},
        system = {},
        pinned = false,
        count = 0
    }
end

-- Default settings
MessageBox.defaultSettings = {
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
    notificationSound = true,
    suppressWhispers = false,
    
    mainColor = {0.08, 0.08, 0.1, 0.95},
    panelColor = {0.15, 0.15, 0.17, 0.6},
    inputColor = {0.1, 0.1, 0.1, 0.8},
    highlightColor = {0.8, 0.8, 0.8, 1},
    buttonColor = {0.2, 0.2, 0.2, 1},
    textColor = {1, 1, 1, 1},
    selectionColor = {0.8, 0.8, 0.8, 0.4},
    gmList = {},
    classCache = {},  -- Persistent class/level data: { ["Name"] = { class="Mage", classUpper="MAGE", level=60 }, ... }
}

-- Get message count for a conversation
function MessageBox:GetCount(c)
    if not c or not c.messages then return 0 end
    if c.count then return c.count end
    c.count = table.getn(c.messages)
    return c.count
end
MessageBox.whoPlayerQueue = {}
MessageBox.whoScanInProgress = false
MessageBox.whoLastSent = nil
MessageBox.whoPendingName = nil
MessageBox.whoApplyBusy = false
MessageBox.whoPollFrame = nil
MessageBox.whoPollAccum = 0
MessageBox.WHO_INTERVAL = 30
MessageBox.WHO_TIMEOUT = 10
MessageBox.WHO_MAX_ATTEMPTS = 5
MessageBox.WHO_QUEUE_MAX = 50
MessageBox.RENDER_THROTTLE = 0.05
MessageBox.whoSuppressChat = false

MessageBox.URLPattern = {
    WWW = {
      ["rx"]="%s?(www%d-)%.([_A-Za-z0-9-]+)%.(%S+)%s?",
      ["fm"]="%s.%s.%s"},
    PROTOCOL = {
      ["rx"]="%s?(%a+)://(%S+)%s?",
      ["fm"]="%s://%s"},
    EMAIL = {
      ["rx"]="%s?([_A-Za-z0-9-%.:]+)@([_A-Za-z0-9-]+)(%.)([_A-Za-z0-9-]+%.?[_A-Za-z0-9-]*)%s?",
      ["fm"]="%s@%s%s%s"},
    IP = {
      ["rx"]="%s?(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?",
      ["fm"]="%s.%s.%s.%s"},
}

MessageBox.themes = {
    classic = {
        mainBackdrop = {
            bgFile = MessageBox.textures.dialogBg,
            edgeFile = MessageBox.textures.dialogBorder,
            tile = true, tileSize = 32, edgeSize = 32,
            insets = {left = 11, right = 12, top = 12, bottom = 11}
        },
        mainColor = {1, 1, 1, 1},
        mainBorderColor = {1, 1, 1, 1},
        panelBackdrop = {
            bgFile = MessageBox.textures.tooltipBg,
            edgeFile = MessageBox.textures.tooltipBorder,
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        },
        panelColor = {0, 0, 0, 0.8},
        panelBorderColor = {1, 1, 1, 1},
        inputBackdrop = {
            bgFile = MessageBox.textures.tooltipBg,
            edgeFile = MessageBox.textures.tooltipBorder,
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 5, right = 5, top = 5, bottom = 5}
        },
        inputColor = {0, 0, 0, 0.6},
        flatButtons = false
    },
    modern = {
        mainBackdrop = {
            bgFile = MessageBox.textures.chatBg,
            edgeFile = MessageBox.textures.chatBg,
            tile = false, tileSize = 0, edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        },
        mainBorderColor = {0, 0, 0, 1},       
        panelBackdrop = {
            bgFile = MessageBox.textures.chatBg,
            edgeFile = MessageBox.textures.chatBg,
            tile = false, tileSize = 0, edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        },
        panelBorderColor = {0.25, 0.25, 0.25, 1},
        inputBackdrop = {
            bgFile = MessageBox.textures.chatBg,
            edgeFile = MessageBox.textures.chatBg,
            tile = false, tileSize = 0, edgeSize = 1,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        },
        flatButtons = true
    }

}

-- Nampower Crash-Save: Serialization & File I/O
function MessageBox:SerializeValue(val, indent)
    local t = type(val)
    if t == "string" then
        return string.format("%q", val)
    elseif t == "number" then
        return tostring(val)
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "table" then
        return self:SerializeTable(val, indent)
    else
        return "nil"
    end
end

function MessageBox:SerializeTable(tbl, indent)
    indent = indent or 1
    local pad = string.rep(" ", indent * 2)
    local padClose = string.rep(" ", (indent - 1) * 2)
    local parts = {}
    local partCount = 0

    local arrayLen = table.getn(tbl)

    for i = 1, arrayLen do
        partCount = partCount + 1
        parts[partCount] = pad .. self:SerializeValue(tbl[i], indent + 1)
    end

    for k, v in pairs(tbl) do
        local isArrayKey = (type(k) == "number" and k >= 1 and k <= arrayLen and math.floor(k) == k)
        if not isArrayKey then
            local keyStr
            if type(k) == "string" then
                if string.find(k, "^[%a_][%w_]*$") then
                    keyStr = k
                else
                    keyStr = "[" .. string.format("%q", k) .. "]"
                end
            elseif type(k) == "number" then
                keyStr = "[" .. tostring(k) .. "]"
            elseif type(k) == "boolean" then
                keyStr = "[" .. (k and "true" or "false") .. "]"
            else
                keyStr = nil
            end
            if keyStr then
                partCount = partCount + 1
                parts[partCount] = pad .. keyStr .. " = " .. self:SerializeValue(v, indent + 1)
            end
        end
    end

    if partCount == 0 then
        return "{}"
    end
    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. padClose .. "}"
end

function MessageBox:Serialize(data)
    return "return " .. self:SerializeValue(data, 1)
end

function MessageBox:Deserialize(str)
    if not str or str == "" then return nil end
    local func, err = loadstring(str)
    if not func then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Crash-save parse error: " .. (err or "unknown"))
        return nil
    end
    local ok, result = pcall(func)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Crash-save load error: " .. (result or "unknown"))
        return nil
    end
    return result
end

-- Returns the filename for the current character's crash save
function MessageBox:GetCrashSaveFilename()
    local name = UnitName("player") or "Unknown"
    return "MessageBox_" .. name .. ".dat"
end

-- Write current session data to disk via Nampower
function MessageBox:FlushToDisk()
    if not self.hasNampower then return end

    local data = {
        conversations = MessageBoxDB,
        unreadCounts = self.unreadCounts,
        settings = MessageBoxSettings,
        saveTime = time(),
    }

    local ok, serialized = pcall(function() return self:Serialize(data) end)
    if not ok or not serialized then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Crash-save serialize failed.")
        return
    end

    local writeOk, writeErr = pcall(function()
        WriteCustomFile(self:GetCrashSaveFilename(), serialized)
    end)
    if not writeOk then
        DEFAULT_CHAT_FRAME:AddMessage("|cff3cb7f0Message|rBox: Crash-save write failed: " .. (writeErr or "unknown"))
        return
    end

    self.lastFlushTime = GetTime()
    self.crashSaveDirty = false
end

-- do not to recover on next login
function MessageBox:WriteCrashSaveClean()
    if not self.hasNampower then return end
    pcall(function()
        WriteCustomFile(self:GetCrashSaveFilename(), "CLEAN")
    end)
end

-- Attempt to recover data from a crash save file
-- Returns true if recovery happened, false otherwise
function MessageBox:AttemptCrashRecovery()
    if not self.hasNampower then return false end

    local filename = self:GetCrashSaveFilename()

    local exists = false
    pcall(function() exists = CustomFileExists(filename) end)
    if not exists then return false end

    local raw = nil
    local readOk, readErr = pcall(function() raw = ReadCustomFile(filename) end)
    if not readOk or not raw then return false end

    -- no recovery needed
    if raw == "CLEAN" then return false end

    local recovered = self:Deserialize(raw)
    if not recovered or not recovered.saveTime then return false end

    -- Recovery: the crash save file had real data, meaning last session did not exit cleanly. Use the crash save data.
    if recovered.conversations then
        MessageBoxDB = recovered.conversations
        self.conversations = MessageBoxDB
    end

    if recovered.unreadCounts then
        if self.settings then
            self.settings.unreadCounts = recovered.unreadCounts
        end
        self.unreadCounts = recovered.unreadCounts
    end

    if recovered.settings then
        -- Merge recovered settings on top of current settings.
        for key, value in pairs(recovered.settings) do
            MessageBoxSettings[key] = value
        end
        self.settings = MessageBoxSettings
        self.unreadCounts = self.settings.unreadCounts
    end

    return true
end
