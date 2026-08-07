for rocket_part_recipe, num_parallels in pairs(mod_data.rocket_part_recipes) do
    local prototype = prototypes.recipe[rocket_part_recipe]
    parallel.on_event(prototype.on_crafted_event, function(event)
        local rocket_silo = event.entity
        if rocket_silo.type ~= "rocket-silo" then return end
        local unit_number = rocket_silo.unit_number

        local overflow = storage.rocket_part_overflow[unit_number] or 0
        local additional = (num_parallels - 1) + overflow

        rocket_silo.rocket_parts = rocket_silo.rocket_parts + additional
    end)
end
