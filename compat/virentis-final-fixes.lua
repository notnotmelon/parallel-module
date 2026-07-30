local mod_data = data.raw["mod-data"].parallel_module_mod_data.data

 -- Recipes removed by Virentis
for name, _ in pairs(data.raw.recipe) do
    if "gmo-" == string.sub(name, 1, 4) then
        table.insert(mod_data.disallowed_recipes, name)
    end
end