if not settings.startup["parallel-module-allow-in-furnaces"].value then return end

local hidden_furnace = table.deepcopy(data.raw.furnace["stone-furnace"])

for name, type in pairs(mod_data.allowed_machines) do
    if type == "furnace" then
        local furnace = table.deepcopy(data.raw.furnace[name])

        furnace.type = "assembling-machine"
        furnace.max_item_product_count = furnace.result_inventory_size
        furnace.ingredient_count = furnace.source_inventory_size
        furnace.source_inventory_size = nil
        furnace.result_inventory_size = nil

        data.raw.furnace[furnace.name] = nil
        data:extend {furnace}
        mod_data.allowed_machines[name] = "assembling-machine"
    end
end

if table_size(data.raw.furnace) == 0 then
    hidden_furnace.name = "hidden-furnace"
    hidden_furnace.hidden = true
    hidden_furnace.next_upgrade = nil
    data:extend {hidden_furnace}
end
