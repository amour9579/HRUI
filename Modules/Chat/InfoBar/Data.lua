local _, ns = ...

local ChatInfoBar = ns.ChatInfoBar or {}
ns.ChatInfoBar = ChatInfoBar

local floor = math.floor
local format = string.format
local tinsert = table.insert
local wipeTable = table.wipe or wipe

local CLASS_NAME_TO_FILE = {
    ["전사"] = "WARRIOR",
    ["마법사"] = "MAGE",
    ["도적"] = "ROGUE",
    ["사제"] = "PRIEST",
    ["드루이드"] = "DRUID",
    ["성기사"] = "PALADIN",
    ["주술사"] = "SHAMAN",
    ["흑마법사"] = "WARLOCK",
    ["사냥꾼"] = "HUNTER",
    ["죽음의 기사"] = "DEATHKNIGHT",
    ["수도사"] = "MONK",
    ["악마사냥꾼"] = "DEMONHUNTER",
    ["기원사"] = "EVOKER",
}

local FRIENDS_ENTRIES = {}
local FRIENDS_ENTRY_POOL = {}

local function ClearArray(tbl)
    if wipeTable then
        wipeTable(tbl)
        return
    end

    for i = #tbl, 1, -1 do
        tbl[i] = nil
    end
end

function ChatInfoBar:ShortName(name)
    if not name or name == "" then
        return ""
    end
    return name:match("([^-]+)") or name
end

function ChatInfoBar:GetClassColor(classFile)
    if RAID_CLASS_COLORS and classFile and RAID_CLASS_COLORS[classFile] then
        return RAID_CLASS_COLORS[classFile]
    end
    return NORMAL_FONT_COLOR
end

function ChatInfoBar:NormalizeClassFile(classValue)
    if not classValue or classValue == "" then
        return nil
    end

    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classValue] then
        return classValue
    end

    return CLASS_NAME_TO_FILE[classValue]
end

function ChatInfoBar:ColorizeName(name, classFile)
    if not name or name == "" then
        return ""
    end

    local c = self:GetClassColor(classFile)
    return format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, name)
end

function ChatInfoBar:ColorDurability(percent)
    if not percent then
        return "|cffffffff0%|r"
    elseif percent >= 80 then
        return format("|cff00ff00%d%%|r", percent)
    elseif percent >= 50 then
        return format("|cffffff00%d%%|r", percent)
    elseif percent >= 25 then
        return format("|cffff9900%d%%|r", percent)
    else
        return format("|cffff0000%d%%|r", percent)
    end
end

function ChatInfoBar:GetCurrentSpecIndex()
    return GetSpecialization and GetSpecialization() or nil
end

function ChatInfoBar:GetCurrentSpecInfo()
    local index = self:GetCurrentSpecIndex()
    if not index or not GetSpecializationInfo then
        return nil
    end

    local specID, name, _, icon = GetSpecializationInfo(index)
    return {
        index = index,
        specID = specID,
        name = name,
        icon = icon,
    }
end

function ChatInfoBar:GetLootSpecName()
    local current = self:GetCurrentSpecInfo()
    local lootSpecID = GetLootSpecialization and GetLootSpecialization() or 0

    if not lootSpecID or lootSpecID == 0 then
        return current and current.name or "현재"
    end

    if GetSpecializationInfoByID then
        local _, name = GetSpecializationInfoByID(lootSpecID)
        return name or "없음"
    end

    return "없음"
end

function ChatInfoBar:SetPlayerSpec(index)
    if not index then
        return
    end

    if C_SpecializationInfo and C_SpecializationInfo.SetSpecialization then
        C_SpecializationInfo.SetSpecialization(index)
    elseif SetSpecialization then
        SetSpecialization(index)
    end
end

function ChatInfoBar:SetPlayerLootSpec(specID)
    if specID == nil then
        return
    end

    if C_SpecializationInfo and C_SpecializationInfo.SetLootSpecialization then
        C_SpecializationInfo.SetLootSpecialization(specID)
    elseif SetLootSpecialization then
        SetLootSpecialization(specID)
    end
end

function ChatInfoBar:InvitePlayer(name)
    if not name or name == "" then
        return
    end

    if C_PartyInfo and C_PartyInfo.InviteUnit then
        C_PartyInfo.InviteUnit(name)
    elseif InviteUnit then
        InviteUnit(name)
    end
end

function ChatInfoBar:GetGuildOnlineCount()
    if not IsInGuild or not IsInGuild() then
        return 0
    end
    local _, onlineCount = GetNumGuildMembers()
    return onlineCount or 0
end

function ChatInfoBar:GetFriendsOnlineCount()
    local count = 0
    if BNGetNumFriends then
        local _, bnOnline = BNGetNumFriends()
        count = count + (bnOnline or 0)
    end
    if C_FriendList and C_FriendList.GetNumOnlineFriends then
        count = count + C_FriendList.GetNumOnlineFriends()
    end
    return count
