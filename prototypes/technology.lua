local is_space_age = mods["space-age"] ~= nil

data:extend({
  {
    effects = {
      {
        recipe = "parallel-module",
        type = "unlock-recipe"
      }
    },
    icon = "__parallel-module__/graphics/technology/parallel-module-1.png",
    icon_size = 256,
    name = "parallel-module",
    prerequisites = {
      "modules"
    },
    type = "technology",
    unit = {
      count = 50,
      ingredients = {
        {
          "automation-science-pack",
          1
        },
        {
          "logistic-science-pack",
          1
        }
      },
      time = 30
    },
    upgrade = true
  },
  {
    effects = {
      {
        recipe = "parallel-module-2",
        type = "unlock-recipe"
      }
    },
    icon = "__parallel-module__/graphics/technology/parallel-module-2.png",
    icon_size = 256,
    name = "parallel-module-2",
    prerequisites = {
      "parallel-module"
    },
    type = "technology",
    unit = {
      count = (is_space_age and 200) or 75,
      ingredients = {
        {
          "automation-science-pack",
          1
        },
        {
          "logistic-science-pack",
          1
        },
        {
          "chemical-science-pack",
          1
        }
      },
      time = 30
    },
    upgrade = true
  },
  {
    effects = {
      {
        recipe = "parallel-module-3",
        type = "unlock-recipe"
      }
    },
    icon = "__parallel-module__/graphics/technology/parallel-module-3.png",
    icon_size = 256,
    name = "parallel-module-3",
    prerequisites = {
      "parallel-module-2"
    },
    type = "technology",
    unit = {
      count = (is_space_age and 2000) or 300,
      ingredients = {
        {
          "automation-science-pack",
          1
        },
        {
          "logistic-science-pack",
          1
        },
        {
          "chemical-science-pack",
          1
        }
      },
      time = 60
    },
    upgrade = true
  }
})

if is_space_age then
  table.insert(data.raw.technology["parallel-module-2"].prerequisites, "space-science-pack")
  table.insert(data.raw.technology["parallel-module-2"].unit.ingredients, {"space-science-pack", 1})
  table.insert(data.raw.technology["parallel-module-3"].unit.ingredients, {"space-science-pack", 1})
  if not mods["planet-crucible"] then
    table.insert(data.raw.technology["parallel-module-3"].prerequisites, "kovarex-enrichment-process")
    table.insert(data.raw.technology["parallel-module-3"].prerequisites, "production-science-pack")
    table.insert(data.raw.technology["parallel-module-3"].prerequisites, "utility-science-pack")
    table.insert(data.raw.technology["parallel-module-3"].unit.ingredients, {"production-science-pack", 1})
    table.insert(data.raw.technology["parallel-module-3"].unit.ingredients, {"utility-science-pack", 1})
  end
else
    table.insert(data.raw.technology["parallel-module-3"].prerequisites, "production-science-pack")
    table.insert(data.raw.technology["parallel-module-3"].unit.ingredients, {"production-science-pack", 1})
end