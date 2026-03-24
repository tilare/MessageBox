local MAIN_ALPHA = 0.8
local MODAL_ALPHA = 0.8
local CONTACT_TINT_ALPHA = 0.14
local CHAT_TINT_ALPHA = 0.06

local function canRun()
    return IsAddOnLoaded("pfUI") and pfUI and pfUI.api and pfUI.env and pfUI.env.C and pfUI_config
end

local function isMessageBoxPfUISkinEnabled()
    if not canRun() then return false end
    if pfUI_config.disabled and pfUI_config.disabled["skin_MessageBox"] == "1" then
        return false
    end
    return true
end

local function syncBackdropColors(frame, maxAlpha)
    if not frame or not frame.backdrop or not canRun() then return end
    local br, bg, bb, ba = pfUI.api.GetStringColor(pfUI_config.appearance.border.background)
    local er, eg, eb, ea = pfUI.api.GetStringColor(pfUI_config.appearance.border.color)
    br, bg, bb, ba = tonumber(br) or 0, tonumber(bg) or 0, tonumber(bb) or 0, tonumber(ba) or 1
    er, eg, eb, ea = tonumber(er) or 1, tonumber(eg) or 1, tonumber(eb) or 1, tonumber(ea) or 1
    if maxAlpha then
        ba = math.min(ba, maxAlpha)
    end
    frame.backdrop:SetBackdropColor(br, bg, bb, ba)
    frame.backdrop:SetBackdropBorderColor(er, eg, eb, ea)
end

local function skinModalFrame(frame, transp, inset)
    if not frame or not canRun() then return end
    inset = inset or 10
    frame:SetBackdrop(nil)
    if not frame.backdrop then
        pfUI.api.CreateBackdrop(frame, nil, nil, transp or MODAL_ALPHA)
        pcall(function()
            pfUI.api.CreateBackdropShadow(frame)
        end)
    else
        syncBackdropColors(frame, transp or MODAL_ALPHA)
    end
    if frame.backdrop then
        frame.backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
        frame.backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
    end
end

local function skinMainWindow(f)
    if not f or not canRun() then return end
    f:SetBackdrop(nil)
    if not f.backdrop then
        pfUI.api.CreateBackdrop(f, nil, nil, MAIN_ALPHA)
        pcall(function()
            pfUI.api.CreateBackdropShadow(f)
        end)
    else
        syncBackdropColors(f, MAIN_ALPHA)
    end
end

local function clearInnerPanels()
    if MessageBox.contactFrame then
        MessageBox.contactFrame:SetBackdrop(nil)
    end
    if MessageBox.chatFrame then
        MessageBox.chatFrame:SetBackdrop(nil)
    end
    if MessageBox.chatHeader then
        MessageBox.chatHeader:SetBackdrop(nil)
    end
end

local function ensureTintOverlay(parent, key, alpha)
    if not parent or not canRun() then return end
    local name = "_pfUIMBTintTex_" .. key
    local tex = parent[name]
    if not tex then
        tex = parent:CreateTexture(nil, "BACKGROUND")
        parent[name] = tex
    end
    tex:SetAllPoints(parent)
    tex:SetTexture(0, 0, 0, alpha)
    tex:Show()
end

local function updateContactChatDivider(mainFrame)
    if not mainFrame or not MessageBox.contactFrame or not canRun() then return end
    local cf = MessageBox.contactFrame
    local d = mainFrame.pfUIMBContactDivider
    if not d then
        d = CreateFrame("Frame", nil, mainFrame)
        d:SetWidth(1)
        d:SetFrameStrata(mainFrame:GetFrameStrata())
        d:SetFrameLevel(mainFrame:GetFrameLevel() + 2)
        d:EnableMouse(false)
        local t = d:CreateTexture(nil, "ARTWORK")
        t:SetAllPoints(d)
        d.tex = t
        mainFrame.pfUIMBContactDivider = d
    end
    local er, eg, eb = pfUI.api.GetStringColor(pfUI_config.appearance.border.color)
    er, eg, eb = tonumber(er) or 0.25, tonumber(eg) or 0.25, tonumber(eb) or 0.25
    d.tex:SetVertexColor(er, eg, eb, 0.45)
    d:SetPoint("TOP", cf, "TOPRIGHT", 3, 0)
    d:SetPoint("BOTTOM", cf, "BOTTOMRIGHT", 3, 0)
    d:Show()
