local _, ns = ...

local DEFAULT_MAX_BOSS_FRAMES = 5
local DEFAULT_SPACING = 8

local function GetMaxBossFrames()
    return tonumber(_G.MAX_BOSS_FRAMES) or DEFAULT_MAX_BOSS_FRAMES
end

local function GetBossDB()
    local ufdb = ns.db and ns.db.profile and ns.db.profile.unitframes
    if not ufdb then
        return nil
    end

    ufdb.boss = ufdb.boss or {
        enabled = true,
        width = 220,
        height = 45,
        x = 560,
        y = 80,
        spacing = DEFAULT_SPACING,
        power = { enabled = true, height = 6, },
        name = { anchor = "LEFT", x = 8, y = 0, format = "levelName", fontSize = 12, },
        healthText = { enabled = true, anchor = "RIGHT", x = -8, y = 0, format = "value", fontSize = 11, },
        powerText = { enabled = false, anchor = "CENTER", x = 0, y = 0, format = "value", fontSize = 10, },
        buffs = { enabled = false, size = 18, spacing = 2, maxIcons = 8, anchor = "TOPRIGHT", x = 0, y = 4, growth = "LEFT", },
        debuffs = { enabled = false, filterMode = "all", cooldownText = false, size = 18, spacing = 2, maxIcons = 8, anchor = "TOPLEFT", x = 0, y = 4, growth = "RIGHT", },
    }

    local db = ufdb.boss
    db.enabled = db.enabled ~= false
    db.width = db.width or 220
    db.height = db.height or 45
    db.x = db.x or 560
    db.y = db.y or 80
    db.spacing = db.spacing or DEFAULT_SPACING
    db.power = db.power or { enabled = true, height = 6, }
    db.name = db.name or { anchor = "LEFT", x = 8, y = 0, format = "levelName", fontSize = 12, }
    db.healthText = db.healthText or { enabled = true, anchor = "RIGHT", x = -8, y = 0, format = "value", fontSize = 11, }
    db.powerText = db.powerText or { enabled = false, anchor = "CENTER", x = 0, y = 0, format = "value", fontSize = 10, }
    db.buffs = db.buffs or { enabled = false, size = 18, spacing = 2, maxIcons = 8, anchor = "TOPRIGHT", x = 0, y = 4, growth = "LEFT", }
    db.debuffs = db.debuffs or { enabled = false, filterMode = "all", cooldownText = false, size = 18, spacing = 2, maxIcons = 8, anchor = "TOPLEFT", x = 0, y = 4, growth = "RIGHT", }
    db.debuffs.filterMode = db.debuffs.filterMode or "all"
    db.debuffs.cooldownText = db.debuffs.cooldownText == true

    for i = 1, GetMaxBossFrames() do
        ufdb["boss" .. i] = db
    end

    return db
end

local function GetBossCastbarDB()
    return ns.db
        and ns.db.profile
        and ns.db.profile.castbars
        and ns.db.profile.castbars.boss
end

local function GetBossCastbarStackOffset()
    local castDB = GetBossCastbarDB()
    if not castDB or castDB.enabled == false then
        return 0
    end

    local barHeight = castDB.height or 18
    local yOffset = castDB.y
    if yOffset == nil then
        yOffset = -4
    end

    local gapBelow = math.max(0, -yOffset)
    return barHeight + gapBelow
end

local function DisableBlizzardBossFrames()
    if InCombatLockdown and InCombatLockdown() then
        return
    end

    for i = 1, GetMaxBossFrames() do
        local frame = _G["Boss" .. i .. "TargetFrame"]
        if frame then
            frame:UnregisterAllEvents()
            frame:Hide()
            if not frame.__HRUIBossSuppressed then
                frame.__HRUIBossSuppressed = true
                frame:HookScript("OnShow", function(self)
                    self:Hide()
                end)
            end
        end
    end
end

local function EnsureBossEventFrame()
    if ns.BossEventFrame then
        return
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:SetScript("OnEvent", DisableBlizzardBossFrames)

    ns.BossEventFrame = eventFrame
