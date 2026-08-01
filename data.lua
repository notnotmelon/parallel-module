data:extend({
  {
    type = "module-category",
    name = "parallel"
  }
})

require "prototypes.mod-data"
require "prototypes.item"
require "prototypes.recipe"
require "prototypes.technology"
require "prototypes.achievement"

require "compat.secretas"

-- data.raw["assembling-machine"]["chemical-plant"].effect_receiver = {base_effect = {speed = 0.5, parallel = 0.5, pollution = 0.5}}