end

function ChatInfoBar:GetAverageDurability()
    local current = 0
    local maxTotal = 0
    local found = false

    for slot = 1, 17 do
        if slot ~= 4 then
            local cur, max = GetInventoryItemDurability(slot)
            if cur and max and max > 0 then
                current = current + cur
                maxTotal = maxTotal + max
                found = true
            end
        end
    end

    if not found or maxTotal == 0 then
        return 100
    end

    return floor((current / maxTotal) * 100 + 0.5)
end

function ChatInfoBar:BuildGuildEntries()
    local entries = {}

    if not IsInGuild or not IsInGuild() then
        return entries
    end

    local total = GetNumGuildMembers and GetNumGuildMembers() or 0
    for i = 1, total do
        local name, _, _, level, _, zone, _, _, isOnline, _, classFile = GetGuildRosterInfo(i)
        if isOnline then
            local shortName = self:ShortName(name)
            local zoneText = zone and zone ~= "" and zone or "알 수 없음"

            tinsert(entries, {
                text = format("|cff808080Lv.%d|r %s |cff808080- %s|r", level or 0,
                self:ColorizeName(shortName, classFile), zoneText),
                targetName = shortName,
            })
        end
    end

    table.sort(entries, function(a, b)
        return (a.targetName or "") < (b.targetName or "")
    end)

    return entries
end

function ChatInfoBar:BuildFriendsEntries()
    local entries = FRIENDS_ENTRIES
    ClearArray(entries)

    local entryCount = 0
    local function PushEntry(text, targetName)
        entryCount = entryCount + 1

        local entry = FRIENDS_ENTRY_POOL[entryCount]
        if not entry then
            entry = {}
            FRIENDS_ENTRY_POOL[entryCount] = entry
        end

        entry.text = text
        entry.targetName = targetName
        entries[entryCount] = entry
    end

    local numFriends = GetNumFriends and GetNumFriends() or 0
    for i = 1, numFriends do
        local name, level, class, area, connected = GetFriendInfo(i)
        if connected then
            local classFile = self:NormalizeClassFile(class)
            local left = self:ColorizeName(name, classFile)
            if level and level > 0 then
                left = format("|cff808080Lv.%d|r %s", level, left)
            end

            local right = area and area ~= "" and area or ""

            PushEntry(right ~= "" and format("%s |cff808080- %s|r", left, right) or left, name)
        end
    end

    local bnCount = BNGetNumFriends and BNGetNumFriends() or 0
    if C_BattleNet and C_BattleNet.GetFriendAccountInfo then
        for i = 1, bnCount do
            local info = C_BattleNet.GetFriendAccountInfo(i)
            if info and info.gameAccountInfo and info.gameAccountInfo.isOnline then
                local g = info.gameAccountInfo
                local clientTag = (g.clientProgram == BNET_CLIENT_WOW) and "|cff00ff00[와우]|r" or
                    ("|cffcccccc[" .. (g.clientProgram or "기타") .. "]|r")
                local charName = self:ShortName(g.characterName)

                local classFile = g.classFileName or g.classFilename
                if not classFile and g.className then
                    classFile = CLASS_NAME_TO_FILE[g.className]
                end

                local coloredChar = charName ~= "" and self:ColorizeName(charName, classFile) or ""
                local accountName = info.accountName or info.battleTag or "Battle.net"
                local statusText = coloredChar ~= "" and coloredChar or (g.richPresence or "")

                if g.clientProgram == BNET_CLIENT_WOW then
                    local levelText = ""
                    if g.characterLevel and g.characterLevel > 0 then
                        levelText = format("|cff808080Lv.%d|r ", g.characterLevel)
                    end

                    local areaText = g.areaName or g.zoneName or g.richPresence or ""

                    if coloredChar ~= "" then
                        statusText = levelText .. coloredChar
                    elseif levelText ~= "" then
                        statusText = levelText .. (g.richPresence or "")
                    end

                    if areaText ~= "" then
                        statusText = format("%s |cff808080- %s|r", statusText, areaText)
                    end
                end

                PushEntry(
                    format("%s %s|cff808080  %s|r", clientTag, accountName, statusText),
                    (g.clientProgram == BNET_CLIENT_WOW and charName ~= "") and charName or nil
                )
            end
        end
    end

    return entries
end

function ChatInfoBar:BuildSpecEntries()
    local current = self:GetCurrentSpecInfo()
    local currentName = (current and current.name) or "없음"
    local lootName = self:GetLootSpecName()

    return {
        {
            text = "|cffffffff현재 전문화:|r " .. currentName,
            targetName = nil,
        },
        {
            text = "|cffffffff전리품 전문화:|r " .. (lootName or "없음"),
            targetName = nil,
        },
    }
