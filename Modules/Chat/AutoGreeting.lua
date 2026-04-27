local _, ns = ...

local AutoGreeting = {}
ns.AutoGreeting = AutoGreeting

AutoGreeting.eventsRegistered = false
AutoGreeting.wasInGreetingGroup = false
AutoGreeting.pendingJoinTimer = nil
AutoGreeting.pendingCompletionTimer = nil
AutoGreeting.pendingSummonTimer = nil
AutoGreeting.pendingLeaderJoinTimer = nil
AutoGreeting.partyMemberCount = 0

local EVENT_PREFIX = "AutoGreeting_"
local DEFAULT_JOIN_MESSAGE = "안녕 하세요"
local DEFAULT_CHALLENGE_COMPLETED_MESSAGE = "수고 하셨습니다"
local DEFAULT_SUMMON_MESSAGE = "감사 합니다"
local DEFAULT_LEADER_JOIN_MESSAGE = "어서 오세요"
local DEFAULT_GREETING_DELAY = 2

local function GetDB()
    ns.db.profile.chat = ns.db.profile.chat or {}
    ns.db.profile.chat.autoGreeting = ns.db.profile.chat.autoGreeting or {
        enabled = true,
        joinEnabled = true,
        joinMessage = DEFAULT_JOIN_MESSAGE,
        challengeCompletedEnabled = true,
        challengeCompletedMessage = DEFAULT_CHALLENGE_COMPLETED_MESSAGE,
        summonEnabled = true,
        summonMessage = DEFAULT_SUMMON_MESSAGE,
        leaderJoinEnabled = true,
        leaderJoinMessage = DEFAULT_LEADER_JOIN_MESSAGE,
    }

    local db = ns.db.profile.chat.autoGreeting

    if db.enabled == nil then
        db.enabled = true
    end

    if db.joinEnabled == nil then
        db.joinEnabled = true
    end

    if db.challengeCompletedEnabled == nil then
        db.challengeCompletedEnabled = true
    end

    if db.summonEnabled == nil then
        db.summonEnabled = true
    end

    if db.leaderJoinEnabled == nil then
        db.leaderJoinEnabled = true
    end

    if db.joinMessage == nil or db.joinMessage == "" then
        db.joinMessage = DEFAULT_JOIN_MESSAGE
    end

    if db.challengeCompletedMessage == nil or db.challengeCompletedMessage == "" then
        db.challengeCompletedMessage = DEFAULT_CHALLENGE_COMPLETED_MESSAGE
    end

    if db.summonMessage == nil or db.summonMessage == "" then
        db.summonMessage = DEFAULT_SUMMON_MESSAGE
    end

    if db.leaderJoinMessage == nil or db.leaderJoinMessage == "" then
        db.leaderJoinMessage = DEFAULT_LEADER_JOIN_MESSAGE
    end

    if db.delay == nil then
        db.delay = DEFAULT_GREETING_DELAY
    end

    db.delay = tonumber(db.delay) or DEFAULT_GREETING_DELAY
    return db
end

local function GetGreetingDelay()
    local delay = tonumber(GetDB().delay) or DEFAULT_GREETING_DELAY

    if delay < 0 then
        return 0
    end

    return delay
end

local function TrimMessage(message)
    if type(message) ~= "string" then
        return ""
    end

    return (message:gsub("^%s+", ""):gsub("%s+$", ""))
end

function AutoGreeting:GetGroupChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    end

    if IsInGroup() and not IsInRaid() then
        return "PARTY"
    end

    return nil
end

function AutoGreeting:GetSummonChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    end

    if IsInRaid() then
        return "RAID"
    end

    if IsInGroup() then
        return "PARTY"
    end

    return nil
end

function AutoGreeting:IsInGreetingGroup()
    return self:GetGroupChannel() ~= nil
end

function AutoGreeting:IsPartyLeader()
    return IsInGroup() and not IsInRaid() and UnitIsGroupLeader("player")
end

function AutoGreeting:GetPartyMemberCount()
    if IsInGroup() and not IsInRaid() then
        return GetNumGroupMembers()
    end

    return 0
end

function AutoGreeting:CancelJoinTimer()
    if self.pendingJoinTimer then
        self.pendingJoinTimer:Cancel()
        self.pendingJoinTimer = nil
    end
end

function AutoGreeting:CancelCompletionTimer()
    if self.pendingCompletionTimer then
        self.pendingCompletionTimer:Cancel()
        self.pendingCompletionTimer = nil
    end
end

function AutoGreeting:CancelSummonTimer()
    if self.pendingSummonTimer then
        self.pendingSummonTimer:Cancel()
        self.pendingSummonTimer = nil
    end
end

function AutoGreeting:CancelLeaderJoinTimer()
    if self.pendingLeaderJoinTimer then
        self.pendingLeaderJoinTimer:Cancel()
        self.pendingLeaderJoinTimer = nil
    end
end

