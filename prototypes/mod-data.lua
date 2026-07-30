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
            -- Maximum parallel allowed for any machine; must be an integer
            max_total_parallel = 64, -- +64% = 64x


            -- Which types of crafting machine to consider for parallel modules and relevant recipes
            -- COMPAT: don't change this unless you really need to
            crafting_machine_types = {
                "assembling-machine",
                "rocket-silo"
            },

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

            -- Crafting categories to explicitly prevent from using parallel
            -- COMPAT: this is the easiest way to exclude a collection of recipes
            -- WARN: append, don't overwrite, to keep values added by other mods
            disallowed_crafting_categories = {
                "tiberium-reprocessing",
                "cosmic_incubator",
                "ammunition",
                "incineration",
                "fuel-incineration",
                "recycling"
            },
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
        name = "parallel_module_mod_parallel_value_cache",
        type = "mod-data",
        data = {}
    },
    {
    -- Internal use only
        name = "spoilable_parallel_modules",
        type = "mod-data",
        data = {}
    },
    {
    -- Internal use only
        name = "parallel_module_mod_entity_to_base_parallel",
        type = "mod-data",
        data = {}
    }
})