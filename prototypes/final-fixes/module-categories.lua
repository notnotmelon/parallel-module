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

local function remove_parallel_modules_from_allowed_categories(entity)
    entity.allowed_module_categories = entity.allowed_module_categories or all_module_categories

    local new_module_categories = {}
    for _, category in pairs(entity.allowed_module_categories) do
        if not parallel.module_categories_that_give_parallel[category] then
            table.insert(new_module_categories, category)
        end
    end

    entity.allowed_module_categories = new_module_categories
end

for _, prototype in pairs(prototypes_with_allowed_module_categories) do
    for _, entity in pairs(data.raw[prototype]) do
        if entity.type == "recipe" then
            if not mod_data.allowed_recipes[entity.name] then
                remove_parallel_modules_from_allowed_categories(entity)
            end
        else
            if not mod_data.allowed_machines[entity.name] then
                remove_parallel_modules_from_allowed_categories(entity)
            end
        end
    end
end
