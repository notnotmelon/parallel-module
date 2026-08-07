parallel.on_event(parallel.events.on_init(), function()
    storage.rocket_part_overflow = storage.rocket_part_overflow or {}
end)

for rocket_part_recipe, num_parallels in pairs(mod_data.rocket_part_recipes) do
    local prototype = prototypes.recipe[rocket_part_recipe]
    parallel.on_event(prototype.on_crafted_event, function(event)
        local rocket_silo = event.entity
        if rocket_silo.type ~= "rocket-silo" then return end
        local unit_number = rocket_silo.unit_number

        local overflow = storage.rocket_part_overflow[unit_number] or 0
        local additional = (num_parallels - 1) + overflow
        local max = rocket_silo.prototype.rocket_parts_storage_cap * 2

        if rocket_silo.rocket_parts + additional > max then
            storage.rocket_part_overflow[unit_number] = (rocket_silo.rocket_parts + additional) - max
            rocket_silo.rocket_parts = max
        else
            rocket_silo.rocket_parts = rocket_silo.rocket_parts + additional
            storage.rocket_part_overflow[unit_number] = nil
        end
    end)
end

parallel.on_event(defines.events.on_rocket_launch_ordered, function(event)
    local rocket_silo = event.rocket_silo
    if not rocket_silo.valid then return end
    local unit_number = rocket_silo.unit_number
    local overflow = storage.rocket_part_overflow[unit_number]
    if not overflow then return end

    local max = rocket_silo.prototype.rocket_parts_storage_cap * 2
    rocket_silo.rocket_parts = math.min(overflow, max)
    storage.rocket_part_overflow[unit_number] = math.max(0, overflow - max)

    if storage.rocket_part_overflow[unit_number] == 0 then
        storage.rocket_part_overflow[unit_number] = nil
    end
end)

parallel.on_event(parallel.events.on_destroyed(), function(event)
    local entity = event.entity
    if not entity.valid then return end
    local unit_number = entity.unit_number
    if not unit_number then return end
    storage.rocket_part_overflow[unit_number] = nil
end)
