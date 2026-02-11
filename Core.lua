-- Core.lua
-- Data structures

MessageBox = {}
MessageBox.conversations = {}
MessageBox.settings = {}
MessageBox.unreadCounts = {}

MessageBox.friendRows = {}
MessageBox.conversationRows = {}
MessageBox.visibleFriends = {}
MessageBox.visibleConversations = {}

MessageBox.playerCache = {}
MessageBox.detachedWindows = {} 

-- Who request queue
MessageBox.whoQueue = {} 
MessageBox.whoTimer = 0
MessageBox.WHO_INTERVAL = 30 
MessageBox.waitingForWhoResult = false
MessageBox.currentWhoEntry = nil 

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
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = {left = 11, right = 12, top = 12, bottom = 11}
        },
        mainColor = {1, 1, 1, 1},
        mainBorderColor = {1, 1, 1, 1},
        panelBackdrop = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        },
        panelColor = {0, 0, 0, 0.8},
        panelBorderColor = {1, 1, 1, 1},
        inputBackdrop = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 5, right = 5, top = 5, bottom = 5}
        },
        inputColor = {0, 0, 0, 0.6},
        flatButtons = false
    },
    modern = {
        mainBackdrop = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        },
        mainBorderColor = {0, 0, 0, 1},       
        panelBackdrop = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        },
        panelBorderColor = {0.25, 0.25, 0.25, 1},
        inputBackdrop = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        },
        flatButtons = true
    }
}