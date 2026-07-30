local item_sounds = require("__base__.prototypes.item_sounds")

-- Add module effect in data-final-fixes to prevent other mods from incorrectly classifying parallel modules as efficiency modules
data:extend({
  {
    type = "module",
    name = "parallel-module",
    icon = "__parallel-module__/graphics/icons/parallel-module.png",
    icon_size = 64,
    subgroup = "module",
    category = "parallel",
    tier = 1,
    order = "e[parallel]-a[parallel-module-1]",
    inventory_move_sound = item_sounds.module_inventory_move,
    pick_sound = item_sounds.module_inventory_pickup,
    drop_sound = item_sounds.module_inventory_move,
    stack_size = 50,
    weight = 20 * kg,
    effect = {
      consumption = 0.3,
      pollution = 0.25,
      speed = -1.0,
      productivity = -0.04,
      parallel = 1.00
    },
    speed_quality_multiplier = 1.0,
  },
  {
    type = "module",
    name = "parallel-module-2",
    icon = "__parallel-module__/graphics/icons/parallel-module-2.png",
    icon_size = 64,
    subgroup = "module",
    category = "parallel",
    tier = 2,
    order = "e[parallel]-b[parallel-module-2]",
    inventory_move_sound = item_sounds.module_inventory_move,
    pick_sound = item_sounds.module_inventory_pickup,
    drop_sound = item_sounds.module_inventory_move,
    stack_size = 50,
    weight = 20 * kg,
    effect = {
      consumption = 0.4,
      pollution = 0.5,
      speed = -0.8,
      productivity = -0.02,
      parallel = 1.00
    },
    speed_quality_multiplier = 1.0,
  },
  {
    type = "module",
    name = "parallel-module-3",
    icon = "__parallel-module__/graphics/icons/parallel-module-3.png",
    icon_size = 64,
    subgroup = "module",
    category = "parallel",
    tier = 3,
    order = "e[parallel]-c[parallel-module-3]",
    inventory_move_sound = item_sounds.module_inventory_move,
    pick_sound = item_sounds.module_inventory_pickup,
    drop_sound = item_sounds.module_inventory_move,
    stack_size = 50,
    weight = 20 * kg,
    effect = {
      consumption = 0.5,
      pollution = 0.75,
      speed = -0.6,
      productivity = -0.00,
      parallel = 1.00
    },
    speed_quality_multiplier = 1.0,
  },
})
