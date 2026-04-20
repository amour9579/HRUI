local _, ns = ...

ns.Modules = ns.Modules or {}
ns.Modules.Chat = ns.Modules.Chat or {}

local Module = ns.Modules.Chat

function Module:Enable()
    if not ns.db or not ns.db.profile or not ns.db.profile.chat or not ns.db.profile.chat.enabled then
        return
    end

    if ns.ChatInfoBar and ns.ChatInfoBar.Initialize then
        ns.ChatInfoBar:Initialize()
    end

    if ns.CombatMessage and ns.CombatMessage.Initialize then
        ns.CombatMessage:Initialize()
    end
end

function Module:Refresh()
    if ns.ChatInfoBar and ns.ChatInfoBar.Refresh then
        ns.ChatInfoBar:Refresh()
    end

    if ns.CombatMessage and ns.CombatMessage.Refresh then
        ns.CombatMessage:Refresh()
    end
end
