for rocket_part_recipe, num_parallels in pairs(mod_data.rocket_part_recipes) do
    local prototype = prototypes.recipe[rocket_part_recipe]
    if not prototype then goto continue end
    parallel.on_event(prototype.on_crafted_event, function(event)
        local rocket_silo = event.entity
        if rocket_silo.type ~= "rocket-silo" then return end
        rocket_silo.rocket_parts = rocket_silo.rocket_parts + num_parallels - 1
    end)
    ::continue::
end
