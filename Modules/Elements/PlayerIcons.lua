local _, ns = ...

local EVENT_PREFIX = "PlayerIcons_"

local function ShouldPreviewIcons()
    return ns.ConfigPreviewIcons == true
end

function ns:DisableIconPreview()
    ns.ConfigPreviewIcons = nil

    if ns.PlayerFrame and ns.UpdatePlayerIcons then
        ns:UpdatePlayerIcons(ns.PlayerFrame)
    end
end

local function GetPlayerIconDB()
    local db = ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes.player
    return db and db.icons
end

local function CreateIcon(frame, texture)
    local parent = frame.Overlay or frame
    local icon = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    icon:SetTexture(texture)
    icon:Hide()
    return icon
end

local function ApplyIcon(icon, frame, cfg)
    if not icon or not cfg then
        return
    end

    icon:ClearAllPoints()
    icon:SetPoint(cfg.anchor or "TOPLEFT", frame, cfg.anchor or "TOPLEFT", cfg.x or 0, cfg.y or 0)

    local size = cfg.size or 16
    icon:SetSize(size, size)
end

local function UpdateRestIcon(frame, db)
    local icon = frame.PlayerIcons and frame.PlayerIcons.rest
    local cfg = db and db.rest
    if not icon or not cfg or not cfg.enabled then
        if icon then icon:Hide() end
        return
    end

    ApplyIcon(icon, frame, cfg)

    local preview = ShouldPreviewIcons()

    if preview or IsResting() then
        icon:SetTexCoord(0, 0.5, 0, 0.421875)
        icon:SetAlpha(preview and 0.85 or 1)
        icon:Show()
    else
        icon:Hide()
    end
end

local function UpdateCombatIcon(frame, db)
    local icon = frame.PlayerIcons and frame.PlayerIcons.combat
    local cfg = db and db.combat
    if not icon or not cfg or not cfg.enabled then
        if icon then icon:Hide() end
        return
    end

    ApplyIcon(icon, frame, cfg)

    local preview = ShouldPreviewIcons()

    if preview or UnitAffectingCombat("player") then
        icon:SetTexCoord(0.5, 1.0, 0, 0.421875)
        icon:SetAlpha(preview and 0.85 or 1)
        icon:Show()
    else
        icon:Hide()
    end
end

local function UpdateLeaderIcon(frame, db)
    local icon = frame.PlayerIcons and frame.PlayerIcons.leader
    local cfg = db and db.leader
    if not icon or not cfg or not cfg.enabled then
        if icon then icon:Hide() end
        return
    end

    ApplyIcon(icon, frame, cfg)

    local preview = ShouldPreviewIcons()

    if preview or UnitIsGroupLeader("player") then
        icon:SetAlpha(preview and 0.85 or 1)
        icon:Show()
    else
        icon:Hide()
    end
end

local function UpdateAssistantIcon(frame, db)
    local icon = frame.PlayerIcons and frame.PlayerIcons.assistant
    local cfg = db and db.assistant
    if not icon or not cfg or not cfg.enabled then
        if icon then icon:Hide() end
        return
    end

    ApplyIcon(icon, frame, cfg)

    local preview = ShouldPreviewIcons()

    if preview or (UnitIsGroupAssistant and UnitIsGroupAssistant("player")) then
        icon:SetAlpha(preview and 0.85 or 1)
        icon:Show()
    else
        icon:Hide()
    end
end

function ns:UpdatePlayerIcons(frame)
    if not frame or frame.unit ~= "player" then
        return
    end

    local db = GetPlayerIconDB()
    if not db or not db.enabled or not frame.PlayerIcons then
        if frame.PlayerIcons then
            for _, icon in pairs(frame.PlayerIcons) do
                icon:Hide()
            end
        end
        return
    end

    UpdateRestIcon(frame, db)
    UpdateCombatIcon(frame, db)
    UpdateLeaderIcon(frame, db)
    UpdateAssistantIcon(frame, db)
end

function ns:RefreshPlayerIcons(frame)
    ns:UpdatePlayerIcons(frame)
end

function ns:RegisterPlayerIconsEvents()
    if ns.PlayerIconsEventsRegistered or not ns.Event then
        return
    end

    local function RefreshIcons()
        local playerFrame = ns.PlayerFrame
        if playerFrame then
            ns:UpdatePlayerIcons(playerFrame)
        end
    end

    ns.Event:Register("PLAYER_UPDATE_RESTING", EVENT_PREFIX .. "Resting", RefreshIcons)
    ns.Event:Register("PLAYER_REGEN_DISABLED", EVENT_PREFIX .. "CombatStart", RefreshIcons)
    ns.Event:Register("PLAYER_REGEN_ENABLED", EVENT_PREFIX .. "CombatEnd", RefreshIcons)
    ns.Event:Register("GROUP_ROSTER_UPDATE", EVENT_PREFIX .. "GroupRoster", RefreshIcons)
    ns.Event:Register("PARTY_LEADER_CHANGED", EVENT_PREFIX .. "LeaderChanged", RefreshIcons)
    ns.Event:Register("PLAYER_ENTERING_WORLD", EVENT_PREFIX .. "PEW", RefreshIcons)

    ns.PlayerIconsEventsRegistered = true
end

function ns:CreatePlayerIcons(frame)
    if not frame or frame.unit ~= "player" then
        return
    end

    if frame.PlayerIcons then
        return
    end

    frame.PlayerIcons = {}

    frame.PlayerIcons.rest = CreateIcon(frame, "Interface\\CharacterFrame\\UI-StateIcon")
    frame.PlayerIcons.combat = CreateIcon(frame, "Interface\\CharacterFrame\\UI-StateIcon")
    frame.PlayerIcons.leader = CreateIcon(frame, "Interface\\GroupFrame\\UI-Group-LeaderIcon")
    frame.PlayerIcons.assistant = CreateIcon(frame, "Interface\\GroupFrame\\UI-Group-AssistantIcon")

    ns:RegisterPlayerIconsEvents()
    ns:UpdatePlayerIcons(frame)
end
