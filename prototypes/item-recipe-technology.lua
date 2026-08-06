local item_sounds = require("__base__.prototypes.item_sounds")

local effects = {
    {
        pollution = 0.25,
        speed = -1.0,
        parallel = 1.00,
    },
    {
        pollution = 0.5,
        speed = -0.8,
        parallel = mods.quality and 1.00 or 2.00,
    },
    {
        pollution = 0.75,
        speed = -0.6,
        parallel = mods.quality and 1.00 or 3.00,
    },
    {
        pollution = 1.0,
        speed = -0.4,
        parallel = mods.quality and 1.00 or 4.00,
    },
}

local letters = {"a", "b", "c", "d", "e", "f"}

for _, suffix in pairs {"", "-2", "-3", "-4", "-4-S"} do
    local base_module = data.raw.module["speed-module" .. suffix]
    local base_recipe = data.raw.recipe["speed-module" .. suffix]
    local base_technology = data.raw.technology["speed-module" .. suffix]

    if not base_module then goto continue end
    if not base_recipe then goto continue end
    if not base_technology then goto continue end

    if suffix == "-4-S" then
        suffix = "-4"
    end

    data:extend {{
        type = "module",
        name = "parallel-module" .. suffix,
        localised_description = {"item-description.parallel-module"},
        icon = "__parallel-module__/graphics/icons/parallel-module" .. suffix .. ".png",
        icon_size = 64,
        subgroup = "module",
        category = "parallel",
        tier = base_module.tier,
        order = "e[parallel]-" .. letters[base_module.tier] .. "-[parallel-module" .. suffix .. "]",
        inventory_move_sound = item_sounds.module_inventory_move,
        pick_sound = item_sounds.module_inventory_pickup,
        drop_sound = item_sounds.module_inventory_move,
        stack_size = 50,
        weight = 20 * kg,
        effect = effects[base_module.tier],
        speed_quality_multiplier = 3.0,
        pollution_quality_multiplier = 4.0,
    }}

    do
        local new_recipe = table.deepcopy(base_recipe)
        assert(new_recipe)

        new_recipe.name = "parallel-module" .. suffix
        new_recipe.localised_name = nil
        new_recipe.localised_description = nil
        new_recipe.icon = nil
        new_recipe.icon_size = nil
        new_recipe.icons = nil

        new_recipe.main_product = "parallel-module" .. suffix
        new_recipe.results = {
            {
                amount = 1,
                name = "parallel-module" .. suffix,
                type = "item",
            },
        }

        for _, ingredient in pairs(new_recipe.ingredients) do
            if ingredient.name == "speed-module" then
                ingredient.name = "parallel-module"
            elseif ingredient.name == "speed-module-2" then
                ingredient.name = "parallel-module-2"
            elseif ingredient.name == "speed-module-3" then
                ingredient.name = "parallel-module-3"
            elseif ingredient.name == "speed-module-4" or ingredient.name == "speed-module-4-S" then
                ingredient.name = "parallel-module-4"
            elseif ingredient.name == "tungsten-carbide" and data.raw.item["lithium-plate"] then
                ingredient.name = "lithium-plate"
            elseif ingredient.name == "tungsten-plate" and data.raw.item["promethium-asteroid-chunk"] then
                ingredient.name = "promethium-asteroid-chunk"
            end
        end
        new_recipe.auto_recycle = true
        data:extend {new_recipe}
    end

    do
        local new_technology = table.deepcopy(base_technology)
        assert(new_technology)

        new_technology.name = "parallel-module" .. suffix
        new_technology.localised_name = nil
        new_technology.localised_description = {"technology-description.parallel-module"}
        new_technology.icon = "__parallel-module__/graphics/technology/parallel-module" .. suffix .. ".png"
        new_technology.icon_size = 256
        new_technology.icons = nil

        new_technology.effects = {
            {
                recipe = "parallel-module" .. suffix,
                type = "unlock-recipe",
            },
        }

        for i, prerequisite in pairs(new_technology.prerequisites) do
            if prerequisite == "speed-module" then
                new_technology.prerequisites[i] = "parallel-module"
            elseif prerequisite == "speed-module-2" then
                new_technology.prerequisites[i] = "parallel-module-2"
            elseif prerequisite == "speed-module-3" then
                new_technology.prerequisites[i] = "parallel-module-3"
            elseif prerequisite == "speed-module-4" or prerequisite == "speed-module-4-S" then
                new_technology.prerequisites[i] = "parallel-module-4"
            end
        end

        data:extend {new_technology}
    end

    ::continue::
end

if mods["space-age"] then
    if data.raw.technology["parallel-module-3"] then
        table.insert(data.raw.technology["parallel-module-3"].prerequisites, "cryogenic-science-pack")
        for _, ingredient in pairs(data.raw.technology["parallel-module-3"].unit.ingredients) do
            if ingredient[1] == "metallurgic-science-pack" then
                ingredient[1] = "cryogenic-science-pack"
                break
            end
        end
    end

    if data.raw.technology["parallel-module-4"] then
        table.insert(data.raw.technology["parallel-module-4"].prerequisites, "promethium-science-pack")

        if mods.secretas then
            table.insert(data.raw.technology["parallel-module-4"].prerequisites, "parallel-module-3")
            table.insert(data.raw.technology["parallel-module-4"].unit.ingredients, {"promethium-science-pack", 1})
        else
            for _, ingredient in pairs(data.raw.technology["parallel-module-4"].unit.ingredients) do
                if ingredient[1] == "metallurgic-science-pack" then
                    ingredient[1] = "promethium-science-pack"
                    break
                end
            end
        end
    end
end
