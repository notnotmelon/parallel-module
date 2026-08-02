for _, suffix in pairs {"", "-2", "-3"} do
    local source = data.raw.recipe["speed-module" .. suffix]
    local destination = data.raw.recipe["parallel-module" .. suffix]
    if source and destination then
        destination.ingredients = table.deepcopy(source.ingredients)
        for _, ingredient in pairs(destination.ingredients) do
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
    end
end
