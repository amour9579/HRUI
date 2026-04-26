local _, ns = ...

ns.Movers = ns.Movers or {}

local movers = {}
local gridLines = {}

local moverOrder = {
    "player",
    "target",
    "targettarget",
    "focus",
    "pet",
    "boss",
    "castbar_player",
    "castbar_target",
    "castbar_pet",
    "chat_infobar",
}

local moverLabels = {
    player = "Player",
    target = "Target",
    targettarget = "TargetTarget",
    focus = "Focus",
    pet = "Pet",
    boss = "Boss",
    castbar_player = "Player Castbar",
    castbar_target = "Target Castbar",
    castbar_pet = "Pet Castbar",
    chat_infobar = "Chat InfoBar",
}

local frameRefs = {
    player = "PlayerFrame",
    target = "TargetFrame",
    targettarget = "TargetTargetFrame",
    focus = "FocusFrame",
    pet = "PetFrame",
    boss = "BossFrame",
    castbar_player = "PlayerCastbar",
    castbar_target = "TargetCastbar",
    castbar_pet = "PetCastbar",
    chat_infobar = "ChatInfoBarFrame",
}

local function GetGridSize()
    return (ns.db and ns.db.profile and ns.db.profile.movers and ns.db.profile.movers.gridSize) or 20
end

local function GetSnapDistance()
    return (ns.db and ns.db.profile and ns.db.profile.movers and ns.db.profile.movers.snapDistance) or 8
end

local function GetFineStep()
    return (ns.db and ns.db.profile and ns.db.profile.movers and ns.db.profile.movers.fineStep) or 2
end

local function RoundToGrid(value, step)
    step = step or 1
    if step <= 0 then
        return value
    end
    return math.floor((value / step) + 0.5) * step
end

local function RoundToPixel(value)
    return math.floor((value or 0) + 0.5)
end

local function ClampToScreenByCenter(frame, x, y)
    if not frame then
        return x, y
    end

    local parent = UIParent
    local halfW = (frame:GetWidth() or 0) * 0.5
    local halfH = (frame:GetHeight() or 0) * 0.5

    local minX = -((parent:GetWidth() * 0.5) - halfW)
    local maxX = ((parent:GetWidth() * 0.5) - halfW)

    local minY = -((parent:GetHeight() * 0.5) - halfH)
    local maxY = ((parent:GetHeight() * 0.5) - halfH)

    if x < minX then x = minX end
    if x > maxX then x = maxX end
    if y < minY then y = minY end
    if y > maxY then y = maxY end

    return x, y
end

local function GetCursorCenterOffset()
    local scale = UIParent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local centerX = cursorX - (UIParent:GetWidth() * 0.5)
    local centerY = cursorY - (UIParent:GetHeight() * 0.5)

    return centerX, centerY
end

local function GetFrameForKey(key)
    local ref = frameRefs[key]
    return ref and ns[ref]
end

local function GetMoverDB(key)
    if key == "castbar_player" then
        return ns.db and ns.db.profile and ns.db.profile.castbars and ns.db.profile.castbars.player
    elseif key == "castbar_target" then
        return ns.db and ns.db.profile and ns.db.profile.castbars and ns.db.profile.castbars.target
    elseif key == "castbar_pet" then
        return ns.db and ns.db.profile and ns.db.profile.castbars and ns.db.profile.castbars.pet
    elseif key == "chat_infobar" then
        return ns.db and ns.db.profile and ns.db.profile.chat and ns.db.profile.chat.infoBar
    end

    return ns.db and ns.db.profile and ns.db.profile.unitframes and ns.db.profile.unitframes[key]
end

local function UpdateMoverCoordText(mover)
    if not mover or not mover.coordText then
        return
    end

    local db = GetMoverDB(mover.key)
    if not db then
        mover.coordText:SetText("")
        return
    end

    mover.coordText:SetText(string.format("X:%d  Y:%d", db.x or 0, db.y or 0))
end

local function ApplyFramePosition(frame, db)
    if not frame or not db then
        return
    end

    local x, y = ClampToScreenByCenter(frame, db.x or 0, db.y or 0)
    db.x = RoundToPixel(x)
    db.y = RoundToPixel(y)

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
end

