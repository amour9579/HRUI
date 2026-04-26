local addonName, ns = ...

ns.mplus = ns.mplus or {}
local M = ns.mplus

M.pendingReport = nil
M.pendingType = nil
M.pendingEng = nil
M.enabled = true
M.pendingResponseTimer = nil
M.suppressNextOwnCommand = nil

local strfind = string.find
local format = string.format
local sort = table.sort
local tinsert = table.insert

local function GetReportFields()
    if not ns.db or not ns.db.profile then
        return nil
    end

    local db = ns.db.profile
    local reporter = db.mythicPlusReporter
    if not reporter then
        return nil
    end

    return reporter.reportFields
end

local function IsReportFieldEnabled(key)
    local reportFields = GetReportFields()
    if not reportFields then
        return true
    end

    return reportFields[key] ~= false
end

local KEYSTONE_ITEM_IDS = {
    [138019] = true,
    [151073] = true,
    [158923] = true,
    [180653] = true,
    [187786] = true,
}

local function IsEnabled()
    if not ns.db or not ns.db.profile then
        return true
    end

    local db = ns.db.profile

    db.mythicPlusReporter = db.mythicPlusReporter or {}

    if db.mythicPlusReporter.enabled == nil then
        db.mythicPlusReporter.enabled = true
    end

    return db.mythicPlusReporter.enabled
end

local function IsCombatBlocked()
    return (InCombatLockdown and InCombatLockdown())
        or (IsEncounterInProgress and IsEncounterInProgress())
        or UnitAffectingCombat("player")
end

local function GetRewardIlvl(level)
    if not level or level < 2 then
        return nil
    end

    -- 시즌 변경 시 수동 수정 필요
    if level >= 10 then
        return 272
    elseif level >= 7 then
        return 269
    elseif level >= 6 then
        return 266
    elseif level >= 4 then
        return 263
    elseif level >= 2 then
        return 259
    end

    return nil
end

local function GetPlayerShortName()
    local name = UnitName("player")
    if Ambiguate and name then
        return Ambiguate(name, "short")
    end
    return name
end

function M:GetResponseDelay()
    local name = GetPlayerShortName() or "player"
    local sum = 0

    for i = 1, #name do
        sum = sum + string.byte(name, i)
    end

    -- 0.15 ~ 0.55 사이의 고정 지연
    return 0.15 + ((sum % 9) * 0.05)
end

function M:CancelPendingResponse()
    if self.pendingResponseTimer then
        self.pendingResponseTimer:Cancel()
        self.pendingResponseTimer = nil
    end
end

function M:ScheduleResponse(channel, reportType, isEnglish, delay)
    if not IsEnabled() then
        return
    end

    if not channel or not reportType then
        return
    end

    self:CancelPendingResponse()

    local waitTime = tonumber(delay) or self:GetResponseDelay()
    if waitTime < 0 then
        waitTime = 0
    end

    self.pendingResponseTimer = C_Timer.NewTimer(waitTime, function()
        self.pendingResponseTimer = nil
        self:Report(channel, reportType, isEnglish)
    end)
end

function M:SendCommandTrigger(command)
    if not IsEnabled() then
        return
    end

    if not command or command == "" then
        return
    end

    if IsCombatBlocked() then
        return
    end

    local channel = self:GetPreferredReportChannel()
    if not channel then
        return
    end

    local reportType, isEnglish = self:ParseCommand(command)
    if reportType then
        -- 정보패널 클릭으로 내가 보낸 명령은
        -- 다음 채팅 이벤트에서 1회 무시하도록 표시
        self.suppressNextOwnCommand = {
            channel = channel,
            reportType = reportType,
            isEnglish = isEnglish,
        }

        self:ScheduleResponse(channel, reportType, isEnglish, self:GetResponseDelay())
    end

    SendChatMessage(command, channel)
end

function M:GetPreferredReportChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    end

    if IsInRaid() then
        return "RAID"
    end

    if IsInGroup() then
        return "PARTY"
    end

    if IsInGuild and IsInGuild() then
        return "GUILD"
    end

    return "SAY"
end

function M:SendManualReport(reportType, isEnglish)
    if not IsEnabled() then
        return
    end

    local channel = self:GetPreferredReportChannel()
    if not channel then
        return
    end

    self:Report(channel, reportType, isEnglish)
end

