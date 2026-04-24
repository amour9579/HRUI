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

local function FormatInteger(n)
    n = math.floor(n)

    if BreakUpLargeNumbers then
        local ok, text = pcall(BreakUpLargeNumbers, n)
        if ok and text ~= nil then
            return text
        end
    end

    return string.format("%d", n)
end

local function TryFormatHealthOneDecimal(value)
    local ok, text = pcall(function()
        local n = tonumber(value)
        if not n then
            return nil
        end

        if n >= 1000000000000 then
            return string.format("%.1f조", math.floor(n / 100000000000) / 10)
        end

        if n >= 100000000 then
            return string.format("%.1f억", math.floor(n / 10000000) / 10)
        end

        if n >= 10000 then
            return string.format("%.1f만", math.floor(n / 1000) / 10)
        end

        return FormatInteger(n)
    end)

    if ok and text ~= nil then
        return text
    end

    return nil
end
local function FormatShortValueRaw(self, value)
    if value == nil then
        return ""
    end

    self:BuildAbbrevConfig()

    if SHORT_ABBREV_CONFIG and AbbreviateNumbers then
        local ok, text = pcall(AbbreviateNumbers, value, SHORT_ABBREV_CONFIG)
        if ok and text ~= nil then
            -- 중요:
            -- 여기서 tostring(text), string.gsub(text), text:gsub(...) 절대 금지
            -- secret string이면 그대로 반환해야 함
            return text
        end
    end

    if BreakUpLargeNumbers then
        local ok2, text2 = pcall(BreakUpLargeNumbers, value)
        if ok2 and text2 ~= nil then
            return text2
        end
    end

    return ""
end

function ns:FormatShortValue(value)
    -- 파워/기타 수치는 Blizzard 축약 결과를 그대로 사용
    -- secret string 후처리 금지
    return FormatShortValueRaw(self, value)
end

function ns:FormatHealth(value)
    -- 체력만 직접 1자리 소수 포맷 시도
    -- 비교/연산은 pcall 안에서만 수행하고, 실패하면 빈 문자열 반환
    local text = TryFormatHealthOneDecimal(value)
    if text ~= nil then
        return text
    end

    return ""
end
