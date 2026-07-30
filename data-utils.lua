local utils = require("__parallel-module__.utils")

local Public = {}

local parallel_module_mod_data = data.raw["mod-data"].parallel_module_mod_data.data

Public.maximum_probability_valid_for_parallel = parallel_module_mod_data.maximum_probability_valid_for_parallel

function Public.get_recipe_result_combined_probability(result)
    if result.shared_probability then
        return (result.shared_probability.max - result.shared_probability.min) * (result.independent_probability or 1)
    end

    return result.independent_probability
end

function Public.is_result_valid_parallel_target(result)
    if result.si_modified then
        return false
    end

    return (result.independent_probability and result.independent_probability < Public.maximum_probability_valid_for_parallel)
        or (result.shared_probability and result.shared_probability.max - result.shared_probability.min < Public.maximum_probability_valid_for_parallel)
end

function Public.lowest_probability_ingredient_idx(recipe)
    local idx = nil
    if not recipe or not recipe.results or table_size(recipe.results) == 0 then
        return idx
    end

    local lowest_probability = Public.maximum_probability_valid_for_parallel
    for i, result in pairs(recipe.results) do
        if not Public.is_result_valid_parallel_target(result) then
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

return Public