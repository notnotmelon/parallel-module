data:extend {{
    name = "parallel-module",
    type = "mod-data",
    -- internal use only, do not edit these
    data = {
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
}}
