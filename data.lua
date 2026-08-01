data:extend({
  {
    type = "module-category",
    name = "parallel"
  }
})

require("__parallel-module__.prototypes.mod-data")
require("__parallel-module__.prototypes.item")
require("__parallel-module__.prototypes.recipe")
require("__parallel-module__.prototypes.technology")
require("__parallel-module__.prototypes.achievement")

require("__parallel-module__.compat.secretas")

-- data.raw["assembling-machine"]["chemical-plant"].effect_receiver = {base_effect = {speed = 0.5, parallel = 0.5, pollution = 0.5}}