end

local function updateChatHeaderRule()
    local ch = MessageBox.chatHeader
    if not ch or not canRun() then return end
    local rule = ch.pfUIMBHeaderRule
    if not rule then
        rule = ch:CreateTexture(nil, "OVERLAY")
        rule:SetHeight(1)
        ch.pfUIMBHeaderRule = rule
    end
    local er, eg, eb = pfUI.api.GetStringColor(pfUI_config.appearance.border.color)
    er, eg, eb = tonumber(er) or 0.25, tonumber(eg) or 0.25, tonumber(eb) or 0.25
    rule:SetTexture(er, eg, eb, 0.35)
    rule:ClearAllPoints()
    rule:SetPoint("BOTTOMLEFT", ch, "BOTTOMLEFT", 4, 0)
    rule:SetPoint("BOTTOMRIGHT", ch, "BOTTOMRIGHT", -4, 0)
    rule:Show()
end

local function skinInputStrip(inputBackdrop)
    if not inputBackdrop or not canRun() then return end
    inputBackdrop:SetBackdrop(nil)
    if not inputBackdrop.backdrop then
        pfUI.api.CreateBackdrop(inputBackdrop, nil, nil, nil)
    else
        syncBackdropColors(inputBackdrop, nil)
    end
end

local function skinContactSearchBox()
    local sb = getglobal("MessageBoxContactSearch")
    if not sb or not canRun() then return end
    local left = getglobal(sb:GetName() .. "Left")
    local middle = getglobal(sb:GetName() .. "Middle")
    local right = getglobal(sb:GetName() .. "Right")
    if left then left:Hide() end
    if middle then middle:Hide() end
    if right then right:Hide() end
    sb:SetBackdrop(nil)
    if not sb.backdrop then
        pfUI.api.CreateBackdrop(sb, nil, nil, 0.85)
    else
        syncBackdropColors(sb, 0.85)
    end
end

local function skinClose(btn, parentFrame)
    if not btn or not canRun() then return end
    pcall(function()
        pfUI.api.SkinCloseButton(btn, parentFrame or btn:GetParent(), -6, -6)
    end)
end

local function skinStdButton(btn)
    if not btn or not canRun() then return end
    pcall(function()
        pfUI.api.SkinButton(btn)
    end)
end

-- Same pattern as Outfitter category rows: pfUI SkinCollapseButton + Blizzard +/- paths for the hook.
local TEX_UI_PLUS = "Interface\\Buttons\\UI-PlusButton-Up"
local TEX_UI_MINUS = "Interface\\Buttons\\UI-MinusButton-Up"

local function skinCollapseSectionToggle(btn, blizzardNormalTex)
    if not btn or not canRun() then return end
    pcall(function()
        pfUI.api.SkinCollapseButton(btn)
        -- SkinCollapseButton uses a child Button for the +/- chrome; it would steal clicks from the parent.
        if btn.icon then
            btn.icon:EnableMouse(false)
        end
        if btn.icon and btn.icon.backdrop then
            btn.icon.backdrop:SetPoint("TOPLEFT", -2, 1)
            btn.icon.backdrop:SetPoint("BOTTOMRIGHT", 1, -2)
        end
        btn:SetNormalTexture(blizzardNormalTex)
    end)
end

local function skinCheckbox(cb, size)
    if not cb or not canRun() then return end
    pcall(function()
        pfUI.api.SkinCheckbox(cb, size or 18)
    end)
end

