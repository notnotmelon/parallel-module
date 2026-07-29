if mods["Krastorio2"] then
    require("__rigor-module__.compat.Krastorio2-recipe")
else
    require("__rigor-module__.prototypes.recipe")
end

require("__rigor-module__.prototypes.mod-data")
require("__rigor-module__.prototypes.item")
require("__rigor-module__.prototypes.technology")
require("__rigor-module__.prototypes.achievement")
-- TODO: Enable if `on_tick` is disabled
-- require("__rigor-module__.prototypes.custom-input")

if mods["secretas"] then
    require("__rigor-module__.compat.secretas")
end