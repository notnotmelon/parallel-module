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