end

function ChatInfoBar:BuildSpecSelectEntries()
    local entries = {}
    local currentSpec = GetSpecialization and GetSpecialization() or nil
    local numSpecs = GetNumSpecializations and GetNumSpecializations() or 0

    for i = 1, numSpecs do
        local specID, name, _, icon = GetSpecializationInfo(i)
        if specID and name then
            tinsert(entries, {
                text = name,
                icon = icon,
                selected = (currentSpec == i),
                onClick = function()
                    self:SetPlayerSpec(i)
                    ChatInfoBar:Update()
                end,
            })
        end
    end

    return entries
end

function ChatInfoBar:BuildLootSpecSelectEntries()
    local entries = {}
    local currentLootSpec = GetLootSpecialization and GetLootSpecialization() or 0

    tinsert(entries, {
        text = "현재 전문화",
        selected = (currentLootSpec == 0),
        onClick = function()
            self:SetPlayerLootSpec(0)
            ChatInfoBar:Update()
        end,
    })

    local numSpecs = GetNumSpecializations and GetNumSpecializations() or 0
    for i = 1, numSpecs do
        local specID, name, _, icon = GetSpecializationInfo(i)
        if specID and name then
            tinsert(entries, {
                text = name,
                icon = icon,
                selected = (currentLootSpec == specID),
                onClick = function()
                    self:SetPlayerLootSpec(specID)
                    ChatInfoBar:Update()
                end,
            })
        end
    end

    return entries
end

function ChatInfoBar:BuildDurabilityEntries()
    local entries = {}
    local slots = {
        { 1, "머리" },
        { 2, "목" },
        { 3, "어깨" },
        { 5, "가슴" },
        { 6, "허리" },
        { 7, "다리" },
        { 8, "발" },
        { 9, "손목" },
        { 10, "손" },
        { 16, "주장비" },
        { 17, "보조장비" },
    }

    for _, info in ipairs(slots) do
        local cur, max = GetInventoryItemDurability(info[1])
        if cur and max and max > 0 then
            local percent = floor((cur / max) * 100 + 0.5)
            tinsert(entries, {
                text = format("|cffffffff%s:|r %s", info[2], self:ColorDurability(percent)),
                targetName = nil,
            })
        end
    end

    if #entries == 0 then
        tinsert(entries, {
            text = "|cffcccccc내구도 정보가 없습니다.|r",
            targetName = nil,
        })
    end

    return entries
end

local floor = math.floor
local format = string.format
local tinsert = table.insert

ChatInfoBar.performanceCache = ChatInfoBar.performanceCache or {
    fps = 0,
    home = 0,
    world = 0,
    lastUpdate = 0,
}

function ChatInfoBar:GetPerformanceInfo()
    local now = GetTime()

    if (now - (self.performanceCache.lastUpdate or 0)) >= 1 then
        local fps = floor(GetFramerate() or 0)
        local _, _, homeLatency, worldLatency = GetNetStats()

        self.performanceCache.fps = fps
        self.performanceCache.home = homeLatency or 0
        self.performanceCache.world = worldLatency or 0
        self.performanceCache.lastUpdate = now
    end

    return self.performanceCache.fps, self.performanceCache.home, self.performanceCache.world
end

function ChatInfoBar:ColorLatency(ms)
    if ms < 150 then
        return format("|cff00ff00%dms|r", ms)
    elseif ms < 300 then
        return format("|cffffff00%dms|r", ms)
    else
        return format("|cffff0000%dms|r", ms)
    end
end

function ChatInfoBar:ColorFPS(fps)
    if fps >= 50 then
        return format("|cff00ff00%d|r", fps)
    elseif fps >= 30 then
        return format("|cffffff00%d|r", fps)
    else
        return format("|cffff0000%d|r", fps)
    end
end

function ChatInfoBar:BuildPerformanceEntries()
    local entries = {}
    local fps, homeLatency, worldLatency = self:GetPerformanceInfo()

    tinsert(entries, {
        text = format("|cffffffff프레임:|r %s fps", self:ColorFPS(fps)),
        targetName = nil,
    })

    tinsert(entries, {
        text = format("|cffffffff지연 시간 (로컬):|r %s", self:ColorLatency(homeLatency)),
        targetName = nil,
    })

    tinsert(entries, {
        text = format("|cffffffff지연 시간 (서버):|r %s", self:ColorLatency(worldLatency)),
        targetName = nil,
    })

    return entries
end

function ChatInfoBar:BuildMythicPlusEntries()
    return {
        { text = "좌클릭: 쐐기돌 정보 전송" },
        { text = "우클릭: 주차 정보 전송" },
    }
end
