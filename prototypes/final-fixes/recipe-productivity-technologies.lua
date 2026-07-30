local base_recipe_to_altered_recipes = data.raw["mod-data"].parallel_module_mod_recipe_table.data

-------------------------------------------------------------------------------
--- TECHNOLOGIES
-------------------------------------------------------------------------------

for _, technology in pairs(data.raw.technology) do
    if not technology.effects then
        goto continue
    end

    local base_unlock_recipes = {}
    local base_productivity_recipes = {}
    for _, effect in pairs(technology.effects) do
        if effect.type == "unlock-recipe" then
            table.insert(base_unlock_recipes, effect.recipe)
        elseif effect.type == "change-recipe-productivity" then
            base_productivity_recipes[effect.recipe] = effect.change
        end
    end

    for _, base_recipe in pairs(base_unlock_recipes) do
        local altered_recipes = base_recipe_to_altered_recipes[base_recipe]
        if altered_recipes == nil then
            goto continue
        end

        for _, altered_recipe in pairs(altered_recipes) do
            if altered_recipe ~= base_recipe then
                table.insert(technology.effects, {
                    type   = "unlock-recipe",
                    recipe = altered_recipe,
                    hidden = true
                })
            end
        end
        ::continue::
    end

    for base_recipe, change in pairs(base_productivity_recipes) do
        local altered_recipes = base_recipe_to_altered_recipes[base_recipe]
        if altered_recipes == nil then
            goto continue
        end

        for _, altered_recipe in pairs(altered_recipes) do
            if altered_recipe ~= base_recipe then
                table.insert(technology.effects, {
                    type   = "change-recipe-productivity",
                    recipe = altered_recipe,
                    change = change,
                    hidden = true
                })
            end
        end
        ::continue::
    end
    ::continue::
end
