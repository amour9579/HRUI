local _, ns = ...

local ChatInfoBar = ns.ChatInfoBar or {}
ns.ChatInfoBar = ChatInfoBar

local EVENT_PREFIX = "InfoBar_"

function ChatInfoBar:GetDB()
    return ns.db and ns.db.profile and ns.db.profile.chat and ns.db.profile.chat.infoBar
end

function ChatInfoBar:HandleEvent(event)
    if event == "PLAYER_ENTERING_WORLD" then
        if IsInGuild and IsInGuild() and GuildRoster then
            GuildRoster()
        end

        if ShowFriends then
            ShowFriends()
        end
    end

    self:Update()
end

function ChatInfoBar:RegisterEvents()
    if self.eventsRegistered or not ns.Event then
        return
    end

    ns.Event:Register("PLAYER_ENTERING_WORLD", EVENT_PREFIX .. "PEW", function(event)
        self:HandleEvent(event)
    end)
    ns.Event:Register("ACTIVE_TALENT_GROUP_CHANGED", EVENT_PREFIX .. "TalentGroup", function(event)
        self:HandleEvent(event)
    end)
    ns.Event:Register("PLAYER_SPECIALIZATION_CHANGED", EVENT_PREFIX .. "Spec", function(event)
        self:HandleEvent(event)
    end)
    ns.Event:Register("PLAYER_LOOT_SPEC_UPDATED", EVENT_PREFIX .. "LootSpec", function(event)
        self:HandleEvent(event)
    end)
    ns.Event:Register("GUILD_ROSTER_UPDATE", EVENT_PREFIX .. "Guild", function(event)
        self:HandleEvent(event)
    end)
    ns.Event:Register("FRIENDLIST_UPDATE", EVENT_PREFIX .. "Friends", function(event)
        self:HandleEvent(event)
    end)
    ns.Event:Register("BN_FRIEND_ACCOUNT_ONLINE", EVENT_PREFIX .. "BNOnline", function(event)
        self:HandleEvent(event)
    end)
    ns.Event:Register("BN_FRIEND_ACCOUNT_OFFLINE", EVENT_PREFIX .. "BNOffline", function(event)
        self:HandleEvent(event)
    end)
    ns.Event:Register("PLAYER_EQUIPMENT_CHANGED", EVENT_PREFIX .. "Equip", function(event)
        self:HandleEvent(event)
    end)
    ns.Event:Register("UPDATE_INVENTORY_DURABILITY", EVENT_PREFIX .. "Durability", function(event)
        self:HandleEvent(event)
    end)

    self.eventsRegistered = true
end

function ChatInfoBar:CreateBar()
    if self.bar then
        return self.bar
    end

    local db = self:GetDB()
    if not db then
        return
    end

    self.bar = CreateFrame("Frame", "HRUIChatInfoBar", UIParent, "BackdropTemplate")
    local bar = self.bar

    bar:SetClampedToScreen(true)
    bar:SetMovable(true)
    bar:EnableMouse(false)
    bar:SetFrameStrata("BACKGROUND")
    bar:SetFrameLevel(1)

    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = nil,
        tile = false,
        tileSize = 0,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })

    ns.ChatInfoBarFrame = bar

    bar.slots = {}
    for i = 1, 5 do
        bar.slots[i] = self:CreateSlot(bar, "LEFT", "LEFT", 0, 0, "CENTER")
    end

    self:RegisterEvents()

    bar.elapsed = 0
    bar:SetScript("OnUpdate", function(_, elapsed)
        if not bar:IsShown() then
            return
        end

        if not self:NeedsFrequentUpdate() then
            return
        end

        bar.elapsed = bar.elapsed + elapsed
        if bar.elapsed >= 1 then
            bar.elapsed = 0
            self:Update()
        end
    end)

    return bar
end

function ChatInfoBar:CreateMover()
    local bar = self.bar
    if not bar or not ns.Movers then
        return
    end

    if ns.Movers.EnsureMover then
        ns.Movers:EnsureMover("chat_infobar")
    end

    if ns.Movers.RefreshMover then
        ns.Movers:RefreshMover("chat_infobar")
    end
end

function ChatInfoBar:ApplySettings()
    local db = self:GetDB()
    local bar = self.bar
    if not db or not bar then
        return
    end

    if self.NormalizeSlots then
        self:NormalizeSlots(db)
    end

    if not db.enabled then
        bar:Hide()

        if self.HideHoverPopup then
            self:HideHoverPopup()
        end

        if self.HidePersistentPopup then
            self:HidePersistentPopup()
        end

        if ns.Movers and ns.Movers.RefreshMover then
            ns.Movers:RefreshMover("chat_infobar")
        end
        return
    end

    local width = db.width or 520
    local height = db.height or 20
    local outerPadding = db.outerPadding or 40
    local slotCount = self:GetSlotCount()

    local innerWidth = width - (outerPadding * 2)
    if innerWidth < 1 then
        innerWidth = width
        outerPadding = 0
    end

    local segment = innerWidth / slotCount

    bar:SetSize(width, height)
    bar:ClearAllPoints()
    bar:SetPoint("CENTER", UIParent, "CENTER", db.x or 0, db.y or 0)

    if db.backdrop then
        bar:SetBackdropColor(0, 0, 0, db.alpha or 0.25)
    else
        bar:SetBackdropColor(0, 0, 0, 0)
    end

    for i = 1, #bar.slots do
        local slot = bar.slots[i]
        slot:ClearAllPoints()

        if i <= slotCount then
            slot:SetPoint("LEFT", bar, "LEFT", outerPadding + ((i - 1) * segment), 0)
            slot:SetSize(segment, height)

            slot.text:SetJustifyH("CENTER")

            slot:Show()
        else
            slot:Hide()
        end
    end

    bar.elapsed = 0
    bar:Show()
    self:Update()

    if ns.Movers and ns.Movers.RefreshMover then
        ns.Movers:RefreshMover("chat_infobar")
    end
end
