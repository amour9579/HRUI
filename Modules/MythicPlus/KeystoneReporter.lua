local addonName, ns = ...

ns.mplus = ns.mplus or {}
local M = ns.mplus

M.pendingReport = nil
M.pendingType = nil
M.pendingEng = nil
M.enabled = true
M.pendingResponseTimer = nil
M.suppressNextOwnCommand = nil
M.weeklyRunHistory = nil
M.weeklyRunHistoryReady = false

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

local function CopyRunHistory(runHistory)
    local copied = {}

    if type(runHistory) ~= "table" then
        return copied
    end

    for i, run in ipairs(runHistory) do
        copied[i] = run
    end

    return copied
end

function M:RequestWeeklyDungeonInfoUpdate()
    if C_MythicPlus and C_MythicPlus.RequestMapInfo then
        C_MythicPlus.RequestMapInfo()
    end
end

function M:RefreshWeeklyDungeonInfoCache()
    if not C_MythicPlus or not C_MythicPlus.GetRunHistory then
        return false
    end

    local runHistory = C_MythicPlus.GetRunHistory(false, true)

    if type(runHistory) ~= "table" then
        return false
    end

    self.weeklyRunHistory = CopyRunHistory(runHistory)
    self.weeklyRunHistoryReady = true

    return true
end

function M:PrimeWeeklyDungeonInfo()
    self.weeklyRunHistoryReady = false
    self:RequestWeeklyDungeonInfoUpdate()

    if C_Timer and C_Timer.After then
        C_Timer.After(1.5, function()
            if not M.weeklyRunHistoryReady then
                M:RefreshWeeklyDungeonInfoCache()
            end
        end)

        C_Timer.After(5, function()
            if not M.weeklyRunHistoryReady then
                M:RequestWeeklyDungeonInfoUpdate()
                M:RefreshWeeklyDungeonInfoCache()
            end
        end)
    else
        self:RefreshWeeklyDungeonInfoCache()
    end
end
function M:GetWeeklyDungeonInfo(isEnglish)
    if not C_MythicPlus or not C_MythicPlus.GetRunHistory then
        return isEnglish and "Weekly: Unavailable" or "주차: 정보 없음"
    end

    if not self.weeklyRunHistoryReady then
        self:RequestWeeklyDungeonInfoUpdate()
        return isEnglish and "Weekly: Updating..." or "주차: 정보 갱신 중"
    end

    local runHistory = CopyRunHistory(self.weeklyRunHistory or C_MythicPlus.GetRunHistory(false, true))
    local numRuns = #runHistory

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
    return format("%d", math.floor(equippedLvl or 0))
end

local function GetCurrentDungeonScore()
    if C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore then
        return C_ChallengeMode.GetOverallDungeonScore() or 0
    end

    return 0
end

local function GetPartyResumeFields()
    if not ns.db or not ns.db.profile then
        return nil
    end

    local reporter = ns.db.profile.mythicPlusReporter
    if not reporter then
        return nil
    end

    reporter.partyResume = reporter.partyResume or {}
    reporter.partyResume.fields = reporter.partyResume.fields or {}

    return reporter.partyResume.fields
end

local function GetPartyResumeDB()
    if not ns.db or not ns.db.profile then
        return nil
    end

    local reporter = ns.db.profile.mythicPlusReporter
    if not reporter then
        return nil
    end

    reporter.partyResume = reporter.partyResume or {}

    return reporter.partyResume
end

local function IsPartyResumeEnabled()
    local db = GetPartyResumeDB()

    if not db then
        return true
    end

    if db.enabled == nil then
        return true
    end

    return db.enabled
end

local function IsPartyResumeManual()
    local db = GetPartyResumeDB()

    return db and db.manual == true
end

local function GetPartyResumeManualMessage()
    local db = GetPartyResumeDB()

    if not db then
        return ""
    end

    return db.manualMessage or ""
end

local function TrimText(text)
    text = tostring(text or "")
    return text:match("^%s*(.-)%s*$") or ""
end
local function IsPartyResumeFieldEnabled(key)
    local fields = GetPartyResumeFields()

    if not fields then
        return true
    end

    if fields[key] == nil then
        return true
    end

    return fields[key]
end

local function GetPartyResumeValue(key, defaultValue)
    local fields = GetPartyResumeFields()

    if not fields then
        return defaultValue
    end

    if fields[key] == nil then
        return defaultValue
    end

    return fields[key]
end
local PARTY_RESUME_SPEC_ABBREV = {
    HUNTER = {
        ["사격"] = "격냥",
        ["생존"] = "생냥",
        ["야수"] = "야냥",
    },
    WARRIOR = {
        ["무기"] = "무전",
        ["분노"] = "분전",
        ["방어"] = "방전",
    },
    MAGE = {
        ["비전"] = "비법",
        ["냉기"] = "냉법",
        ["화염"] = "화법",
    },
    WARLOCK = {
        ["악마"] = "악흑",
        ["고통"] = "고흑",
        ["파괴"] = "파흑",
    },
    PRIEST = {
        ["수양"] = "수사",
        ["암흑"] = "암사",
        ["신성"] = "신사",
    },
    SHAMAN = {
        ["정기"] = "정술",
        ["고양"] = "고술",
        ["복원"] = "복술",
    },
    PALADIN = {
        ["신성"] = "신기",
        ["징벌"] = "징기",
        ["보호"] = "보기",
    },
    DRUID = {
        ["회복"] = "회드",
        ["야성"] = "야드",
        ["조화"] = "조드",
        ["수호"] = "수드",
    },
    DEATHKNIGHT = {
        ["혈기"] = "혈죽",
        ["냉기"] = "냉죽",
        ["부정"] = "부죽",
    },
}

