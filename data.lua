if mods["Krastorio2"] then
    require("__parallel-module__.compat.Krastorio2-recipe")
else
    require("__parallel-module__.prototypes.recipe")
end

require("__parallel-module__.prototypes.mod-data")
require("__parallel-module__.prototypes.item")
require("__parallel-module__.prototypes.technology")
require("__parallel-module__.prototypes.achievement")

if mods["secretas"] then
    require("__parallel-module__.compat.secretas")
end