local function ApplyMoverSize(mover, key, attachedFrame, db)
    if not mover then
        return
    end

    local width = db and db.width or 100
    local height = db and db.height or 20

    if key == "boss" and ns.GetBossMoverSize then
        width, height = ns:GetBossMoverSize()
    elseif attachedFrame and attachedFrame.GetSize then
        local frameWidth, frameHeight = attachedFrame:GetSize()
        width = frameWidth and frameWidth > 0 and frameWidth or width
        height = frameHeight and frameHeight > 0 and frameHeight or height
    end

    mover:SetSize(width or 100, height or 20)
end

local function ClearGrid()
    for _, line in ipairs(gridLines) do
        line:Hide()
        line:SetParent(nil)
    end
    wipe(gridLines)
end

local function BuildGrid()
    ClearGrid()

    local gridSize = GetGridSize()
    local parent = UIParent
    local width = parent:GetWidth()
    local height = parent:GetHeight()

    local cols = math.floor(width / gridSize)
    local rows = math.floor(height / gridSize)

    for i = 0, cols do
        local line = parent:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(0, 0.7, 1, 0.12)
        line:SetWidth(1)
        line:SetHeight(height)
        line:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", i * gridSize, 0)
        line:Hide()
        table.insert(gridLines, line)
    end

    for i = 0, rows do
        local line = parent:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(0, 0.7, 1, 0.12)
        line:SetWidth(width)
        line:SetHeight(1)
        line:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, i * gridSize)
        line:Hide()
        table.insert(gridLines, line)
    end

    local vCenter = parent:CreateTexture(nil, "BACKGROUND")
    vCenter:SetColorTexture(1, 0.82, 0, 0.35)
    vCenter:SetWidth(1)
    vCenter:SetHeight(height)
    vCenter:SetPoint("CENTER", parent, "CENTER", 0, 0)
    vCenter:Hide()
    table.insert(gridLines, vCenter)

    local hCenter = parent:CreateTexture(nil, "BACKGROUND")
    hCenter:SetColorTexture(1, 0.82, 0, 0.35)
    hCenter:SetWidth(width)
    hCenter:SetHeight(1)
    hCenter:SetPoint("CENTER", parent, "CENTER", 0, 0)
    hCenter:Hide()
    table.insert(gridLines, hCenter)
end

function ns.Movers:ShowGrid()
    if #gridLines == 0 then
        BuildGrid()
    end

    for _, line in ipairs(gridLines) do
        line:Show()
    end
end

function ns.Movers:HideGrid()
    for _, line in ipairs(gridLines) do
        line:Hide()
    end
end

function ns.Movers:RefreshGrid()
    local wasUnlocked = self.unlocked == true

    self:HideGrid()
    BuildGrid()

    if wasUnlocked then
        self:ShowGrid()
    end
end

local function UpdateMoverDrag(mover)
    local db = GetMoverDB(mover.key)
    if not db then
        return
    end

    local cursorX, cursorY = GetCursorCenterOffset()

    local newX = cursorX + (mover.dragOffsetX or 0)
    local newY = cursorY + (mover.dragOffsetY or 0)

    if IsShiftKeyDown() then
        local fineStep = GetFineStep()
        newX = RoundToGrid(newX, fineStep)
        newY = RoundToGrid(newY, fineStep)
    end

    if IsControlKeyDown() then
        local gridSize = GetGridSize()
        local snapDistance = GetSnapDistance()

        local snappedX = RoundToGrid(newX, gridSize)
        local snappedY = RoundToGrid(newY, gridSize)

        if math.abs(snappedX - newX) <= snapDistance then
            newX = snappedX
        end

        if math.abs(snappedY - newY) <= snapDistance then
            newY = snappedY
        end
    end

    newX, newY = ClampToScreenByCenter(mover, newX, newY)

    newX = RoundToPixel(newX)
    newY = RoundToPixel(newY)

    db.x = newX
    db.y = newY

    ApplyFramePosition(mover, db)
    ApplyFramePosition(mover.attachedFrame, db)

    UpdateMoverCoordText(mover)

    if ns.UpdateConfigCoordValues then
        ns:UpdateConfigCoordValues(mover.key)
    end
end

local function OnMoverMouseDown(self, button)
    if button ~= "LeftButton" then
        return
    end

    local db = GetMoverDB(self.key)
    if not db then
        return
    end

    local cursorX, cursorY = GetCursorCenterOffset()

    self.dragOffsetX = (db.x or 0) - cursorX
    self.dragOffsetY = (db.y or 0) - cursorY
    self.isDragging = true

    self:SetScript("OnUpdate", function(frame)
        UpdateMoverDrag(frame)
    end)
end

