local _, ns = ...

ns.Modules = ns.Modules or {}
ns.Modules.ActionBars = ns.Modules.ActionBars or {}

local Module = ns.Modules.ActionBars
local EVENT_PREFIX = "ActionBars_"

local buttonGroups = {
    { prefix = "ActionButton",              count = 12 },
    { prefix = "MultiBarBottomLeftButton",  count = 12 },
    { prefix = "MultiBarBottomRightButton", count = 12 },
    { prefix = "MultiBarRightButton",       count = 12 },
    { prefix = "MultiBarLeftButton",        count = 12 },
    { prefix = "MultiBar5Button",           count = 12 },
    { prefix = "MultiBar6Button",           count = 12 },
    { prefix = "MultiBar7Button",           count = 12 },
    { prefix = "PetActionButton",           count = 10 },
    { prefix = "StanceButton",              count = 10 },
    { prefix = "PossessButton",             count = 2 },
}

local function GetDB()
    return ns.db and ns.db.profile and ns.db.profile.actionbars
end

local function GetFontPath(fontKey)
    if ns.GetFont then
        local font = ns:GetFont(fontKey)
        if font then
            return font
        end
    end

    if ns.Media and ns.Media.fonts and ns.Media.fonts[fontKey] then
        return ns.Media.fonts[fontKey]
    end

    return STANDARD_TEXT_FONT
end

local function BuildButtonCache()
    if Module.buttonCache then
        return Module.buttonCache
    end

    local cache = {}

    for _, group in ipairs(buttonGroups) do
        for i = 1, group.count do
            local button = _G[group.prefix .. i]
            if button then
                cache[#cache + 1] = button
            end
        end
    end

    Module.buttonCache = cache
    return cache
end

local function GetButtonObjects(button)
    if not button then
        return
    end

    if button.HRUIObj then
        return button.HRUIObj
    end

    local name = button:GetName()
    if not name then
        return
    end

    local obj = {
        icon       = _G[name .. "Icon"] or button.icon,
        normal     = _G[name .. "NormalTexture"] or button:GetNormalTexture(),
        border     = _G[name .. "Border"],
        floatingBG = _G[name .. "FloatingBG"],
        shine      = _G[name .. "Shine"],
        hotkey     = _G[name .. "HotKey"],
        count      = _G[name .. "Count"],
        nameText   = _G[name .. "Name"],
        slotBG     = _G[name .. "SlotBackground"],
        pushed     = button:GetPushedTexture(),
        highlight  = button:GetHighlightTexture(),
        checked    = button:GetCheckedTexture(),
    }

    button.HRUIObj = obj
    return obj
end

local function StoreButtonState(button)
    if not button or button.HRUIStateStored then
        return
    end

    local obj = GetButtonObjects(button)
    if not obj then
        return
    end

    button.HRUIOriginal = {
        normalAlpha     = obj.normal and obj.normal:GetAlpha() or nil,
        borderAlpha     = obj.border and obj.border:GetAlpha() or nil,
        floatingBGAlpha = obj.floatingBG and obj.floatingBG:GetAlpha() or nil,
        shineAlpha      = obj.shine and obj.shine:GetAlpha() or nil,
        nameAlpha       = obj.nameText and obj.nameText:GetAlpha() or nil,
        hotkeyScale     = obj.hotkey and obj.hotkey:GetScale() or nil,
        countScale      = obj.count and obj.count:GetScale() or nil,
        slotBGAlpha     = obj.slotBG and obj.slotBG:GetAlpha() or nil,

        iconTexCoord1   = obj.icon and select(1, obj.icon:GetTexCoord()) or nil,
        iconTexCoord2   = obj.icon and select(2, obj.icon:GetTexCoord()) or nil,
        iconTexCoord3   = obj.icon and select(3, obj.icon:GetTexCoord()) or nil,
        iconTexCoord4   = obj.icon and select(4, obj.icon:GetTexCoord()) or nil,

        hotkeyFont1     = obj.hotkey and select(1, obj.hotkey:GetFont()) or nil,
        hotkeyFont2     = obj.hotkey and select(2, obj.hotkey:GetFont()) or nil,
        hotkeyFont3     = obj.hotkey and select(3, obj.hotkey:GetFont()) or nil,

        countFont1      = obj.count and select(1, obj.count:GetFont()) or nil,
        countFont2      = obj.count and select(2, obj.count:GetFont()) or nil,
        countFont3      = obj.count and select(3, obj.count:GetFont()) or nil,

        nameFont1       = obj.nameText and select(1, obj.nameText:GetFont()) or nil,
        nameFont2       = obj.nameText and select(2, obj.nameText:GetFont()) or nil,
        nameFont3       = obj.nameText and select(3, obj.nameText:GetFont()) or nil,
    }

    button.HRUIStateStored = true
end

local function EnsureBackdrop(button)
    if button.HRUIBackdrop then
        button.HRUIBackdrop:Show()
        return button.HRUIBackdrop
    end

    local backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
    backdrop:SetAllPoints(button)
    backdrop:SetFrameLevel(math.max(button:GetFrameLevel() - 1, 0))
    backdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    backdrop:SetBackdropColor(0, 0, 0, 1)
    backdrop:SetBackdropBorderColor(0, 0, 0, 1)

    button.HRUIBackdrop = backdrop
    return backdrop
end

local function ResetBorder(button)
    if button and button.HRUIBackdrop then
        button.HRUIBackdrop:SetBackdropBorderColor(0, 0, 0, 1)
    end
end

local function ApplyTextSettings(button)
    local db = GetDB()
    local obj = GetButtonObjects(button)
    if not db or not obj then
        return
    end

    local fontPath = GetFontPath(db.font or "default")
    local hotkeySize = db.hotkeyFontSize or 11
    local macroSize = db.macroFontSize or 10
    local countSize = db.countFontSize or 11
    local outline = db.fontOutline or "OUTLINE"

    if obj.hotkey then
        obj.hotkey:SetFont(fontPath, hotkeySize, outline)
        obj.hotkey:ClearAllPoints()
        obj.hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
    end

    if obj.count then
        obj.count:SetFont(fontPath, countSize, outline)
        obj.count:ClearAllPoints()
        obj.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    end

    if obj.nameText then
        obj.nameText:SetFont(fontPath, macroSize, outline)
        obj.nameText:ClearAllPoints()
        obj.nameText:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)

        if db.showMacroName then
            obj.nameText:SetAlpha(1)
            obj.nameText:Show()
        else
            obj.nameText:SetAlpha(0)
            obj.nameText:Hide()
        end
    end
