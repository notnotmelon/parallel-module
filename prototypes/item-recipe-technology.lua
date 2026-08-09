local item_sounds = require("__base__.prototypes.item_sounds")

local effects = {
    {
        pollution = 0.25,
        speed = -1.0,
        parallel = mods.quality and 1.00 or 1.00,
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
    {
        pollution = 1.25,
        speed = -0.35,
        parallel = mods.quality and 1.00 or 5.00,
    },
    {
        pollution = 1.5,
        speed = -0.3,
        parallel = mods.quality and 1.00 or 6.00,
    },
    {
        pollution = 1.75,
        speed = -0.3,
        parallel = mods.quality and 1.25 or 7.00,
    },
    {
        pollution = 2.0,
        speed = -0.3,
        parallel = mods.quality and 1.5 or 8.00,
    },
    {
        pollution = 2.5,
        speed = -0.3,
        parallel = mods.quality and 2.00 or 9.00,
    },
}

local letters = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o"}

local function get_icon(suffix, tier)
    if mods["space-exploration"] or tier >= 5 then
        return "__parallel-module__/graphics/icons/space-exploration/parallel-module" .. suffix .. ".png"
    end

    return "__parallel-module__/graphics/icons/parallel-module" .. suffix .. ".png"
end
local function get_technology_icon(suffix, tier)
    if mods["space-exploration"] or tier >= 5 then
        return "__parallel-module__/graphics/technology/space-exploration/parallel-module" .. suffix .. ".png"
    end

    return "__parallel-module__/graphics/technology/parallel-module" .. suffix .. ".png"
end
local function get_technology_icon_size()
    return mods["space-exploration"] and 128 or 64
end
local function space_exploration_ingredients(tier)
    local ingredients = {
        {
            {type = "item", name = "electronic-circuit", amount = 30},
            {type = "item", name = "refined-concrete",   amount = 20},
        },
        {
            {type = "item", name = "parallel-module",  amount = 2},
            {type = "item", name = "advanced-circuit", amount = 30},
            {type = "item", name = "se-methane-ice",   amount = 30},
        },
        {
            {type = "item",  name = "parallel-module-2",          amount = 2},
            {type = "item",  name = "processing-unit",            amount = 30},
            {type = "fluid", name = "se-contaminated-bio-sludge", amount = 100},
        },
        {
            {type = "item", name = "parallel-module-3",        amount = 2},
            {type = "item", name = "se-naquium-plate",         amount = 90},
            {type = "item", name = "se-machine-learning-data", amount = 1},
        },
        {
            {type = "item", name = "parallel-module-4",   amount = 2},
            {type = "item", name = "se-naquium-ingot",    amount = 30},
            {type = "item", name = "se-significant-data", amount = 2},
        },
        {
            {type = "item", name = "parallel-module-5",   amount = 2},
            {type = "item", name = "se-deep-catalogue-1", amount = 2},
            {type = "item", name = "se-naquium-cube",     amount = 40},
        },
        {
            {type = "item", name = "parallel-module-6",    amount = 2},
            {type = "item", name = "se-deep-catalogue-2",  amount = 4},
            {type = "item", name = "se-naquium-tessaract", amount = 30},
        },
        {
            {type = "item",  name = "parallel-module-7",    amount = 2},
            {type = "item",  name = "se-deep-catalogue-3",  amount = 8},
            {type = "item",  name = "se-naquium-processor", amount = 80},
            {type = "fluid", name = "se-proton-stream",     amount = 500},
        },
        {
            {type = "item",  name = "parallel-module-8",   amount = 2},
            {type = "item",  name = "se-deep-catalogue-4", amount = 10},
            {type = "item",  name = "se-void-probe",       amount = 10},
            {type = "fluid", name = "se-particle-stream",  amount = 1000},
        },
    }

    return ingredients[tier]
end
local function space_exploration_technology_prerequsites(tier)
    local prerequisites = {
        {"modules",           "concrete"},
        {"parallel-module",   "se-processing-methane-ice"},
        {"parallel-module-2", "se-space-supercomputer-1",   "se-space-growth-facility"},
        {"parallel-module-3", "se-processing-naquium"},
        {"parallel-module-4"},
        {"parallel-module-5", "se-naquium-cube",            "se-deep-catalogue-1"},
        {"parallel-module-6", "se-naquium-tessaract",       "se-deep-catalogue-2"},
        {"parallel-module-7", "se-naquium-processor",       "se-deep-catalogue-3"},
        {"parallel-module-8", "se-space-particle-collider", "se-deep-catalogue-4"},
    }

    return prerequisites[tier]
end
local function add_space_exploration_science_packs(technology, tier)
    local science_packs = {
        {"automation-science-pack", "logistic-science-pack"},
        {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "se-rocket-science-pack", "space-science-pack"},
        {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "se-rocket-science-pack", "space-science-pack", "production-science-pack", "utility-science-pack", "se-astronomic-science-pack-1", "se-material-science-pack-1"},
        {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "se-rocket-science-pack", "space-science-pack", "production-science-pack", "utility-science-pack", "se-astronomic-science-pack-4", "se-material-science-pack-4"},
        {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "se-rocket-science-pack", "space-science-pack", "production-science-pack", "utility-science-pack", "se-astronomic-science-pack-4", "se-material-science-pack-4", "se-deep-space-science-pack-1"},
        {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "se-rocket-science-pack", "space-science-pack", "production-science-pack", "utility-science-pack", "se-astronomic-science-pack-4", "se-material-science-pack-4", "se-energy-science-pack-4",    "se-deep-space-science-pack-1"},
        {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "se-rocket-science-pack", "space-science-pack", "production-science-pack", "utility-science-pack", "se-astronomic-science-pack-4", "se-material-science-pack-4", "se-energy-science-pack-4",    "se-deep-space-science-pack-2"},
        {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "se-rocket-science-pack", "space-science-pack", "production-science-pack", "utility-science-pack", "se-astronomic-science-pack-4", "se-material-science-pack-4", "se-energy-science-pack-4",    "se-biological-science-pack-4", "se-deep-space-science-pack-3"},
        {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "se-rocket-science-pack", "space-science-pack", "production-science-pack", "utility-science-pack", "se-astronomic-science-pack-4", "se-material-science-pack-4", "se-energy-science-pack-4",    "se-biological-science-pack-4", "se-deep-space-science-pack-4"},
    }

    technology.unit.ingredients = {}
    for _, pack in pairs(science_packs[tier]) do
        table.insert(technology.unit.ingredients, {pack, 1})
        table.insert(technology.prerequisites, pack)
    end
end

for _, suffix in pairs {"", "-2", "-3", "-4", "-4-S", "-5", "-6", "-7", "-8", "-9"} do
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
        icon = get_icon(suffix, base_module.tier),
        icon_size = 64,
        subgroup = mods["space-exploration"] and "module-parallel" or "module",
        category = "parallel",
        tier = base_module.tier,
        order = "e[parallel]-" .. letters[base_module.tier] .. "-[parallel-module" .. suffix .. "]",
        inventory_move_sound = item_sounds.module_inventory_move,
        pick_sound = item_sounds.module_inventory_pickup,
        drop_sound = item_sounds.module_inventory_move,
        stack_size = base_module.stack_size,
        weight = base_module.weight or (20 * kg),
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
        new_recipe.auto_recycle = true

        new_recipe.main_product = "parallel-module" .. suffix
        new_recipe.results = {
            {
                amount = 1,
                name = "parallel-module" .. suffix,
                type = "item",
            },
        }

        if mods["space-exploration"] then
            new_recipe.ingredients = space_exploration_ingredients(base_module.tier)
            if base_module.tier == 3 then new_recipe.categories = {"crafting-with-fluid"} end
        else
            for _, ingredient in pairs(new_recipe.ingredients) do
                if ingredient.name == "speed-module-4-S" then
                    ingredient.name = "parallel-module-4"
                elseif ingredient.name:sub(1, 12) == "speed-module" then
                    ingredient.name = ingredient.name:gsub("^speed%-module", "parallel-module")
                elseif ingredient.name == "tungsten-carbide" and data.raw.item["lithium-plate"] then
                    ingredient.name = "lithium-plate"
                elseif ingredient.name == "tungsten-plate" and data.raw.item["promethium-asteroid-chunk"] then
                    ingredient.name = "promethium-asteroid-chunk"
                end
            end
        end

        data:extend {new_recipe}
    end

    do
        local new_technology = table.deepcopy(base_technology)
        assert(new_technology)

        new_technology.name = "parallel-module" .. suffix
        new_technology.localised_name = {"item-name.parallel-module" .. suffix}
        new_technology.localised_description = {"technology-description.parallel-module"}
        new_technology.icon = get_technology_icon(suffix, base_module.tier)
        new_technology.icon_size = get_technology_icon_size()
        new_technology.icons = nil

        new_technology.effects = {
            {
                recipe = "parallel-module" .. suffix,
                type = "unlock-recipe",
            },
        }

        if mods["space-exploration"] then
            new_technology.prerequisites = space_exploration_technology_prerequsites(base_module.tier)
            add_space_exploration_science_packs(new_technology, base_module.tier)
        else
            for i, prerequisite in pairs(new_technology.prerequisites) do
                if prerequisite == "speed-module-4-S" then
                    new_technology.prerequisites[i] = "parallel-module-4"
                elseif prerequisite:sub(1, 12) == "speed-module" then
                    new_technology.prerequisites[i] = prerequisite:gsub("^speed%-module", "parallel-module")
                end
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

if data.raw.module["parallel-module-3"] then
    data:extend {{
        type = "produce-achievement",
        name = "crafting-with-parallel",
        item_product = "parallel-module-3",
        amount = 1,
        limited_to_one_game = false,
        order = "a[progress]-h[crafting-tier-3-module]-f[parallel]",
        icon = "__parallel-module__/graphics/achievement/crafting-with-parallel.png",
        icon_size = 128,
    }}
end

if mods["space-exploration"] then
    data:extend {{
        type = "item-subgroup",
        name = "module-parallel",
        order = "z-m-b",
        group = "production",
    }}
end
