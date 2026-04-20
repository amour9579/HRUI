local _, ns = ...

local DEFAULT_ICON_SIZE = 18
local DEFAULT_SPACING = 2
local DEFAULT_MAX_ICONS = 8
local useLegacyUnitBuff = type(UnitBuff) == "function"
local useUnitAura = type(UnitAura) == "function"
local useCUnitAuras = C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function"

local anchorValues = {
    TOPLEFT = "좌상",
    TOP = "상",
    TOPRIGHT = "우상",
    LEFT = "좌",
    CENTER = "중앙",
    RIGHT = "우",
    BOTTOMLEFT = "좌하",
    BOTTOM = "하",
    BOTTOMRIGHT = "우하",
}

local function GetBuffDB(unit)
    local unitDB = ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes[unit]
    if not unitDB then
        return nil
    end

    unitDB.buffs = unitDB.buffs or {}
    local db = unitDB.buffs

    if db.enabled == nil then
        db.enabled = true
    end

    db.size = db.size or DEFAULT_ICON_SIZE
    db.spacing = db.spacing or DEFAULT_SPACING
    db.maxIcons = db.maxIcons or DEFAULT_MAX_ICONS
    db.anchor = db.anchor or "TOPRIGHT"
    db.x = db.x or 0
    db.y = db.y or 4
    db.growth = db.growth or "LEFT"

    return db
end

