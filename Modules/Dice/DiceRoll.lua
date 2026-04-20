local _, ns = ...

ns.Modules = ns.Modules or {}

local Dice = {}
ns.Modules.Dice = Dice

local GetItemInfo = C_Item.GetItemInfo
local RollOnLoot = RollOnLoot
local ConfirmLootRoll = ConfirmLootRoll
local GetLootRollItemLink = GetLootRollItemLink
local After = C_Timer.After
local NewTimer = C_Timer.NewTimer
local GetInstanceInfo = GetInstanceInfo
local HookSecureFunc = hooksecurefunc
local StaticPopupHide = StaticPopup_Hide
local StaticPopupFindVisible = StaticPopup_FindVisible

local HOUSING_CLASS_ID = (Enum.ItemClass and Enum.ItemClass.Housing) or 20

Dice.db = nil
Dice.currentInstanceType = "none"
Dice.closeTimer = nil
Dice.historyHookInstalled = false
Dice.elvUILootModule = nil
Dice.activeRolls = {}

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

        return db
    end

    return nil
end

function Dice:IsEnabled()
    local db = self.db or GetDB()
    return db and db.enabled
end

function Dice:UpdateInstanceInfo()
    local _, instanceType = GetInstanceInfo()
    self.currentInstanceType = instanceType or "none"
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

function Dice:ShouldHideInDungeon()
    if not self:IsEnabled() then
        return false
    end

    if not self.db or not self.db.hideInDungeons then
        return false
    end

    if self.currentInstanceType ~= "party" then
        return false
    end

    if not self:HasActiveRolls() then
        return true
    end

    for rollID in pairs(self.activeRolls) do
        local itemLink = GetLootRollItemLink(rollID)
        if itemLink then
            local classID = select(12, GetItemInfo(itemLink))
            if not classID or classID ~= HOUSING_CLASS_ID then
                return false
            end
        end
    end

    return true
end

function Dice:UpdateVisibility()
    if self:ShouldHideInDungeon() then
        self:HideHistoryFrame()
    end
end

function Dice:StopCloseTimer()
    if self.closeTimer then
        self.closeTimer:Cancel()
        self.closeTimer = nil
    end
end

function Dice:TryStartCloseTimer()
    if not self:IsEnabled() then
        return
    end

    if self:HasActiveRolls() then
        return
    end

    if self.closeTimer then
        return
    end

    self.closeTimer = NewTimer(self.db.delay, function()
        Dice:HideHistoryFrame()
        Dice.closeTimer = nil
    end)
end

function Dice:ExecuteRoll(rollID, classID)
    if not self:IsEnabled() then
        return
    end

    if classID ~= HOUSING_CLASS_ID then
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

    pcall(ConfirmLootRoll, rollID, rollType)

    After(0.1, function()
        if StaticPopupFindVisible("CONFIRM_LOOT_ROLL") then
            StaticPopupHide("CONFIRM_LOOT_ROLL")
        end
        Dice:UpdateVisibility()
    end)
end

function Dice:HandleAutoRoll(rollID)
    if not self:IsEnabled() then
        return
    end

    if not self.db or self.db.autoRoll == -1 then
        return
    end

    local itemLink = GetLootRollItemLink(rollID)
    if not itemLink then
        return
    end

    local classID = select(12, GetItemInfo(itemLink))
    if classID then
        self:ExecuteRoll(rollID, classID)
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
        if Dice:ShouldHideInDungeon() then
            GroupLootHistoryFrame:Hide()
        end
    end)

    self.historyHookInstalled = true
end

function Dice:Refresh()
    self.db = GetDB()
    self:UpdateInstanceInfo()

    if not self:IsEnabled() then
        self:StopCloseTimer()
        self.activeRolls = {}
        return
    end

    self:UpdateVisibility()
end

function Dice:Initialize()
    self.db = GetDB()
    self:UpdateInstanceInfo()

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

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ns.ADDON_NAME then
        Dice:Initialize()

    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        Dice:UpdateInstanceInfo()
        Dice.activeRolls = {}
        Dice:StopCloseTimer()
        Dice:UpdateVisibility()

    elseif event == "START_LOOT_ROLL" then
        if not Dice:IsEnabled() then
            return
        end

        Dice.activeRolls[arg1] = true
        Dice:StopCloseTimer()
        Dice:InstallHistoryHook()
        Dice:HandleAutoRoll(arg1)
        After(0.2, function()
            Dice:UpdateVisibility()
        end)

    elseif event == "LOOT_ROLLS_COMPLETE" then
        if Dice.activeRolls[arg1] ~= nil then
            Dice.activeRolls[arg1] = nil
        end

        After(0.5, function()
            Dice:TryStartCloseTimer()
        end)

    elseif event == "PLAYER_REGEN_DISABLED" then
        Dice:HideHistoryFrame()
        Dice:StopCloseTimer()
        Dice.activeRolls = {}
    end
end)
