data:extend {{
    type = "bool-setting",
    name = "parallel-module-allow-in-furnaces",
    setting_type = "startup",
    default_value = false,
    order = "a",
}}

data:extend {{
    type = "int-setting",
    name = "parallel-module-max-ingredient-product-amount",
    setting_type = "startup",
    default_value = 5000,
    miniumum_value = 100,
    maximum_value = 65535,
    order = "b",
}}
