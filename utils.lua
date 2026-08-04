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

return utils
