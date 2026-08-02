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
            allowed_machines = {},
            allowed_recipes = {},
            recipe_table = {},
            recipe_table_inverse = {},
            parallel_value_cache = {},
            spoilable_modules = {},
            entity_to_base_parallel = {},
            crafting_machine_types = {
                "assembling-machine",
                "rocket-silo",
                "furnace",
            },
        },
    },
}
