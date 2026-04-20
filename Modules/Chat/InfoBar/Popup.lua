local _, ns = ...

local ChatInfoBar = ns.ChatInfoBar or {}
ns.ChatInfoBar = ChatInfoBar

local function CreateBasePopup(frameLevel)
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("TOOLTIP")
    popup:SetFrameLevel(frameLevel or 20)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)

    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    popup:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
    popup:SetBackdropBorderColor(0, 0, 0, 1)

    popup.rows = {}

    popup.accent = popup:CreateTexture(nil, "ARTWORK")
    popup.accent:SetPoint("TOPLEFT", popup, "TOPLEFT", 1, -1)
    popup.accent:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 1, 1)
    popup.accent:SetWidth(3)
    popup.accent:Hide()

    return popup
end

function ChatInfoBar:ApplyPopupStyle(popup, popupKind)
    if not popup then
        return
    end

    local titleColor = { 1, 0.82, 0, 1 }
    local accentColor = { 1, 0.82, 0, 0.9 }
    local borderColor = { 0, 0, 0, 1 }

    if popupKind == "specSelect" then
        titleColor = { 0.35, 0.95, 0.60, 1 }
        accentColor = { 0.20, 0.85, 0.50, 0.9 }
        borderColor = { 0.10, 0.35, 0.20, 1 }
    elseif popupKind == "lootSpecSelect" then
        titleColor = { 1.00, 0.82, 0.20, 1 }
        accentColor = { 0.95, 0.72, 0.18, 0.9 }
        borderColor = { 0.35, 0.25, 0.08, 1 }
    else
        titleColor = { 0.90, 0.90, 0.90, 1 }
        accentColor = { 0.50, 0.50, 0.50, 0.5 }
        borderColor = { 0, 0, 0, 1 }
    end

    if popup.titleText then
        popup.titleText:SetTextColor(titleColor[1], titleColor[2], titleColor[3], titleColor[4])
    end

    if popup.accent then
        popup.accent:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], accentColor[4])
        popup.accent:Show()
    end

    popup:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
end

local function ResetRowVisual(row)
    row.isSelected = false

    if row.selectedBg then
        row.selectedBg:Hide()
    end

    if row.hoverBg then
        row.hoverBg:Hide()
    end

    if row.text then
        row.text:SetTextColor(0.85, 0.85, 0.85)
    end

    if row.icon then
        row.icon:SetAlpha(0.8)
    end
end

function ChatInfoBar:GetOrCreateHoverPopup()
    if self.hoverPopup then
        return self.hoverPopup
    end

    local popup = CreateBasePopup(20)
    popup.ownerButton = nil
    popup.popupKind = nil

    popup:SetScript("OnEnter", function()
        if ChatInfoBar.hidePopupTimer then
            ChatInfoBar.hidePopupTimer:Cancel()
            ChatInfoBar.hidePopupTimer = nil
        end
    end)

    popup:SetScript("OnLeave", function()
        ChatInfoBar:HandleHoverPopupLeave()
    end)

    self.hoverPopup = popup
    return popup
end

function ChatInfoBar:GetOrCreatePersistentPopup()
    if self.persistentPopup then
        return self.persistentPopup
    end

    local popup = CreateBasePopup(22)
    popup.ownerButton = nil
    popup.popupKind = nil

    popup:SetScript("OnEnter", function()
        if ChatInfoBar.hidePopupTimer then
            ChatInfoBar.hidePopupTimer:Cancel()
            ChatInfoBar.hidePopupTimer = nil
        end
    end)

    popup:SetScript("OnLeave", function()
        -- 고정 팝업은 마우스 이탈로 닫지 않음
    end)

    self.persistentPopup = popup
    return popup
end

function ChatInfoBar:GetOrCreatePopupClickCatcher()
    if self.popupClickCatcher then
        return self.popupClickCatcher
    end

    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("TOOLTIP")
    catcher:SetFrameLevel(21)
    catcher:EnableMouse(true)
    catcher:RegisterForClicks("AnyUp")
    catcher:Hide()

    catcher:SetScript("OnClick", function()
        ChatInfoBar:HidePersistentPopup()
    end)

    self.popupClickCatcher = catcher
    return catcher
