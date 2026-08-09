return {
    technology_prerequsites = function(tier)
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
    end,
    add_science_packs = function(technology, tier)
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
    end,
    module_ingredients = function(tier)
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
    end,
}
