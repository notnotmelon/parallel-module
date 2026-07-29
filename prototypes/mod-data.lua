local utils = require("__parallel-module__.utils")

data:extend({
    ---------------------------------------------------------------------------
    --- SETTINGS AND COMPATIBILITY
    ---------------------------------------------------------------------------
    --- NOTE for other modders: Instructions are provided in comments for if/how
    --- your mod should alter these values for compatibility. This should happen
    --- in your mod's data-updates.lua
    ---------------------------------------------------------------------------
    {
        name = "parallel_module_mod_data",
        type = "mod-data",
        data = {
            -- Maximum possible parallel from non-module effect sources (machines, surfaces, etc.)
            -- DEPRECATED: this is unused
            max_parallel_wihtout_modules = 0,

            -- Parallel of the highest quality of the highest tier of parallel module
            -- DEPRECATED: this is now calculated automatically
            max_parallel_per_module = 200,

            -- Maximum parallel allowed for any machine; must be a multiple of round_parallel_to_nearest
            -- COMPAT: a very high value will require coarser rounding (a larger value for round_parallel_to_nearest)
            max_total_parallel = 2400, -- +2400% = 25x

            -- Practical implementation necessity
            -- COMPAT: change this only if other changes make this an unreasonable rounding quantity
            round_parallel_to_nearest = 25,

            -- Maximum probability value of a recipe product for which parallel will be automatically applied
            -- COMPAT: explicit_recipe_results and extra_count_fraction_recipe_results have higher priority
            maximum_probability_valid_for_parallel = 0.5,

            -- Used to calculate parallel per module tier with formula:
            -- ax^2 + bx + c, where
            --   x = tier
            --   a = parallel_formula_coefficients[1]
            --   b = parallel_formula_coefficients[2]
            --   c = parallel_formula_coefficients[3]
            -- Default value gives: T1->30, T2->50, T3->80
            -- COMPAT: change this if your mod breaks parallel module balance, e.g. by adding more module tiers, module slots, qualities, etc.
            parallel_formula_coefficients = utils.is_quality_enabled() and { 5, 5, 20 } or { 5, 15, 10 },

            -- Which types of crafting machine to consider for parallel modules and relevant recipes
            -- COMPAT: don't change this unless you really need to
            crafting_machine_types = {
                "assembling-machine",
                "furnace"
            },

            -- Recipes in recycling categories are prevented from using parallel, for balance and bloat; only recycling recipes specified here are allowed
            -- COMPAT: Recycling categories are all crafting categories that contain the substring 'recylcing'
            -- WARN: append, don't overwrite, to keep values added by other mods
            allowed_recycling_recipes = {
                "scrap-recycling",
            },

            -- Crafting categories to explicitly prevent from using parallel
            -- COMPAT: this is the easiest way to exclude a collection of recipes
            -- WARN: append, don't overwrite, to keep values added by other mods
            disallowed_crafting_categories = {
                "tiberium-reprocessing",
                "cosmic_incubator",
                "ammunition"
            },

            -- Recipes to explicitly prevent from using parallel
            -- COMPAT: this is the easiest way to exclude a recipe
            -- WARN: append, don't overwrite, to keep values added by other mods
            disallowed_recipes = {},

            -- Dictionary of [recipe -> output]; must be used for any recipe where the desired output is not the output with the (exclusively) smallest probability
            -- COMPAT: this is especially useful for recipes like scrap recycling, with multiple products sharing the smallest probability
            -- WARN: append, don't overwrite, to keep values added by other mods
            explicit_recipe_results = {
                ["scrap-recycling"] = "holmium-ore"
            },

            -- Dictionary of [recipe -> output idx]; must be used instead of explicit_recipe_results if multiple results share same name
            -- COMPAT: this is especially useful for recipes like scrap recycling, with multiple products sharing the smallest probability
            -- WARN: append, don't overwrite, to keep values added by other mods
            explicit_recipe_result_indices = {
                ["muluna-diffused-plastic"] = 2
            },

            -- Recipes without a probabilistic result to explicitly allowed parallel
            -- COMPAT: use this if a recipe needs to accept parallel modules despite parallel having no effect (added for Tellus compatibility)
            -- WARN: append, don't overwrite, to keep values added by other mods
            explicit_recipes_without_results = {},

            -- Crafting machine entities that would normally not allow parallel to explicitly allowed parallel
            -- COMPAT: use this if an entity needs to accept parallel modules despite parallel having no effect (added for Tellus compatibility)
            -- WARN: append, don't overwrite, to keep values added by other mods
            explicit_entities = {},

            -- Dictionary of [name -> parallel]; adds "base" parallel value to a crafting machine prototype
            -- NOTE: this should usually be a multiple of 'round_parallel_to_nearest'
            -- WARN: append, don't overwrite, to keep values added by other mods
            entity_to_base_parallel = {},

            -- Dictionary of [recipe -> output]; must be used for any recipe where the 'extra_count_fraction', instead of the 'probability', will be affected
            -- COMPAT: this is also a workaround for recipes where the parallel-affected output appears more than once in the products
            -- WARN: append, don't overwrite, to keep values added by other mods
            extra_count_fraction_recipe_results = {},

            -- Module categories to be considered "default", i.e. that should be treated like vanilla module categories
            -- COMPAT: if this mod is removing module categories from crafting machines and/or recipes, adding them here should restore them 
            -- NOTE: this is discarded at the end of the data stage and is not available at runtime
            -- WARN: append, don't overwrite, to keep values added by other mods
            additional_default_categories = {
                "arcanyx-curse",
                "azure-speed"
            },

            ---------------------------------------------------------------------------
            --- COMPATIBILITY MODE SETTINGS
            ---------------------------------------------------------------------------
            --- These settings are only read if compatibility mode is enabled. In
            --- compatibility mode, rather than evaluating all recipes, only recipes
            --- that belong to a whitelisted category, or are whitelisted themselves,
            --- are evaluated.
            --- See settings.startup["parallel-module-compatibility-mode"].
            ---------------------------------------------------------------------------
            
            --- Dictionary of [recipe category -> true], of recipe categories to evaluate when in compatibility mode
            --- COMPAT: add to this list judiciously, especially for vanilla categories
            compatibility_mode_category_whitelist = {},

            --- Dictionary of [recipe -> true], of recipes to evaluate when in compatibility mode
            --- COMPAT: add to this list judiciously
            compatibility_mode_recipe_whitelist = {}
        }
    },
    
    ---------------------------------------------------------------------------
    --- INTERNAL USE ONLY
    ---------------------------------------------------------------------------
    {
    -- Internal use only
        name = "parallel_module_mod_recipe_table",
        type = "mod-data",
        data = {}
    },
    {
    -- Internal use only
        name = "parallel_module_mod_recipe_table_inverse",
        type = "mod-data",
        data = {}
    },
    {
    -- Internal use only
        name = "parallel_module_mod_crafting_machine_table",
        type = "mod-data",
        data = {}
    },
    {
    -- Internal use only
        name = "parallel_module_mod_crafting_machine_table_inverse",
        type = "mod-data",
        data = {}
    },
    {
    -- Internal use only
        name = "parallel_module_mod_parallel_value_cache",
        type = "mod-data",
        data = {}
    },
    {
    -- Internal use only
        name = "crafting_machine_to_fixed_base_recipe",
        type = "mod-data",
        data = {}
    },
    {
    -- Internal use only
        name = "spoilable_parallel_modules",
        type = "mod-data",
        data = {}
    }
})