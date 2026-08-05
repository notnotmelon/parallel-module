local utils = {}

utils.table_contains_value = function(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

utils.round_parallel = function(parallel)
    return math.ceil(parallel)
end

utils.parallel_tooltip = function(parallel)
    if parallel >= 0 then
        return {"mod-tooltip-value.parallel-module-value-positive", tostring(100 * parallel)}
    else
        return {"mod-tooltip-value.parallel-module-value-negative", tostring(100 * parallel)}
    end
end

return utils
