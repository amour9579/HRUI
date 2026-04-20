local _, ns = ...

local function GetKeystoneDB()
    ns.db.profile.mythicPlusReporter = ns.db.profile.mythicPlusReporter or {}

    if ns.db.profile.mythicPlusReporter.enabled == nil then
        ns.db.profile.mythicPlusReporter.enabled = true
    end

    return ns.db.profile.mythicPlusReporter
end

function ns:CreateKeystoneReporter()
    return {
        type = "group",
        name = "쐐기",
        order = 6,
        args = {
            mythicPlusReporter = {
                type = "toggle",
                name = "쐐기 채팅 자동 보고 사용",
                desc = "길드/파티 채팅에서 !돌, !주차, !keys, !weekly 입력 시 자동으로 응답합니다.",
                order = 1,
                width = "full",
                get = function()
                    return GetKeystoneDB().enabled
                end,
                set = function(_, value)
                    GetKeystoneDB().enabled = value

                    if ns.mplus and ns.mplus.Initialize then
                        ns.mplus:Initialize()
                    end
                end,
            },
            keystone_notice = {
                type = "description",
                name = "|cffffff00※ 채팅에서 !돌, !주차, !keys, !weekly 입력 시 자동으로 응답합니다.|r",
                order = 2,
                width = "full",
            },
        }
    }
end
