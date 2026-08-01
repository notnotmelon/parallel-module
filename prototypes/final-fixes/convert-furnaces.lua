local utils = require "utils"

if not settings.startup["parallel-module-allow-in-furnaces"].value then return end

local hidden_furnace = table.deepcopy(data.raw["furnace"]["stone-furnace"])
hidden_furnace.name = "hidden-furnace"
hidden_furnace.hidden = true
hidden_furnace.next_upgrade = nil
data:extend{hidden_furnace}

local function can_be_replaced(furnace)
    if furnace.hidden then return false end
    if (furnace.module_slots or 0) <= 0 and not furnace.quality_affects_module_slots then return false end
    if not utils.table_contains_value(furnace.allowed_effects or {}, "parallel") then return end

    for _, category in pairs(furnace.crafting_categories or {}) do
        if parallel.crafting_category_to_should_enable_parallel_effect[category] then
            return true
        end
    end

    return false
end

for _, furnace in pairs(data.raw.furnace) do
    if can_be_replaced(furnace) then
        local furnace = table.deepcopy(furnace)

        furnace.type = "assembling-machine"
        furnace.max_item_product_count = furnace.result_inventory_size
        furnace.ingredient_count = furnace.source_inventory_size
        furnace.source_inventory_size = nil
        furnace.result_inventory_size = nil

        data:extend{furnace}
        data.raw.furnace[furnace.name] = nil
    end
end
