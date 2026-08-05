if not mods["secretas"] then return end

local item_sounds = require("__base__.prototypes.item_sounds")

local categories = data.raw.recipe["speed-module"].categories

local ingredients = nil
if settings.startup["xy-secretas-polish"] and settings.startup["xy-secretas-polish"].value then
    ingredients = {
        {
            amount = 5,
            name = "gold-plate",
            type = "item",
        },
        {
            amount = 4,
            name = "parallel-module-3",
            type = "item",
        },
        {
            amount = 5,
            name = "quantum-processor",
            type = "item",
        },
        {
            amount = 5,
            name = "kr-ai-core",
            type = "item",
        },
        {
            amount = 5,
            name = "uranium-fuel-cell",
            type = "item",
        },
    }
else
    ingredients = {
        {
            amount = 6,
            name = "gold-plate",
            type = "item",
        },
        {
            amount = 4,
            name = "parallel-module-3",
            type = "item",
        },
        {
            amount = 7,
            name = "advanced-circuit",
            type = "item",
        },
        {
            amount = 7,
            name = "processing-unit",
            type = "item",
        },
        {
            amount = 5,
            name = "uranium-fuel-cell",
            type = "item",
        },
    }
end

data:extend {
    {
        type = "module",
        name = "parallel-module-4",
        icon = "__parallel-module__/graphics/icons/parallel-module-4.png",
        icon_size = 64,
        subgroup = "module",
        category = "parallel",
        tier = 4,
        order = "e[parallel]-d[parallel-module-4]",
        localised_name = {"", {"item-name.parallel-module"}, " 4"},
        localised_description = {"item-description.parallel-module"},
        inventory_move_sound = item_sounds.module_inventory_move,
        pick_sound = item_sounds.module_inventory_pickup,
        drop_sound = item_sounds.module_inventory_move,
        stack_size = 50,
        weight = 25 * kg,
        effect = {
            pollution = 1.0,
            speed = -0.4,
            parallel = mods.quality and 1.00 or 4.00,
        },
        speed_quality_multiplier = 3.0,
        pollution_quality_multiplier = 4.0,
        default_import_location = "frozeta",
    },
    {
        name = "parallel-module-4",
        type = "recipe",
        categories = categories,
        enabled = false,
        localised_name = {"", {"recipe-name.parallel-module"}, " 4"},
        energy_required = 120,
        ingredients = ingredients,
        results = {
            {
                amount = 1,
                name = "parallel-module-4",
                type = "item",
            },
        },
    },
    {
        effects = {
            {
                recipe = "parallel-module-4",
                type = "unlock-recipe",
            },
        },
        icon = "__parallel-module__/graphics/technology/parallel-module-4.png",
        icon_size = 256,
        name = "parallel-module-4",
        prerequisites = {
            "parallel-module-3",
            "golden-science-pack",
        },
        type = "technology",
        localised_name = {"", {"technology-name.parallel-module"}, " 4"},
        unit = {
            count = 2000,
            ingredients = {
                {
                    "automation-science-pack",
                    1,
                },
                {
                    "logistic-science-pack",
                    1,
                },
                {
                    "chemical-science-pack",
                    1,
                },
                {
                    "space-science-pack",
                    1,
                },
                {
                    "production-science-pack",
                    1,
                },
                {
                    "utility-science-pack",
                    1,
                },
                {
                    "metallurgic-science-pack",
                    1,
                },
                {
                    "agricultural-science-pack",
                    1,
                },
                {
                    "electromagnetic-science-pack",
                    1,
                },
                {
                    "cryogenic-science-pack",
                    1,
                },
                {
                    "golden-science-pack",
                    1,
                },
            },
            time = 60,
        },
        upgrade = true,
    },
}
