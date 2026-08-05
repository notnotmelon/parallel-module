_tostring = tostring
function tostring(x)
    local s = storage.cached_to_string[x]
    if s == nil then
        s = _tostring(x)
        storage.cached_to_string[x] = s
    end
    return s
end

parallel.on_event(parallel.events.on_init(), function()
    storage.cached_to_string = {}
end)