end


local function GetUnitFontPath(fontKind)
    local ufdb = ns.db and ns.db.profile and ns.db.profile.unitframes
    local appearance = ufdb and ufdb.appearance
    local fontKey = "default"

    if fontKind == "health" then
        fontKey = appearance and appearance.healthFont or "default"
    elseif fontKind == "power" then
        fontKey = appearance and appearance.powerFont or "default"
    else
        fontKey = appearance and appearance.nameFont or "default"
    end

    if ns.GetUnitFontPath then
        return ns:GetUnitFontPath(fontKey)
    end

    return STANDARD_TEXT_FONT
end

local function FormatPreviewValue(value)
    if ns.FormatHealth then
        return ns:FormatHealth(value)
    elseif BreakUpLargeNumbers then
        return BreakUpLargeNumbers(value)
    end

    return tostring(value)
end

local function FormatPreviewPower(value)
    if ns.FormatShortValue then
        return ns:FormatShortValue(value)
    elseif BreakUpLargeNumbers then
        return BreakUpLargeNumbers(value)
    end

    return tostring(value)
end

local function SetPreviewTextPosition(fontString, relativeFrame, cfg, defaultAnchor)
    if not fontString or not relativeFrame then
        return
    end

    cfg = cfg or {}
    local anchor = ns.GetTextAnchorPoint and ns:GetTextAnchorPoint(cfg.anchor or defaultAnchor or "CENTER") or (cfg.anchor or defaultAnchor or "CENTER")

    fontString:ClearAllPoints()
    fontString:SetPoint(anchor, relativeFrame, anchor, cfg.x or 0, cfg.y or 0)

    if anchor == "LEFT" then
        fontString:SetJustifyH("LEFT")
    elseif anchor == "RIGHT" then
        fontString:SetJustifyH("RIGHT")
    else
        fontString:SetJustifyH("CENTER")
    end
end

local function SetPreviewCooldownText(button, enabled)
    if not button or not button.cooldown or not button.cooldown.SetHideCountdownNumbers then
        return
    end

    pcall(button.cooldown.SetHideCountdownNumbers, button.cooldown, not enabled)
end

local function ApplyPreviewCooldown(button, cfg)
    if not button or not button.cooldown then
        return
    end

    local enabled = cfg and cfg.cooldownText == true
    SetPreviewCooldownText(button, enabled)

    if enabled and type(GetTime) == "function" then
        local ok = pcall(function()
            button.cooldown:SetCooldown(GetTime() - 12, 45)
        end)

        if ok then
            button.cooldown:Show()
            return
        end
    end

    button.cooldown:Hide()
end

local function CreatePreviewBuffButton(parent, withCooldown)
    local button = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    button:EnableMouse(false)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    if withCooldown then
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        button.cooldown:SetAllPoints()
        button.cooldown:SetDrawEdge(false)
        button.cooldown:SetDrawSwipe(true)
        button.cooldown:SetReverse(true)
        SetPreviewCooldownText(button, false)
        button.cooldown:Hide()
    end

    button:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    button:SetBackdropBorderColor(0, 0, 0, 1)

    return button
end

