local data_utils = require("__parallel-module__.data-utils")
local parallel_module_mod_data = data.raw["mod-data"].parallel_module_mod_data.data

local explicitly_allowed_recycling_recipes = parallel_module_mod_data.allowed_recycling_recipes

local new_recipes = {}
local crafting_category_to_recipes = {}
local new_crafting_categories = {}

local base_recipe_to_altered_recipes = data.raw["mod-data"].parallel_module_mod_recipe_table.data
local altered_recipe_to_base_recipe_parallel_pair = data.raw["mod-data"].parallel_module_mod_recipe_table_inverse.data

local function is_category_parallelizable(recipe_name, category)
    if category.parallel_blacklist == true then
        return false
    end

    if (crafting_category_to_max_module_slots[category] or 0) == 0 then
        return false
    end

    if category:find("recycling", 1, true) and not utils.table_contains_value(explicitly_allowed_recycling_recipes, recipe_name) then
        return false
    end
    if category:find("voidcraft", 1, true) and not utils.table_contains_value(explicitly_allowed_recycling_recipes, recipe_name) then
        return false
    end
    return true
end

local function get_max_module_slots_for_recipe(crafting_categories)
    local slots = 0
    for _, category in pairs(crafting_categories) do
        slots = math.max(slots, crafting_category_to_max_module_slots[category])
    end
    return slots
end

local function get_max_parallel_without_modules_for_recipe(crafting_categories)
    local parallel = 0
    for _, category in pairs(crafting_categories) do
        parallel = math.max(parallel, crafting_category_to_max_parallel_without_modules[category])
    end
    return parallel
end

-------------------------------------------------------------------------------
--- CREATE PARALLEL RECIPE PROTOTYPES
-------------------------------------------------------------------------------

local function can_recipe_be_parallelized(recipe)
    if recipe.hidden then return false end
    if recipe.allow_speed == false then return false end
    if recipe.allow_parallel == false then return false end
    if not recipe.ingredients then return false end
    if not recipe.results then return false end
    if table_size(recipe.ingredients) == 0 then return false end
    if table_size(recipe.results) == 0 then return false end
    if recipe.name:match("%-barrel$") then return false end
    if recipe.name:match("%-recycling$") then return false end

    -- ensure recipes with results with the "non-stackable" flag are not parallelized
    for _, result in pairs(recipe.results) do
        if result.type == "item" then
            for prototype in pairs(defines.prototypes.item) do
                if result.name and data.raw[prototype] and data.raw[prototype][result.name] then
                    if data.raw[prototype][result.name].stack_size == 1 then
                        return false
                    end
                    local flags = data.raw[prototype][result.name].flags
                    for _, flag in pairs(flags or {}) do
                        if flag == "not-stackable" then
                            return false
                        end
                    end
                end
            end
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

    -- Explicitly allow parallel modules in recipe.allowed_module_categories
    table.insert(base_recipe.allowed_module_categories, EFFECT_NAME)
    
    valid_categories = valid_categories or {}
    for _, category in pairs(valid_categories) do
        if not crafting_category_to_recipes[category] then
            crafting_category_to_recipes[category] = {}
        end
        crafting_category_to_recipes[category][recipe_name] = true
    end

    base_recipe_to_altered_recipes[recipe_name] = { [tostring(0)] = recipe_name }
    altered_recipe_to_base_recipe_parallel_pair[recipe_name] = { [tostring(0)] = recipe_name }
    local total_max_module_value = math.min(parallel_module_mod_data.max_total_parallel, get_max_parallel_without_modules_for_recipe(valid_categories) +
        max_parallel_per_module * get_max_module_slots_for_recipe(valid_categories))
    
    for scale = 1, total_max_module_value do
        local scale_str = tostring(scale)
        local new_recipe_name = string.format("%s__parallel_module_mod__%d", recipe_name, scale_str)
        base_recipe_to_altered_recipes[recipe_name][scale_str] = new_recipe_name
        altered_recipe_to_base_recipe_parallel_pair[new_recipe_name] = { [scale_str] = recipe_name }

        local num_parallels = scale + 1

        local new_recipe = table.deepcopy(base_recipe)
        new_recipe.name = new_recipe_name
        new_recipe.localised_name = data_utils.get_recipe_localised_field(base_recipe, "name")
        new_recipe.localised_description = data_utils.get_recipe_localised_field(base_recipe, "description")
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
        
        for _, products in pairs{new_recipe.ingredients or {}, new_recipe.results or {}} do
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
    data:extend({ new_category })
end
for _, new_recipe in pairs(new_recipes) do
    data:extend({ new_recipe })
end