end

function ChatInfoBar:GetPopupRow(popup, index)
    popup.rows = popup.rows or {}

    if popup.rows[index] then
        return popup.rows[index]
    end

    local row = CreateFrame("Button", nil, popup)
    row:SetHeight(20)
    row:SetPoint("LEFT", popup, "LEFT", 8, 0)
    row:SetPoint("RIGHT", popup, "RIGHT", -8, 0)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0.20)

    row.hoverBg = row:CreateTexture(nil, "HIGHLIGHT")
    row.hoverBg:SetAllPoints()
    row.hoverBg:SetColorTexture(1, 1, 1, 0.10)
    row.hoverBg:Hide()

    row.selectedBg = row:CreateTexture(nil, "ARTWORK")
    row.selectedBg:SetAllPoints()
    row.selectedBg:SetColorTexture(1, 0.82, 0, 0.15)
    row.selectedBg:Hide()

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icon:SetAlpha(0.8)

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetTextColor(0.85, 0.85, 0.85)

    row:SetScript("OnEnter", function(self)
        if ChatInfoBar.hidePopupTimer then
            ChatInfoBar.hidePopupTimer:Cancel()
            ChatInfoBar.hidePopupTimer = nil
        end

        if self.hoverBg then
            self.hoverBg:Show()
        end

        if self.text then
            self.text:SetTextColor(1, 1, 1)
        end

        if self.icon then
            self.icon:SetAlpha(1)
        end
    end)

    row:SetScript("OnLeave", function(self)
        if popup == ChatInfoBar.hoverPopup then
            ChatInfoBar:HandleHoverPopupLeave()
        end

        if self.hoverBg then
            self.hoverBg:Hide()
        end

        if not self.isSelected and self.text then
            self.text:SetTextColor(0.85, 0.85, 0.85)
        end

        if not self.isSelected and self.icon then
            self.icon:SetAlpha(0.8)
        end
    end)

    row:SetScript("OnClick", function(self)
        if self.onClick then
            self.onClick()
        elseif self.targetName then
            if IsAltKeyDown() then
                ChatInfoBar:InvitePlayer(self.targetName)
            else
                ChatFrame_SendTell(self.targetName)
            end
        end

        if popup and popup.rows then
            for _, r in ipairs(popup.rows) do
                ResetRowVisual(r)
            end
        end

        self.isSelected = true

        if self.selectedBg then
            self.selectedBg:Show()
        end

        if self.text then
            self.text:SetTextColor(1, 1, 1)
        end

        if self.icon then
            self.icon:SetAlpha(1)
        end

        if ChatInfoBar.hidePopupTimer then
            ChatInfoBar.hidePopupTimer:Cancel()
            ChatInfoBar.hidePopupTimer = nil
        end

        if popup == ChatInfoBar.persistentPopup then
            ChatInfoBar:HidePersistentPopup()
        else
            ChatInfoBar:HideHoverPopup()
        end
    end)

    popup.rows[index] = row
    return row
end

function ChatInfoBar:LayoutPopupRow(row, entry)
    row.icon:ClearAllPoints()
    row.text:ClearAllPoints()

    local left = 6

    if entry.icon then
        row.icon:SetPoint("LEFT", row, "LEFT", left, 0)
        row.icon:SetTexture(entry.icon)
        row.icon:Show()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    else
        row.icon:Hide()
        row.text:SetPoint("LEFT", row, "LEFT", left, 0)
    end

    row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)

    return left
end

function ChatInfoBar:IsMouseOverHoverPopup()
    local popup = self.hoverPopup
    if not popup or not popup:IsShown() then
        return false
    end

    if popup:IsMouseOver() then
        return true
    end

    if popup.rows then
        for i = 1, #popup.rows do
            local row = popup.rows[i]
            if row and row:IsShown() and row:IsMouseOver() then
                return true
            end
        end
    end

    return false
end

function ChatInfoBar:IsMouseOverPersistentPopup()
    local popup = self.persistentPopup
    if not popup or not popup:IsShown() then
        return false
    end

    if popup:IsMouseOver() then
        return true
    end

    if popup.rows then
        for i = 1, #popup.rows do
            local row = popup.rows[i]
            if row and row:IsShown() and row:IsMouseOver() then
                return true
            end
        end
    end

    return false
