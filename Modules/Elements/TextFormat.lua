local _, ns = ...

local SHORT_ABBREV_CONFIG
local HEALTH_ABBREV_CONFIG

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

local function FormatWithConfig(value, config)
    local valueType = type(value)
    if valueType == "nil" then
        return ""
    elseif valueType == "string" then
        return value
    end

    if config and AbbreviateNumbers then
        local ok, text = pcall(AbbreviateNumbers, value, config)
        if ok then
            return text
        end
    end

    if BreakUpLargeNumbers then
        local ok, text = pcall(BreakUpLargeNumbers, value)
        if ok then
            return text
        end
    end

    local ok, text = pcall(tostring, value)
    if ok then
        return text
    end

    return ""
end

function ns:FormatShortValue(value)
    self:BuildAbbrevConfig()
    return FormatWithConfig(value, SHORT_ABBREV_CONFIG)
end

function ns:FormatHealth(value)
    self:BuildHealthAbbrevConfig()
    return FormatWithConfig(value, HEALTH_ABBREV_CONFIG)
end
