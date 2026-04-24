local _, ns = ...

local SHORT_ABBREV_CONFIG
local HEALTH_ABBREV_CONFIG
local HEALTH_INTEGER_ABBREV_CONFIG

local function CreateConfig(data)
    if CreateAbbreviateConfig then
        return { config = CreateAbbreviateConfig(data) }
    end

    return data
end

local function CreateShortConfig()
    return CreateConfig({
        {
            breakpoint = 10000,
            abbreviation = "만",
            significandDivisor = 10000,
            fractionDivisor = 10,
            abbreviationIsGlobal = false,
        },
        {
            breakpoint = 100000000,
            abbreviation = "억",
            significandDivisor = 100000000,
            fractionDivisor = 10,
            abbreviationIsGlobal = false,
        },
        {
            breakpoint = 1000000000000,
            abbreviation = "조",
            significandDivisor = 1000000000000,
            fractionDivisor = 10,
            abbreviationIsGlobal = false,
        },
    })
end

local function CreateHealthConfig()
    return CreateConfig({
        {
            breakpoint = 1000000000000,
            abbreviation = "조",
            significandDivisor = 100000000000,
            fractionDivisor = 10,
            abbreviationIsGlobal = false,
        },
        {
            breakpoint = 100000000,
            abbreviation = "억",
            significandDivisor = 10000000,
            fractionDivisor = 10,
            abbreviationIsGlobal = false,
        },
        {
            breakpoint = 10000,
            abbreviation = "만",
            significandDivisor = 1000,
            fractionDivisor = 10,
            abbreviationIsGlobal = false,
        },
    })
end

local function CreateHealthIntegerConfig()
    return CreateConfig({
        {
            breakpoint = 1000000000000,
            abbreviation = "조",
            significandDivisor = 1000000000000,
            fractionDivisor = 1,
            abbreviationIsGlobal = false,
        },
        {
            breakpoint = 100000000,
            abbreviation = "억",
            significandDivisor = 100000000,
            fractionDivisor = 1,
            abbreviationIsGlobal = false,
        },
        {
            breakpoint = 10000,
            abbreviation = "만",
            significandDivisor = 10000,
            fractionDivisor = 1,
            abbreviationIsGlobal = false,
        },
    })
end
function ns:BuildAbbrevConfig()
    if SHORT_ABBREV_CONFIG then
        return
    end

    SHORT_ABBREV_CONFIG = CreateShortConfig()
end

function ns:BuildHealthAbbrevConfig()
    if HEALTH_ABBREV_CONFIG then
        return
    end

    HEALTH_ABBREV_CONFIG = CreateHealthConfig()
end

function ns:BuildHealthIntegerAbbrevConfig()
    if HEALTH_INTEGER_ABBREV_CONFIG then
        return
    end

    HEALTH_INTEGER_ABBREV_CONFIG = CreateHealthIntegerConfig()
end
function ns:GetHealthDecimalMode()
    local ufdb = ns.db and ns.db.profile and ns.db.profile.unitframes
    local appearance = ufdb and ufdb.appearance
    local mode = appearance and appearance.healthDecimalMode or "one"

    if mode ~= "auto" and mode ~= "one" and mode ~= "zero" then
        mode = "one"
    end

    return mode
end

local function FormatWithConfigInner(value, config)
    if value == nil then
        return ""
    end

    if type(value) == "string" then
        return value
    end

    if config and AbbreviateNumbers then
        return AbbreviateNumbers(value, config)
    end

    if BreakUpLargeNumbers then
        return BreakUpLargeNumbers(value)
    end

    return tostring(value)
end

local function FormatWithConfig(value, config)
    local ok, text = pcall(FormatWithConfigInner, value, config)
    if ok then
        return text
    end

    return ""
end

local function FormatHealthDirectInner(value, decimals)
    local num = tonumber(value)
    if not num then
        return nil
    end

    local absValue = math.abs(num)
    local divisor, suffix

    if absValue >= 1000000000000 then
        divisor, suffix = 1000000000000, "조"
    elseif absValue >= 100000000 then
        divisor, suffix = 100000000, "억"
    elseif absValue >= 10000 then
        divisor, suffix = 10000, "만"
    end

    if divisor then
        local scaled = num / divisor

        if decimals == 0 then
            if scaled < 0 then
                scaled = math.ceil(scaled)
            else
                scaled = math.floor(scaled)
            end

            return string.format("%d%s", scaled, suffix)
        end

        return string.format("%." .. decimals .. "f%s", scaled, suffix)
    end

    if BreakUpLargeNumbers then
        return BreakUpLargeNumbers(num)
    end

    return string.format("%.0f", num)
end

local function FormatHealthDirect(value, decimals)
    local ok, text = pcall(FormatHealthDirectInner, value, decimals)
    if ok then
        return text
    end
end

function ns:FormatShortValue(value)
    self:BuildAbbrevConfig()
    return FormatWithConfig(value, SHORT_ABBREV_CONFIG)
end

function ns:FormatHealth(value)
    local mode = self:GetHealthDecimalMode()

    if mode == "one" then
        local text = FormatHealthDirect(value, 1)
        if text ~= nil then
            return text
        end

        self:BuildHealthAbbrevConfig()
        return FormatWithConfig(value, HEALTH_ABBREV_CONFIG)
    end

    local text = FormatHealthDirect(value, 0)
    if text ~= nil then
        return text
    end

    self:BuildHealthIntegerAbbrevConfig()
    return FormatWithConfig(value, HEALTH_INTEGER_ABBREV_CONFIG)
end
