local _, ns = ...

function ns:RegisterChatCommands()
    SLASH_HRUIRELOAD1 = "/rl"
    SLASH_HRUIRELOAD2 = "/기"
    SlashCmdList["HRUIRELOAD"] = function()
        ReloadUI()
    end
end
