local utils = require("__rigor-module__.utils")

local Public = {}

local rigor_module_mod_data = data.raw["mod-data"].rigor_module_mod_data.data

Public.maximum_probability_valid_for_rigor = rigor_module_mod_data.maximum_probability_valid_for_rigor

function Public.get_recipe_result_combined_probability(result)
    if result.shared_probability then
        return (result.shared_probability.max - result.shared_probability.min) * (result.independent_probability or 1)
    end

    return result.independent_probability
end

function Public.is_result_valid_rigor_target(result)
    if result.si_modified then
        return false
    end

    return (result.independent_probability and result.independent_probability < Public.maximum_probability_valid_for_rigor)
        or (result.shared_probability and result.shared_probability.max - result.shared_probability.min < Public.maximum_probability_valid_for_rigor)
end

function Public.lowest_probability_ingredient_idx(recipe)
    local idx = nil
    if not recipe or not recipe.results or table_size(recipe.results) == 0 then
        return idx
    end

    local lowest_probability = Public.maximum_probability_valid_for_rigor
    for i, result in pairs(recipe.results) do
        if not Public.is_result_valid_rigor_target(result) then
            goto continue
        end

        local raw_probability = Public.get_recipe_result_combined_probability(result)
        if raw_probability and raw_probability <= lowest_probability then
            idx = i
            lowest_probability = raw_probability
        end
        ::continue::
    end
    return idx
end

Public.SharedProbFlags = {}
Public.SharedProbFlags.HAS_GAP_VALUE_BELOW = 1
Public.SharedProbFlags.HAS_GAP_VALUE_ABOVE = 2
Public.SharedProbFlags.HAS_EXACT_VALUE_BELOW = 4
Public.SharedProbFlags.HAS_EXACT_VALUE_ABOVE = 8
Public.SharedProbFlags.HAS_PARTIAL_OVERLAP = 16
Public.SharedProbFlags.HAS_INNER_OVERLAP = 32
Public.SharedProbFlags.HAS_OUTER_OVERLAP = 64
Public.SharedProbFlags.HAS_MIN_EXACT_OVERLAP = 128
Public.SharedProbFlags.HAS_MAX_EXACT_OVERLAP = 256

Public.SharedProbFlags.HAS_ANY_VALUE_FULLY_BELOW =
    Public.SharedProbFlags.HAS_GAP_VALUE_BELOW +
    Public.SharedProbFlags.HAS_EXACT_VALUE_BELOW
Public.SharedProbFlags.HAS_ANY_VALUE_FULLY_ABOVE =
    Public.SharedProbFlags.HAS_GAP_VALUE_ABOVE +
    Public.SharedProbFlags.HAS_EXACT_VALUE_ABOVE
Public.SharedProbFlags.HAS_ANY_OVERLAP =
    Public.SharedProbFlags.HAS_PARTIAL_OVERLAP +
    Public.SharedProbFlags.HAS_INNER_OVERLAP +
    Public.SharedProbFlags.HAS_OUTER_OVERLAP +
    Public.SharedProbFlags.HAS_MIN_EXACT_OVERLAP +
    Public.SharedProbFlags.HAS_MAX_EXACT_OVERLAP

function Public.has_flag(flags, flag)
    return bit32.band(flags, flag) ~= 0
end

function Public.add_flag(flags, flag)
    return bit32.bor(flags, flag)
end

function Public.build_shared_prob_flags_of_result(recipe, idx)
    local shared = recipe.results[idx].shared_probability
    local recipe_flags = 0
    local result_flags = {}
    for i, result in pairs(recipe.results) do
        local flags = 0
        if i == idx or not result.shared_probability then
            goto continue
        end

        if result.shared_probability.min < shared.min then
            if result.shared_probability.max < shared.min then
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_GAP_VALUE_BELOW)
            elseif result.shared_probability.max == shared.min then
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_EXACT_VALUE_BELOW)
            elseif result.shared_probability.max < shared.max then
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_PARTIAL_OVERLAP)
            elseif result.shared_probability.max == shared.max then
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_OUTER_OVERLAP)
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_MAX_EXACT_OVERLAP)
            else
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_OUTER_OVERLAP)
            end
        elseif result.shared_probability.min == shared.min then
            flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_MIN_EXACT_OVERLAP)
            if result.shared_probability.max < shared.max then
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_INNER_OVERLAP)
            elseif result.shared_probability.max == shared.max then
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_MAX_EXACT_OVERLAP)
            else
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_OUTER_OVERLAP)
            end
        else
            if result.shared_probability.max < shared.max then
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_INNER_OVERLAP)
            elseif result.shared_probability.max == shared.max then
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_INNER_OVERLAP)
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_MAX_EXACT_OVERLAP)
            elseif result.shared_probability.min < shared.max then
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_PARTIAL_OVERLAP)
            elseif result.shared_probability.min == shared.max then
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_EXACT_VALUE_ABOVE)
            else
                flags = Public.add_flag(flags, Public.SharedProbFlags.HAS_GAP_VALUE_ABOVE)
            end
        end
        ::continue::
        recipe_flags = Public.add_flag(recipe_flags, flags)
        result_flags[i] = flags
    end
    return recipe_flags, result_flags
