local utils = require "utils"
local data_utils = require "data-utils"

local PROTOTYPE_LIMIT = 64000

-------------------------------------------------------------------------------
--- DETERMINE ALL POSSIBLE PARALLEL AMOUNTS
-------------------------------------------------------------------------------

local function get_possible_parallels_for_recipe(recipe)
    local possible_parallels = {}

    for name, prototype in pairs(mod_data.allowed_machines) do
        local machine = data.raw[prototype][name]
        if not data_utils.can_recipe_be_made_in_this_machine(recipe, machine) then goto continue end

        local num_module_slots = machine.module_slots or 0
        if machine.quality_affects_module_slots then
            for _, quality in pairs(data.raw.quality) do
                if not quality.hidden then
                    local bonus = quality.crafting_machine_module_slots_bonus or quality.level
                    num_module_slots = math.max(num_module_slots, bonus)
                end
            end
        end


        local possible_parallels_for_this_machine = {[parallel.get_base_parallel(machine)] = true}
        for _ = 1, num_module_slots do
            for _, by_quality in pairs(mod_data.parallel_value_cache) do
                for _, module_strength in pairs(by_quality) do
                    local possible_parallels_for_this_module = {}
                    for existing in pairs(possible_parallels_for_this_machine) do
                        table.insert(possible_parallels_for_this_module, existing + module_strength)
                    end
                    for _, possible in pairs(possible_parallels_for_this_module) do
                        possible_parallels_for_this_machine[possible] = true
                    end
                end
            end
        end

        for possible in pairs(possible_parallels_for_this_machine) do
            possible_parallels[utils.round_parallel(possible)] = true
        end

        ::continue::
    end

    return possible_parallels
end

-------------------------------------------------------------------------------
--- CREATE PARALLEL RECIPE PROTOTYPES
-------------------------------------------------------------------------------

for recipe_name in pairs(mod_data.allowed_recipes) do
    local base_recipe = data.raw.recipe[recipe_name]

    mod_data.recipe_table[recipe_name] = {[1] = recipe_name}
    mod_data.recipe_table_inverse[recipe_name] = recipe_name

    for num_parallels in pairs(get_possible_parallels_for_recipe(base_recipe)) do
        if num_parallels == 1 then goto continue end -- 1x parallel is the same as the base recipe
        assert(num_parallels > 1)

        if table_size(data.raw.recipe) >= PROTOTYPE_LIMIT then goto continue end

        local new_recipe_name = string.format("%s__parallel-module__%d", recipe_name, tostring(num_parallels))
        mod_data.recipe_table[recipe_name][num_parallels] = new_recipe_name
        mod_data.recipe_table_inverse[new_recipe_name] = recipe_name

        local new_recipe = table.deepcopy(base_recipe)
        new_recipe.name = new_recipe_name
        new_recipe.localised_name = {
            "recipe-name.parallel-module-num-parallels",
            data_utils.get_recipe_localised_name(base_recipe),
            tostring(num_parallels),
        }
        new_recipe.localised_description = data_utils.get_recipe_localised_description(base_recipe)
        data_utils.ensure_recipe_icon_or_icons(new_recipe, base_recipe)
        new_recipe.factoriopedia_alternative = base_recipe.factoriopedia_alternative or recipe_name
        new_recipe.hidden = true
        -- new_recipe.hidden_in_factoriopedia = true
        -- new_recipe.hide_from_stats = true
        new_recipe.hide_from_player_crafting = true
        new_recipe.allow_as_intermediate = false
        new_recipe.hide_from_bonus_gui = true
        new_recipe.enabled = true
        new_recipe.allow_decomposition = false
        new_recipe.unlock_results = false
        new_recipe.hide_from_signal_gui = true
        new_recipe.auto_recycle = false
        new_recipe.request_paste_multiplier = math.ceil((new_recipe.request_paste_multiplier or 1) / num_parallels)

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
            end
        end

        data:extend {new_recipe}

        ::continue::
    end
end