local function ApplyPreviewAuras(frame, holder, cfg, defaultAnchor, defaultGrowth)
    if not frame or not holder then
        return
    end

    if not cfg or cfg.enabled == false then
        holder:Hide()
        return
    end

    local anchor = cfg.anchor or defaultAnchor or "TOPRIGHT"
    local size = math.max(10, cfg.size or 18)
    local spacing = cfg.spacing or 2
    local maxIcons = math.max(1, math.min(cfg.maxIcons or 8, #holder.buttons))
    local growth = cfg.growth or defaultGrowth or "LEFT"
    local growLeft = growth == "LEFT"

    holder:ClearAllPoints()
    holder:SetPoint(anchor, frame, anchor, cfg.x or 0, cfg.y or 0)
    holder:SetSize((size * maxIcons) + (spacing * math.max(maxIcons - 1, 0)), size)

    for i, button in ipairs(holder.buttons) do
        button:ClearAllPoints()
        button:SetSize(size, size)

        if i <= maxIcons then
            local offset = (i - 1) * (size + spacing)
            local x = growLeft and -offset or offset
            button:SetPoint(anchor, holder, anchor, x, 0)
            ApplyPreviewCooldown(button, cfg)
            button:Show()
        else
            if button.cooldown then
                button.cooldown:Hide()
            end
            button:Hide()
        end
    end

    holder:Show()
end

local function ApplyPreviewBuffs(frame, db)
    ApplyPreviewAuras(frame, frame and frame.Buffs, db and db.buffs, "TOPRIGHT", "LEFT")
end

local function ApplyPreviewDebuffs(frame, db)
    ApplyPreviewAuras(frame, frame and frame.Debuffs, db and db.debuffs, "TOPLEFT", "RIGHT")
end

local function CreateBossPreviewFrame(parent, index)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame.__HRUIBossPreviewFrame = true
    frame:EnableMouse(false)
    frame:SetFrameLevel(parent:GetFrameLevel() + 5)

    if ns.CreateBackdrop then
        ns:CreateBackdrop(frame)
    else
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        frame:SetBackdropColor(0.06, 0.06, 0.06, 0.90)
        frame:SetBackdropBorderColor(0.20, 0.20, 0.20, 1)
    end

    local health = CreateFrame("StatusBar", nil, frame)
    health:SetStatusBarTexture(ns.GetTexture and ns:GetTexture() or "Interface\\TARGETINGFRAME\\UI-StatusBar")
    health:SetMinMaxValues(0, 100)
    health:SetValue(math.max(35, 100 - ((index - 1) * 12)))
    health:SetStatusBarColor(0.55, 0.08, 0.08, 0.95)

    health.bg = health:CreateTexture(nil, "BORDER")
    health.bg:SetAllPoints()
    health.bg:SetTexture(ns.GetTexture and ns:GetTexture() or "Interface\\TARGETINGFRAME\\UI-StatusBar")
    health.bg:SetVertexColor(0.15, 0.15, 0.15, 0.70)
    frame.Health = health

    local power = CreateFrame("StatusBar", nil, frame)
    power:SetStatusBarTexture(ns.GetTexture and ns:GetTexture() or "Interface\\TARGETINGFRAME\\UI-StatusBar")
    power:SetMinMaxValues(0, 100)
    power:SetValue(math.max(25, 80 - ((index - 1) * 8)))
    power:SetStatusBarColor(0.12, 0.35, 0.90, 0.95)

    power.bg = power:CreateTexture(nil, "BORDER")
    power.bg:SetAllPoints()
    power.bg:SetTexture(ns.GetTexture and ns:GetTexture() or "Interface\\TARGETINGFRAME\\UI-StatusBar")
    power.bg:SetVertexColor(0.15, 0.15, 0.15, 0.70)
    frame.Power = power


    local castbar = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
    castbar.unit = "boss"
    castbar:SetStatusBarTexture(ns.GetTexture and ns:GetTexture() or "Interface\\TARGETINGFRAME\\UI-StatusBar")
    castbar:SetStatusBarColor(0.95, 0.75, 0.20, 0.95)
    castbar:SetMinMaxValues(0, 100)
    castbar:SetValue(65)
    castbar:SetScript("OnUpdate", function(self)
        if ns.UpdateCastbar then
            ns:UpdateCastbar(self)
        end
    end)
    frame.Castbar = castbar

    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints(frame)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
    overlay:EnableMouse(false)
    frame.Overlay = overlay

    local name = overlay:CreateFontString(nil, "OVERLAY")
    name:SetTextColor(1, 1, 1)
    frame.Name = name

    local healthValue = overlay:CreateFontString(nil, "OVERLAY")
    healthValue:SetTextColor(1, 1, 1)
    frame.HealthValue = healthValue

    local powerValue = overlay:CreateFontString(nil, "OVERLAY")
    powerValue:SetTextColor(1, 1, 1)
    frame.PowerValue = powerValue

    local buffs = CreateFrame("Frame", nil, overlay)
    buffs:SetFrameLevel(overlay:GetFrameLevel() + 2)
    buffs.buttons = {}
    for i = 1, 20 do
        buffs.buttons[i] = CreatePreviewBuffButton(buffs)
    end
    frame.Buffs = buffs

    local debuffs = CreateFrame("Frame", nil, overlay)
    debuffs:SetFrameLevel(overlay:GetFrameLevel() + 2)
    debuffs.buttons = {}
    for i = 1, 20 do
        debuffs.buttons[i] = CreatePreviewBuffButton(debuffs, true)
        debuffs.buttons[i]:SetBackdropBorderColor(1, 0, 0, 1)
    end
    frame.Debuffs = debuffs

    frame:Hide()
    return frame
end

local function EnsureBossPreviewFrames()
    if ns.BossPreviewFrames then
        return ns.BossPreviewFrames
    end

    if not ns.BossFrame then
        return nil
    end

    ns.BossPreviewFrames = {}

    for i = 1, GetMaxBossFrames() do
        ns.BossPreviewFrames[i] = CreateBossPreviewFrame(ns.BossFrame, i)
    end

    return ns.BossPreviewFrames
end

function ns:RefreshBossPreviewFrames()
    local db = GetBossDB()
    local previews = EnsureBossPreviewFrames()
    if not db or not previews then
        return
    end

    local width = db.width or 220
    local height = db.height or 45
    local spacing = db.spacing or DEFAULT_SPACING
    local castbarDB = GetBossCastbarDB()
    if castbarDB and castbarDB.enabled ~= false then
        local castbarWidth = castbarDB.width or width
        local castbarXOffset = math.abs(castbarDB.x or 0)
        width = math.max(width, castbarWidth + (castbarXOffset * 2))
    end
    local castbarStackOffset = GetBossCastbarStackOffset()
    local texture = ns.GetTexture and ns:GetTexture() or "Interface\\TARGETINGFRAME\\UI-StatusBar"
    local healthMax = 125000000
    local powerMax = 10000

    for index, frame in ipairs(previews) do
        frame:SetSize(width, height)
        frame:ClearAllPoints()
        if index == 1 then
            frame:SetPoint("TOP", ns.BossFrame, "TOP", 0, 0)
        else
            frame:SetPoint("TOP", previews[index - 1], "BOTTOM", 0, -(spacing + castbarStackOffset))
        end

        if frame.Backdrop and ns.ApplyBackdropStyle then
            ns:ApplyBackdropStyle(frame, false)
        end

        if frame.Health then
            frame.Health:SetStatusBarTexture(texture)
            if frame.Health.bg then
                frame.Health.bg:SetTexture(texture)
            end
        end
        if frame.Power then
            frame.Power:SetStatusBarTexture(texture)
            if frame.Power.bg then
                frame.Power.bg:SetTexture(texture)
            end
        end

        local powerCfg = db.power or {}
        local powerHeight = powerCfg.height or 6
        if powerCfg.enabled ~= false then
            frame.Power:ClearAllPoints()
            frame.Power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
            frame.Power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
            frame.Power:SetHeight(powerHeight)
            frame.Power:Show()

            frame.Health:ClearAllPoints()
            frame.Health:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
            frame.Health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
            frame.Health:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, powerHeight + 1)
            frame.Health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, powerHeight + 1)
        else
            frame.Power:Hide()

            frame.Health:ClearAllPoints()
            frame.Health:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
            frame.Health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
            frame.Health:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
            frame.Health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        end

        local nameCfg = db.name or {}
        frame.Name:SetFont(GetUnitFontPath("name"), nameCfg.fontSize or 12, "OUTLINE")
        if nameCfg.format == "name" then
            frame.Name:SetText("가상 보스 " .. index)
        else
            frame.Name:SetText("|cffffff00??|r 가상 보스 " .. index)
        end
        SetPreviewTextPosition(frame.Name, frame.Health, nameCfg, "LEFT")

        local healthCfg = db.healthText or {}
        frame.HealthValue:SetFont(GetUnitFontPath("health"), healthCfg.fontSize or 11, "OUTLINE")
        if healthCfg.enabled then
            local cur = healthMax - ((index - 1) * 7250000)
            if healthCfg.format == "valueMax" then
                frame.HealthValue:SetText(FormatPreviewValue(cur) .. " / " .. FormatPreviewValue(healthMax))
            else
                frame.HealthValue:SetText(FormatPreviewValue(cur))
            end
            SetPreviewTextPosition(frame.HealthValue, frame.Health, healthCfg, "RIGHT")
            frame.HealthValue:Show()
        else
            frame.HealthValue:Hide()
        end

        local powerTextCfg = db.powerText or {}
        frame.PowerValue:SetFont(GetUnitFontPath("power"), powerTextCfg.fontSize or 10, "OUTLINE")
        if powerCfg.enabled ~= false and powerTextCfg.enabled then
            local curPower = powerMax - ((index - 1) * 600)
            if powerTextCfg.format == "valueMax" then
                frame.PowerValue:SetText(FormatPreviewPower(curPower) .. " / " .. FormatPreviewPower(powerMax))
            else
                frame.PowerValue:SetText(FormatPreviewPower(curPower))
            end
            SetPreviewTextPosition(frame.PowerValue, frame.Power, powerTextCfg, "CENTER")
            frame.PowerValue:Show()
        else
            frame.PowerValue:Hide()
        end


        local castCfg = GetBossCastbarDB() or {}
        if frame.Castbar then
            frame.Castbar:SetStatusBarTexture(texture)
            frame.Castbar:SetMinMaxValues(0, 100)
            frame.Castbar:SetValue(65)
            frame.Castbar:SetStatusBarColor(0.95, 0.75, 0.20, 0.95)

            if ns.CreateCastbar then
                ns:CreateCastbar(frame.Castbar, castCfg)
            end

            if ns.ApplyCastbarTextSettings then
                ns:ApplyCastbarTextSettings(frame.Castbar, castCfg)
            end

            frame.Castbar:ClearAllPoints()
            frame.Castbar:SetPoint("TOP", frame, "BOTTOM", castCfg.x or 0, castCfg.y or -4)
            frame.Castbar:SetSize(castCfg.width or width, castCfg.height or 18)

            if frame.Castbar.Text then
                frame.Castbar.Text:SetText("암흑의 화살")
            end

            if frame.Castbar.Time then
                frame.Castbar.Time:SetText("1.8")
            end

            if castCfg.enabled ~= false then
                frame.Castbar:Show()
            else
                frame.Castbar:Hide()
            end
        end

        ApplyPreviewBuffs(frame, db)
        ApplyPreviewDebuffs(frame, db)

        if ns.BossPreviewActive and db.enabled ~= false then
            frame:Show()
        else
            frame:Hide()
        end
    end
