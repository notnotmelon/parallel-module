local categories = data.raw.recipe["speed-module"].categories

local parallel_module_3_ingredients = {
  {
    amount = 4,
    name = "parallel-module-2",
    type = "item"
  },
  {
    amount = 5,
    name = "advanced-circuit",
    type = "item"
  },
  {
    amount = 5,
    name = "processing-unit",
    type = "item"
  }
}
if mods["space-age"] then
  table.insert(parallel_module_3_ingredients, {
    amount = 1,
    name = "uranium-235",
    type = "item"
  })
end

data:extend({
  {
    name = "parallel-module",
    type = "recipe",
    categories = categories,
    enabled = false,
    energy_required = 15,
    ingredients = {
      {
        amount = 5,
        name = "electronic-circuit",
        type = "item"
      },
      {
        amount = 5,
        name = "advanced-circuit",
        type = "item"
      }
    },
    results = {
      {
        amount = 1,
        name = "parallel-module",
        type = "item"
      }
    }
  },
  {
    name = "parallel-module-2",
    type = "recipe",
    categories = categories,
    enabled = false,
    energy_required = 30,
    ingredients = {
      {
        amount = 4,
        name = "parallel-module",
        type = "item"
      },
      {
        amount = 5,
        name = "advanced-circuit",
        type = "item"
      },
      {
        amount = 5,
        name = "processing-unit",
        type = "item"
      }
    },
    results = {
      {
        amount = 1,
        name = "parallel-module-2",
        type = "item"
      }
    }
  },
  {
    name = "parallel-module-3",
    type = "recipe",
    categories = categories,
    enabled = false,
    energy_required = 60,
    ingredients = parallel_module_3_ingredients,
    results = {
      {
        amount = 1,
        name = "parallel-module-3",
        type = "item"
      }
    }
  },
})