local function skinChatSearchBarFrame()
    if not MessageBox.searchBarFrame or not canRun() then return end
    local bar = MessageBox.searchBarFrame
    bar:SetBackdrop(nil)
    if not bar.backdrop then
        pfUI.api.CreateBackdrop(bar, nil, nil, 0.75)
    else
        syncBackdropColors(bar, 0.75)
    end
    if bar.searchInput then
        bar.searchInput:SetBackdrop(nil)
        if not bar.searchInput.backdrop then
            pfUI.api.CreateBackdrop(bar.searchInput, nil, nil, 0.75)
        else
            syncBackdropColors(bar.searchInput, 0.75)
        end
    end
    skinStdButton(bar.prevBtn)
    skinStdButton(bar.nextBtn)
    if bar.closeBtn then skinClose(bar.closeBtn, bar.backdrop or bar) end
end

local function resetPfUIScrollbarChildren(sb)
    if not sb then return end
    pcall(function()
        if sb.bg then
            sb.bg:Hide()
            sb.bg:SetParent(nil)
        end
        if sb.thumb then
            sb.thumb:Hide()
            sb.thumb:SetParent(nil)
        end
    end)
    sb.bg = nil
    sb.thumb = nil
end

local function skinScroll(sb)
    if not sb or not canRun() then return end
    if sb.track then
        sb.track:Hide()
    end

    local name = sb:GetName()
    if not name then return end

    local up = getglobal(name .. "ScrollUpButton")
    local down = getglobal(name .. "ScrollDownButton")
    local top = getglobal(name .. "Top")
    local mid = getglobal(name .. "Middle")
    local bot = getglobal(name .. "Bottom")
    local nativeThumb = getglobal(name .. "ThumbTexture")

    if up then up:Show() end
    if down then down:Show() end
    if top then top:Hide() end
    if mid then mid:Hide() end
    if bot then bot:Hide() end

    resetPfUIScrollbarChildren(sb)

    if nativeThumb then
        nativeThumb:SetTexture("Interface\\Buttons\\WHITE8X8")
        nativeThumb:SetVertexColor(0.85, 0.85, 0.85, 0.35)
        nativeThumb:SetWidth(math.min(10, math.max(4, (sb:GetWidth() or 16) - 4)))
    end

    pcall(function()
        pfUI.api.SkinScrollbar(sb)
    end)

    nativeThumb = getglobal(name .. "ThumbTexture")
    local insetY = 6
    if sb.thumb and nativeThumb then
        sb.thumb:ClearAllPoints()
        sb.thumb:SetPoint("TOPLEFT", nativeThumb, "TOPLEFT", 0, -insetY)
        sb.thumb:SetPoint("BOTTOMRIGHT", nativeThumb, "BOTTOMRIGHT", 0, insetY)
        sb.thumb:SetTexture(1, 1, 1, 1)
        sb.thumb:SetVertexColor(0.42, 0.42, 0.42, 0.95)
    elseif sb.thumb then
        sb.thumb:SetVertexColor(0.42, 0.42, 0.42, 0.95)
    end

    if sb.bg and sb.bg.SetBackdropColor then
        local br, bg, bb, ba = pfUI.api.GetStringColor(pfUI_config.appearance.border.background)
        br, bg, bb, ba = tonumber(br) or 0, tonumber(bg) or 0, tonumber(bb) or 0, tonumber(ba) or 1
        pcall(function()
            sb.bg:SetBackdropColor(br, bg, bb, math.min(ba, 0.5))
        end)
    end
end

local function skinDetached()
    if not MessageBox.detachedWindows then return end
    for _, win in pairs(MessageBox.detachedWindows) do
        if win then
            skinModalFrame(win, MODAL_ALPHA, 10)
            if win.closeBtn then skinClose(win.closeBtn, win.backdrop or win) end
            if win.scrollBar then skinScroll(win.scrollBar) end
            if win.inputBackdrop then skinInputStrip(win.inputBackdrop) end
        end
    end
end