end

function ChatInfoBar:HandleHoverPopupLeave()
    if self.hidePopupTimer then
        self.hidePopupTimer:Cancel()
        self.hidePopupTimer = nil
    end

    self.hidePopupTimer = C_Timer.NewTimer(0.08, function()
        if self.slotHovered then
            return
        end

        if self:IsMouseOverHoverPopup() then
            return
        end

        self:HideHoverPopup()
    end)
end

function ChatInfoBar:HideHoverPopup()
    if self.hidePopupTimer then
        self.hidePopupTimer:Cancel()
        self.hidePopupTimer = nil
    end

    if self.hoverPopup then
        self.hoverPopup.ownerButton = nil
        self.hoverPopup.popupKind = nil
        self.hoverPopup:Hide()
    end
end

function ChatInfoBar:HidePersistentPopup()
    if self.persistentPopup then
        self.persistentPopup.ownerButton = nil
        self.persistentPopup.popupKind = nil
        self.persistentPopup:Hide()
    end

    if self.popupClickCatcher then
        self.popupClickCatcher:Hide()
    end
end

function ChatInfoBar:HideAllPopups()
    self:HideHoverPopup()
    self:HidePersistentPopup()
end

function ChatInfoBar:ShowPopup(popup, anchor, title, entries, footer, popupKind)
    if not popup or not anchor then
        return
    end

    if not entries or #entries == 0 then
        entries = {
            { text = "표시할 항목이 없습니다." }
        }
    end

    if not popup.titleText then
        popup.titleText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        popup.titleText:SetJustifyH("LEFT")
        popup.titleText:SetJustifyV("MIDDLE")
    end

    if not popup.footerText then
        popup.footerText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        popup.footerText:SetJustifyH("LEFT")
        popup.footerText:SetJustifyV("MIDDLE")
    end

    local maxWidth = 120
    local rowHeight = 18
    local topPadding = 6
    local bottomPadding = 6
    local leftPadding = 6
    local rightPadding = 6
    local titleHeight = 0
    local footerHeight = 0
    local contentTop = topPadding

    popup.titleText:Hide()
    popup.footerText:Hide()

    if title and title ~= "" then
        popup.titleText:SetText(title)
        popup.titleText:ClearAllPoints()
        popup.titleText:SetPoint("TOPLEFT", popup, "TOPLEFT", leftPadding, -topPadding)
        popup.titleText:SetPoint("RIGHT", popup, "RIGHT", -rightPadding, 0)
        popup.titleText:Show()

        titleHeight = 20
        contentTop = contentTop + titleHeight
        maxWidth = math.max(maxWidth, popup.titleText:GetStringWidth() + 8)
    end

    if footer and footer ~= "" then
        popup.footerText:SetText(footer)
        popup.footerText:Show()
        footerHeight = 18
        maxWidth = math.max(maxWidth, popup.footerText:GetStringWidth() + 8)
    end

    for i = 1, #(popup.rows or {}) do
        local row = popup.rows[i]
        if row then
            row:Hide()
            row.targetName = nil
            row.onClick = nil

            ResetRowVisual(row)

            if row.icon then
                row.icon:Hide()
                row.icon:ClearAllPoints()
            end

            if row.text then
                row.text:SetText("")
                row.text:ClearAllPoints()
            end
        end
    end

    for i, entry in ipairs(entries) do
        local row = self:GetPopupRow(popup, i)

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", popup, "TOPLEFT", leftPadding, -contentTop - ((i - 1) * rowHeight))
        row:SetPoint("RIGHT", popup, "RIGHT", -rightPadding, 0)
        row:SetHeight(rowHeight)

        local leftOffset = self:LayoutPopupRow(row, entry)

        if entry.selected then
            row.text:SetText("|cff88ff88" .. (entry.text or "") .. "|r")
        else
            row.text:SetText(entry.text or "")
        end

        row.targetName = entry.targetName
        row.onClick = entry.onClick
        row:Show()

        local textWidth = row.text:GetStringWidth() or 0
        local totalWidth = leftOffset + textWidth + 8
        if totalWidth > maxWidth then
            maxWidth = totalWidth
        end
    end

    local count = #entries
    local rowsHeight = count * rowHeight
    local totalHeight = contentTop + rowsHeight + bottomPadding

    if footerHeight > 0 then
        popup.footerText:ClearAllPoints()
        popup.footerText:SetPoint("TOPLEFT", popup, "TOPLEFT", leftPadding, -(contentTop + rowsHeight + 2))
        popup.footerText:SetPoint("RIGHT", popup, "RIGHT", -rightPadding, 0)
        totalHeight = totalHeight + footerHeight
    end

    popup.ownerButton = anchor
    popup.popupKind = popupKind

    self:ApplyPopupStyle(popup, popupKind)

    popup:SetSize(leftPadding + maxWidth + rightPadding, totalHeight)
    popup:ClearAllPoints()
    popup:SetPoint("BOTTOM", anchor, "TOP", 0, 4)
    popup:Show()
