local utils = require "lib.utils"
local pairs = pairs
local TOOLTIP_ID = 42005542

parallel.on_event(parallel.events.on_init(), function()
    storage.previous_tick_info = storage.previous_tick_info or {}
end)

function parallel.get_machine_parallel(machine)
    local module_inventory
    if machine.type == "entity-ghost" then
        module_inventory = machine.item_requests
    else
        module_inventory = machine.get_module_inventory()
        if module_inventory then module_inventory = module_inventory.get_contents() end
    end

    local module_parallel = 0.0
    for _, module in pairs(module_inventory or {}) do
        if module and mod_data.parallel_value_cache[module.name] then
            module_parallel = module_parallel + module.count * mod_data.parallel_value_cache[module.name][module.quality]
        end
    end

    local machine_name = machine.type == "entity-ghost" and machine.ghost_name or machine.name
    local base_parallel = mod_data.entity_to_base_parallel[machine_name]
    return (module_parallel or 0) + (base_parallel or 0)
end

local function get_previous_tick_info(unit_number)
    local latest = storage.previous_tick_info[unit_number]
    if not latest then
        return nil, nil
    end

    return latest[1], latest[2]
end

local function get_parallel_recipe(recipe_name, parallel)
    local base_recipe_name = mod_data.recipe_table_inverse[recipe_name]
    if not base_recipe_name then return recipe_name end

    if parallel == 0 then
        return base_recipe_name
    end

    local parallel_recipes = mod_data.recipe_table[base_recipe_name]
    if not parallel_recipes then
        return base_recipe_name
    end

    return parallel_recipes[tostring(parallel + 1)] or base_recipe_name
end

local function set_parallel_recipe(entity, recipe, quality, current_recipe)
    if recipe and recipe == current_recipe then
        return
    end


    local spillage = entity.set_recipe(recipe, quality)
    for _, spillage in pairs(spillage) do
        entity.surface.spill_item_stack {
            position = entity.position,
            stack = spillage,
            enable_looted = true,
            force = entity.force_index,
            allow_belts = false,
            use_start_position_on_failure = true,
            drop_full_stack = true,
        }
    end
end

local function update_machine_info(machine, recipe_name, current_parallel_amount)
    if not machine or not machine.valid then
        return
    end

    if current_parallel_amount == 0 then
        storage.previous_tick_info[machine.unit_number] = nil
        machine.clear_tooltip_field(TOOLTIP_ID)
        return
    end

    local _, previous_parallel_amount = get_previous_tick_info(machine.unit_number)
    if previous_parallel_amount ~= current_parallel_amount then
        machine.set_tooltip_field {
            id = TOOLTIP_ID,
            name = {"mod-tooltip-name.parallel-module-parallel"},
            value = {
                "mod-tooltip-value.parallel-module-num-parallels",
                math.max(1, utils.round_parallel(current_parallel_amount) + 1),
                utils.parallel_tooltip(current_parallel_amount),
            },
            order = 90,
        }
    end

    storage.previous_tick_info[machine.unit_number] = {recipe_name, current_parallel_amount}

    if machine.type == "entity-ghost" then
        -- ghosts don't have module tooltips, for some reason
        -- lets clear it to have parity with vanilla
        machine.clear_tooltip_field(TOOLTIP_ID)
    end
end

local function clear_circuit_set_recipe(machine)
    local machine_control_behavior = machine.get_control_behavior()
    if machine_control_behavior and machine_control_behavior.circuit_set_recipe then
        machine_control_behavior.circuit_set_recipe = false
        machine.force.print({
            "mod-tooltip-name.parallel-module-circuit-set-recipe-warning",
            {"gui-control-behavior-modes.set-recipe"},
            machine.gps_tag,
        }, {
            skip = defines.print_skip.if_visible,
            game_state = false,
        })
    end
end

function parallel.update_machine(machine, just_built)
    if not machine then return end
    if not machine.valid then return end
    if machine.prototype.hidden then return end
    local machine_name = (machine.type == "entity-ghost" and machine.ghost_name) or machine.name
    if not mod_data.allowed_machines[machine_name] then return end

    local current_parallel_amount = parallel.get_machine_parallel(machine)
    local previous_recipe, previous_parallel_amount = get_previous_tick_info(machine.unit_number)

    if not just_built and (not previous_parallel_amount or previous_parallel_amount == 0) and current_parallel_amount == 0 then
        return -- machine has no parallel and is not dirty
    end

    local recipe, quality = machine.get_recipe()
    if recipe then
        recipe = recipe.prototype
    end
    local recipe_name = recipe and recipe.name

    if current_parallel_amount > 0 then
        clear_circuit_set_recipe(machine)
    end

    local was_changed = previous_recipe ~= recipe_name or previous_parallel_amount ~= current_parallel_amount
    if was_changed or just_built then
        set_parallel_recipe(
            machine,
            get_parallel_recipe(recipe_name, utils.round_parallel(current_parallel_amount)),
            quality,
            (recipe and recipe.name) or nil
        )
        update_machine_info(machine, recipe_name, current_parallel_amount)
    elseif current_parallel_amount > 0 then
        update_machine_info(machine, recipe_name, current_parallel_amount)
    end

    script.register_on_object_destroyed(machine)
end
