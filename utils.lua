local utils = {}

utils.split = function(s, delimiter)
    local result = {}
    for part in string.gmatch(s, "[^" .. delimiter .. "]+") do
        table.insert(result, part)
    end
    return result
end

-- Split by at most one instance of delimiter in string!
-- Always returns 2 results: if delimiter not in string, second result will be nil
utils.split_pair = function(s, delimiter)
    local prefix = nil
    local suffix = nil
    local delim_from, delim_to = string.find(s, delimiter, 1, true)
    if delim_from then
        prefix = string.sub(s, 1, delim_from - 1)
        suffix = string.sub(s, delim_to + 1)
    else
        prefix = string.sub(s, 1)
    end
    return prefix, suffix
end

utils.split_pairs = function(s, list_delimiter, pair_delimiter)
    local results = {}
    for _, part in pairs(utils.split(s, list_delimiter)) do
        local k, v = utils.split_pair(part, pair_delimiter)
        results[k] = v
    end
    return results
end

utils.table_contains_value = function(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

utils.is_quality_enabled = function()
    if utils._is_quality_enabled == nil then
        utils._is_quality_enabled = mods["quality"] and data.raw.quality and table_size(data.raw.quality) > 1
    end
    return utils._is_quality_enabled
end

utils.is_quality_enabled_runtime = function()
    if utils._is_quality_enabled == nil then
        utils._is_quality_enabled = script.active_mods["quality"] and prototypes.quality and #prototypes.quality > 1
    end
    return utils._is_quality_enabled
end

utils.round_parallel = function(parallel)
    return math.ceil(parallel)
end

return utils
