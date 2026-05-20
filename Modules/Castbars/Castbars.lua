local _, ns = ...

ns.Modules = ns.Modules or {}
ns.Modules.Castbars = ns.Modules.Castbars or {}

local frameMap = {
    player = "PlayerCastbar",
    target = "TargetCastbar",
    pet = "PetCastbar",
}

local spawnOrder = {
    "player",
    "target",
    "pet",
    "boss",
}

local function ApplyCastbarTextSettings(frame, db)
    if not frame or not frame.Text or not db or not db.text then
        return
    end

    if not db.text.enabled then
        frame.Text:Hide()
        return
    end

    frame.Text:Show()

    local styleDB = ns.db and ns.db.profile and ns.db.profile.castbars and ns.db.profile.castbars.style
    local fontKey = (styleDB and styleDB.font) or db.text.font or "default"
    local fontPath = ns.GetCastbarFontPath and ns:GetCastbarFontPath(fontKey) or STANDARD_TEXT_FONT
    local fontSize = db.text.size or math.max(10, math.floor((db.height or 30) * 0.5))

    frame.Text:SetFont(fontPath, fontSize, "OUTLINE")
    frame.Text:SetWordWrap(false)
    frame.Text:SetMaxLines(1)
    frame.Text:ClearAllPoints()
    frame.Text:SetPoint(
        db.text.anchor or "CENTER",
        frame,
        db.text.anchor or "CENTER",
        db.text.x or 0,
        db.text.y or 0
    )

    frame.Text:SetText(frame.Text:GetText() or "")
end

local function GetFrame(key)
    local ref = frameMap[key]
    return ref and ns[ref]
end

local function ApplyFrameAnchor(key, frame, db)
    if key == "player" and ns.UpdatePlayerCastbarAnchor then
        ns:UpdatePlayerCastbarAnchor(frame)
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x or 0, db.y or 0)
end
local function ApplyCastbarSettings(key)
    if key == "boss" then
        if ns.RefreshBossFrames then
            ns:RefreshBossFrames()
        elseif ns.RefreshBossCastbars then
            ns:RefreshBossCastbars()
        end
        return
    end

    local db = ns.db.profile.castbars[key]
    local frame = GetFrame(key)

    if not db or not frame then
        return
    end

    ApplyFrameAnchor(key, frame, db)
    if key == "player" and frame.__HRUI_UsingProfessionAnchor then
        frame:SetSize(240, 20)
    else
        frame:SetSize(db.width, db.height)
    end
    frame:SetStatusBarTexture(ns:GetTexture())

    ns:CreateCastbar(frame, db)

    if frame.bg then
        frame.bg:SetTexture(ns:GetTexture())
        frame.bg:SetVertexColor(0.15, 0.15, 0.15, 0.7)
    end

    if frame.Icon then
        frame.Icon:SetSize(db.icon.size, db.icon.size)
        if db.icon.enabled then
            frame.Icon:Show()
        else
            frame.Icon:Hide()
        end
    end

    if frame.Text then
        ApplyCastbarTextSettings(frame, db)
    end

    if frame.Time then
        if db.time.enabled then
            frame.Time:Show()
        else
            frame.Time:Hide()
        end
    end

    if not db.enabled then
        ns:ResetCastbar(frame)
    end
end

function ns.Modules.Castbars:Enable()
    ns:SpawnPlayerCastbar()
    ns:SpawnTargetCastbar()
    ns:SpawnPetCastbar()
    if ns.SpawnBossCastbars then
        ns:SpawnBossCastbars()
    end

    if ns.Movers and ns.Movers.CreateAll then
        ns.Movers:CreateAll()
    end

    self:RefreshAll()
end

function ns.Modules.Castbars:RefreshBar(key)
    ApplyCastbarSettings(key)

    if key ~= "boss" and ns.Movers and ns.Movers.RefreshMover then
        ns.Movers:RefreshMover("castbar_" .. key)
    end

    if ns.UpdateConfigCoordValues then
        ns:UpdateConfigCoordValues("castbar_" .. key)
    end
end

function ns.Modules.Castbars:RefreshAll()
    for _, key in ipairs(spawnOrder) do
        self:RefreshBar(key)
    end
end

function ns:ApplyCastbarTextSettings(frame, db)
    ApplyCastbarTextSettings(frame, db)
end