end

function ns:ShowBossPreviewFrames()
    local db = GetBossDB()
    if not db or db.enabled == false then
        ns:HideBossPreviewFrames()
        return
    end

    ns.BossPreviewActive = true
    ns:RefreshBossPreviewFrames()
end

function ns:HideBossPreviewFrames()
    ns.BossPreviewActive = nil

    if not ns.BossPreviewFrames then
        return
    end

    for _, frame in ipairs(ns.BossPreviewFrames) do
        frame:Hide()
    end
end

local function SetBossVisibility(enabled)
    if not ns.BossFrames then
        return
    end

    for _, frame in ipairs(ns.BossFrames) do
        if UnregisterUnitWatch then
            UnregisterUnitWatch(frame)
        end

        if enabled then
            frame.__HRUIForceHidden = nil
            frame:EnableMouse(true)
            frame:SetAlpha(1)
            if RegisterUnitWatch then
                RegisterUnitWatch(frame)
            else
                frame:Show()
            end
        else
            frame.__HRUIForceHidden = true
            frame:EnableMouse(false)
            frame:SetAlpha(0)
            frame:Hide()
        end
    end
end

function ns:SetBossFramesEnabled(enabled)
    local container = ns.BossFrame
    if container then
        container.__HRUIForceHidden = not enabled
        container:SetShown(enabled)
    end

    if ns.Movers and ns.Movers.IsUnlocked and ns.Movers:IsUnlocked() then
        if enabled ~= false and ns.ShowBossPreviewFrames then
            ns:ShowBossPreviewFrames()
        elseif ns.HideBossPreviewFrames then
            ns:HideBossPreviewFrames()
        end
    elseif enabled == false and ns.HideBossPreviewFrames then
        ns:HideBossPreviewFrames()
    end

    if ns.RefreshBossCastbars then
        ns:RefreshBossCastbars()
    end

    SetBossVisibility(enabled)
