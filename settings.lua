data:extend {{
    type = "bool-setting",
    name = "parallel-module-allow-in-furnaces",
    setting_type = "startup",
    default_value = not not mods.pyalienlife,
    order = "a",
}}

data:extend {{
    type = "string-setting",
    name = "parallel-module-rounding-strictness",
    setting_type = "startup",
    default_value = mods.pyalienlife and "24x" or "never-round",
    order = "b",
    allowed_values = {
        "12x",
        "24x",
        "48x",
        "never-round",
    },
}}

data:extend {{
    type = "int-setting",
    name = "parallel-module-max-ingredient-product-amount",
    setting_type = "startup",
    default_value = 1000,
    miniumum_value = 100,
    maximum_value = 65535,
    order = "c",
}}

data:extend {{
    type = "bool-setting",
    name = "parallel-module-exclude-fluid-recipes",
    setting_type = "startup",
    default_value = false,
    order = "d",
}}