local function GetPartyResumeSpecDisplayName(specName)
    if GetPartyResumeValue("useSpecAbbrev", false) ~= true then
        return specName
    end

    local _, classToken = UnitClass("player")
    local classSpecAbbrev = classToken and PARTY_RESUME_SPEC_ABBREV[classToken]

    if not classSpecAbbrev then
        return specName
    end

    return classSpecAbbrev[specName] or specName
end

local function GetCurrentSpecIDAndName()
    local fallbackName = "캐릭터"

    if not GetSpecialization or not GetSpecializationInfo then
        return nil, fallbackName
    end

    local specIndex = GetSpecialization()

    if specIndex and specIndex > 0 then
        local specID, specName = GetSpecializationInfo(specIndex)
        if specName and specName ~= "" then
            return specID, specName
        end
    end

    return nil, fallbackName
end

local TIER_SLOTS = {
    1,  -- 머리
    3,  -- 어깨
    5,  -- 가슴
    7,  -- 다리
    10, -- 손
}

local function GetEquippedItemID(slot)
    local link = GetInventoryItemLink("player", slot)

    if not link then
        return nil
    end

    if GetItemInfoInstant then
        local itemID = GetItemInfoInstant(link)
        return itemID
    end

    return nil
end

local function GetTierSetCount()
    local specID = select(1, GetCurrentSpecIDAndName())

    if not specID then
        return 0
    end

    local count = 0

    for _, slot in ipairs(TIER_SLOTS) do
        local itemID = GetEquippedItemID(slot)

        if itemID then
            local bonuses

            if C_Item and C_Item.GetSetBonusesForSpecializationByItemID then
                bonuses = C_Item.GetSetBonusesForSpecializationByItemID(specID, itemID)
            elseif GetSetBonusesForSpecializationByItemID then
                bonuses = GetSetBonusesForSpecializationByItemID(specID, itemID)
            end

            if bonuses and #bonuses > 0 then
                count = count + 1

                if count >= 4 then
                    return 4
                end
            end
        end
    end

    return count
end

local EQUIPPED_ITEM_SLOTS = {
    1,  -- 머리
    2,  -- 목
    3,  -- 어깨
    5,  -- 가슴
    6,  -- 허리
    7,  -- 다리
    8,  -- 발
    9,  -- 손목
    10, -- 손
    11, -- 손가락 1
    12, -- 손가락 2
    13, -- 장신구 1
    14, -- 장신구 2
    15, -- 등
    16, -- 주무기
    17, -- 보조장비
}

local EMBELLISHMENT_TOOLTIP_KEYWORD = "장식됨"

local function TooltipDataHasEmbellishment(tooltipData)
    if not tooltipData or type(tooltipData.lines) ~= "table" then
        return false
    end

    for _, line in ipairs(tooltipData.lines) do
        local leftText = line and line.leftText

        if type(leftText) == "string" and leftText:find(EMBELLISHMENT_TOOLTIP_KEYWORD, 1, true) then
            return true
        end
    end

    return false
end

local function IsEquippedItemEmbellished(slot)
    if not GetInventoryItemLink("player", slot) then
        return false
    end

    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local ok, tooltipData = pcall(C_TooltipInfo.GetInventoryItem, "player", slot)

        if ok and TooltipDataHasEmbellishment(tooltipData) then
            return true
        end
    end

    return false
end

local function GetAutomaticEmbellishmentCount()
    local count = 0

    for _, slot in ipairs(EQUIPPED_ITEM_SLOTS) do
        if IsEquippedItemEmbellished(slot) then
            count = count + 1

            if count >= 2 then
                return 2
            end
        end
    end

    return count
end

