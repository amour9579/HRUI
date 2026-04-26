local _, ns = ...

local DEFAULT_ICON_SIZE = 18
local DEFAULT_SPACING = 2
local DEFAULT_MAX_ICONS = 8
local useLegacyUnitDebuff = type(UnitDebuff) == "function"
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

local function GetDebuffDB(unit)
    local unitDB = ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes[unit]
    if not unitDB then
        return nil
    end

    unitDB.debuffs = unitDB.debuffs or {}
    local db = unitDB.debuffs

    if db.enabled == nil then
        db.enabled = false
    end

    db.size = db.size or DEFAULT_ICON_SIZE
    db.spacing = db.spacing or DEFAULT_SPACING
    db.maxIcons = db.maxIcons or DEFAULT_MAX_ICONS
    db.anchor = db.anchor or "TOPLEFT"
    db.x = db.x or 0
    db.y = db.y or 4
    db.growth = db.growth or "RIGHT"

    return db
end

local function CreateDebuffButton(parent, size)
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
    button.cooldown:SetEdgeColor(1, 0, 0, 1)

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
    button.border:SetVertexColor(1, 0, 0, 1)

    button:SetScript("OnEnter", function(self)
        if not self.unit then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        if self.auraInstanceID and GameTooltip.SetUnitDebuffByAuraInstanceID then
            GameTooltip:SetUnitDebuffByAuraInstanceID(self.unit, self.auraInstanceID)
        elseif GameTooltip.SetUnitDebuff and self.auraIndex then
            local filter = self.auraFilter or "HARMFUL"
            GameTooltip:SetUnitDebuff(self.unit, self.auraIndex, filter)
        elseif GameTooltip.SetUnitAura and self.auraIndex then
            local filter = self.auraFilter or "HARMFUL"
            GameTooltip:SetUnitAura(self.unit, self.auraIndex, filter)
        end

        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

local function ApplyDebuffLayout(frame, db)
    local debuffs = frame.DeBuffIndicators
    if not debuffs or not debuffs.buttons then
        return
    end

    local anchor = anchorValues[db.anchor] and db.anchor or "TOPLEFT"
    local point = anchor

    debuffs:ClearAllPoints()
    debuffs:SetPoint(point, frame, point, db.x or 0, db.y or 0)

    local iconSize = math.max(10, db.size or DEFAULT_ICON_SIZE)
    local spacing = db.spacing or DEFAULT_SPACING
    local maxIcons = math.max(1, db.maxIcons or DEFAULT_MAX_ICONS)
    local growLeft = db.growth == "LEFT"

    for i = 1, #debuffs.buttons do
        local button = debuffs.buttons[i]
        button:ClearAllPoints()
        button:SetSize(iconSize, iconSize)
        button.__baseAnchor = anchor

        local offset = (i - 1) * (iconSize + spacing)
        local xOffset = growLeft and -offset or offset
        button.__baseX = xOffset
        button.__baseY = 0
        button:SetPoint(anchor, debuffs, anchor, xOffset, 0)
        button:SetShown(i <= maxIcons)

        if i > maxIcons then
            button:Hide()
        end
    end

    debuffs:SetSize((iconSize * maxIcons) + (spacing * (maxIcons - 1)), iconSize)
end

local function GetDebuffData(unit, index)
    local filter = "HARMFUL"

    if useLegacyUnitDebuff then
        local name, icon, count, debuffType, duration, expirationTime = UnitDebuff(unit, index, filter)
        if not name or not icon then
            return nil
        end

        return {
            icon = icon,
            count = count,
            debuffType = debuffType,
            duration = duration,
            expirationTime = expirationTime,
            hasSafeTimer = true,
            index = index,
            filter = filter,
        }
    end

    if useUnitAura then
        local name, icon, count, debuffType, duration, expirationTime = UnitAura(unit, index, filter)
        if not name or not icon then
            return nil
        end

        return {
            icon = icon,
            count = count,
            debuffType = debuffType,
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
            debuffType = aura.dispelName,
            duration = d,
            expirationTime = e,
            auraInstanceID = aura.auraInstanceID,
            hasSafeTimer = true,
            index = index,
            filter = filter,
        }
    end

    return nil
end

local function ApplyDebuffBorder(button, debuffType)
    local color = DebuffTypeColor and (DebuffTypeColor[debuffType or "none"] or DebuffTypeColor.none)

    if color then
        button.border:SetVertexColor(color.r or color[1] or 1, color.g or color[2] or 0, color.b or color[3] or 0, 1)
    else
        button.border:SetVertexColor(1, 0, 0, 1)
    end
end

function ns:UpdateDeBuffIndicators(frame)
    if not frame or not frame.DeBuffIndicators then
        return
    end

    local db = GetDebuffDB(frame.unit)
    if not db or db.enabled == false or not UnitExists(frame.unit) then
        frame.DeBuffIndicators:Hide()
        return
    end

    ApplyDebuffLayout(frame, db)
    frame.DeBuffIndicators:Show()

    local maxIcons = math.max(1, db.maxIcons or DEFAULT_MAX_ICONS)

    for i = 1, #frame.DeBuffIndicators.buttons do
        local button = frame.DeBuffIndicators.buttons[i]
        if i > maxIcons then
            button:SetScale(1)
            button:Hide()
        else
            local aura = GetDebuffData(frame.unit, i)
            if aura then
                button.unit = frame.unit
                button.auraIndex = aura.index
                button.auraFilter = aura.filter
                button.auraInstanceID = aura.auraInstanceID
                button.icon:SetTexture(aura.icon)
                button.count:SetText((aura.count and aura.count > 1) and aura.count or "")
                ApplyDebuffBorder(button, aura.debuffType)
                button:SetScale(1)
                button:ClearAllPoints()
                button:SetPoint(
                    button.__baseAnchor or db.anchor or "TOPLEFT",
                    frame.DeBuffIndicators,
                    button.__baseAnchor or db.anchor or "TOPLEFT",
                    button.__baseX or 0,
                    button.__baseY or 0
                )

                if aura.hasSafeTimer and aura.duration and aura.duration > 0 and aura.expirationTime then
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

function ns:CreateDeBuffIndicators(frame)
    if not frame or frame.DeBuffIndicators then
        return
    end

    local parent = frame.Overlay or frame
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetFrameLevel(parent:GetFrameLevel() + 2)
    holder.buttons = {}

    for i = 1, 20 do
        holder.buttons[i] = CreateDebuffButton(holder, DEFAULT_ICON_SIZE)
    end

    frame.DeBuffIndicators = holder

    local eventFrame = CreateFrame("Frame", nil, frame)
    eventFrame:RegisterUnitEvent("UNIT_AURA", frame.unit)
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    if frame.unit == "target" then
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    elseif frame.unit == "focus" then
        eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    elseif frame.unit and frame.unit:match("^boss%d+$") then
        eventFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end

    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_AURA" and unit ~= frame.unit then
            return
        end
        ns:UpdateDeBuffIndicators(frame)
    end)

    frame.DeBuffIndicatorEventFrame = eventFrame
    ns:UpdateDeBuffIndicators(frame)
end
