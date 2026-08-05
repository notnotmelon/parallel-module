local utils = require "lib.utils"

function parallel.get_base_parallel(machine)
    if machine.effect_receiver and machine.effect_receiver.base_effect and machine.effect_receiver.base_effect.parallel then
        return machine.effect_receiver.base_effect.parallel
    end
    return 0
end

local function get_all_machines_with_base_parallel()
    local result = {}

    for name, type in pairs(mod_data.allowed_machines) do
        local machine = data.raw[type][name]
        if parallel.get_base_parallel(machine) ~= 0 then
            table.insert(result, machine)
        end
    end

    return result
end

-- add to mod-data table
for _, machine in pairs(get_all_machines_with_base_parallel()) do
    mod_data.entity_to_base_parallel[machine.name] = parallel.get_base_parallel(machine)
end

-- add to item tooltip
for prototype in pairs(defines.prototypes.item) do
    for _, item in pairs(data.raw[prototype] or {}) do
        local base_parallel = mod_data.entity_to_base_parallel[item.place_result or ""]
        if base_parallel then
            item.custom_tooltip_fields = item.custom_tooltip_fields or {}
            table.insert(item.custom_tooltip_fields, {
                name = {"mod-tooltip-name.parallel-module-base-parallel"},
                value = utils.parallel_tooltip(base_parallel),
                order = 109,
                show_in_factoriopedia = true,
                show_in_tooltip = true,
            })
        end
    end
end
