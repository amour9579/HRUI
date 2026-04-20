local _, ns = ...

ns.Event = ns.Event or {}

local Event = ns.Event

Event.frame = Event.frame or CreateFrame("Frame")
Event.handlers = Event.handlers or {}

local function CleanupEventBucket(self, event)
    local bucket = self.handlers[event]
    if not bucket then
        return
    end

    for key, func in pairs(bucket) do
        if func ~= nil then
            return
        end
    end

    self.handlers[event] = nil
    self.frame:UnregisterEvent(event)
end

function Event:Register(event, key, func)
    if not event or not key or type(func) ~= "function" then
        return
    end

    self.handlers[event] = self.handlers[event] or {}
    self.handlers[event][key] = func
    self.frame:RegisterEvent(event)
end

function Event:Unregister(event, key)
    if not event or not key then
        return
    end

    local bucket = self.handlers[event]
    if not bucket then
        return
    end

    bucket[key] = nil
    CleanupEventBucket(self, event)
end

function Event:UnregisterPrefix(prefix)
    if not prefix or prefix == "" then
        return
    end

    for event, bucket in pairs(self.handlers) do
        for key in pairs(bucket) do
            if type(key) == "string" and key:find("^" .. prefix) then
                bucket[key] = nil
            end
        end

        CleanupEventBucket(self, event)
    end
end

function Event:Dispatch(event, ...)
    local bucket = self.handlers[event]
    if not bucket then
        return
    end

    for _, func in pairs(bucket) do
        if type(func) == "function" then
            func(event, ...)
        end
    end
end

Event.frame:SetScript("OnEvent", function(_, event, ...)
    Event:Dispatch(event, ...)
end)
