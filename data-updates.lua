local utils = require("__parallel-module__.utils")
local data_utils = require("__parallel-module__.data-utils")

if mods["Krastorio2"] then
    require("__parallel-module__.compat.Krastorio2-updates")
end

local mod_data = data.raw["mod-data"].parallel_module_mod_data.data
local crushing_categories = {}
for category, _ in pairs(data.raw["recipe-category"]) do
    if category:find("crushing", 1, true) then
        crushing_categories[category] = true
    end
end

local asteroid_chunks = {}
for _, chunk in pairs(data.raw["asteroid-chunk"]) do
    if chunk.minable then
        if chunk.minable.result then
            asteroid_chunks[chunk.minable.result] = true
        end
        if chunk.minable.results then
            for _, result in pairs(chunk.results) do
                if result.type == "item" then
                    asteroid_chunks[result.name] = true
                end
            end
        end
    end
end

for name, recipe in pairs(data.raw.recipe) do
    if utils.is_recipe_in_parallel_mod_data(mod_data, name)
        or not recipe.ingredients or #recipe.ingredients == 0
        or not recipe.results or #recipe.results == 0
        or not recipe.categories or #recipe.categories == 0 then
        goto continue
    end

    local is_crushing = false
    for _, category in pairs(recipe.categories) do
        if crushing_categories[category] then
            is_crushing = true
            break
        end
    end
    if not is_crushing then
        goto continue
    end

    local ingredients = {}
    for i, ingredient in ipairs(recipe.ingredients) do
        if ingredient.type == "item" then
            ingredients[ingredient.name] = i
        end
    end

    local has_asteroid_chunk_result = false
    local result_idx = nil
    for i, result in ipairs(recipe.results) do
        if result.type == "item" then
            if asteroid_chunks[result.name] then
                if has_asteroid_chunk_result then
                    -- Disallow parallel for asteroid reprocessing (and similar)
                    table.insert(mod_data.disallowed_recipes, name)
                    goto continue
                end

                has_asteroid_chunk_result = true
            end

            if data_utils.is_result_valid_parallel_target(result) and ingredients[result.name] then
                if result_idx then
                    -- Disallow parallel for crushing recipes with multiple probabilistic catalysts
                    table.insert(mod_data.disallowed_recipes, name)
                    goto continue
                end

                result_idx = i
            end
        end
    end
    if not result_idx then
        -- No special logic for this crushing recipe
        goto continue
    end

    local result = recipe.results[result_idx]
    if not result.ignored_by_productivity then
        result.ignored_by_productivity = recipe.ingredients[ingredients[result.name]].amount
    end
    mod_data.explicit_recipe_results[name] = result.name
    ::continue::
end