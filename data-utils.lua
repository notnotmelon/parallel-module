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

function Public.get_prototype_helper(base_type, name)
    for type_name in pairs(defines.prototypes[base_type]) do
        local prototypes = data.raw[type_name]
        if prototypes and prototypes[name] then
            return prototypes[name]
        end
    end
end

function Public.get_recipe_localised_field(prototype, field_type)
    local field = "localised_"..field_type
    if prototype[field] then
        return prototype[field]
    end

    local fluid = data.raw.fluid[prototype.name]
    if fluid and fluid[field] then
        return fluid[field]
    end
    
    local entity = Public.get_prototype_helper("entity", prototype.name)
    local equipment = Public.get_prototype_helper("equipment", prototype.name)
    local tile = data.raw.tile[prototype.name]
    local item = data.raw.item[prototype.name]
    if item then
        if item[field] then
            return item[field]
        end

        entity = entity or (item.place_result and Public.get_prototype_helper("entity", item.place_result))
        equipment = equipment or (item.place_as_equipment_result and Public.get_prototype_helper("equipment", item.place_as_equipment_result))
        tile = tile or (item.place_as_tile_result and data.raw.tile[item.place_as_tile_result])
    end

    if entity and entity[field] then
        return entity[field]
    end
    if equipment and equipment[field] then
        return equipment[field]
    end
    if tile and tile[field] then
        return tile[field]
    end

    local localised_field = {
        "?",
        { "recipe-"..field_type.."."..prototype.name }
    }
    if fluid then
        table.insert(localised_field, { "fluid-"..field_type.."."..fluid.name })
    end
    if item then
        table.insert(localised_field, { "item-"..field_type.."."..item.name })
    end
    if entity then
        table.insert(localised_field, { "entity-"..field_type.."."..entity.name })
    end
    if equipment then
        table.insert(localised_field, { "equipment-"..field_type.."."..equipment.name })
    end
    if tile then
        table.insert(localised_field, { "tile-"..field_type.."."..tile.name })
    end
    return localised_field
end

function Public.set_recipe_icon_or_icons(prototype, prototype_with_icon)
    prototype.icon = prototype_with_icon.icon
    prototype.icon_size = prototype_with_icon.icon_size
    prototype.icons = prototype_with_icon.icons -- Non-deep copy is probably better
end

function Public.ensure_recipe_icon_or_icons(prototype, base_prototype)
    if prototype.icon or prototype.icons then
        return
    end

    local fluid = data.raw.fluid[base_prototype.name]
    if fluid and (fluid.icon or fluid.icons) then
        Public.set_recipe_icon_or_icons(prototype, fluid)
        return
    end

    local entity = Public.get_prototype_helper("entity", base_prototype.name)
    local equipment = Public.get_prototype_helper("equipment", base_prototype.name)
    local tile = data.raw.tile[base_prototype.name]
    local item = data.raw.item[base_prototype.name]
    if item then
        if item and (item.icon or item.icons) then
            Public.set_recipe_icon_or_icons(prototype, item)
            return
        end

        entity = entity or (item.place_result and Public.get_prototype_helper("entity", item.place_result))
        equipment = equipment or (item.place_as_equipment_result and Public.get_prototype_helper("equipment", item.place_as_equipment_result))
        tile = tile or (item.place_as_tile_result and data.raw.tile[item.place_as_tile_result])
    end

    if entity and (entity.icon or entity.icons) then
        Public.set_recipe_icon_or_icons(prototype, entity)
        return
    end

    if equipment and (equipment.icon or equipment.icons) then
        Public.set_recipe_icon_or_icons(prototype, equipment)
        return
    end

    if tile and (tile.icon or tile.icons) then
        Public.set_recipe_icon_or_icons(prototype, tile)
        return
    end
end

return Public