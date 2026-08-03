local utils = require "utils"

-- step 1: determine module categories that can provide the parallel effect

local module_categories_that_give_parallel = {}
for _, module in pairs(data.raw.module) do
    if type(module.category) == "string" and type(module.effect) == "table" then
        if (module.effect.parallel or 0) ~= 0 then
            module_categories_that_give_parallel[module.category] = true
        end
    end
end

local function has_parallel_module_category(recipe_or_machine)
    if type(recipe_or_machine.allowed_module_categories) ~= "table" then
        -- by default, all module categories are allowed
        return true
    end

    for _, category in pairs(recipe_or_machine.allowed_module_categories) do
        if utils.table_contains_value(module_categories_that_give_parallel, category) then
            return true
        end
    end

    local default_module_categories = {"speed", "efficiency", "productivity"}
    for _, module_category in pairs(default_module_categories) do
        if data.raw["module-category"][module_category] then
            if not utils.table_contains_value(recipe_or_machine.allowed_module_categories, module_category) then
                return false
            end
        end
    end

    return true
end

-- step 2: determine machines that meet basic criteria

local function can_machine_be_parallelized(machine)
    if machine.hidden then return false end

    if machine.type == "furnace"
        and not settings.startup["parallel-module-allow-in-furnaces"].value then
        return false
    end

    local has_base_parallel = machine.effect_receiver
        and machine.effect_receiver.base_effect
        and type(machine.effect_receiver.base_effect.parallel) == "number"
        and machine.effect_receiver.base_effect.parallel ~= 0

    local allow_parallel = machine.allow_parallel
    if allow_parallel == nil then
        allow_parallel = type(machine.allowed_effects) == "table"
            and utils.table_contains_value(machine.allowed_effects, "speed")
            and utils.table_contains_value(machine.allowed_effects, "productivity")
            and utils.table_contains_value(machine.allowed_effects, "consumption")
            and utils.table_contains_value(machine.allowed_effects, "pollution")
    end

    local can_i_stick_the_module_in_there =
        has_parallel_module_category(machine)
        and allow_parallel
        and (machine.quality_affects_module_slots or (machine.module_slots or 0) >= 1)

    return has_base_parallel or can_i_stick_the_module_in_there
end

local machines_that_meet_basic_criteria = {}
for _, prototype in pairs {
    "assembling-machine",
    "rocket-silo",
    "furnace",
} do
    for _, machine in pairs(data.raw[prototype] or {}) do
        if can_machine_be_parallelized(machine) then
            table.insert(machines_that_meet_basic_criteria, machine)
        end
    end
end

-- step 3: determine recipes that meet basic criteria

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
    if not recipe.ingredients then return false end
    if not recipe.results then return false end
    if table_size(recipe.ingredients) == 0 then return false end
    if table_size(recipe.results) == 0 then return false end
    if recipe.allow_speed == false then return false end
    if recipe.allow_parallel == false then return false end
    if recipe.name:match("%-barrel$") then return false end
    if not has_parallel_module_category(recipe) then return false end

    for _, category in pairs(recipe.categories or {"crafting"}) do
        local category = data.raw["recipe-category"][category]
        if category and category.parallel_blacklist == true then return false end
    end

    -- ensure recipes with results with the "non-stackable" flag are not parallelized
    for _, result in pairs(recipe.results) do
        if result.type == "item" and type(result.name) == "string" and has_non_stackable_flag(result.name) then
            return false
        end
    end

    return true
end

local recipes_that_meet_basic_criteria = {}
for _, recipe in pairs(data.raw.recipe) do
    if can_recipe_be_parallelized(recipe) then
        table.insert(recipes_that_meet_basic_criteria, recipe)
    end
end

-- step 4: find union of recipe categories between recipes and machines

local allowed_recipe_categories = {}
do
    local in_machines = {}
    for _, machine in pairs(machines_that_meet_basic_criteria) do
        for _, category in pairs(machine.crafting_categories or {}) do
            in_machines[category] = true
        end
    end

    for _, recipe in pairs(recipes_that_meet_basic_criteria) do
        for _, category in pairs(recipe.categories or {"crafting"}) do
            if in_machines[category] then
                allowed_recipe_categories[category] = true
            end
        end
    end
end

-- step 5: create final list of allowed recipes and machines

assert(table_size(mod_data.allowed_machines) == 0)
assert(table_size(mod_data.allowed_recipes) == 0)

for _, machine in pairs(machines_that_meet_basic_criteria) do
    for _, category in pairs(machine.crafting_categories or {}) do
        if allowed_recipe_categories[category] then
            mod_data.allowed_machines[machine.name] = machine.type
        end
    end
end

for _, recipe in pairs(recipes_that_meet_basic_criteria) do
    for _, category in pairs(recipe.categories or {"crafting"}) do
        if allowed_recipe_categories[category] then
            mod_data.allowed_recipes[recipe.name] = true
        end
    end
end