function AutoGreeting:SendMessage(channel, message)
    local trimmedMessage = TrimMessage(message)
    if not channel or trimmedMessage == "" then
        return
    end

    SendChatMessage(trimmedMessage, channel)
end

function AutoGreeting:ScheduleJoinGreeting()
    local db = GetDB()
    if not db.enabled or not db.joinEnabled then
        return
    end

    self:CancelJoinTimer()

    self.pendingJoinTimer = C_Timer.NewTimer(GetGreetingDelay(), function()
        self.pendingJoinTimer = nil

        local channel = self:GetGroupChannel()
        if not channel then
            return
        end

        self:SendMessage(channel, GetDB().joinMessage)
    end)
end

function AutoGreeting:ScheduleChallengeCompletedGreeting()
    local db = GetDB()
    if not db.enabled or not db.challengeCompletedEnabled then
        return
    end

    self:CancelCompletionTimer()

    self.pendingCompletionTimer = C_Timer.NewTimer(GetGreetingDelay(), function()
        self.pendingCompletionTimer = nil

        local channel = self:GetGroupChannel()
        if not channel then
            return
        end

        self:SendMessage(channel, GetDB().challengeCompletedMessage)
    end)
end

function AutoGreeting:ScheduleSummonGreeting()
    local db = GetDB()
    if not db.enabled or not db.summonEnabled then
        return
    end

    self:CancelSummonTimer()

    self.pendingSummonTimer = C_Timer.NewTimer(GetGreetingDelay(), function()
        self.pendingSummonTimer = nil

        local channel = self:GetSummonChannel()
        if not channel then
            return
        end

    self:SendMessage(channel, GetDB().summonMessage)
    end)
end

function AutoGreeting:ScheduleLeaderJoinGreeting()
    local db = GetDB()
    if not db.enabled or not db.leaderJoinEnabled then
        return
    end

    self.pendingLeaderJoinTimer = C_Timer.NewTimer(GetGreetingDelay(), function()
        self.pendingLeaderJoinTimer = nil
        local timerDB = GetDB()

        if not timerDB.enabled or not timerDB.leaderJoinEnabled or not self:IsPartyLeader() then
            return
        end

        self:SendMessage("PARTY", timerDB.leaderJoinMessage)
    end)
end

function AutoGreeting:OnGroupRosterUpdate()
    local isInGreetingGroup = self:IsInGreetingGroup()
    local currentPartyMemberCount = self:GetPartyMemberCount()
    local addedPartyMemberCount = currentPartyMemberCount - self.partyMemberCount

    if isInGreetingGroup and not self.wasInGreetingGroup then
        self:ScheduleJoinGreeting()
    elseif isInGreetingGroup and self.wasInGreetingGroup and addedPartyMemberCount > 0 and self:IsPartyLeader() then
        for _ = 1, addedPartyMemberCount do
            self:ScheduleLeaderJoinGreeting()
        end
    elseif not isInGreetingGroup then
        self:CancelJoinTimer()
        self:CancelLeaderJoinTimer()
    end

    self.wasInGreetingGroup = isInGreetingGroup
    self.partyMemberCount = currentPartyMemberCount
end

function AutoGreeting:OnChallengeModeCompleted()
    self:ScheduleChallengeCompletedGreeting()
end

function AutoGreeting:OnConfirmSummon()
    self:ScheduleSummonGreeting()
end

function AutoGreeting:RegisterEvents()
    if self.eventsRegistered or not ns.Event then
        return
    end

    ns.Event:Register("GROUP_ROSTER_UPDATE", EVENT_PREFIX .. "GroupRosterUpdate", function()
        AutoGreeting:OnGroupRosterUpdate()
    end)

    ns.Event:Register("CHALLENGE_MODE_COMPLETED", EVENT_PREFIX .. "ChallengeModeCompleted", function()
        AutoGreeting:OnChallengeModeCompleted()
    end)

    ns.Event:Register("CONFIRM_SUMMON", EVENT_PREFIX .. "ConfirmSummon", function()
        AutoGreeting:OnConfirmSummon()
    end)

    self.eventsRegistered = true
end

function AutoGreeting:UnregisterEvents()
    if ns.Event and ns.Event.UnregisterPrefix then
        ns.Event:UnregisterPrefix(EVENT_PREFIX)
    end

    self.eventsRegistered = false
    self:CancelJoinTimer()
    self:CancelCompletionTimer()
    self:CancelSummonTimer()
    self:CancelLeaderJoinTimer()
end

function AutoGreeting:ApplySettings()
    local db = GetDB()

    self:UnregisterEvents()
    self.wasInGreetingGroup = self:IsInGreetingGroup()
    self.partyMemberCount = self:GetPartyMemberCount()

    if db.enabled then
        self:RegisterEvents()
    end
end

function AutoGreeting:Initialize()
    self:ApplySettings()
end

function AutoGreeting:Refresh()
    self:ApplySettings()
end
