local _, ns = ...

ns.Modules = ns.Modules or {}

local Dice = {}
ns.Modules.Dice = Dice

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
local RollOnLoot = RollOnLoot
local ConfirmLootRoll = ConfirmLootRoll
local GetLootRollItemLink = GetLootRollItemLink
local After = C_Timer and C_Timer.After
local NewTimer = C_Timer and C_Timer.NewTimer
local GetInstanceInfo = GetInstanceInfo
local HookSecureFunc = hooksecurefunc
local StaticPopupHide = StaticPopup_Hide
local StaticPopupFindVisible = StaticPopup_FindVisible
local Item = Item

local HOUSING_CLASS_ID = (Enum.ItemClass and Enum.ItemClass.Housing) or 20

Dice.db = nil
Dice.currentInstanceType = "none"
Dice.closeTimer = nil
Dice.historyHookInstalled = false
Dice.elvUILootModule = nil
Dice.activeRolls = {}
Dice.rollTimers = {}

local eventFrame = CreateFrame("Frame")

local function GetDB()
    if ns.db and ns.db.profile then
        ns.db.profile.dice = ns.db.profile.dice or {}
        local db = ns.db.profile.dice

        if db.enabled == nil then
            db.enabled = true
        end

        if db.delay == nil then
            db.delay = 5
        end

        if db.autoRoll == nil then
            db.autoRoll = 1
        end

        if db.hideInDungeons == nil then
            db.hideInDungeons = false
        end

        if db.rollTimeout == nil then
            db.rollTimeout = 60
        end
        return db
    end

    return nil
end

local function SafeCancelTimer(timer)
    if timer and type(timer) == "table" and timer.Cancel then
        pcall(timer.Cancel, timer)
    end
end
function Dice:IsEnabled()
    local db = self.db or GetDB()
    return db and db.enabled
end

function Dice:UpdateInstanceInfo()
    local ok, _, instanceType = pcall(GetInstanceInfo)
    self.currentInstanceType = (ok and instanceType) or "none"
end

function Dice:HasActiveRolls()
    for _ in pairs(self.activeRolls) do
        return true
    end

    return false
end

function Dice:HideHistoryFrame()
    if GroupLootHistoryFrame then
        GroupLootHistoryFrame:Hide()
    end

    if self.elvUILootModule and self.elvUILootModule.GroupLootHistoryFrame then
        self.elvUILootModule.GroupLootHistoryFrame:Hide()
    end
end

function Dice:CancelAllRollTimers()
    for _, timer in pairs(self.rollTimers) do
        SafeCancelTimer(timer)
    end

    if wipe then
        wipe(self.rollTimers)
    else
        self.rollTimers = {}
    end
end

function Dice:ShouldHideInInstance()
    if not self:IsEnabled() then
        return false
    end

    if not self.db or not self.db.hideInDungeons then
        return false
    end

    if self.currentInstanceType ~= "party" and self.currentInstanceType ~= "raid" then
        return false
    end

    if not self:HasActiveRolls() then
        return true
    end

    if not GetItemInfo then
        return false
    end
    for rollID in pairs(self.activeRolls) do
        local itemLink = GetLootRollItemLink(rollID)
        if not itemLink then
            return false
        end

        local classID = select(12, GetItemInfo(itemLink))
        if not classID or classID ~= HOUSING_CLASS_ID then
            return false
        end
    end

    return true
end

function Dice:UpdateVisibility()
    if self:ShouldHideInInstance() then
        self:HideHistoryFrame()
    end
end

function Dice:StopCloseTimer()
    if self.closeTimer then
        SafeCancelTimer(self.closeTimer)
        self.closeTimer = nil
    end
end

function Dice:TryStartCloseTimer()
    if not self:IsEnabled() or not self.db then
        return
    end

    if self:HasActiveRolls() or self.closeTimer then
        return
    end

    if NewTimer then
        self.closeTimer = NewTimer(self.db.delay, function()
            Dice:HideHistoryFrame()
            Dice.closeTimer = nil
        end)
    elseif After then
        self.closeTimer = true
        After(self.db.delay, function()
            if not Dice:HasActiveRolls() then
                Dice:HideHistoryFrame()
            end
            Dice.closeTimer = nil
        end)
    end
end

function Dice:FullReset()
    self:CancelAllRollTimers()
    self:StopCloseTimer()

    if wipe then
        wipe(self.activeRolls)
    else
        self.activeRolls = {}
    end

    self:HideHistoryFrame()
end

function Dice:ExecuteRoll(rollID, classID)
    if not self:IsEnabled() then
        return
    end

    if classID ~= HOUSING_CLASS_ID or not RollOnLoot then
        return
    end

    local rollType = self.db.autoRoll
    if rollType == -1 then
        return
    end

    local ok, err = pcall(RollOnLoot, rollID, rollType)
    if not ok then
        if ns.HRUI and ns.HRUI.Print then
            ns.HRUI:Print("주사위 자동 굴림 실행에 실패했습니다: " .. tostring(err))
        else
            print("|cffff3333HRUI:|r 주사위 자동 굴림 실행에 실패했습니다: " .. tostring(err))
        end
        return
    end

    if ConfirmLootRoll then
        pcall(ConfirmLootRoll, rollID, rollType)
    end

    if After then
        After(0.1, function()
            if StaticPopupFindVisible and StaticPopupFindVisible("CONFIRM_LOOT_ROLL") then
                StaticPopupHide("CONFIRM_LOOT_ROLL")
            end
            Dice:UpdateVisibility()
        end)
    else
        self:UpdateVisibility()
    end