end

function ChatInfoBar:ShowHoverPopup(anchor, title, entries, footer, popupKind)
    local popup = self:GetOrCreateHoverPopup()
    self:ShowPopup(popup, anchor, title, entries, footer, popupKind)
end

function ChatInfoBar:ShowPersistentPopup(anchor, title, entries, footer, popupKind)
    self:HideHoverPopup()

    local popup = self:GetOrCreatePersistentPopup()
    self:ShowPopup(popup, anchor, title, entries, footer, popupKind)

    self:GetOrCreatePopupClickCatcher():Show()
end

function ChatInfoBar:ShowGuildList(anchor)
    local entries = self:BuildGuildEntries()

    if #entries == 0 then
        entries[1] = {
            text = "|cffcccccc접속 중인 길드원이 없습니다.|r",
            targetName = nil,
        }
    end

    self:ShowHoverPopup(
        anchor,
        "길드 접속자",
        entries,
        "|cff00ff00클릭: 귓속말|r\n|cff00ff00Alt+클릭: 파티 초대|r",
        "guild"
    )
end

function ChatInfoBar:ShowFriendsList(anchor)
    local entries = self:BuildFriendsEntries()

    if #entries == 0 then
        entries[1] = {
            text = "|cffcccccc접속 중인 친구가 없습니다.|r",
            targetName = nil,
        }
    end

    self:ShowHoverPopup(
        anchor,
        "친구 접속자",
        entries,
        "|cff00ff00클릭: 귓속말|r\n|cff00ff00Alt+클릭: 파티 초대|r",
        "friends"
    )
end

function ChatInfoBar:ShowSpecPopup(anchor)
    local entries = self:BuildSpecEntries()

    self:ShowHoverPopup(
        anchor,
        "특성",
        entries,
        "|cff00ff00좌클릭: 특성 변경|r\n|cff00ff00우클릭: 전리품 획득 변경|r",
        "specInfo"
    )
end

function ChatInfoBar:ShowSpecSelectPopup(anchor)
    local entries = self:BuildSpecSelectEntries()

    self:ShowPersistentPopup(
        anchor,
        "특성 변경",
        entries,
        nil,
        "specSelect"
    )
end

function ChatInfoBar:ShowLootSpecSelectPopup(anchor)
    local entries = self:BuildLootSpecSelectEntries()

    self:ShowPersistentPopup(
        anchor,
        "전리품 획득 변경",
        entries,
        nil,
        "lootSpecSelect"
    )
end

function ChatInfoBar:ShowDurabilityPopup(anchor)
    local entries = self:BuildDurabilityEntries()

    self:ShowHoverPopup(
        anchor,
        "내구도",
        entries,
        " ",
        "durability"
    )
end

function ChatInfoBar:ShowPerformancePopup(anchor)
    local entries = self:BuildPerformanceEntries()
    self:ShowHoverPopup(anchor, "성능 정보", entries, nil, "performance")
end

function ChatInfoBar:ShowMythicPlusPopup(anchor)
    local entries = self:BuildMythicPlusEntries()
    self:ShowHoverPopup(anchor, "쐐기 정보", entries, nil, "mythicplus")
end