end

--- TODO: Currently unused WIP
function Public.build_shared_probability_strategy(recipe, idx)
    local recipe_flags, result_flags = Public.build_shared_prob_flags_of_result(recipe, idx)
    if not recipe_flags then
        return nil
    end

    local has_any_fully_below = Public.has_flag(recipe_flags, Public.SharedProbFlags.HAS_ANY_VALUE_FULLY_BELOW)
    local has_any_fully_above = Public.has_flag(recipe_flags, Public.SharedProbFlags.HAS_ANY_VALUE_FULLY_ABOVE)
    local has_any_overlap = Public.has_flag(recipe_flags, Public.SharedProbFlags.HAS_ANY_OVERLAP)

    if not has_any_overlap  then
        log("Strategy simple_zero_sum_scale: "..recipe.name)
        return {
            prepare = function() end,
            scale = Public.Strategy.simple_zero_sum_scale
        }
    end

    -- TODO: Actual strategies!!!
    log("Strategy simple_positive_sum_scale: "..recipe.name)
    return {
        prepare = Public.Strategy.standardize,
        scale = Public.Strategy.simple_positive_sum_scale
    }
end

function Public.get_limits(recipe)
    local min_min = 1
    local max_max = 0
    for _, result in pairs(recipe.results) do
        if not result.shared_probability then
            goto continue
        end

        min_min = math.min(min_min, result.shared_probability.min)
        max_max = math.max(max_max, result.shared_probability.max)
        ::continue::
    end
    return min_min, max_max
end

Public.Strategy = {}

--- Shift all values down so that lowest min = 0 (no-op change)
function Public.Strategy.standardize(recipe)
    local min_min = 1
    for _, result in pairs(recipe.results) do
        if not result.shared_probability then
            goto continue
        end

        if result.shared_probability.min < min_min then
            if result.shared_probability == 0 then
                return
            end

            min_min = result.shared_probability.min
        end
        ::continue::
    end
    for _, result in pairs(recipe.results) do
        if not result.shared_probability then
            goto continue
        end

        result.shared_probability.min = result.shared_probability.min - min_min
        result.shared_probability.max = result.shared_probability.max - min_min
        ::continue::
    end
end

--- Scale up rigor result with standard formula.
--- Scale down other results to reach no net change.
function Public.Strategy.simple_zero_sum_scale(recipe, idx, scale)
    -- TODO: improve scaling
    local min_min, max_max = Public.get_limits(recipe)
    local shared = recipe.results[idx].shared_probability
    local low = shared.min
    local high = shared.max
    local base_prob = high - low
    local scaled_prob = utils.scale_probability_as_odds(base_prob, scale) * (max_max - min_min)
    local diff = scaled_prob - base_prob * (max_max - min_min)
    local p = function(x)
        return (x <= low and x * (1 - diff / (1 - base_prob))) or (x >= high and 1 - (1 - x) * (1 - diff / (1 - base_prob))) or x
    end
    for _, result in pairs(recipe.results) do
        if not result.shared_probability then
            goto continue
        end

        result.shared_probability.min = p(result.shared_probability.min)
        result.shared_probability.max = p(result.shared_probability.max)
        ::continue::
    end
end

--- Scale up rigor result with standard formula.
--- Leave other results unchanged.
function Public.Strategy.simple_positive_sum_scale(recipe, idx, scale)
    local _, max_max = Public.get_limits(recipe)
    local headroom = 1 - max_max
    local shared = recipe.results[idx].shared_probability
    local threshold = shared.max
    local base_prob = shared.max - shared.min
    local scaled_prob = utils.scale_probability_as_odds(base_prob, scale)
    local diff = math.min(headroom, scaled_prob - base_prob)
    for _, result in pairs(recipe.results) do
        if not result.shared_probability then
            goto continue
        end

        if result.shared_probability.min >= threshold then
            result.shared_probability.min = result.shared_probability.min + diff
        end
        if result.shared_probability.max >= threshold then
            result.shared_probability.max = result.shared_probability.max + diff
        end
        ::continue::
    end
end

return Public