local function OnMoverMouseUp(self)
    local db = GetMoverDB(self.key)

    self:SetScript("OnUpdate", nil)
    self.isDragging = nil

    if not db then
        return
    end

    db.x = RoundToPixel(db.x or 0)
    db.y = RoundToPixel(db.y or 0)

    ApplyFramePosition(self, db)
    ApplyFramePosition(self.attachedFrame, db)

    UpdateMoverCoordText(self)

    if ns.UpdateConfigCoordValues then
        ns:UpdateConfigCoordValues(self.key)
    end
end

local function CreateMover(key, attachedFrame, label)
    if movers[key] then
        movers[key].attachedFrame = attachedFrame
        return movers[key]
    end

    local mover = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    mover.key = key
    mover.attachedFrame = attachedFrame
    mover:SetFrameStrata("DIALOG")
    mover:EnableMouse(true)
    mover:SetClampedToScreen(true)

    mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    mover:SetBackdropColor(0, 0.65, 1, 0.10)
    mover:SetBackdropBorderColor(0, 0.75, 1, 0.95)

    mover.text = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mover.text:SetPoint("CENTER")
    mover.text:SetText(label or key)

    mover.coordText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mover.coordText:SetPoint("BOTTOM", mover, "TOP", 0, 4)
    mover.coordText:SetText("")

    mover.hintText = mover:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    mover.hintText:SetPoint("TOP", mover, "BOTTOM", 0, -4)
    mover.hintText:SetText("Ctrl: 스냅 / Shift: 미세 이동")

    mover:SetScript("OnMouseDown", OnMoverMouseDown)
    mover:SetScript("OnMouseUp", OnMoverMouseUp)
    mover:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
        self.isDragging = nil
    end)

    mover:Hide()

    movers[key] = mover
    return mover
end

function ns.Movers:EnsureMover(key)
    if movers[key] then
        return movers[key]
    end

    local frame = GetFrameForKey(key)
    local db = GetMoverDB(key)

    if not frame or not db then
        return nil
    end

    local mover = CreateMover(key, frame, moverLabels[key] or key)
    ApplyMoverSize(mover, key, frame, db)
    ApplyFramePosition(mover, db)
    UpdateMoverCoordText(mover)

    return mover
end

function ns.Movers:CreateAll()
    for _, key in ipairs(moverOrder) do
        local frame = GetFrameForKey(key)
        local db = GetMoverDB(key)

        if frame and db then
            local mover = CreateMover(key, frame, moverLabels[key] or key)
            ApplyMoverSize(mover, key, frame, db)
            ApplyFramePosition(mover, db)
            UpdateMoverCoordText(mover)
        end
    end
end

function ns.Movers:IsUnlocked()
    return self.unlocked == true
end

function ns.Movers:Unlock()
    self.unlocked = true
    self:ShowGrid()

    if ns.ShowBossPreviewFrames then
        ns:ShowBossPreviewFrames()
    end

    for _, key in ipairs(moverOrder) do
        local mover = movers[key]
        local db = GetMoverDB(key)

        if mover and db then
            ApplyMoverSize(mover, key, mover.attachedFrame, db)
            ApplyFramePosition(mover, db)
            UpdateMoverCoordText(mover)

            if db.enabled then
                mover:Show()
            else
                mover:Hide()
            end
        end
    end
end

function ns.Movers:Lock()
    self.unlocked = false
    self:HideGrid()

    if ns.HideBossPreviewFrames then
        ns:HideBossPreviewFrames()
    end

    for _, mover in pairs(movers) do
        mover:Hide()
        mover:SetScript("OnUpdate", nil)
        mover.isDragging = nil
    end
end

function ns.Movers:RefreshMover(key)
    local mover = movers[key]
    local db = GetMoverDB(key)

    if not mover or not db then
        return
    end

    local attachedFrame = mover.attachedFrame
    if not attachedFrame then
        return
    end

    ApplyMoverSize(mover, key, attachedFrame, db)

    ApplyFramePosition(mover, db)
    ApplyFramePosition(attachedFrame, db)

    UpdateMoverCoordText(mover)

    if key == "boss" and self.unlocked then
        if db.enabled and ns.ShowBossPreviewFrames then
            ns:ShowBossPreviewFrames()
        elseif ns.HideBossPreviewFrames then
            ns:HideBossPreviewFrames()
        end
    end

    if db.enabled and self.unlocked then
        mover:Show()
    else
        mover:Hide()
    end
end
