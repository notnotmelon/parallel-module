local categories = data.raw.recipe["speed-module"] and data.raw.recipe["speed-module"].categories or nil

local fallbacks = {
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
  },
  {
    name = "parallel-module-3",
    type = "recipe",
    categories = categories,
    enabled = false,
    energy_required = 60,
    ingredients = {
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
      },
      mods["space-age"] and {
        amount = 1,
        name = "quantum-processor",
        type = "item"
      } or nil
    },
  }
}

for i, suffix in pairs{"", "-2", "-3"} do
  local new_recipe = table.deepcopy(data.raw.recipe["speed-module" .. suffix] or fallbacks[i])
  new_recipe.name = "parallel-module" .. suffix
  new_recipe.results = {
    {
      amount = 1,
      name = "parallel-module" .. suffix,
      type = "item"
    }
  }
  for _, ingredient in pairs(new_recipe.ingredients) do
    if ingredient.name == "speed-module" then
      ingredient.name = "parallel-module"
    elseif ingredient.name == "speed-module-2" then
      ingredient.name = "parallel-module-2"
    elseif ingredient.name == "speed-module-3" then
      ingredient.name = "parallel-module-3"
    elseif ingredient.name == "tungsten-carbide" then
      ingredient.name = "quantum-processor"
    end
  end
  data:extend{new_recipe}
end