end

local function HookHover(button)
    if button.HRUIHoverHooked then
        return
    end

    button:HookScript("OnEnter", function(self)
        local db = GetDB()
        if not db or not db.skin then
            return
        end

        if self.HRUIBackdrop and self.HRUIBackdrop:IsShown() then
            self.HRUIBackdrop:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end
    end)

    button:HookScript("OnLeave", function(self)
        ResetBorder(self)
    end)

    button.HRUIHoverHooked = true
end

local function ApplyStaticSkin(button)
    if not button or button.HRUIStyled then
        return
    end

    local obj = GetButtonObjects(button)
    if not obj then
        return
    end

    StoreButtonState(button)
    EnsureBackdrop(button)
    HookHover(button)

    if obj.normal then
        obj.normal:SetAlpha(0)
        obj.normal:SetTexture("")
    end

    if obj.border then
        obj.border:SetAlpha(0)
        obj.border:SetTexture("")
    end

    if obj.floatingBG then
        obj.floatingBG:SetAlpha(0)
        obj.floatingBG:SetTexture("")
    end

    if obj.shine then
        obj.shine:SetAlpha(0)
    end

    if obj.slotBG then
        obj.slotBG:SetAlpha(0)
    end

    if obj.icon then
        obj.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    button.HRUIStyled = true
end

local function UpdateButtonVisual(button)
    local db = GetDB()
    local obj = GetButtonObjects(button)
    if not db or not obj then
        return
    end

    local backdrop = EnsureBackdrop(button)
    backdrop:SetBackdropBorderColor(0, 0, 0, 1)

    if obj.pushed then
        obj.pushed:SetAlpha(db.skin and 0 or 1)
    end

    if obj.highlight then
        obj.highlight:SetAlpha(db.skin and 0.08 or 1)
    end

    if obj.checked then
        obj.checked:SetAlpha(db.skin and 0.12 or 1)
    end

    ApplyTextSettings(button)
end

local function SkinButton(button, forceTextUpdate)
    if not button then
        return
    end

    ApplyStaticSkin(button)

    if forceTextUpdate then
        ApplyTextSettings(button)
    end

    UpdateButtonVisual(button)
end