function M:GetMyKeystone()
    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then
        return "쐐기돌 없음"
    end

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink then
                local itemID = info.itemID

                if itemID and KEYSTONE_ITEM_IDS[itemID] then
                    return info.hyperlink
                end

                if itemID then
                    local classID, subclassID = select(6, GetItemInfoInstant(itemID))
                    if classID == 15 and subclassID == 5 then
                        return info.hyperlink
                    end
                end

                local itemName = GetItemInfo(info.hyperlink)
                if itemName and type(itemName) == "string" and strfind(itemName, "쐐기돌", 1, true) then
                    return info.hyperlink
                end
            end
        end
    end

    return "쐐기돌 없음"
end

function M:GetWeeklyDungeonInfo(isEnglish)
    if not C_MythicPlus or not C_MythicPlus.GetRunHistory then
        return isEnglish and "Weekly: Unavailable" or "주차: 정보 없음"
    end

    local runHistory = C_MythicPlus.GetRunHistory(false, true)
    local numRuns = (runHistory and #runHistory) or 0

    if numRuns == 0 then
        return isEnglish and "Weekly: Incomplete" or "주차: 미완료"
    end

    sort(runHistory, function(a, b)
        return (a.level or 0) > (b.level or 0)
    end)

    local ilvl1 = GetRewardIlvl(runHistory[1] and runHistory[1].level) or (isEnglish and "N/A" or "미완료")
    local ilvl2 = GetRewardIlvl(runHistory[4] and runHistory[4].level) or (isEnglish and "N/A" or "미완료")
    local ilvl3 = GetRewardIlvl(runHistory[8] and runHistory[8].level) or (isEnglish and "N/A" or "미완료")

    if isEnglish then
        return format("Weekly: Total %d [1st:%s / 4th:%s / 8th:%s]", numRuns, tostring(ilvl1), tostring(ilvl2),
            tostring(ilvl3))
    end

    return format("주차: 총 %d회 [1회:%s / 4회:%s / 8회:%s]", numRuns, tostring(ilvl1), tostring(ilvl2), tostring(ilvl3))
end

local function GetCurrentSpecName(isEnglish)
    local fallbackName = isEnglish and "Character" or "캐릭터"
    local specIndex = GetSpecialization()

    if specIndex and specIndex > 0 then
        local _, name = GetSpecializationInfo(specIndex)
        if name and name ~= "" then
            return name
        end
    end

    return fallbackName
end

local function GetCurrentEquippedItemLevelText()
    local _, equippedLvl = GetAverageItemLevel()
    return format("%.1f", equippedLvl or 0)
end

local function GetCurrentDungeonScore()
    if C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore then
        return C_ChallengeMode.GetOverallDungeonScore() or 0
    end

    return 0
end

function M:BuildReportMessage(reportType, isEnglish)
    if reportType == "돌" then
        local keystone = self:GetMyKeystone()
        local infoParts = {}

        if isEnglish and keystone == "쐐기돌 없음" then
            keystone = "No Keystone"
        end

        if IsReportFieldEnabled("showSpec") then
            tinsert(infoParts, format("[%s]", GetCurrentSpecName(isEnglish)))
        end

        if IsReportFieldEnabled("showItemLevel") then
            if isEnglish then
                tinsert(infoParts, format("iLvl:%s", GetCurrentEquippedItemLevelText()))
            else
                tinsert(infoParts, format("템렙:%s", GetCurrentEquippedItemLevelText()))
            end
        end

        if IsReportFieldEnabled("showScore") then
            if isEnglish then
                tinsert(infoParts, format("(Score:%d)", GetCurrentDungeonScore()))
            else
                tinsert(infoParts, format("(점수:%d)", GetCurrentDungeonScore()))
            end
        end

        if #infoParts > 0 then
            return format("%s >> %s", table.concat(infoParts, " "), keystone)
        end

        return tostring(keystone)
    elseif reportType == "주차" then
        return self:GetWeeklyDungeonInfo(isEnglish)
    end

    return ""
end

function M:ClearPending()
    self.pendingReport = nil
    self.pendingType = nil
    self.pendingEng = nil
end

function M:SetPending(channel, reportType, isEnglish)
    self.pendingReport = channel
    self.pendingType = reportType
    self.pendingEng = isEnglish
end

function M:Report(channel, reportType, isEnglish)
    if not IsEnabled() then
        return
    end

    if not channel or not reportType then
        return
    end

    if IsCombatBlocked() then
        self:SetPending(channel, reportType, isEnglish)
        return
    end

    local outMsg = self:BuildReportMessage(reportType, isEnglish)
    if outMsg and outMsg ~= "" then
        SendChatMessage(outMsg, channel)
    end

    self:ClearPending()
end

local strfind = string.find

function M:ParseCommand(msg)
    if type(msg) ~= "string" then
        return nil, false
    end

    local ok, found = pcall(strfind, msg, "^%s*!돌%s*$")
    if ok and found then
        return "돌", false
    end

    ok, found = pcall(strfind, msg, "^%s*!keys%s*$")
    if ok and found then
        return "돌", true
    end

    ok, found = pcall(strfind, msg, "^%s*!ehf%s*$")
    if ok and found then
        return "돌", true
    end

    ok, found = pcall(strfind, msg, "^%s*!주차%s*$")
    if ok and found then
        return "주차", false
    end

    ok, found = pcall(strfind, msg, "^%s*!weekly%s*$")
    if ok and found then
        return "주차", true
    end

    return nil, false
end

function M:GetChannelFromEvent(event)
    if event == "CHAT_MSG_GUILD" then
        return "GUILD"
    elseif event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" then
        return "PARTY"
    elseif event == "CHAT_MSG_INSTANCE_CHAT" or event == "CHAT_MSG_INSTANCE_CHAT_LEADER" then
        return "INSTANCE_CHAT"
    elseif event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then
        return "RAID"
    end

    return nil
end

function M:HandleChatCommand(event, msg, sender)
    if not IsEnabled() then
        return
    end

    local reportType, isEnglish = self:ParseCommand(msg)
    if not reportType then
        return
    end

    local channel = self:GetChannelFromEvent(event)
    if not channel then
        return
    end

    local playerName = GetPlayerShortName()
    local shortSender = sender
    if Ambiguate and sender then
        shortSender = Ambiguate(sender, "short")
    end

    -- 정보패널 클릭으로 내가 방금 보낸 명령의 에코면 1회 무시
    if shortSender == playerName and self.suppressNextOwnCommand then
        local pending = self.suppressNextOwnCommand
        if pending.channel == channel
            and pending.reportType == reportType
            and pending.isEnglish == isEnglish then
            self.suppressNextOwnCommand = nil
            return
        end
    end

    self:ScheduleResponse(channel, reportType, isEnglish, self:GetResponseDelay())
end

function M:OnRegenEnabled()
    if not IsEnabled() then
        self:ClearPending()
        self:CancelPendingResponse()
        return
    end

    if self.pendingReport and self.pendingType then
        self:Report(self.pendingReport, self.pendingType, self.pendingEng)
    end
end

function M:RegisterEvents()
    if not ns.Event or not ns.Event.Register then
        return
    end

    ns.Event:Register("CHAT_MSG_GUILD", "KeystoneReporterGuild", function(event, msg, sender, ...)
        M:HandleChatCommand(event, msg, sender, ...)
    end)

    ns.Event:Register("CHAT_MSG_PARTY", "KeystoneReporterParty", function(event, msg, sender, ...)
        M:HandleChatCommand(event, msg, sender, ...)
    end)

    ns.Event:Register("CHAT_MSG_PARTY_LEADER", "KeystoneReporterPartyLeader", function(event, msg, sender, ...)
        M:HandleChatCommand(event, msg, sender, ...)
    end)

    ns.Event:Register("CHAT_MSG_INSTANCE_CHAT", "KeystoneReporterInstance", function(event, msg, sender, ...)
        M:HandleChatCommand(event, msg, sender, ...)
    end)

    ns.Event:Register("CHAT_MSG_INSTANCE_CHAT_LEADER", "KeystoneReporterInstanceLeader",
        function(event, msg, sender, ...)
            M:HandleChatCommand(event, msg, sender, ...)
        end)

    ns.Event:Register("CHAT_MSG_RAID", "KeystoneReporterRaid", function(event, msg, sender, ...)
        M:HandleChatCommand(event, msg, sender, ...)
    end)

    ns.Event:Register("CHAT_MSG_RAID_LEADER", "KeystoneReporterRaidLeader", function(event, msg, sender, ...)
        M:HandleChatCommand(event, msg, sender, ...)
    end)

    ns.Event:Register("PLAYER_REGEN_ENABLED", "KeystoneReporterRegen", function()
        M:OnRegenEnabled()
    end)
end

function M:UnregisterEvents()
    if ns.Event and ns.Event.UnregisterPrefix then
        ns.Event:UnregisterPrefix("KeystoneReporter")
    end

    self:CancelPendingResponse()
end

function M:Initialize()
    self:UnregisterEvents()

    if IsEnabled() then
        self:RegisterEvents()
    end
end

M:Initialize()
