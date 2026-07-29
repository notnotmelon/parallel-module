local categories = data.raw.recipe["speed-module"].categories

local rigor_module_3_ingredients = {
  {
    amount = 4,
    name = "rigor-module-2",
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
  table.insert(rigor_module_3_ingredients, {
    amount = 1,
    name = "uranium-235",
    type = "item"
  })
end

data:extend({
  {
    name = "rigor-module",
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
        name = "rigor-module",
        type = "item"
      }
    }
  },
  {
    name = "rigor-module-2",
    type = "recipe",
    categories = categories,
    enabled = false,
    energy_required = 30,
    ingredients = {
      {
        amount = 4,
        name = "rigor-module",
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
        name = "rigor-module-2",
        type = "item"
      }
    }
  },
  {
    name = "rigor-module-3",
    type = "recipe",
    categories = categories,
    enabled = false,
    energy_required = 60,
    ingredients = rigor_module_3_ingredients,
    results = {
      {
        amount = 1,
        name = "rigor-module-3",
        type = "item"
      }
    }
  },
})
