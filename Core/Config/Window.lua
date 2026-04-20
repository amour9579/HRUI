local _, ns = ...

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local function GetRealFrame(widget)
    if not widget then
        return nil
    end

    return widget.frame or widget
end

local function EnsureWindowDB()
    ns.db.profile.config = ns.db.profile.config or {}
    ns.db.profile.config.window = ns.db.profile.config.window or {}

    local saved = ns.db.profile.config.window
    saved.width = saved.width or 1200
    saved.height = saved.height or 600

    return saved
end

local function SaveWindowState(frame)
    local saved = EnsureWindowDB()
    if not frame then
        return
    end

    saved.left = frame:GetLeft()
    saved.top = frame:GetTop()
    saved.width = math.floor(frame:GetWidth() + 0.5)
    saved.height = math.floor(frame:GetHeight() + 0.5)

    local status = AceConfigDialog:GetStatusTable("HRUI")
    if status then
        status.left = saved.left
        status.top = saved.top
        status.width = saved.width
        status.height = saved.height
    end
end

local function ApplyWindowState(frame)
    local saved = EnsureWindowDB()
    if not frame then
        return
    end

    local minWidth, minHeight = 900, 500
    local width = math.max(saved.width or 1200, minWidth)
    local height = math.max(saved.height or 600, minHeight)

    saved.width = width
    saved.height = height

    frame:ClearAllPoints()

    if saved.left and saved.top then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.left, saved.top)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    frame:SetSize(width, height)

    local status = AceConfigDialog:GetStatusTable("HRUI")
    if status then
        status.left = saved.left
        status.top = saved.top
        status.width = width
        status.height = height
    end
end

local function SetupWindow(widget)
    local frame = GetRealFrame(widget)
    if not frame or frame.HRUI_WindowSetup then
        return
    end

    frame:SetParent(UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetResizable(true)

    if frame.SetResizeBounds then
        frame:SetResizeBounds(900, 500, 1600, 1200)
    end

    frame:SetScript("OnDragStart", function(f)
        f:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        SaveWindowState(f)
    end)

    if widget and widget.sizer_se then
        widget.sizer_se:Show()
        widget.sizer_se:HookScript("OnMouseUp", function()
            SaveWindowState(frame)
        end)
    end

    frame:HookScript("OnHide", function()
        SaveWindowState(frame)

        if ns.DisableIconPreview then
            ns:DisableIconPreview()
        end

        if ns.Movers and ns.Movers.IsUnlocked and ns.Movers:IsUnlocked() then
            ns.Movers:Lock()
        end
    end)

    frame.HRUI_WindowSetup = true
end

function ns:OpenConfig()
    if InCombatLockdown() then
        local msg = "경고 : 전투 중에는 설정창을 열 수 없습니다."

        if ns.HRUI and ns.HRUI.Print then
            ns.HRUI:Print(msg)
        else
            print("|cffff3333HRUI|r: " .. msg)
        end

        if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] then
            RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
        elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
            UIErrorsFrame:AddMessage(msg, 1.0, 0.1, 0.1, 1.0)
        end

        return
    end

    ns.ConfigPreviewIcons = true

    local saved = EnsureWindowDB()
    local status = AceConfigDialog:GetStatusTable("HRUI")
    if status then
        status.width = saved.width
        status.height = saved.height
        status.left = saved.left
        status.top = saved.top
    end

    AceConfigDialog:Open("HRUI")

    local widget = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["HRUI"]
    if not widget then
        return
    end

    local frame = GetRealFrame(widget)
    if not frame then
        return
    end

    widget:SetStatusTable(status)
    widget:SetStatusText("HRUI 설정")

    SetupWindow(widget)
    ApplyWindowState(frame)

    ns.ConfigWindow = frame

    if ns.PlayerFrame and ns.UpdatePlayerIcons then
        ns:UpdatePlayerIcons(ns.PlayerFrame)
    end
end

function ns:CloseConfig()
    local widget = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["HRUI"]
    if widget then
        local frame = GetRealFrame(widget)
        if frame then
            SaveWindowState(frame)
        end
    end

    AceConfigDialog:Close("HRUI")

    if ns.DisableIconPreview then
        ns:DisableIconPreview()
    end
end