function M:BuildPartyResumeMessage()
    if IsPartyResumeManual() then
        return TrimText(GetPartyResumeManualMessage())
    end
    local _, specName = GetCurrentSpecIDAndName()
    specName = GetPartyResumeSpecDisplayName(specName)
    local parts = {}

    if IsPartyResumeFieldEnabled("showItemLevel") then
        tinsert(parts, GetCurrentEquippedItemLevelText())
    end

    if IsPartyResumeFieldEnabled("showTierSet") then
        local tierSetCount = GetTierSetCount()

        if tierSetCount > 0 then
            tinsert(parts, format("%d셋", tierSetCount))
        end
    end

    local embellishmentSetting = GetPartyResumeValue("embellishmentCount", "auto")
    local embellishmentCount

    if embellishmentSetting == "auto" then
        embellishmentCount = GetAutomaticEmbellishmentCount()
    else
        embellishmentCount = tonumber(embellishmentSetting) or 0
    end

    if embellishmentCount > 0 then
        if embellishmentCount > 2 then
            embellishmentCount = 2
        end

        tinsert(parts, format("%d장식", embellishmentCount))
    end

    local prefix = table.concat(parts, " / ")

    if IsPartyResumeFieldEnabled("showSpec") then
        if prefix ~= "" then
            return format("%s %s입니다.", prefix, specName)
        end

        return format("%s입니다.", specName)
    end

    return prefix
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
    ns.Event:Register("PLAYER_ENTERING_WORLD", "KeystoneReporterWeeklyEnteringWorld",
        function(_, isInitialLogin, isReloadingUi)
            if isInitialLogin or isReloadingUi then
                M:PrimeWeeklyDungeonInfo()
            else
                M:RequestWeeklyDungeonInfoUpdate()
            end
        end)

    ns.Event:Register("CHALLENGE_MODE_MAPS_UPDATE", "KeystoneReporterWeeklyMapsUpdate", function()
        M:RefreshWeeklyDungeonInfoCache()
    end)

    ns.Event:Register("MYTHIC_PLUS_NEW_WEEKLY_RECORD", "KeystoneReporterWeeklyNewRecord", function()
        M:PrimeWeeklyDungeonInfo()
    end)

    ns.Event:Register("CHALLENGE_MODE_COMPLETED", "KeystoneReporterWeeklyCompleted", function()
        M:PrimeWeeklyDungeonInfo()
    end)
end

function M:UnregisterEvents()
    if ns.Event and ns.Event.UnregisterPrefix then
        ns.Event:UnregisterPrefix("KeystoneReporter")
    end

    self:CancelPendingResponse()
end

M.partyResumeDialogHooked = false
M.partyResumeHelperFrame = nil

function M:GetPartyResumeHelperFrame()
    if self.partyResumeHelperFrame then
        return self.partyResumeHelperFrame
    end

    local frame = CreateFrame("Frame", "HRUIPartyResumeHelperFrame", UIParent,
        BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(430, 82)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
    end

    frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.label:SetPoint("TOPLEFT", 16, -14)
    frame.label:SetText("파티 이력서: Ctrl+C 후 신청 쪽지 칸에 Ctrl+V")

    frame.edit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.edit:SetAutoFocus(false)
    frame.edit:SetSize(320, 24)
    frame.edit:SetPoint("TOPLEFT", frame.label, "BOTTOMLEFT", 0, -8)
    frame.edit:SetFontObject(ChatFontNormal)
    frame.edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        frame:Hide()
    end)
    frame.edit:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    frame.edit:SetScript("OnMouseUp", function(self)
        self:HighlightText()
    end)

    frame.select = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.select:SetSize(58, 24)
    frame.select:SetPoint("LEFT", frame.edit, "RIGHT", 8, 0)
    frame.select:SetText("선택")
    frame.select:SetScript("OnClick", function()
        frame.edit:SetText(M:BuildPartyResumeMessage())
        frame.edit:SetFocus()
        frame.edit:HighlightText()
        print("|cff00ff00HRUI|r Ctrl+C로 복사한 뒤 신청 쪽지 칸에 Ctrl+V 하세요.")
    end)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", -4, -4)

    self.partyResumeHelperFrame = frame

    return frame
end

function M:ShowPartyResumeHelper()
    if not IsPartyResumeEnabled() then
        return
    end
    local frame = self:GetPartyResumeHelperFrame()

    frame.edit:SetText(self:BuildPartyResumeMessage())

    frame:ClearAllPoints()

    if LFGListApplicationDialog and LFGListApplicationDialog:IsShown() then
        frame:SetPoint("BOTTOM", LFGListApplicationDialog, "TOP", 0, 8)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
    end

    frame:Show()
    frame.edit:SetFocus()
    frame.edit:HighlightText()
end

function M:HookPartyResumeDialog()
    if self.partyResumeDialogHooked then
        return
    end

    if not LFGListApplicationDialog then
        return
    end

    LFGListApplicationDialog:HookScript("OnShow", function()
        C_Timer.After(0, function()
            if IsPartyResumeEnabled() then
                M:ShowPartyResumeHelper()
            end
        end)
    end)

    LFGListApplicationDialog:HookScript("OnHide", function()
        local frame = M.partyResumeHelperFrame
        if frame then
            frame:Hide()
        end
    end)

    self.partyResumeDialogHooked = true
end

local partyResumeEventFrame = CreateFrame("Frame")
partyResumeEventFrame:RegisterEvent("PLAYER_LOGIN")
partyResumeEventFrame:RegisterEvent("ADDON_LOADED")
partyResumeEventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "PLAYER_LOGIN" or addonName == "Blizzard_GroupFinder" then
        M:HookPartyResumeDialog()
    end
end)
function M:Initialize()
    self:UnregisterEvents()

    if IsEnabled() then
        self:RegisterEvents()
    end
end

M:Initialize()
