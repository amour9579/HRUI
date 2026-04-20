local _, ns = ...

local CombatMessage = {}
ns.CombatMessage = CombatMessage
CombatMessage.isTestActive = false
CombatMessage.eventsRegistered = false

local EVENT_PREFIX = "CombatMessage_"

local function GetDB()
    ns.db.profile.chat = ns.db.profile.chat or {}
    ns.db.profile.chat.combatMessage = ns.db.profile.chat.combatMessage or {
        enabled = true,
        backdrop = false,

        fontSize = 32,
        x = 0,
        y = 200,
        fadeTime = 1.5,

        startText = "* 전투 시작 *",
        endText = "* 전투 종료 *",

        startColor = { 1.0, 0.1, 0.1 },
        endColor = { 0.2, 1.0, 0.2 },
    }

    return ns.db.profile.chat.combatMessage
end

function CombatMessage:CreateFrame()
    if self.frame then
        return
    end

    local frame = CreateFrame("Frame", "HRUICombatMessageFrame", UIParent)
    frame:SetSize(500, 80)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    frame:Hide()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0, 0, 0, 0.4)
    bg:Hide()
    frame.Background = bg

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetAllPoints()
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetFont(STANDARD_TEXT_FONT, 32, "OUTLINE")
    frame.Text = text

    self.frame = frame
end

function CombatMessage:RegisterEvents()
    if self.eventsRegistered or not ns.Event then
        return
    end

    ns.Event:Register("PLAYER_REGEN_DISABLED", EVENT_PREFIX .. "Start", function(event)
        self:OnEvent(event)
    end)
    ns.Event:Register("PLAYER_REGEN_ENABLED", EVENT_PREFIX .. "End", function(event)
        self:OnEvent(event)
    end)

    self.eventsRegistered = true
end

function CombatMessage:ApplySettings()
    if not self.frame then
        return
    end

    local db = GetDB()

    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", db.x or 0, db.y or 200)

    self.frame.Text:SetFont(STANDARD_TEXT_FONT, db.fontSize or 32, "OUTLINE")

    if db.backdrop then
        self.frame.Background:Show()
    else
        self.frame.Background:Hide()
    end

    self:RegisterEvents()

    if not db.enabled then
        self.frame:Hide()
    end
end

function CombatMessage:ToggleTest(text, color)
    if not self.frame then return end

    if self.isTestActive then
        self.isTestActive = false

        if UIFrameIsFading(self.frame) then
            UIFrameFadeRemoveFrame(self.frame)
        end

        self.frame:Hide()
        return
    end

    self.isTestActive = true
    self:ShowMessage(text, color, nil)
end

function CombatMessage:ShowMessage(text, color, duration)
    if not self.frame then return end

    local r, g, b = color[1], color[2], color[3]

    if UIFrameIsFading(self.frame) then
        UIFrameFadeRemoveFrame(self.frame)
    end

    self.frame.Text:SetText(text or "")
    self.frame.Text:SetTextColor(r or 1, g or 1, b or 1, 1)

    self.frame:SetAlpha(1)
    self.frame:Show()

    if duration then
        UIFrameFadeOut(self.frame, duration, 1, 0)
    end
end

function CombatMessage:OnEvent(event)
    local db = GetDB()
    if not db.enabled then
        return
    end

    local fadeTime = db.fadeTime or 1.5

    if event == "PLAYER_REGEN_DISABLED" then
        self:ShowMessage(
            db.startText or "* 전투 시작 *",
            db.startColor or { 1.0, 0.1, 0.1 },
            fadeTime
        )
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:ShowMessage(
            db.endText or "* 전투 종료 *",
            db.endColor or { 0.2, 1.0, 0.2 },
            fadeTime
        )
    end
end

function CombatMessage:Initialize()
    self:CreateFrame()
    self:ApplySettings()
end

function CombatMessage:Refresh()
    if not self.frame then
        self:Initialize()
        return
    end

    self:ApplySettings()
end
