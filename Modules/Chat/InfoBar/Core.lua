local _, ns = ...

local ChatInfoBar = ns.ChatInfoBar or {}
ns.ChatInfoBar = ChatInfoBar

function ChatInfoBar:Initialize()
    local db = self:GetDB()
    if not db then
        return
    end

    self:CreateBar()
    self:CreateMover()
    self:ApplySettings()
end

function ChatInfoBar:Refresh()
    local db = self:GetDB()
    if not db then
        return
    end

    if not self.bar then
        self:CreateBar()
        self:CreateMover()
    end

    self:ApplySettings()
end

function ChatInfoBar:GetSlotCount()
    local db = self:GetDB()
    if not db then
        return 4
    end

    local count = tonumber(db.slotCount) or 4
    if count < 2 then
        count = 2
    elseif count > 5 then
        count = 5
    end

    return count
end

function ChatInfoBar:NormalizeSlots(db)
    if not db then
        return
    end

    db.slotCount = tonumber(db.slotCount) or 4
    if db.slotCount < 2 then
        db.slotCount = 2
    elseif db.slotCount > 5 then
        db.slotCount = 5
    end

    db.slots = db.slots or {}

    if not db.slots[1] then
        db.slots[1] = db.slots1 or "TIME"
        db.slots[2] = db.slots2 or "DURABILITY"
        db.slots[3] = db.slots3 or "SPEC"
        db.slots[4] = db.slots4 or "GUILD"
        db.slots[5] = db.slots5 or "MPLUS"
    end

    for i = 1, 5 do
        if not db.slots[i] or db.slots[i] == "" then
            db.slots[i] = "NONE"
        end
    end
end

function ChatInfoBar:GetSlotType(index)
    local db = self:GetDB()
    if not db then
        return "NONE"
    end

    self:NormalizeSlots(db)
    return db.slots[index] or "NONE"
end

function ChatInfoBar:NeedsFrequentUpdate()
    local db = self:GetDB()
    if not db then
        return false
    end

    self:NormalizeSlots(db)

    local slotCount = self:GetSlotCount()
    for i = 1, slotCount do
        local slotType = db.slots[i]
        if slotType == "TIME" or slotType == "PERFORMANCE" then
            return true
        end
    end

    return false
end

function ChatInfoBar:Update()
    local db = self:GetDB()
    local bar = self.bar
    if not db or not bar or not bar.slots then
        return
    end

    self:NormalizeSlots(db)

    local slotCount = self:GetSlotCount()

    for i = 1, #bar.slots do
        local slot = bar.slots[i]
        local slotType = (i <= slotCount) and self:GetSlotType(i) or "NONE"

        slot.displayType = slotType
        slot.text:SetText(self:GetSlotText(slotType))

        if i <= slotCount then
            slot:Show()
        else
            slot:Hide()
        end
    end
end
