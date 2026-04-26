local _, ns = ...

local DEFAULT_ICON_SIZE = 18
local DEFAULT_SPACING = 2
local DEFAULT_MAX_ICONS = 8
local useLegacyUnitDebuff = type(UnitDebuff) == "function"
local useUnitAura = type(UnitAura) == "function"
local useCUnitAuras = C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function"

local PREVIEW_UNITS = {
    "player",
    "target",
    "targettarget",
    "focus",
    "pet",
}

local PREVIEW_TEXTURES = {
    "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
    "Interface\\Icons\\Spell_Nature_CorrosiveBreath",
    "Interface\\Icons\\Spell_Nature_AbolishMagic",
    "Interface\\Icons\\Spell_Shadow_CurseOfSargeras",
    "Interface\\Icons\\Ability_Creature_Disease_03",
}

local PREVIEW_DEBUFF_TYPES = {
    "Magic",
    "Poison",
    "Curse",
    "Disease",
    "none",
}

local frameRefs = {
    player = "PlayerFrame",
    target = "TargetFrame",
    targettarget = "TargetTargetFrame",
    focus = "FocusFrame",
    pet = "PetFrame",
}

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
    db.filterMode = db.filterMode or "all"
    db.cooldownText = db.cooldownText == true

    return db
end

local function GetDebuffFilter(db)
    local mode = db and db.filterMode or "all"

    if mode == "mine" or mode == "player" then
        return "HARMFUL|PLAYER"
    end

    return "HARMFUL"
end

local function IsBossUnit(unit)
    return type(unit) == "string" and unit:match("^boss%d+$") ~= nil
end

local function IsMoveModeUnlocked()
    return ns.Movers and ns.Movers.IsUnlocked and ns.Movers:IsUnlocked()
end

local function ShouldUseMoverPreview(frame)
    return frame and frame.unit and not IsBossUnit(frame.unit) and IsMoveModeUnlocked()
end

local function GetUnitEnabled(unit)
    local unitDB = ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes[unit]
    return unitDB and unitDB.enabled ~= false
end

local function SetCooldownTextVisibility(cooldown, enabled)
    if not cooldown or not cooldown.SetHideCountdownNumbers then
        return
    end

    local ok = pcall(function()
        cooldown:SetHideCountdownNumbers(not enabled)
    end)

    if not ok then
        pcall(cooldown.SetHideCountdownNumbers, cooldown, true)
    end
end

local function ApplyDebuffCooldownTextSetting(button, db)
    if not button or not button.cooldown then
        return
    end

    SetCooldownTextVisibility(button.cooldown, db and db.cooldownText == true)
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

    SetCooldownTextVisibility(button.cooldown, false)

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

local function CreatePreviewDebuffButton(parent, size)
    local button = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    button:SetSize(size, size)
    button:EnableMouse(false)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.cooldown:SetDrawEdge(false)
    button.cooldown:SetDrawSwipe(true)
    button.cooldown:SetReverse(true)
    SetCooldownTextVisibility(button.cooldown, false)
    button.cooldown:Hide()

    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.count:SetJustifyH("RIGHT")

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetAllPoints()
    button.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    button.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    button.border:SetVertexColor(1, 0, 0, 1)

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

