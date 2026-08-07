local rocket_silo_recipe_categories = {}
for _, rocket_silo in pairs(data.raw["rocket-silo"]) do
    for _, category in pairs(rocket_silo.crafting_categories or {}) do
        rocket_silo_recipe_categories[category] = true
    end
end

local function is_rocket_part_recipe(recipe)
    for _, category in pairs(recipe.categories or {"crafting"}) do
        if rocket_silo_recipe_categories[category] then
            return true
        end
    end
    return false
end

for recipe in pairs(mod_data.allowed_recipes) do
    recipe = data.raw.recipe[recipe]
    if is_rocket_part_recipe(recipe) then
        for num_parallels, parallel_recipe in pairs(mod_data.recipe_table[recipe.name] or {}) do
            assert(type(num_parallels) == "string")
            assert(tostring(tonumber(num_parallels)) == num_parallels)
            if num_parallels ~= "1" then
                parallel_recipe = data.raw.recipe[parallel_recipe]
                assert(not recipe.raise_on_crafted, parallel_recipe.name)
                mod_data.rocket_part_recipes[parallel_recipe.name] = tonumber(num_parallels)
                parallel_recipe.raise_on_crafted = true
            end
        end
    end
end
