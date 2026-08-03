local Public = {}

Public.maximum_probability_valid_for_parallel = mod_data.maximum_probability_valid_for_parallel

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

local function get_recipe_main_product(recipe)
    local main_product_name = recipe.main_product

    if not main_product_name or type(main_product_name) ~= "string" then
        if type(recipe.results) == "table" and table_size(recipe.results) == 1 and type(recipe.results[1]) == "table" then
            main_product_name = recipe.results[1].name
        end
    end

    if type(main_product_name) ~= "string" then
        return nil
    end

    for prototype in pairs(defines.prototypes.item) do
        if data.raw[prototype] and data.raw[prototype][main_product_name] then
            return data.raw[prototype][main_product_name]
        end
    end

    return data.raw.fluid[main_product_name]
end

function Public.get_recipe_localised_name(recipe)
    local fallback = recipe.localised_name or {"recipe-name." .. recipe.name}
    local main_product = get_recipe_main_product(recipe)
    if not main_product then return fallback end

    return {
        "?",
        fallback,
        main_product.localised_name or {"item-name." .. main_product.name},
        {"entity-name." .. main_product.name},
        {"fluid-name." .. main_product.name},
        {"equipment-name." .. main_product.name},
        {"tile-name." .. main_product.name},
    }
end

function Public.get_recipe_localised_description(recipe)
    local fallback = recipe.localised_description or {"recipe-description." .. recipe.name}
    local main_product = get_recipe_main_product(recipe)
    if not main_product then return fallback end

    return {
        "?",
        fallback,
        main_product.localised_description or {"item-description." .. main_product.name},
        {"entity-description." .. main_product.name},
        {"fluid-description." .. main_product.name},
        {"equipment-description." .. main_product.name},
        {"tile-description." .. main_product.name},
    }
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

function Public.can_recipe_be_made_in_this_machine(recipe, machine)
    local function shares_any_crafting_category(recipe, machine)
        for _, a in pairs(recipe.categories or {"crafting"}) do
            for _, b in pairs(machine.crafting_categories or {}) do
                local category = data.raw["recipe-category"][a]
                if a == b and category and not category.parallel_blacklist then
                    return true
                end
            end
        end
        return false
    end

    if not shares_any_crafting_category(recipe, machine) then return false end

    local num_fluid_ingredients = 0
    local num_fluid_results = 0
    local num_item_ingredients = 0
    local num_item_results = 0

    for _, ingredient in pairs(recipe.ingredients or {}) do
        if ingredient.type == "fluid" then
            num_fluid_ingredients = num_fluid_ingredients + 1
        elseif ingredient.type == "item" then
            num_item_ingredients = num_item_ingredients + 1
        end
    end
    for _, result in pairs(recipe.results or {}) do
        if result.type == "fluid" then
            num_fluid_results = num_fluid_results + 1
        elseif result.type == "item" then
            num_item_results = num_item_results + 1
        end
    end

    local num_fluid_inputs = 0
    local num_fluid_outputs = 0

    for _, fluidbox in pairs(machine.fluid_boxes or {}) do
        if fluidbox.production_type == "input" then
            num_fluid_inputs = num_fluid_inputs + 1
        elseif fluidbox.production_type == "output" then
            num_fluid_outputs = num_fluid_outputs + 1
        else
            num_fluid_inputs = num_fluid_inputs + 1
            num_fluid_outputs = num_fluid_outputs + 1
        end
    end

    if num_fluid_ingredients > num_fluid_inputs then return false end
    if num_fluid_results > num_fluid_outputs then return false end

    local source_inventory_size = machine.ingredient_count or machine.source_inventory_size or 65535
    local result_inventory_size = machine.max_item_product_count or machine.result_inventory_size or 65535
    if num_item_ingredients > source_inventory_size then return false end
    if num_item_results > result_inventory_size then return false end

    if machine.type == "furnace" and num_fluid_ingredients > 1 then return false end
    if machine.type == "furnace" and num_item_ingredients > 1 then return false end
    if machine.type == "furnace" and table_size(recipe.ingredients) == 0 then return false end

    return true
end

return Public
