local _, ns = ...

ns.Modules.UnitFrames = ns.Modules.UnitFrames or {}

local spawned = false

local frameMap = {
    player = "PlayerFrame",
    target = "TargetFrame",
    targettarget = "TargetTargetFrame",
    focus = "FocusFrame",
    pet = "PetFrame",
}

local spawnOrder = {
    "player",
    "target",
    "targettarget",
    "focus",
    "pet",
}

local function GetFrame(key)
    local ref = frameMap[key]
    return ref and ns[ref]
end

local function EnsureVisibilityHook(frame)
    if not frame or frame.__HRUIVisibilityHooked then
        return
    end

    frame.__HRUIVisibilityHooked = true

    frame:HookScript("OnShow", function(self)
        if self.__HRUIForceHidden then
            self:Hide()
        end
    end)
end

local function ApplyFrameEnabled(key, frame, enabled)
    if not frame then
        return
    end

    EnsureVisibilityHook(frame)

    if key ~= "player" and UnregisterUnitWatch then
        UnregisterUnitWatch(frame)
    end

    if enabled then
        frame.__HRUIForceHidden = nil
        frame:EnableMouse(true)
        frame:SetAlpha(1)

        if key ~= "player" and RegisterUnitWatch then
            RegisterUnitWatch(frame)
        end

        frame:Show()
    else
        frame.__HRUIForceHidden = true
        frame:EnableMouse(false)
        frame:SetAlpha(0)
        frame:Hide()
    end
end

local function ApplyFrameSettings(key)
    local ufdb = ns.db.profile.unitframes
    local db = ufdb[key]
    local frame = GetFrame(key)

    if not db or not frame then
        return
    end

    if InCombatLockdown() then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
    frame:SetSize(db.width, db.height)

    ApplyFrameEnabled(key, frame, db.enabled)
end

function ns.Modules.UnitFrames:Enable()
    local oUF = _G.oUF
    if not oUF then
        if ns.HRUI and ns.HRUI.Print then
            ns.HRUI:Print("oUF not loaded.")
        end
        return
    end

    if not spawned then
        oUF:RegisterStyle("HRUI", ns.UnitFrameStyle)
        oUF:SetActiveStyle("HRUI")

        ns:SpawnPlayerFrame(oUF)
        ns:SpawnTargetFrame(oUF)
        ns:SpawnTargetTargetFrame(oUF)
        ns:SpawnFocusFrame(oUF)
        ns:SpawnPetFrame(oUF)

        spawned = true
    end

    if ns.Movers then
        ns.Movers:CreateAll()
    end

    self:RefreshAll()

    if ns.Movers then
        ns.Movers:Lock()
    end
end

function ns.Modules.UnitFrames:RefreshUnit(key)
    ApplyFrameSettings(key)

    local frame = GetFrame(key)
    if frame and ns.RefreshFrameElements then
        ns:RefreshFrameElements(frame)
    end

    if frame and ns.db.profile.unitframes[key] and not ns.db.profile.unitframes[key].enabled then
        frame:Hide()
    end

    if ns.Movers and ns.Movers.RefreshMover then
        ns.Movers:RefreshMover(key)
    end
end

function ns.Modules.UnitFrames:RefreshAll()
    for _, key in ipairs(spawnOrder) do
        self:RefreshUnit(key)
    end
end