end

function ns:GetBossMoverSize()
    local db = GetBossDB()
    if not db then
        return 220, 45
    end

    local maxFrames = GetMaxBossFrames()
    local width = db.width or 220
    local height = db.height or 45
    local spacing = db.spacing or DEFAULT_SPACING
    local castbarStackOffset = GetBossCastbarStackOffset()

    return width, (height * maxFrames)
        + ((spacing + castbarStackOffset) * math.max(maxFrames - 1, 0))
        + castbarStackOffset
end

function ns:RefreshBossFrames()
    local db = GetBossDB()
    if not db or not ns.BossFrame or not ns.BossFrames then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        return
    end

    DisableBlizzardBossFrames()

    local enabled = db.enabled ~= false
    local width = db.width or 220
    local height = db.height or 45
    local spacing = db.spacing or DEFAULT_SPACING
    local castbarStackOffset = GetBossCastbarStackOffset()
    local totalWidth, totalHeight = ns:GetBossMoverSize()

    ns.BossFrame:ClearAllPoints()
    ns.BossFrame:SetPoint("CENTER", UIParent, "CENTER", db.x or 0, db.y or 0)
    ns.BossFrame:SetSize(totalWidth, totalHeight)
    ns.BossFrame:SetShown(enabled)

    for index, frame in ipairs(ns.BossFrames) do
        frame:SetSize(width, height)
        frame:ClearAllPoints()
        if index == 1 then
            frame:SetPoint("TOP", ns.BossFrame, "TOP", 0, 0)
        else
            frame:SetPoint("TOP", ns.BossFrames[index - 1], "BOTTOM", 0, -(spacing + castbarStackOffset))
        end


        if ns.RefreshFrameElements then
            ns:RefreshFrameElements(frame)
        end
    end

    if ns.RefreshBossCastbars then
        ns:RefreshBossCastbars()
    end

    SetBossVisibility(enabled)

    if ns.BossPreviewActive and ns.RefreshBossPreviewFrames then
        ns:RefreshBossPreviewFrames()
    end
end

function ns:SpawnBossFrames(oUF)
    if ns.BossFrame then
        return ns.BossFrame
    end

    local db = GetBossDB()
    if not db then
        return nil
    end

    DisableBlizzardBossFrames()
    EnsureBossEventFrame()

    local container = CreateFrame("Frame", "HRUI_Boss", UIParent, "BackdropTemplate")
    container:SetClampedToScreen(true)
    container:EnableMouse(false)

    ns.BossFrame = container
    ns.BossFrames = {}

    for i = 1, GetMaxBossFrames() do
        local unit = "boss" .. i
        local frame = oUF:Spawn(unit, "HRUI_Boss" .. i)
        frame:SetParent(container)
        frame.__HRUIBossIndex = i
        frame.__HRUIBossFrame = true

        ns.BossFrames[i] = frame
    end

    ns:RefreshBossFrames()

    return container
end
