local prototypes_with_allowed_module_categories = {
    "assembling-machine",
    "furnace",
    "rocket-silo",
    "lab",
    "mining-drill",
    "beacon",
    "recipe",
    data.raw["agricultural-tower"] and "agricultural-tower" or nil,
}

local all_module_categories = {}
for _, module_category in pairs(data.raw["module-category"]) do
    table.insert(all_module_categories, module_category.name)
end

local function remove_parallel_from_allowed_categories(recipe_or_machine)
    recipe_or_machine.allowed_module_categories =
        recipe_or_machine.allowed_module_categories or all_module_categories

    local new_module_categories = {}
    for _, category in pairs(recipe_or_machine.allowed_module_categories) do
        if not parallel.module_categories_that_give_parallel[category] then
            table.insert(new_module_categories, category)
        end
    end

    recipe_or_machine.allowed_module_categories = new_module_categories
end

-- remove all parallel module categories for disallowed machines
for _, prototype in pairs(prototypes_with_allowed_module_categories) do
    for _, recipe_or_machine in pairs(data.raw[prototype]) do
        if recipe_or_machine.type == "recipe" then
            if not mod_data.allowed_recipes[recipe_or_machine.name] then
                remove_parallel_from_allowed_categories(recipe_or_machine)
            end
        else
            if not mod_data.allowed_machines[recipe_or_machine.name] then
                remove_parallel_from_allowed_categories(recipe_or_machine)
            end
        end
    end
end

-- remove the parallel module category for allowed machines

local function add_parallel_to_allowed_categories(recipe_or_machine)
    if not parallel.has_parallel_module_category(recipe_or_machine) then
        table.insert(recipe_or_machine.allowed_module_categories, "parallel")
    end
end

for name, prototype in pairs(mod_data.allowed_machines) do
    add_parallel_to_allowed_categories(data.raw[prototype][name])
end
for name in pairs(mod_data.allowed_recipes) do
    add_parallel_to_allowed_categories(data.raw.recipe[name])
end
