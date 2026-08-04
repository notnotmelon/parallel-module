data:extend {{
    type = "module-category",
    name = "parallel",
}}
ModuleCategoryDefaults = ModuleCategoryDefaults
table.insert(ModuleCategoryDefaults.default_categories, "parallel")
table.insert(ModuleCategoryDefaults.recipe_default_categories, "parallel")

require "prototypes.mod-data"
require "prototypes.item"
require "prototypes.recipe"
require "prototypes.technology"
require "prototypes.achievement"

require "compat.secretas"
