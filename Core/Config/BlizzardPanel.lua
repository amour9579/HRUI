local _, ns = ...

local function CreateBlizzardOptionsPanel()
    if ns.BlizzardOptionsPanel then
        return ns.BlizzardOptionsPanel
    end

    local panel = CreateFrame("Frame", "HRUIBlizzardOptionsPanel", UIParent)
    ns.BlizzardOptionsPanel = panel

    panel.name = "HRUI"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("HRUI")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetWidth(600)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("HRUI 설정창으로 바로 이동하거나 명령어를 확인할 수 있습니다.")

    local openButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openButton:SetSize(160, 24)
    openButton:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
    openButton:SetText("설정창 열기")

    openButton:SetScript("OnClick", function()
        local function OpenHRUIConfig()
            if ns and ns.OpenConfig then
                ns:OpenConfig()
                return
            end

            if SlashCmdList and SlashCmdList["HRUI"] then
                SlashCmdList["HRUI"]("")
            end
        end

        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
            C_Timer.After(0, OpenHRUIConfig)
            return
        end

        if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
            HideUIPanel(InterfaceOptionsFrame)
            C_Timer.After(0, OpenHRUIConfig)
            return
        end

        OpenHRUIConfig()
    end)

    local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    help:SetPoint("TOPLEFT", openButton, "BOTTOMLEFT", 0, -16)
    help:SetWidth(700)
    help:SetJustifyH("LEFT")
    help:SetJustifyV("TOP")
    help:SetText(
        "|cffffcc00HRUI 명령어:|r\n\n" ..
        "|cffd5d5d5/hrui|r - 설정창 열기/닫기\n" ..
        "|cffd5d5d5/hrui move|r - 이동 모드 ON\n" ..
        "|cffd5d5d5/hrui lock|r - 이동 모드 OFF\n" ..
        "|cffd5d5d5/hrui close|r - 설정창 닫기"
    )

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        category.ID = panel.name
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    panel:Hide()

    return panel
end

if ns.Event then
    ns.Event:Register("PLAYER_LOGIN", "BlizzardOptionsPanel_Create", function()
        CreateBlizzardOptionsPanel()
    end)
else
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("PLAYER_LOGIN")
    loader:SetScript("OnEvent", function()
        CreateBlizzardOptionsPanel()
    end)
end
