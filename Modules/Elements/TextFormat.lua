local _, ns = ...

local SHORT_ABBREV_OPTIONS
local HEALTH_AUTO_ABBREV_OPTIONS
local HEALTH_ONE_DECIMAL_ABBREV_OPTIONS
local HEALTH_ZERO_DECIMAL_ABBREV_OPTIONS

local function CreateAbbrevOptions(data)
    local options = {
        breakpointData = data,
    }

    if CreateAbbreviateConfig then
        options.config = CreateAbbreviateConfig(data)
        options.breakpointData = nil
    end

    return options
end

local function CreateAutoAbbrevOptions()
    -- 기존 축약 방식: 단위값의 10 미만 구간만 소수 첫째 자리.
    -- 65,000 -> 6.5만 / 100,000 -> 10만 / 416,000 -> 41만
    return CreateAbbrevOptions({
        {
            breakpoint = 10000000000000,
            abbreviation = "조",
            significandDivisor = 1000000000000,
            fractionDivisor = 1,
            abbreviationIsGlobal = false,
        },
        {
            breakpoint = 1000000000000,
            abbreviation = "조",
            significandDivisor = 100000000000,
            fractionDivisor = 10,
            abbreviationIsGlobal = false,
        },
        {
            breakpoint = 1000000000,
            abbreviation = "억",
            significandDivisor = 100000000,
            fractionDivisor = 1,
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
            breakpoint = 100000,
            abbreviation = "만",
            significandDivisor = 10000,
            fractionDivisor = 1,
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

local function CreateOneDecimalAbbrevOptions()
    -- 항상 소수 첫째 자리.
    -- 65,000 -> 6.5만 / 100,000 -> 10.0만 / 416,000 -> 41.6만
    return CreateAbbrevOptions({
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

local function CreateZeroDecimalAbbrevOptions()
    -- 소수점 표시 안 함.
    -- 65,000 -> 6만 / 100,000 -> 10만 / 416,000 -> 41만
    return CreateAbbrevOptions({
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
    if SHORT_ABBREV_OPTIONS then
        return
    end

    SHORT_ABBREV_OPTIONS = CreateAutoAbbrevOptions()
end

function ns:BuildHealthAbbrevConfigs()
    if HEALTH_AUTO_ABBREV_OPTIONS then
        return
    end

    HEALTH_AUTO_ABBREV_OPTIONS = CreateAutoAbbrevOptions()
    HEALTH_ONE_DECIMAL_ABBREV_OPTIONS = CreateOneDecimalAbbrevOptions()
    HEALTH_ZERO_DECIMAL_ABBREV_OPTIONS = CreateZeroDecimalAbbrevOptions()
end

function ns:GetHealthDecimalMode()
    local ufdb = ns.db and ns.db.profile and ns.db.profile.unitframes
    local appearance = ufdb and ufdb.appearance
    local mode = appearance and appearance.healthDecimalMode or "auto"

    if mode ~= "auto" and mode ~= "one" and mode ~= "zero" then
        mode = "auto"
    end

    return mode
end

local function FormatWithOptionsInner(value, options)
    if value == nil then
        return ""
    end

    if type(value) == "string" then
        return value
    end

    if options and AbbreviateNumbers then
        return AbbreviateNumbers(value, options)
    end

    if BreakUpLargeNumbers then
        return BreakUpLargeNumbers(value)
    end

    return tostring(value)
end

local function FormatWithOptions(value, options)
    local ok, text = pcall(FormatWithOptionsInner, value, options)
    if ok then
        return text
    end

    return ""
end

function ns:FormatShortValue(value)
    self:BuildAbbrevConfig()
    return FormatWithOptions(value, SHORT_ABBREV_OPTIONS)
end

function ns:FormatHealth(value)
    self:BuildHealthAbbrevConfigs()

    local mode = self:GetHealthDecimalMode()
    if mode == "one" then
        return FormatWithOptions(value, HEALTH_ONE_DECIMAL_ABBREV_OPTIONS)
    elseif mode == "zero" then
        return FormatWithOptions(value, HEALTH_ZERO_DECIMAL_ABBREV_OPTIONS)
    end

    return FormatWithOptions(value, HEALTH_AUTO_ABBREV_OPTIONS)
end