local function CreateBuffButton(parent, size)
    local button = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    button:SetSize(size, size)
    button:Hide()
    button:EnableMouse(true)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.cooldown:SetDrawEdge(true)
    button.cooldown:SetDrawSwipe(true)
    button.cooldown:SetReverse(true)
    button.cooldown:SetEdgeColor(1, 1, 0, 1)
    
    if button.cooldown.SetHideCountdownNumbers then
        button.cooldown:SetHideCountdownNumbers(true)
    end

    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.count:SetJustifyH("RIGHT")

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetAllPoints()
    button.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    button.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    button.border:SetVertexColor(0, 0, 0, 1)

    button:SetScript("OnEnter", function(self)
        if not self.unit then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        if self.auraInstanceID and GameTooltip.SetUnitBuffByAuraInstanceID then
            GameTooltip:SetUnitBuffByAuraInstanceID(self.unit, self.auraInstanceID)
        elseif GameTooltip.SetUnitBuff and self.auraIndex then
            local filter = self.auraFilter or "HELPFUL"
            GameTooltip:SetUnitBuff(self.unit, self.auraIndex, filter)
        end

        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

local function ApplyBuffLayout(frame, db)
    local buffs = frame.BuffIndicators
    if not buffs or not buffs.buttons then
        return
    end

    local anchor = anchorValues[db.anchor] and db.anchor or "TOPRIGHT"
    local point = anchor

    buffs:ClearAllPoints()
    buffs:SetPoint(point, frame, point, db.x or 0, db.y or 0)

    local iconSize = math.max(10, db.size or DEFAULT_ICON_SIZE)
    local spacing = db.spacing or DEFAULT_SPACING
    local maxIcons = math.max(1, db.maxIcons or DEFAULT_MAX_ICONS)
    local growLeft = db.growth ~= "RIGHT"

    for i = 1, #buffs.buttons do
        local button = buffs.buttons[i]
        button:ClearAllPoints()
        button:SetSize(iconSize, iconSize)
        button.__baseAnchor = anchor

        local offset = (i - 1) * (iconSize + spacing)
        local xOffset = growLeft and -offset or offset
        button.__baseX = xOffset
        button.__baseY = 0
        button:SetPoint(anchor, buffs, anchor, xOffset, 0)
        button:SetShown(i <= maxIcons)

        if i > maxIcons then
            button:Hide()
        end
    end

    buffs:SetSize((iconSize * maxIcons) + (spacing * (maxIcons - 1)), iconSize)
end

local function GetBuffData(unit, index)
    local filter = "HELPFUL"

    if useLegacyUnitBuff then
        local name, icon, count, _, duration, expirationTime, sourceUnit = UnitBuff(unit, index, filter)
        if not name or not icon then
            return nil
        end

        return {
            icon = icon,
            count = count,
            duration = duration,
            expirationTime = expirationTime,
            hasSafeTimer = true,
            index = index,
            filter = filter,
        }
    end

    if useCUnitAuras then
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
        if not aura or not aura.icon then
            return nil
        end

        local d = tonumber(aura.duration) or 0
        local e = tonumber(aura.expirationTime) or 0
        local c = tonumber(aura.applications) or 0

        return {
            icon = aura.icon,
            count = c,
            duration = d,
            expirationTime = e,
            auraInstanceID = aura.auraInstanceID,
            hasSafeTimer = true,
            index = index,
            filter = filter,
        }
    end

    if useCUnitAuras then
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
        if not aura or not aura.icon then
            return nil
        end

        return {
            icon = aura.icon,
            auraInstanceID = aura.auraInstanceID,
            hasSafeTimer = false,
            index = index,
            filter = filter,
        }
    end

    return nil
end

function ns:UpdateBuffIndicators(frame)
    if not frame or not frame.BuffIndicators then
        return
    end

    local db = GetBuffDB(frame.unit)
    if not db or db.enabled == false or not UnitExists(frame.unit) then
        frame.BuffIndicators:Hide()
        return
    end

    ApplyBuffLayout(frame, db)
    frame.BuffIndicators:Show()

    local maxIcons = math.max(1, db.maxIcons or DEFAULT_MAX_ICONS)

    for i = 1, #frame.BuffIndicators.buttons do
        local button = frame.BuffIndicators.buttons[i]
        if i > maxIcons then
            button:SetScale(1)
            button:Hide()
        else
            local aura = GetBuffData(frame.unit, i)
            if aura then
                button.unit = frame.unit
                button.auraIndex = aura.index
                button.auraFilter = aura.filter
                button.auraInstanceID = aura.auraInstanceID
                button.icon:SetTexture(aura.icon)
                button.count:SetText("")
                button:SetScale(1)
                button:ClearAllPoints()
                button:SetPoint(
                    button.__baseAnchor or db.anchor or "TOPRIGHT",
                    frame.BuffIndicators,
                    button.__baseAnchor or db.anchor or "TOPRIGHT",
                    button.__baseX or 0,
                    button.__baseY or 0
                )

                if aura.hasSafeTimer and aura.duration and aura.expirationTime then
                    pcall(function()
                        local start = aura.expirationTime - aura.duration
                        button.cooldown:SetCooldown(start, aura.duration)
                        button.cooldown:Show()
                    end)
                else
                    button.cooldown:Hide()
                end

                button:Show()
            else
                button.unit = nil
                button.auraIndex = nil
                button.auraFilter = nil
                button.auraInstanceID = nil
                button:SetScale(1)
                button:Hide()
            end
        end
    end
end

function ns:CreateBuffIndicators(frame)
    if not frame or frame.BuffIndicators then
        return
    end

    local parent = frame.Overlay or frame
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetFrameLevel(parent:GetFrameLevel() + 2)
    holder.buttons = {}

    for i = 1, 20 do
        holder.buttons[i] = CreateBuffButton(holder, DEFAULT_ICON_SIZE)
    end

    frame.BuffIndicators = holder

    local eventFrame = CreateFrame("Frame", nil, frame)
    eventFrame:RegisterUnitEvent("UNIT_AURA", frame.unit)
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    if frame.unit == "target" then
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    elseif frame.unit == "focus" then
        eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    end

    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_AURA" and unit ~= frame.unit then
            return
        end
        ns:UpdateBuffIndicators(frame)
    end)

    frame.BuffIndicatorEventFrame = eventFrame
    ns:UpdateBuffIndicators(frame)
end
