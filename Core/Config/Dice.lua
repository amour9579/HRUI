local _, ns = ...

function ns:CreateDiceOptions()
    return {
        type = "group",
        name = "주사위",
        order = 8,
        args = {
            header = {
                type = "header",
                name = "전리품 주사위 굴림",
                order = 1,
            },

            enabled = {
                type = "toggle",
                name = "사용",
                order = 2,
                width = "full",
                get = function()
                    return ns.db.profile.dice.enabled
                end,
                set = function(_, value)
                    ns.db.profile.dice.enabled = value
                    if ns.Modules and ns.Modules.Dice and ns.Modules.Dice.Refresh then
                        ns.Modules.Dice:Refresh()
                    end
                end,
            },

            delay = {
                type = "range",
                name = "전리품 주사위 창 닫기 지연",
                desc = "모든 굴림이 끝난 뒤 전리품 주사위 창을 자동으로 닫기 까지의 시간입니다.",
                order = 3,
                min = 1,
                max = 10,
                step = 1,
                get = function()
                    return ns.db.profile.dice.delay
                end,
                set = function(_, value)
                    ns.db.profile.dice.delay = value
                    if ns.Modules and ns.Modules.Dice and ns.Modules.Dice.Refresh then
                        ns.Modules.Dice:Refresh()
                    end
                end,
            },

            autoRoll = {
                type = "select",
                name = "하우징 장식 아이템 자동 굴림",
                desc = "하우징 장식 아이템에만 자동으로 적용됩니다.",
                order = 4,
                values = {
                    [-1] = "사용 안 함",
                    [1] = "입찰",
                    [2] = "차비",
                    [0] = "포기",
                },
                get = function()
                    return ns.db.profile.dice.autoRoll
                end,
                set = function(_, value)
                    ns.db.profile.dice.autoRoll = value
                    if ns.Modules and ns.Modules.Dice and ns.Modules.Dice.Refresh then
                        ns.Modules.Dice:Refresh()
                    end
                end,
            },

            hideInDungeons = {
                type = "toggle",
                name = "던전에서 하우징 장식 아이템만 굴릴 때 전리품 주사위 창 숨김",
                desc = "파티 던전에서 진행 중인 굴림이 모두 하우징 장식 아이템일 때만 전리품 주사위 창을 숨깁니다.",
                order = 5,
                width = "full",
                get = function()
                    return ns.db.profile.dice.hideInDungeons
                end,
                set = function(_, value)
                    ns.db.profile.dice.hideInDungeons = value
                    if ns.Modules and ns.Modules.Dice and ns.Modules.Dice.Refresh then
                        ns.Modules.Dice:Refresh()
                    end
                end,
            },

            help = {
                type = "description",
                name = "하우징 장식 아이템 자동 굴림, 던전 내 전리품 주사위 창 숨김, 굴림 종료 후 자동 닫기를 설정합니다.",
                order = 6,
                width = "full",
            },
        },
    }
end
