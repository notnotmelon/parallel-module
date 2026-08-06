local utils = require "lib.utils"

local PROTOTYPE_LIMIT = 64000
local num_recipes = table_size(data.raw.recipe)

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

local function get_recipe_localised_name(recipe)
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

local function get_recipe_localised_description(recipe)
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

local function can_recipe_be_made_in_this_machine(recipe, machine)
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

-- simulate putting all combinations of modules inside this machine
-- in order to determine all possible parallel amounts
local function get_possible_parallels_for_recipe(recipe)
    local possible_parallels = {}

    for name, prototype in pairs(mod_data.allowed_machines) do
        local machine = data.raw[prototype][name]
        if not can_recipe_be_made_in_this_machine(recipe, machine) then goto continue end

        local num_module_slots = machine.module_slots or 0
        if machine.quality_affects_module_slots then
            for _, quality in pairs(data.raw.quality) do
                if not quality.hidden then
                    local bonus = quality.crafting_machine_module_slots_bonus or quality.level
                    num_module_slots = math.max(num_module_slots, bonus)
                end
            end
        end

        local possible_parallels_for_this_machine = {[parallel.get_base_parallel(machine) + 1] = true}
        for _ = 1, num_module_slots do
            local possible_parallels_for_this_module = {}
            for _, by_quality in pairs(mod_data.parallel_value_cache) do
                for _, module_strength in pairs(by_quality) do
                    for existing in pairs(possible_parallels_for_this_machine) do
                        table.insert(possible_parallels_for_this_module, existing + module_strength)
                    end
                end
            end
            for _, possible in pairs(possible_parallels_for_this_module) do
                possible_parallels_for_this_machine[possible] = true
            end
        end

        for possible in pairs(possible_parallels_for_this_machine) do
            possible_parallels[utils.round_parallel(possible)] = true
        end

        ::continue::
    end

    local array = {}
    for num_parallels in pairs(possible_parallels) do
        if num_parallels >= 2 then
            table.insert(array, num_parallels)
        end
    end
    table.sort(array)
    return array
end

-------------------------------------------------------------------------------
--- CREATE PARALLEL RECIPE PROTOTYPES
-------------------------------------------------------------------------------

local function to_hidden_recipe_name(recipe_name, num_parallels)
    return string.format("%s__parallel-module__%d", recipe_name, tostring(num_parallels))
end

for recipe_name in pairs(mod_data.allowed_recipes) do
    local base_recipe = data.raw.recipe[recipe_name]

    mod_data.recipe_table[recipe_name] = {["1"] = recipe_name}
    mod_data.recipe_table_inverse[recipe_name] = recipe_name
    mod_data.module_effect_limits[recipe_name] = 1

    for _, num_parallels in pairs(get_possible_parallels_for_recipe(base_recipe)) do
        local new_recipe = table.deepcopy(base_recipe)
        new_recipe.name = to_hidden_recipe_name(recipe_name, num_parallels)
        new_recipe.localised_name = {
            "recipe-name.parallel-module-num-parallels",
            get_recipe_localised_name(base_recipe),
            tostring(num_parallels),
        }
        new_recipe.localised_description = get_recipe_localised_description(base_recipe)
        new_recipe.factoriopedia_alternative = base_recipe.factoriopedia_alternative or recipe_name
        new_recipe.hidden = true
        new_recipe.hide_from_player_crafting = true
        new_recipe.allow_as_intermediate = false
        new_recipe.hide_from_bonus_gui = true
        new_recipe.enabled = true
        new_recipe.allow_decomposition = false
        new_recipe.unlock_results = false
        new_recipe.hide_from_signal_gui = true
        new_recipe.auto_recycle = false
        new_recipe.request_paste_multiplier = math.ceil((new_recipe.request_paste_multiplier or 1) / num_parallels)

        local any_product_over_limit = false
        for _, products in pairs {new_recipe.ingredients or {}, new_recipe.results or {}} do
            for _, product in pairs(products) do
                if product.amount then
                    product.amount = product.amount * num_parallels
                end
                if product.ignored_by_stats then
                    product.ignored_by_stats = product.ignored_by_stats * num_parallels
                end
                if product.ignored_by_productivity then
                    product.ignored_by_productivity = product.ignored_by_productivity * num_parallels
                end
                if product.amount_min then
                    product.amount_min = product.amount_min * num_parallels
                end
                if product.amount_max then
                    product.amount_max = product.amount_max * num_parallels
                end
                if product.extra_count_fraction and product.extra_count_fraction > 0 then
                    product.extra_count_fraction = product.extra_count_fraction * num_parallels
                    while product.extra_count_fraction > 1 do
                        product.extra_count_fraction = product.extra_count_fraction - 1
                        if product.amount then
                            product.amount = product.amount + 1
                        end
                        if product.amount_min then
                            product.amount_min = product.amount_min + 1
                        end
                        if product.amount_max then
                            product.amount_max = product.amount_max + 1
                        end
                    end
                end

                if product.type == "item" then
                    local limit = settings.startup["parallel-module-max-ingredient-product-amount"].value
                    if product.amount and product.amount > limit then any_product_over_limit = true end
                    if product.ignored_by_stats and product.ignored_by_stats > limit then any_product_over_limit = true end
                    if product.amount_min and product.amount_min > limit then any_product_over_limit = true end
                    if product.amount_max and product.amount_max > limit then any_product_over_limit = true end
                end
            end
        end

        if any_product_over_limit then
            break
        else
            if num_recipes >= PROTOTYPE_LIMIT then return end
            mod_data.recipe_table[recipe_name][tostring(num_parallels)] = new_recipe.name
            mod_data.recipe_table_inverse[new_recipe.name] = recipe_name
            data:extend {new_recipe}
            num_recipes = num_recipes + 1
            mod_data.module_effect_limits[recipe_name] = math.max(num_parallels, mod_data.module_effect_limits[recipe_name])
        end
    end

    local limit_recipe_name = to_hidden_recipe_name(recipe_name, mod_data.module_effect_limits[recipe_name])
    local limit_recipe = data.raw.recipe[limit_recipe_name]
    if limit_recipe then
        limit_recipe.localised_name[1] = "recipe-name.parallel-module-num-parallels-limit"
    end
end