end

function Dice:HandleAutoRoll(rollID)
    if not self:IsEnabled() then
        return
    end

    if not self.db or self.db.autoRoll == -1 then
        return
    end

    local itemLink = GetLootRollItemLink(rollID)
    if not itemLink or not GetItemInfo then
        return
    end

    local classID = select(12, GetItemInfo(itemLink))
    if classID then
        self:ExecuteRoll(rollID, classID)
        return
    end

    if not Item or not Item.CreateFromItemLink then
        return
    end
    local ok, item = pcall(Item.CreateFromItemLink, Item, itemLink)
    if not ok or not item then
        return
    end

    item:ContinueOnItemLoad(function()
        if not GetLootRollItemLink(rollID) then
            return
        end

        local asyncClassID = select(12, GetItemInfo(itemLink))
        if asyncClassID then
            Dice:ExecuteRoll(rollID, asyncClassID)
            Dice:UpdateVisibility()
        end
    end)
end

function Dice:InstallHistoryHook()
    if self.historyHookInstalled or not GroupLootHistoryFrame then
        return
    end

    HookSecureFunc(GroupLootHistoryFrame, "Show", function()
        if Dice:ShouldHideInInstance() then
            GroupLootHistoryFrame:Hide()
        end
    end)

    self.historyHookInstalled = true
end

function Dice:Refresh()
    self.db = GetDB()
    self:UpdateInstanceInfo()

    if not self:IsEnabled() then
        self:CancelAllRollTimers()
        self:StopCloseTimer()
        if wipe then
            wipe(self.activeRolls)
        else
            self.activeRolls = {}
        end
        return
    end

    self:UpdateVisibility()
end

function Dice:Initialize()
    self.db = GetDB()
    self:UpdateInstanceInfo()

    if self.db and not RollOnLoot then
        self.db.autoRoll = -1
    end
    if ElvUI then
        local E = unpack(ElvUI)
        if E and E.GetModule then
            self.elvUILootModule = E:GetModule("Loot", true)
        end
    end

    self:InstallHistoryHook()
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("START_LOOT_ROLL")
eventFrame:RegisterEvent("LOOT_ROLLS_COMPLETE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("GROUP_LEFT")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ns.ADDON_NAME then
        Dice:Initialize()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        Dice:UpdateInstanceInfo()
        Dice:FullReset()
        Dice:UpdateVisibility()
    elseif event == "START_LOOT_ROLL" then
        if not Dice:IsEnabled() or not Dice.db then
            return
        end

        Dice:UpdateInstanceInfo()
        Dice.activeRolls[arg1] = true
        Dice:StopCloseTimer()
        Dice:InstallHistoryHook()
        if Dice.db.rollTimeout and Dice.db.rollTimeout > 0 and not Dice.rollTimers[arg1] then
            local watchdogRollID = arg1

            if NewTimer then
                Dice.rollTimers[watchdogRollID] = NewTimer(Dice.db.rollTimeout, function()
                    Dice.rollTimers[watchdogRollID] = nil
                    Dice.activeRolls[watchdogRollID] = nil

                    if not Dice:HasActiveRolls() then
                        if wipe then
                            wipe(Dice.activeRolls)
                        else
                            Dice.activeRolls = {}
                        end
                        Dice:CancelAllRollTimers()
                        Dice:HideHistoryFrame()
                    end
                end)
            elseif After then
                Dice.rollTimers[watchdogRollID] = true
                After(Dice.db.rollTimeout, function()
                    if not Dice.rollTimers[watchdogRollID] then
                        return
                    end

                    Dice.rollTimers[watchdogRollID] = nil
                    Dice.activeRolls[watchdogRollID] = nil

                    if not Dice:HasActiveRolls() then
                        if wipe then
                            wipe(Dice.activeRolls)
                        else
                            Dice.activeRolls = {}
                        end
                        Dice:CancelAllRollTimers()
                        Dice:HideHistoryFrame()
                    end
                end)
            end
        end

        if Dice:ShouldHideInInstance() then
            Dice:HideHistoryFrame()
        end
        Dice:HandleAutoRoll(arg1)
        if After then
            After(0.2, function()
                Dice:UpdateVisibility()
            end)
        end
    elseif event == "LOOT_ROLLS_COMPLETE" then
        Dice.activeRolls[arg1] = nil
        SafeCancelTimer(Dice.rollTimers[arg1])
        Dice.rollTimers[arg1] = nil

        for rollID in pairs(Dice.activeRolls) do
            if not GetLootRollItemLink(rollID) then
                SafeCancelTimer(Dice.rollTimers[rollID])
                Dice.rollTimers[rollID] = nil
                Dice.activeRolls[rollID] = nil
            end
        end

        local function CheckAndStartTimer()
            if not Dice:HasActiveRolls() then
                if wipe then
                    wipe(Dice.activeRolls)
                else
                    Dice.activeRolls = {}
                end
                Dice:TryStartCloseTimer()
            end
        end

        if After then
            After(0.1, CheckAndStartTimer)
        else
            CheckAndStartTimer()
        end
    elseif event == "GROUP_LEFT" or event == "PLAYER_REGEN_DISABLED" then
        Dice:FullReset()
    end
end)
