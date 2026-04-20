local _, ns = ...

local ChatInfoBar = ns.ChatInfoBar or {}
ns.ChatInfoBar = ChatInfoBar

local format = string.format
local date = date

local SLOT_TYPES = {
    NONE = true,
    TIME = true,
    GUILD = true,
    FRIENDS = true,
    SPEC = true,
    DURABILITY = true,
    PERFORMANCE = true,
    MPLUS = true,
}

function ChatInfoBar:GetSlotText(slotType)
    if not slotType or not SLOT_TYPES[slotType] then
        return ""
    end

    if slotType == "NONE" then
        return ""
    elseif slotType == "TIME" then
        return date("%H:%M")
    elseif slotType == "GUILD" then
        if not IsInGuild or not IsInGuild() then
            return "길드 없음"
        end
        return format("길드 %d", self:GetGuildOnlineCount())
    elseif slotType == "FRIENDS" then
        return format("친구 %d", self:GetFriendsOnlineCount())
    elseif slotType == "SPEC" then
        local current = self:GetCurrentSpecInfo()
        if not current or not current.name then
            return "특성 없음"
        end

        local lootName = self:GetLootSpecName()
        if lootName and lootName ~= "" and lootName ~= current.name then
            return current.name .. "/" .. lootName
        end

        return current.name
    elseif slotType == "DURABILITY" then
        return "내구도 " .. self:ColorDurability(self:GetAverageDurability())
    elseif slotType == "PERFORMANCE" then
        local fps, homeLatency, worldLatency = self:GetPerformanceInfo()

        return format("%s/%s/%s",
            self:ColorFPS(fps),
            self:ColorLatency(homeLatency),
            self:ColorLatency(worldLatency)
        )
    elseif slotType == "MPLUS" then
        return "쐐기"
    end

    return ""
end

function ChatInfoBar:CreateSlot(parent, point, relativePoint, x, y, justify)
    local button = CreateFrame("Button", nil, parent)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnEnter", function(btn)
        self:OnSlotEnter(btn)
    end)

    button:SetScript("OnLeave", function()
        ChatInfoBar.slotHovered = false
        ChatInfoBar:HandleHoverPopupLeave()
    end)

    button:SetScript("OnClick", function(btn, mouseButton)
        self:OnSlotClick(btn, mouseButton)
    end)

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:ClearAllPoints()
    button.text:SetJustifyH("CENTER")
    button.text:SetJustifyV("MIDDLE")
    button.text:SetPoint("TOP", button, "TOP", 0, 0)
    button.text:SetPoint("BOTTOM", button, "BOTTOM", 0, 0)
    button.text:SetPoint("LEFT", button, "LEFT", 0, 0)
    button.text:SetPoint("RIGHT", button, "RIGHT", 0, 0)

    button:SetPoint(point, parent, relativePoint, x, y)
    return button
end

function ChatInfoBar:OnSlotEnter(button)
    self.slotHovered = true

    if self.hidePopupTimer then
        self.hidePopupTimer:Cancel()
        self.hidePopupTimer = nil
    end

    if not button or not button.displayType then
        return
    end

    if button.displayType == "GUILD" then
        if self.persistentPopup and self.persistentPopup:IsShown() then
            return
        end
        self:ShowGuildList(button)
    elseif button.displayType == "FRIENDS" then
        if self.persistentPopup and self.persistentPopup:IsShown() then
            return
        end
        self:ShowFriendsList(button)
    elseif button.displayType == "SPEC" then
        if self.persistentPopup and self.persistentPopup:IsShown() and self.persistentPopup.ownerButton == button then
            return
        end
        self:ShowSpecPopup(button)
    elseif button.displayType == "DURABILITY" then
        if self.persistentPopup and self.persistentPopup:IsShown() then
            return
        end
        self:ShowDurabilityPopup(button)
    elseif button.displayType == "PERFORMANCE" then
        if self.persistentPopup and self.persistentPopup:IsShown() then
            return
        end
        self:ShowPerformancePopup(button)
    elseif button.displayType == "MPLUS" then
        if self.persistentPopup and self.persistentPopup:IsShown() then
            return
        end
        self:ShowMythicPlusPopup(button)
    else
        self:HideHoverPopup()
    end
end

function ChatInfoBar:OpenFriendsFrame()
    if ToggleFriendsFrame then
        ToggleFriendsFrame(1)
    end
end

function ChatInfoBar:OpenGuildFrame()
    if ToggleCommunitiesFrame then
        ToggleCommunitiesFrame()
    end
end

function ChatInfoBar:OnSlotClick(button, mouseButton)
    if not button or not button.displayType then
        return
    end

    if button.displayType == "FRIENDS" then
        self:OpenFriendsFrame()
        return
    end

    if button.displayType == "GUILD" then
        self:OpenGuildFrame()
        return
    end

    if button.displayType == "MPLUS" then
        if not ns.mplus or not ns.mplus.SendCommandTrigger then
            return
        end

        if mouseButton == "LeftButton" then
            ns.mplus:SendCommandTrigger("!돌")
        elseif mouseButton == "RightButton" then
            ns.mplus:SendManualReport("주차", false)
        end
        return
    end

    if button.displayType ~= "SPEC" then
        return
    end

    local popup = self.persistentPopup
    if popup and popup:IsShown() and popup.ownerButton == button then
        if (mouseButton == "LeftButton" and popup.popupKind == "specSelect")
            or (mouseButton == "RightButton" and popup.popupKind == "lootSpecSelect") then
            self:HidePersistentPopup()
            return
        end
    end

    if mouseButton == "LeftButton" then
        self:ShowSpecSelectPopup(button)
    elseif mouseButton == "RightButton" then
        self:ShowLootSpecSelectPopup(button)
        
    end
end
