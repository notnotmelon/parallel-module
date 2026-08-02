data:extend {
    ---------------------------------------------------------------------------
    --- SETTINGS AND COMPATIBILITY
    ---------------------------------------------------------------------------
    --- NOTE for other modders: Instructions are provided in comments for if/how
    --- your mod should alter these values for compatibility. This should happen
    --- in your mod's data-updates.lua
    ---------------------------------------------------------------------------
    {
        name = "parallel-module",
        type = "mod-data",
        data = {
            -- Maximum parallel allowed for any machine; must be an integer
            max_total_parallel = 64, -- +64000% = 64x


            -- Which types of crafting machine to consider for parallel modules and relevant recipes
            -- COMPAT: don't change this unless you really need to
            crafting_machine_types = {
                "assembling-machine",
                "rocket-silo",
                "furnace",
            },

            -- Module categories to be considered "default", i.e. that should be treated like vanilla module categories
            -- COMPAT: if this mod is removing module categories from crafting machines and/or recipes, adding them here should restore them
            -- NOTE: this is discarded at the end of the data stage and is not available at runtime
            -- WARN: append, don't overwrite, to keep values added by other mods
            additional_default_categories = {
                "arcanyx-curse",
                "azure-speed",
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
                "recycling",
            },

            -- internal use only
            recipe_table = {},
            recipe_table_inverse = {},
            parallel_value_cache = {},
            spoilable_modules = {},
            entity_to_base_parallel = {},
            allowed_machines = {},
        },
    },
}