local function ApplyDebuffLayoutToHolder(relativeFrame, holder, db)
    if not relativeFrame or not holder or not holder.buttons then
        return
    end

    local anchor = anchorValues[db.anchor] and db.anchor or "TOPLEFT"
    local iconSize = math.max(10, db.size or DEFAULT_ICON_SIZE)
    local spacing = db.spacing or DEFAULT_SPACING
    local maxIcons = math.max(1, math.min(db.maxIcons or DEFAULT_MAX_ICONS, #holder.buttons))
    local growLeft = db.growth == "LEFT"

    holder:ClearAllPoints()
    holder:SetPoint(anchor, relativeFrame, anchor, db.x or 0, db.y or 0)
    holder:SetSize((iconSize * maxIcons) + (spacing * math.max(maxIcons - 1, 0)), iconSize)

    for i, button in ipairs(holder.buttons) do
        button:ClearAllPoints()
        button:SetSize(iconSize, iconSize)
        button.__baseAnchor = anchor

        local offset = (i - 1) * (iconSize + spacing)
        local xOffset = growLeft and -offset or offset
        button.__baseX = xOffset
        button.__baseY = 0
        button:SetPoint(anchor, holder, anchor, xOffset, 0)

        if i > maxIcons then
            button:Hide()
        end
    end
end

local function SafeAuraNumber(value, fallback)
    if value == nil then
        return fallback
    end

    local ok, numberValue = pcall(function()
        local n = tonumber(value)
        if n == nil then
            return nil
        end

        -- Some aura APIs can return protected/secret numeric values.
        -- Validate inside pcall so comparison/arithmetic errors do not break unit frames.
        if n > -math.huge then
            return n
        end

        return nil
    end)

    if ok and type(numberValue) == "number" then
        return numberValue
    end

    return fallback
end

local function SafeAuraString(value, fallback)
    if value == nil then
        return fallback
    end

    local ok, stringValue = pcall(function()
        local s = tostring(value)
        if s and s ~= "" then
            return s
        end

        return nil
    end)

    if ok and type(stringValue) == "string" then
        return stringValue
    end

    return fallback
end

local function GetDebuffCountText(count)
    local ok, text = pcall(function()
        local n = tonumber(count)
        if n and n > 1 then
            return tostring(n)
        end

        return ""
    end)

    return ok and text or ""
end

local function GetDebuffCooldownValues(aura)
    if not aura or not aura.hasSafeTimer then
        return nil, nil
    end

    local ok, start, duration = pcall(function()
        local d = tonumber(aura.duration)
        local e = tonumber(aura.expirationTime)

        if d and e and d > 0 then
            return e - d, d
        end

        return nil, nil
    end)

    if ok and start and duration then
        return start, duration
    end

    return nil, nil
end

local function GetDebuffData(unit, index, filter)
    filter = filter or "HARMFUL"

    -- Retail 12.x can return secret timing/count values from legacy aura APIs.
    -- Prefer C_UnitAuras so we can later feed its auraInstanceID into the
    -- duration-object cooldown API instead of comparing/passing secret numbers.
    if useCUnitAuras then
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if not ok or not aura or not aura.icon then
            return nil
        end

        return {
            icon = aura.icon,
            count = SafeAuraNumber(aura.applications, 0),
            debuffType = SafeAuraString(aura.dispelName, "none"),
            duration = SafeAuraNumber(aura.duration, 0),
            expirationTime = SafeAuraNumber(aura.expirationTime, 0),
            auraInstanceID = aura.auraInstanceID,
            hasSafeTimer = true,
            index = index,
            filter = filter,
        }
    end

    if useLegacyUnitDebuff then
        local ok, name, icon, count, debuffType, duration, expirationTime = pcall(UnitDebuff, unit, index, filter)
        if not ok or not name or not icon then
            return nil
        end

        return {
            icon = icon,
            count = SafeAuraNumber(count, 0),
            debuffType = SafeAuraString(debuffType, "none"),
            duration = SafeAuraNumber(duration, 0),
            expirationTime = SafeAuraNumber(expirationTime, 0),
            hasSafeTimer = true,
            index = index,
            filter = filter,
        }
    end

    if useUnitAura then
        local ok, name, icon, count, debuffType, duration, expirationTime = pcall(UnitAura, unit, index, filter)
        if not ok or not name or not icon then
            return nil
        end

        return {
            icon = icon,
            count = SafeAuraNumber(count, 0),
            debuffType = SafeAuraString(debuffType, "none"),
            duration = SafeAuraNumber(duration, 0),
            expirationTime = SafeAuraNumber(expirationTime, 0),
            hasSafeTimer = true,
            index = index,
            filter = filter,
        }
    end

    return nil
end

local function GetDebuffApplicationText(unit, aura)
    if aura and aura.auraInstanceID and C_UnitAuras and type(C_UnitAuras.GetAuraApplicationDisplayCount) == "function" then
        local ok, text = pcall(C_UnitAuras.GetAuraApplicationDisplayCount, unit, aura.auraInstanceID, 2, 999)
        if ok and text ~= nil then
            return text
        end
    end

    return GetDebuffCountText(aura and aura.count)
end

local function ApplyDebuffCooldown(button, unit, aura)
    if not button or not button.cooldown then
        return
    end

    if aura and aura.auraInstanceID and C_UnitAuras and type(C_UnitAuras.GetAuraDuration) == "function" and button.cooldown.SetCooldownFromDurationObject then
        local okDuration, durationObject = pcall(C_UnitAuras.GetAuraDuration, unit, aura.auraInstanceID)
        if okDuration and durationObject then
            local okCooldown = pcall(function()
                button.cooldown:SetCooldownFromDurationObject(durationObject, true)
            end)

            if okCooldown then
                button.cooldown:Show()
                return
            end
        end
    end

    local cooldownStart, cooldownDuration = GetDebuffCooldownValues(aura)
    if cooldownStart and cooldownDuration then
        local cooldownOk = pcall(function()
            button.cooldown:SetCooldown(cooldownStart, cooldownDuration)
        end)

        if cooldownOk then
            button.cooldown:Show()
            return
        end
    end

    button.cooldown:Hide()
end

local function ApplyDebuffBorder(button, debuffType)
    local color = DebuffTypeColor and (DebuffTypeColor[debuffType or "none"] or DebuffTypeColor.none)

    if color then
        button.border:SetVertexColor(color.r or color[1] or 1, color.g or color[2] or 0, color.b or color[3] or 0, 1)
    else
        button.border:SetVertexColor(1, 0, 0, 1)
    end
end

local function FillPreviewDebuffs(holder, db)
    if not holder or not holder.buttons then
        return
    end

    local maxIcons = math.max(1, math.min(db.maxIcons or DEFAULT_MAX_ICONS, #holder.buttons))

    for i, button in ipairs(holder.buttons) do
        if i <= maxIcons then
            button.unit = nil
            button.auraIndex = nil
            button.auraFilter = nil
            button.auraInstanceID = nil
            button.icon:SetTexture(PREVIEW_TEXTURES[((i - 1) % #PREVIEW_TEXTURES) + 1])
            button.count:SetText((i == 2 or i == 5 or i == 8) and "2" or "")
            if button.cooldown then
                ApplyDebuffCooldownTextSetting(button, db)
                if db and db.cooldownText == true and type(GetTime) == "function" then
                    button.cooldown:SetCooldown(GetTime() - 12, 45)
                    button.cooldown:Show()
                else
                    button.cooldown:Hide()
                end
            end
            ApplyDebuffBorder(button, PREVIEW_DEBUFF_TYPES[((i - 1) % #PREVIEW_DEBUFF_TYPES) + 1])
            button:Show()
        else
            button:Hide()
        end
    end
end

local function EnsureMoverPreviewHolder(mover)
    if not mover then
        return nil
    end

    if mover.DeBuffPreviewIndicators then
        return mover.DeBuffPreviewIndicators
    end

    local holder = CreateFrame("Frame", nil, mover)
    holder:SetFrameLevel(mover:GetFrameLevel() + 5)
    holder:EnableMouse(false)
    holder.buttons = {}

    for i = 1, 20 do
        holder.buttons[i] = CreatePreviewDebuffButton(holder, DEFAULT_ICON_SIZE)
    end

    mover.DeBuffPreviewIndicators = holder
    return holder
end

local function HideMoverPreviewHolder(mover)
    if mover and mover.DeBuffPreviewIndicators then
        mover.DeBuffPreviewIndicators:Hide()
    end
end

local function UpdateMoverPreviewForUnit(unit)
    if not ns.Movers or not ns.Movers.GetMover then
        return
    end

    local mover = ns.Movers:GetMover(unit)
    if not mover then
        return
    end

    local db = GetDebuffDB(unit)
    if not IsMoveModeUnlocked() or not db or db.enabled == false or not GetUnitEnabled(unit) then
        HideMoverPreviewHolder(mover)
        return
    end

    local holder = EnsureMoverPreviewHolder(mover)
    if not holder then
        return
    end

    ApplyDebuffLayoutToHolder(mover, holder, db)
    FillPreviewDebuffs(holder, db)
    holder:Show()
end

function ns:UpdateMoveModeDeBuffPreviews(unit)
    if unit then
        UpdateMoverPreviewForUnit(unit)
        return
    end

    for _, unitKey in ipairs(PREVIEW_UNITS) do
        UpdateMoverPreviewForUnit(unitKey)
    end
end

function ns:HideMoveModeDeBuffPreviews()
    if not ns.Movers or not ns.Movers.GetMover then
        return
    end

    for _, unitKey in ipairs(PREVIEW_UNITS) do
        HideMoverPreviewHolder(ns.Movers:GetMover(unitKey))
    end
end

function ns:RefreshDeBuffIndicatorPreviewFrames()
    for _, unitKey in ipairs(PREVIEW_UNITS) do
        local frame = ns[frameRefs[unitKey]]
        if frame and frame.DeBuffIndicators then
            ns:UpdateDeBuffIndicators(frame)
        end
    end

    if IsMoveModeUnlocked() then
        ns:UpdateMoveModeDeBuffPreviews()
    else
        ns:HideMoveModeDeBuffPreviews()
    end
end

function ns:UpdateDeBuffIndicators(frame)
    if not frame or not frame.DeBuffIndicators then
        return
    end

    local db = GetDebuffDB(frame.unit)
    if not db or db.enabled == false then
        frame.DeBuffIndicators:Hide()
        return
    end

    if ShouldUseMoverPreview(frame) then
        frame.DeBuffIndicators:Hide()
        UpdateMoverPreviewForUnit(frame.unit)
        return
    end

    if not UnitExists(frame.unit) then
        frame.DeBuffIndicators:Hide()
        return
    end

    ApplyDebuffLayout(frame, db)
    frame.DeBuffIndicators:Show()

    local maxIcons = math.max(1, db.maxIcons or DEFAULT_MAX_ICONS)
    local auraFilter = GetDebuffFilter(db)

    for i = 1, #frame.DeBuffIndicators.buttons do
        local button = frame.DeBuffIndicators.buttons[i]
        if i > maxIcons then
            button:SetScale(1)
            button:Hide()
        else
            local aura = GetDebuffData(frame.unit, i, auraFilter)
            if aura then
                button.unit = frame.unit
                button.auraIndex = aura.index
                button.auraFilter = aura.filter
                button.auraInstanceID = aura.auraInstanceID
                button.icon:SetTexture(aura.icon)
                button.count:SetText(GetDebuffApplicationText(frame.unit, aura))
                ApplyDebuffCooldownTextSetting(button, db)
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

                ApplyDebuffCooldown(button, frame.unit, aura)

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