function ns:UpdateConfigCoordValues()
    local widget = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["HRUI"]
    local frame = widget and GetRealFrame(widget)

    local currentLeft, currentTop
    if frame then
        currentLeft = frame:GetLeft()
        currentTop = frame:GetTop()
    end

    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
    if AceConfigRegistry then
        AceConfigRegistry:NotifyChange("HRUI")
    end

    if frame and currentLeft and currentTop then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", currentLeft, currentTop)

        local status = AceConfigDialog:GetStatusTable("HRUI")
        if status then
            status.left = currentLeft
            status.top = currentTop
        end
    end
end

function ns:UpdateTexturePreviewPanel()
    local panel = self.TexturePreviewPanel
    if not panel or not panel.rows then
        return
    end

    local selected = self.db.profile.general.texture

    for _, row in ipairs(panel.rows) do
        row.preview:SetStatusBarTexture(self.Media.Textures[row.key])

        if row.key == selected then
            row.bg:SetColorTexture(1, 1, 1, 0.05)
            row.label:SetTextColor(1, 0.82, 0, 1)
        else
            row.bg:SetColorTexture(0, 0, 0, 0.03)
            row.label:SetTextColor(0.82, 0.82, 0.82, 1)
        end
    end
end

function ns:ToggleTexturePreviewPanel()
    local parent = self.ConfigWindow
    if not parent then
        return
    end

    if self.TexturePreviewPanel then
        if self.TexturePreviewPanel:IsShown() then
            self.TexturePreviewPanel:Hide()
        else
            self.TexturePreviewPanel:Show()
            self:UpdateTexturePreviewPanel()
        end
        return
    end

    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetSize(250, 260)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 250, -100)

    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    panel:SetBackdropColor(0.08, 0.08, 0.08, 0.48)
    panel:SetBackdropBorderColor(0.10, 0.10, 0.10, 0.28)

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
    panel.title:SetText("유닛 프레임 미리보기")
    panel.title:SetTextColor(0.78, 0.78, 0.78, 1)

    panel.rows = {}

    local keys = {}
    for key in pairs(self.Media.Textures or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys)

    local previous
    for _, key in ipairs(keys) do
        local label = self.ConfigValues.textureValues and self.ConfigValues.textureValues[key] or key

        local row = CreateFrame("Button", nil, panel)
        row:SetSize(220, 22)

        if previous then
            row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -4)
        else
            row:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -32)
        end

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0, 0, 0, 0.03)

        row.hover = row:CreateTexture(nil, "HIGHLIGHT")
        row.hover:SetAllPoints()
        row.hover:SetColorTexture(1, 1, 1, 0.025)

        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.label:SetWidth(90)
        row.label:SetJustifyH("LEFT")
        row.label:SetText(label)
        row.label:SetTextColor(0.82, 0.82, 0.82, 1)

        row.previewBG = row:CreateTexture(nil, "BORDER")
        row.previewBG:SetPoint("LEFT", row.label, "RIGHT", 8, 0)
        row.previewBG:SetSize(110, 12)
        row.previewBG:SetColorTexture(0.09, 0.09, 0.09, 0.42)

        row.preview = CreateFrame("StatusBar", nil, row)
        row.preview:SetPoint("CENTER", row.previewBG, "CENTER")
        row.preview:SetSize(110, 12)
        row.preview:SetMinMaxValues(0, 1)
        row.preview:SetValue(1)
        row.preview:SetStatusBarTexture(self.Media.Textures[key])
        row.preview:SetStatusBarColor(0.25, 0.85, 0.25)

        row.border = CreateFrame("Frame", nil, row, "BackdropTemplate")
        row.border:SetPoint("TOPLEFT", row.preview, "TOPLEFT", -1, 1)
        row.border:SetPoint("BOTTOMRIGHT", row.preview, "BOTTOMRIGHT", 1, -1)
        row.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        row.border:SetBackdropBorderColor(0.10, 0.10, 0.10, 0.18)

        row.key = key

        row:SetScript("OnClick", function(self)
            ns.db.profile.general.texture = self.key

            if ns.RefreshAllUnits then
                ns:RefreshAllUnits()
            end

            if ns.UpdateTexturePreviewPanel then
                ns:UpdateTexturePreviewPanel()
            end
        end)

        panel.rows[#panel.rows + 1] = row
        previous = row
    end

    self.TexturePreviewPanel = panel
    self:UpdateTexturePreviewPanel()
end
