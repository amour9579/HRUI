local _, ns = ...

function ns:BuildOptions()
    return {
        type = "group",
        name = "HRUI",
        childGroups = "tree",
        args = {
            general = ns:CreateGeneralOptions(),
            unitframes = ns:CreateUnitFrameOptions(),
            castbars = ns:CreateCastbarOptions(),
            actionbars = ns:CreateActionBarsOptions(),
            chat = ns:CreateChatOptions(),
            keystone = ns:CreateKeystoneReporter(),
            dice = ns:CreateDiceOptions(),
            profiles = ns:CreateProfileOptions(),
        },
    }
end

function ns:SetupOptions()
    local AceConfig = LibStub("AceConfig-3.0")
    local options = ns:BuildOptions()
    AceConfig:RegisterOptionsTable("HRUI", options)
    ns.Options = options
end
