local utils = require "utils"
local data_utils = require "data-utils"

local new_recipes = {}
local crafting_category_to_recipes = {}
local new_crafting_categories = {}

local function is_category_parallelizable(recipe_name, category)
    if category.parallel_blacklist == true then
        return false
    end

    if (parallel.crafting_category_to_max_module_slots[category] or 0) == 0 then
        return false
    end

    return true
end

local function get_max_module_slots_for_recipe(crafting_categories)
    local slots = 0
    for _, category in pairs(crafting_categories) do
        slots = math.max(slots, parallel.crafting_category_to_max_module_slots[category])
    end
    return slots
end

local function get_max_parallel_without_modules_for_recipe(crafting_categories)
    local max_parallel = 0
    for _, category in pairs(crafting_categories) do
        max_parallel = math.max(max_parallel, parallel.crafting_category_to_max_parallel_without_modules[category])
    end
    return max_parallel
end

-------------------------------------------------------------------------------
--- CREATE PARALLEL RECIPE PROTOTYPES
-------------------------------------------------------------------------------

local function has_non_stackable_flag(item_name)
    for prototype in pairs(defines.prototypes.item) do
        if data.raw[prototype] and data.raw[prototype][item_name] then
            if data.raw[prototype][item_name].stack_size == 1 then
                return true
            end
            if utils.table_contains_value(data.raw[prototype][item_name].flags or {}, "not-stackable") then
                return true
            end
        end
    end

    return false
end

local function can_recipe_be_parallelized(recipe)
    if recipe.hidden then return false end
    if recipe.allow_speed == false then return false end
    if recipe.allow_parallel == false then return false end
    if not recipe.ingredients then return false end
    if not recipe.results then return false end
    if table_size(recipe.ingredients) == 0 then return false end
    if table_size(recipe.results) == 0 then return false end
    if recipe.name:match("%-barrel$") then return false end

    -- ensure recipes with results with the "non-stackable" flag are not parallelized
    for _, result in pairs(recipe.results) do
        if result.type == "item" and result.name and has_non_stackable_flag(result.name) then
            return false
        end
    end

    local valid_categories = {}
    recipe.categories = recipe.categories or {"crafting"}
    for _, category in pairs(recipe.categories) do
        if is_category_parallelizable(recipe.name, category) then
            table.insert(valid_categories, category)
        end
    end

    if table_size(valid_categories) == 0 then
        return false
    end

    return true, valid_categories
end

for recipe_name, base_recipe in pairs(data.raw.recipe) do
    local can_be, valid_categories = can_recipe_be_parallelized(base_recipe)
    if not can_be then goto continue end

    -- explicitly allow parallel modules in recipe.allowed_module_categories
    table.insert(base_recipe.allowed_module_categories, "parallel")

    valid_categories = valid_categories or {}
    for _, category in pairs(valid_categories) do
        if not crafting_category_to_recipes[category] then
            crafting_category_to_recipes[category] = {}
        end
        crafting_category_to_recipes[category][recipe_name] = true
    end

    mod_data.recipe_table[recipe_name] = {[tostring(0)] = recipe_name}
    mod_data.recipe_table_inverse[recipe_name] = {[tostring(0)] = recipe_name}
    local total_max_module_value = math.min(mod_data.max_total_parallel, get_max_parallel_without_modules_for_recipe(valid_categories) +
        parallel.max_parallel_per_module_slot * get_max_module_slots_for_recipe(valid_categories))

    for scale = 1, utils.round_parallel(total_max_module_value) do
        local scale_str = tostring(scale)
        local new_recipe_name = string.format("%s__parallel-module__%d", recipe_name, scale_str)
        mod_data.recipe_table[recipe_name][scale_str] = new_recipe_name
        mod_data.recipe_table_inverse[new_recipe_name] = {[scale_str] = recipe_name}

        local num_parallels = scale + 1

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

        new_recipes[new_recipe_name] = new_recipe
    end
    ::continue::
end

for _, new_category in pairs(new_crafting_categories) do
    data:extend {new_category}
end
for _, new_recipe in pairs(new_recipes) do
    data:extend {new_recipe}
end
