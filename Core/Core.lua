local _, ns = ...

ns.Modules = ns.Modules or {}

local HRUI = LibStub("AceAddon-3.0"):NewAddon("HRUI", "AceEvent-3.0", "AceConsole-3.0")
ns.HRUI = HRUI

local function DisableBlizzardCastBar(frame)
    if not frame then
        return
    end

    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end

    if frame.Hide then
        frame:Hide()
    end

    frame.Show = function() end
end

function HRUI:DisableBlizzardCastBars()
    DisableBlizzardCastBar(_G.CastingBarFrame)
    DisableBlizzardCastBar(_G.PlayerCastingBarFrame)
    DisableBlizzardCastBar(_G.PetCastingBarFrame)
end

function HRUI:OnInitialize()
    ns.db = LibStub("AceDB-3.0"):New("HRUIDB", ns.Defaults, true)
    self.db = ns.db

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshAll")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshAll")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshAll")

    if ns.SetupOptions then
        ns:SetupOptions()
    end

    if ns.RegisterChatCommands then
        ns:RegisterChatCommands()
    end

    self:RegisterChatCommand("hrui", "HandleSlash")
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("HRUI", 1200, 600)
end

function HRUI:OnEnable()
    if ns.ApplyItemTooltipCVar then
        ns:ApplyItemTooltipCVar()
    end
    if ns.Modules.UnitFrames and ns.Modules.UnitFrames.Enable then
        ns.Modules.UnitFrames:Enable()
    end

    if ns.Modules.Castbars and ns.Modules.Castbars.Enable then
        ns.Modules.Castbars:Enable()
    end

    if ns.Modules and ns.Modules.ActionBars then
        ns.Modules.ActionBars:Enable()
    end

    if ns.Modules and ns.Modules.Chat and ns.Modules.Chat.Enable then
        ns.Modules.Chat:Enable()
    end

    --self:Print("|cff00ff00설정 명령어|r :/HRUI 또는 ESC-설정-애드온 HRUI메뉴에서 버튼 클릭")
end

function HRUI:IsConfigOpen()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    return AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["HRUI"] ~= nil
end

function HRUI:HandleSlash(msg)
    msg = (msg or ""):lower()

    if msg == "move" then
        if InCombatLockdown() then
            local warn = "경고 : 전투 중에는 이동 모드를 사용할 수 없습니다."

            self:Print(warn)

            if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] then
                RaidNotice_AddMessage(RaidWarningFrame, warn, ChatTypeInfo["RAID_WARNING"])
            elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
                UIErrorsFrame:AddMessage(warn, 1.0, 0.1, 0.1, 1.0)
            end

            return
        end

        if ns.Movers then
            ns.Movers:Unlock()
        end
    elseif msg == "lock" then
        if ns.Movers then
            ns.Movers:Lock()
        end
    elseif msg == "close" then
        if ns.CloseConfig then
            ns:CloseConfig()
        end

    elseif msg == "" or msg == "config" or msg == "options" then
        if self:IsConfigOpen() then
            if ns.CloseConfig then
                ns:CloseConfig()
            end
        else
            if ns.OpenConfig then
                ns:OpenConfig()
            end
        end
    else
        self:Print("HRUI 명령어:")
        self:Print("/hrui - 설정창 열기/닫기")
        self:Print("/hrui move - 이동 모드")
        self:Print("/hrui lock - 이동 모드 종료")
        self:Print("/hrui close - 설정창 닫기")
    end
end

function HRUI:RefreshAll()
    if ns.ApplyItemTooltipCVar then
        ns:ApplyItemTooltipCVar()
    end
    if ns.Modules.UnitFrames and ns.Modules.UnitFrames.RefreshAll then
        ns.Modules.UnitFrames:RefreshAll()
    end

    if ns.Modules.Castbars and ns.Modules.Castbars.RefreshAll then
        ns.Modules.Castbars:RefreshAll()
    end

    if ns.Modules.ActionBars and ns.Modules.ActionBars.Refresh then
        ns.Modules.ActionBars:Refresh()
    end

    if ns.Modules.Chat and ns.Modules.Chat.Refresh then
        ns.Modules.Chat:Refresh()
    end

    if ns.Modules.Dice and ns.Modules.Dice.Refresh then
        ns.Modules.Dice:Refresh()
    end
end
