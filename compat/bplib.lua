assert(mods["bplib"])
local utils = require "utils"

local function register_with_bplib(name)
    local bplib = data.raw["mod-data"]["bplib"]
    bplib.data.extract_entity_names[name] = true
    bplib.data.overlap_entity_names[name] = true
end

local function try_register_entity_with_bp_lib(machine)
    if machine.hidden then return end
    if machine.type == "furnace" then return end
    if (machine.module_slots or 0) <= 0 and not machine.quality_affects_module_slots then return end
    if not utils.table_contains_value(machine.allowed_effects or {}, "parallel") then return end

    for _, category in pairs(machine.crafting_categories) do
        if parallel.crafting_category_to_should_enable_parallel_effect[category] then
            register_with_bplib(machine.name)
            goto continue
        end
        ::continue::
    end
end

for _, machine_type in pairs(mod_data.crafting_machine_types) do
    for _, machine in pairs(data.raw[machine_type]) do
        try_register_entity_with_bp_lib(machine)
    end
end
