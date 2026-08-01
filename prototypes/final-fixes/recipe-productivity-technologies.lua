local base_recipe_to_altered_recipes = data.raw["mod-data"].parallel_module_mod_recipe_table.data

for _, technology in pairs(data.raw.technology) do
    if not technology.effects then
        goto continue
    end

    local base_productivity_recipes = {}
    for _, effect in pairs(technology.effects) do
        if effect.type == "change-recipe-productivity" then
            base_productivity_recipes[effect.recipe] = effect.change
        end
    end

    for base_recipe, change in pairs(base_productivity_recipes) do
        for _, altered_recipe in pairs(base_recipe_to_altered_recipes[base_recipe] or {}) do
            if altered_recipe ~= base_recipe then
                table.insert(technology.effects, {
                    type   = "change-recipe-productivity",
                    recipe = altered_recipe,
                    change = change,
                    hidden = true
                })
            end
        end
    end
    ::continue::
end
