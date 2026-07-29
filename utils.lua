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

utils.round = function(value, scale)
    if scale <= 0 or value == 0 then
        return value
    elseif value < 0 then
        return math.floor(value / scale - 0.5) * scale
    else
        return math.floor(value / scale + 0.5) * scale
    end
end

utils.clamp = function(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

--- Convert a probability to odds, scale the odds, then convert back to probability, e.g.:
--- scale_probability_as_odds(0.5, 3.0) => 0.75
---     [prob] 0.5 => [odds] 1:1
---     [odds] 1:1 * [scale] 3.0 => [odds] 3:1
---     [odds] 3:1 => [prob] 75%
utils.scale_probability_as_odds = function(prob, scale)
    prob = utils.clamp(prob, 0.0, 1.0)
    return (scale * prob) / (scale * prob - prob + 1)
end

utils.get_rigor_effect = function(rigor_formula_coefficients, tier)
    -- See data.lua for formula explanation
    return rigor_formula_coefficients[3]
        + rigor_formula_coefficients[2] * tier
        + rigor_formula_coefficients[1] * tier * tier
end

utils.is_recipe_in_rigor_mod_data = function(mod_data, recipe_name)
    return mod_data.explicit_recipe_results[recipe_name]
            or mod_data.explicit_recipe_result_indices[recipe_name]
            or mod_data.extra_count_fraction_recipe_results[recipe_name]
            or mod_data.compatibility_mode_recipe_whitelist[recipe_name]
            or utils.table_contains_value(mod_data.explicit_recipes_without_results, recipe_name)
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

return utils