local utils = {}

utils.table_contains_value = function(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- round parallel amounts to keep the total number of added recipes small
local precision = settings.startup["parallel-module-rounding-strictness"].value
if precision == "12x" then
    utils.round_parallel = function(parallel)
        if parallel <= 12 then
            return math.ceil(parallel)
        end

        if parallel <= 24 then
            return math.ceil(parallel / 2) * 2
        end

        if parallel <= 48 then
            return math.ceil(parallel / 4) * 4
        end

        if parallel <= 96 then
            return math.ceil(parallel / 8) * 8
        end

        local step = 10 ^ math.floor(math.log(parallel, 10) - 1)
        return math.floor(parallel / step) * step
    end
elseif precision == "24x" then
    utils.round_parallel = function(parallel)
        if parallel <= 24 then
            return math.ceil(parallel)
        end

        if parallel <= 48 then
            return math.ceil(parallel / 2) * 2
        end

        if parallel <= 96 then
            return math.ceil(parallel / 4) * 4
        end

        local step = 10 ^ math.floor(math.log(parallel, 10) - 1)
        return math.floor(parallel / step) * step
    end
elseif precision == "48x" then
    utils.round_parallel = function(parallel)
        if parallel <= 48 then
            return math.ceil(parallel)
        end

        if parallel <= 96 then
            return math.ceil(parallel / 2) * 2
        end

        local step = 10 ^ math.floor(math.log(parallel, 10) - 1)
        return math.floor(parallel / step) * step
    end
elseif precision == "never-round" then
    utils.round_parallel = function(parallel)
        return math.ceil(parallel)
    end
else
    error()
end

if data and data.raw then cached_tostring = tostring end
utils.parallel_tooltip = function(parallel)
    if parallel >= 0 then
        return {"mod-tooltip-value.parallel-module-value-positive", cached_tostring(100 * parallel)}
    else
        return {"mod-tooltip-value.parallel-module-value-negative", cached_tostring(100 * parallel)}
    end
end

return utils
