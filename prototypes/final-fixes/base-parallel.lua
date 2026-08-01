local parallel_module_mod_data = data.raw["mod-data"].parallel_module_mod_data.data
local entity_to_base_parallel = data.raw["mod-data"].parallel_module_mod_entity_to_base_parallel.data
local crafting_machine_types = parallel_module_mod_data.crafting_machine_types

function parallel.get_base_parallel(machine)
    if machine.effect_receiver and machine.effect_receiver.base_effect and machine.effect_receiver.base_effect.parallel then
        return math.min(
            parallel_module_mod_data.max_total_parallel,
            machine.effect_receiver.base_effect.parallel
        )
    end
    return 0
end

local function get_all_machines_with_base_parallel()
    local result = {}

    for _, machine_type in pairs(crafting_machine_types) do
        for _, machine in pairs(data.raw[machine_type]) do
            if parallel.get_base_parallel(machine) ~= 0 then
                table.insert(result, machine)
            end
        end
    end

    return result
end

-- add to mod-data table
for _, machine in pairs(get_all_machines_with_base_parallel()) do
    entity_to_base_parallel[machine.name] = parallel.get_base_parallel(machine)
end

-- add to item tooltip
for prototype in pairs(defines.prototypes.item) do
    for _, item in pairs(data.raw[prototype] or {}) do
        local base_parallel = entity_to_base_parallel[item.place_result or ""]
        if base_parallel then
            item.custom_tooltip_fields = item.custom_tooltip_fields or {}
            table.insert(item.custom_tooltip_fields, {
                name = { "mod-tooltip-name.parallel-module-base-parallel" },
                value = { "mod-tooltip-value.parallel-module-value", tostring(100 * base_parallel) },
                order = 109,
                show_in_factoriopedia = true,
                show_in_tooltip = true
            })
        end
    end
end
