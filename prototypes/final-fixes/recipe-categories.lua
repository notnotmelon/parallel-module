local utils = require "utils"
local parallel_module_mod_data = data.raw["mod-data"].parallel_module_mod_data.data
local explicitly_disallowed_categories = parallel_module_mod_data.disallowed_crafting_categories
local crafting_machine_types = parallel_module_mod_data.crafting_machine_types

-- defaults
do
    parallel.crafting_category_to_max_module_slots = {}
    parallel.crafting_category_to_max_parallel_without_modules = {}
    parallel.crafting_category_to_should_enable_parallel_effect = {}

    for name, _ in pairs(data.raw["recipe-category"]) do
        parallel.crafting_category_to_max_module_slots[name] = 0
        parallel.crafting_category_to_max_parallel_without_modules[name] = 0
        parallel.crafting_category_to_should_enable_parallel_effect[name] = false
    end
end

-- set max module slots per crafting category
local function calculate_max_module_slots(machines)
    for _, machine in pairs(machines) do
        local machine_module_slots = machine.module_slots or 0

        local categories = {}
        for _, category in pairs(machine.crafting_categories) do
            if not utils.table_contains_value(explicitly_disallowed_categories, category) then
                table.insert(categories, category)
            end
        end
        if table_size(categories) == 0 then goto continue end

        if machine.quality_affects_module_slots then
            local max_extra_module_slots = 0
            for _, quality in pairs(data.raw.quality) do
                if machine.module_slots_quality_bonus and machine.module_slots_quality_bonus[quality.name] then
                    max_extra_module_slots = math.max(max_extra_module_slots, machine.module_slots_quality_bonus[quality.name])
                else
                    max_extra_module_slots = math.max(max_extra_module_slots, quality.crafting_machine_module_slots_bonus or quality.level)
                end
            end
            machine_module_slots = machine_module_slots + max_extra_module_slots
        end

        local base_machine_parallel = parallel.get_base_parallel(machine)
        for _, category in pairs(categories) do
            if data.raw["recipe-category"][category] then
                parallel.crafting_category_to_max_module_slots[category] = math.max(parallel.crafting_category_to_max_module_slots[category], machine_module_slots)
                parallel.crafting_category_to_max_parallel_without_modules[category] = math.max(parallel.crafting_category_to_max_parallel_without_modules[category], base_machine_parallel)
            end
        end

        ::continue::
    end
end

for _, machine_type in pairs(crafting_machine_types) do
    calculate_max_module_slots(data.raw[machine_type])
end