function MessageBoxPfUI_ApplyAfterTheme()
    if not isMessageBoxPfUISkinEnabled() then return end
    if not MessageBox then return end

    skinDetached()

    local f = MessageBox.frame
    if f then
        clearInnerPanels()
        skinMainWindow(f)

        if MessageBox.contactFrame then
            ensureTintOverlay(MessageBox.contactFrame, "contact", CONTACT_TINT_ALPHA)
        end
        if MessageBox.chatFrame then
            ensureTintOverlay(MessageBox.chatFrame, "chat", CHAT_TINT_ALPHA)
        end
        updateContactChatDivider(f)
        updateChatHeaderRule()

        skinContactSearchBox()

        if MessageBox.inputBackdrop then
            skinInputStrip(MessageBox.inputBackdrop)
        end

        if MessageBox.closeButton then skinClose(MessageBox.closeButton, f.backdrop or f) end

        skinStdButton(MessageBox.sendButton)
        skinStdButton(MessageBox.deleteButton)
        skinStdButton(MessageBox.deleteAllButton)
        skinStdButton(MessageBox.settingsButton)

        if MessageBox.friendsHeader then
            skinCollapseSectionToggle(MessageBox.friendsHeader.plusButton, TEX_UI_PLUS)
            skinCollapseSectionToggle(MessageBox.friendsHeader.minusButton, TEX_UI_MINUS)
        end
        if MessageBox.conversationsHeader then
            skinCollapseSectionToggle(MessageBox.conversationsHeader.plusButton, TEX_UI_PLUS)
            skinCollapseSectionToggle(MessageBox.conversationsHeader.minusButton, TEX_UI_MINUS)
        end

        skinScroll(getglobal("MessageBoxFriendsScrollScrollBar"))
        skinScroll(getglobal("MessageBoxConversationsScrollScrollBar"))
        skinScroll(getglobal("MessageBoxChatHistoryScrollBar"))
    end

    if MessageBox.settingsFrame then
        local sf = MessageBox.settingsFrame
        skinModalFrame(sf, MODAL_ALPHA, 12)
        if sf.closeBtn then skinClose(sf.closeBtn, sf.backdrop or sf) end
        if sf.checks then
            for _, check in pairs(sf.checks) do
                skinCheckbox(check, 18)
            end
        end
        if sf.fontSlider and not sf.fontSlider._pfUIMBSkinSlider then
            pcall(function()
                pfUI.api.SkinSlider(sf.fontSlider)
                sf.fontSlider._pfUIMBSkinSlider = true
            end)
        end
    end

    if MessageBox.themeFrame then
        local tf = MessageBox.themeFrame
        skinModalFrame(tf, MODAL_ALPHA, 12)
        if tf.closeBtn then skinClose(tf.closeBtn, tf.backdrop or tf) end
        skinStdButton(tf.resetBtn)
    end

    if MessageBox.copyPopup then
        local c = MessageBox.copyPopup
        skinModalFrame(c, MODAL_ALPHA, 10)
        for _, child in pairs({ c:GetChildren() }) do
            if child and child:GetObjectType() == "Button" then
                skinStdButton(child)
                break
            end
        end
    end

    if MessageBox.notificationList then
        skinModalFrame(MessageBox.notificationList, 0.75, 6)
    end

    skinChatSearchBarFrame()
end

local hooksInstalled = false

local function installHooks()
    if hooksInstalled or not MessageBox then return end
    hooksInstalled = true

    local origApply = MessageBox.ApplyTheme
    MessageBox.ApplyTheme = function(self)
        origApply(self)
        MessageBoxPfUI_ApplyAfterTheme()
    end

    local origCreate = MessageBox.CreateFrame
    MessageBox.CreateFrame = function(self)
        origCreate(self)
        MessageBoxPfUI_ApplyAfterTheme()
    end

    local origCopy = MessageBox.ShowCopyPopup
    MessageBox.ShowCopyPopup = function(self, url)
        origCopy(self, url)
        MessageBoxPfUI_ApplyAfterTheme()
    end
end

function MessageBox_pfUISkin()
    if not (IsAddOnLoaded("pfUI") and pfUI and pfUI.api and pfUI.env and pfUI.env.C) then
        return
    end
    installHooks()
    pfUI:RegisterSkin("MessageBox", "vanilla", function()
        MessageBoxPfUI_ApplyAfterTheme()
    end)
end
