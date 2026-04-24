local _, ns = ...

local SHORT_ABBREV_CONFIG

function ns:BuildAbbrevConfig()
    if SHORT_ABBREV_CONFIG then
        return
    end

    if not CreateAbbreviateConfig then
        return
    end

    SHORT_ABBREV_CONFIG = CreateAbbreviateConfig({
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

function ns:FormatShortValue(value)
    if value == nil then
        return ""
    end

    if type(value) == "string" then
        return value
    end

    self:BuildAbbrevConfig()

    if SHORT_ABBREV_CONFIG and AbbreviateNumbers then
        local ok, text = pcall(AbbreviateNumbers, value, SHORT_ABBREV_CONFIG)
        if ok and text then
            return tostring(text)
        end
    end

    if BreakUpLargeNumbers then
        local ok2, text2 = pcall(BreakUpLargeNumbers, value)
        if ok2 and text2 then
            return tostring(text2)
        end
    end

    return tostring(value)
end

function ns:FormatHealth(value)
    return self:FormatShortValue(value)
end