local function RestoreButton(button)
    if not button then
        return
    end

    local obj = GetButtonObjects(button)
    local orig = button.HRUIOriginal
    if not obj or not orig then
        return
    end

    if button.HRUIBackdrop then
        button.HRUIBackdrop:Hide()
    end

    if obj.normal then
        obj.normal:SetAlpha(orig.normalAlpha or 1)
    end

    if obj.border then
        obj.border:SetAlpha(orig.borderAlpha or 1)
    end

    if obj.floatingBG then
        obj.floatingBG:SetAlpha(orig.floatingBGAlpha or 1)
    end

    if obj.shine then
        obj.shine:SetAlpha(orig.shineAlpha or 1)
    end

    if obj.slotBG then
        obj.slotBG:SetAlpha(orig.slotBGAlpha or 1)
    end

    if obj.icon and orig.iconTexCoord1 then
        obj.icon:SetTexCoord(
            orig.iconTexCoord1,
            orig.iconTexCoord2,
            orig.iconTexCoord3,
            orig.iconTexCoord4
        )
    elseif obj.icon then
        obj.icon:SetTexCoord(0, 1, 0, 1)
    end

    if obj.hotkey and orig.hotkeyScale then
        obj.hotkey:SetScale(orig.hotkeyScale)
    end

    if obj.count and orig.countScale then
        obj.count:SetScale(orig.countScale)
    end

    if obj.nameText and orig.nameAlpha ~= nil then
        obj.nameText:SetAlpha(orig.nameAlpha)
        obj.nameText:Show()
    end

    if obj.hotkey and orig.hotkeyFont1 then
        obj.hotkey:SetFont(orig.hotkeyFont1, orig.hotkeyFont2, orig.hotkeyFont3)
    end

    if obj.count and orig.countFont1 then
        obj.count:SetFont(orig.countFont1, orig.countFont2, orig.countFont3)
    end

    if obj.nameText and orig.nameFont1 then
        obj.nameText:SetFont(orig.nameFont1, orig.nameFont2, orig.nameFont3)
    end
end

local function SetFrameHidden(frame, hidden)
    if not frame then
        return
    end

    if hidden then
        frame:Hide()
        frame:SetAlpha(0)
        frame:EnableMouse(false)
    else
        frame:Show()
        frame:SetAlpha(1)
        frame:EnableMouse(true)
    end
end

function Module:ApplyBlizzardBarVisibility()
    local db = GetDB()
    if not db then
        return
    end

    -- 가방바
    SetFrameHidden(_G.MainMenuBarBackpackButton, db.hideBagBar)
    SetFrameHidden(_G.BagsBar, db.hideBagBar)

    -- 메뉴바
    local microButtons = {
        "CharacterMicroButton",
        "ProfessionMicroButton",
        "PlayerSpellsMicroButton",
        "AchievementMicroButton",
        "QuestLogMicroButton",
        "HousingMicroButton",
        "GuildMicroButton",
        "LFDMicroButton",
        "CollectionsMicroButton",
        "EJMicroButton",
        "StoreMicroButton",
        "MainMenuMicroButton",
    }

    for i = 1, #microButtons do
        SetFrameHidden(_G[microButtons[i]], db.hideMicroMenu)
    end
end

function Module:Refresh(forceTextUpdate)
    local db = GetDB()
    if not db then
        return
    end

    local buttons = BuildButtonCache()
    for i = 1, #buttons do
        local button = buttons[i]
        if db.skin then
            SkinButton(button, forceTextUpdate)
        else
            RestoreButton(button)
        end
    end
end

function Module:RefreshVisuals()
    local db = GetDB()
    if not db or not db.skin then
        return
    end

    local buttons = BuildButtonCache()
    for i = 1, #buttons do
        UpdateButtonVisual(buttons[i])
    end
end

function Module:HandleEvent(event)
    if event == "ACTIONBAR_SLOT_CHANGED" then
        if self.refreshPending then
            self.needsRefreshVisual = true
            return
        end

        self.refreshPending = true
        self.needsRefreshVisual = false

        C_Timer.After(0.15, function()
            self.refreshPending = false
            self:RefreshVisuals()

            if self.needsRefreshVisual then
                self.needsRefreshVisual = false
                self:RefreshVisuals()
            end
        end)
        return
    end

    if event == "UPDATE_BINDINGS" or event == "UPDATE_MACROS" then
        self:Refresh(true)
        return
    end

    self:Refresh(false)
end

function Module:RegisterEvents()
    if not ns.Event then
        return
    end

    ns.Event:Register("PLAYER_ENTERING_WORLD", EVENT_PREFIX .. "PEW", function(event)
        Module:HandleEvent(event)
    end)
    ns.Event:Register("PLAYER_ENTERING_WORLD", EVENT_PREFIX .. "ApplyBlizzardBarVisibility", function()
        Module:ApplyBlizzardBarVisibility()
    end)
    ns.Event:Register("UPDATE_BINDINGS", EVENT_PREFIX .. "Bindings", function(event)
        Module:HandleEvent(event)
    end)
    ns.Event:Register("UPDATE_MACROS", EVENT_PREFIX .. "Macros", function(event)
        Module:HandleEvent(event)
    end)
    ns.Event:Register("ACTIONBAR_SLOT_CHANGED", EVENT_PREFIX .. "Slots", function(event)
        Module:HandleEvent(event)
    end)
end

function Module:Enable()
    BuildButtonCache()

    if not self.eventsRegistered then
        self:RegisterEvents()
        self.eventsRegistered = true
    end

    self:Refresh(true)

    C_Timer.After(0.2, function()
        self:Refresh(false)
    end)
end
