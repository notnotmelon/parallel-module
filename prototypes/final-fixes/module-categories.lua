local parallel_module_mod_data = data.raw["mod-data"].parallel_module_mod_data.data
local additional_default_categories = parallel_module_mod_data.additional_default_categories

local types_with_allowed_module_categories = {
    "assembling-machine",
    "furnace",
    "beacon",
    "lab",
    "mining-drill",
    "recipe",
    "rocket-silo",
    data.raw["agricultural-tower"] and "agricultural-tower" or nil
}

-- Update default allowed module categories
local base_module_categories
ModuleCategoryDefaults = ModuleCategoryDefaults
if ModuleCategoryDefaults and ModuleCategoryDefaults.default_categories then
    base_module_categories = ModuleCategoryDefaults.default_categories
else
    base_module_categories = { "speed", "efficiency", "productivity" }
    if mods["quality"] then
        table.insert(base_module_categories, "quality")
    end
end
for _, category in pairs(additional_default_categories) do
    if data.raw["module-category"][category] then
        table.insert(base_module_categories, category)
    end
end
local base_module_category_mask = {}
for _, category in pairs(base_module_categories) do
    base_module_category_mask[category] = true
end

local module_categories_with_explicit_entity_rules = {}
local module_categories_with_explicit_recipe_rules = {}
for _, prototype_type in pairs(types_with_allowed_module_categories) do
    local is_recipe = prototype_type == "recipe"
    for _, prototype in pairs(data.raw[prototype_type]) do
        if prototype.allowed_module_categories then
            for _, category in pairs(prototype.allowed_module_categories) do
                if not base_module_category_mask[category] then
                    if is_recipe then
                        module_categories_with_explicit_recipe_rules[category] = true
                    else
                        module_categories_with_explicit_entity_rules[category] = true
                    end
                end
            end
        end
    end
end

-- Normalize prototypes' allowed_module_categories
local base_categories_recipe = table.deepcopy(base_module_categories)
local base_category_mask_recipe = table.deepcopy(base_module_category_mask)
local base_categories_entity = table.deepcopy(base_module_categories)
local base_category_mask_entity = table.deepcopy(base_module_category_mask)
for _, category in pairs(data.raw["module-category"]) do
    if not base_module_category_mask[category.name] then
        if not module_categories_with_explicit_recipe_rules[category.name] then
            table.insert(base_categories_recipe, category.name)
            base_category_mask_recipe[category.name] = true
        end
        if not module_categories_with_explicit_entity_rules[category.name] then
            table.insert(base_categories_entity, category.name)
            base_category_mask_entity[category.name] = true
        end
    end
end

for _, prototype_type in pairs(types_with_allowed_module_categories) do
    local is_recipe = prototype_type == "recipe"
    for _, prototype in pairs(data.raw[prototype_type]) do
        if not prototype.allowed_module_categories then
            prototype.allowed_module_categories = table.deepcopy(is_recipe and base_categories_recipe or base_categories_entity)
            goto continue
        end
        if table_size(prototype.allowed_module_categories) == 0 then
            goto continue
        end

        local base_category_mask_typed = is_recipe and base_category_mask_recipe or base_category_mask_entity
        for _, category in pairs(prototype.allowed_module_categories) do
            if not base_category_mask_typed[category] then
                goto continue
            end
        end

        prototype.allowed_module_categories = table.deepcopy(is_recipe and base_categories_recipe or base_categories_entity)
        ::continue::
    end
end