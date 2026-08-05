local utils = require "lib.utils"
local pairs = pairs
local TOOLTIP_ID = 42005542

parallel.on_event(parallel.events.on_init(), function()
    storage.machines_waiting_for_parallel_module = storage.machines_waiting_for_parallel_module or {}
    storage.player_to_machine_with_open_gui = storage.player_to_machine_with_open_gui or {}
    storage.player_to_selected_machine = storage.player_to_selected_machine or {}
    storage.players_holding_cut_paste_tool = storage.players_holding_cut_paste_tool or {}
    storage.machine_to_latest_recipe_and_parallel = storage.machine_to_latest_recipe_and_parallel or {}
end)

function parallel.get_machine_parallel(machine)
    local machine_name = machine.type == "entity-ghost" and machine.ghost_name or machine.name
    if not mod_data.allowed_machines[machine_name] then return nil, nil end

    local module_inventory
    if entity.type == "entity-ghost" then
        module_inventory = entity.item_requests
    else
        module_inventory = entity.get_module_inventory()
        if module_inventory then module_inventory = module_inventory.get_contents() end
    end

    local module_parallel = 0.0
    for _, module in pairs(module_inventory or {}) do
        if module and mod_data.parallel_value_cache[module.name] then
            module_parallel = module_parallel + module.count * mod_data.parallel_value_cache[module.name][module.quality]
        end
    end

    local base_parallel = mod_data.entity_to_base_parallel[machine_name]
    local parallel = (module_parallel or 0) + (base_parallel or 0)
    return parallel, module_parallel > 0
end

local function get_latest_recipe_and_parallel(unit_number)
    local latest = storage.machine_to_latest_recipe_and_parallel[unit_number]
    if not latest then
        return nil, nil, nil
    end

    return latest[1], latest[2], latest[3]
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

local function update_machine_info(machine, recipe_name, current_machine_parallel, is_set_recipe)
    if not machine or not machine.valid then
        return
    end

    if not is_set_recipe and current_machine_parallel == 0 then
        storage.machine_to_latest_recipe_and_parallel[machine.unit_number] = nil
        machine.clear_tooltip_field(TOOLTIP_ID)
        return
    end
    local old_values = storage.machine_to_latest_recipe_and_parallel[machine.unit_number]
    local old_parallel = (old_values and old_values[2]) or nil

    local tooltip_machine_parallel = current_machine_parallel
    if old_parallel ~= tooltip_machine_parallel then
        machine.set_tooltip_field {
            id = TOOLTIP_ID,
            name = {"mod-tooltip-name.parallel-module-parallel"},
            value = {
                "mod-tooltip-value.parallel-module-num-parallels",
                math.max(1, utils.round_parallel(tooltip_machine_parallel) + 1),
                utils.parallel_tooltip(tooltip_machine_parallel),
            },
            order = 90,
        }
    end

    storage.machine_to_latest_recipe_and_parallel[machine.unit_number] = {recipe_name, current_machine_parallel, is_set_recipe}

    if machine.type == "entity-ghost" then
        machine.clear_tooltip_field(TOOLTIP_ID)
    end
end

function parallel.update_machine_for_parallel(machine, just_built)
    if not machine then return end
    if not machine.valid then return end
    if machine.prototype.hidden then return end
    local machine_name = (machine.type == "entity-ghost" and machine.ghost_name) or machine.name
    if not mod_data.allowed_machines[machine_name] then return end

    local current_machine_parallel, has_parallel_modules = parallel.get_machine_parallel(machine)
    -- Machine does not support parallel modules
    if not current_machine_parallel then return end

    -- Machine has no parallel and is not dirty
    local latest_recipe, latest_parallel, latest_set_recipe = get_latest_recipe_and_parallel(machine.unit_number)
    if not just_built and (not latest_parallel or latest_parallel == 0) and current_machine_parallel == 0 then return end

    local recipe, quality = machine.get_recipe()
    if recipe then
        recipe = recipe.prototype
    end
    local recipe_name = recipe and recipe.name
    local machine_control_behavior = machine.get_control_behavior()

    local is_set_recipe = machine_control_behavior and machine_control_behavior.circuit_set_recipe
    if is_set_recipe and current_machine_parallel > 0 then
        local has_base_parallel_but_no_connections = not has_parallel_modules and recipe and not machine_control_behavior.get_circuit_network(defines.wire_connector_id.circuit_red) and not machine_control_behavior.get_circuit_network(defines.wire_connector_id.circuit_green)
        if has_parallel_modules or has_base_parallel_but_no_connections then
            is_set_recipe = false
            machine_control_behavior.circuit_set_recipe = false
        else
            current_machine_parallel = 0
        end
        if not latest_set_recipe or not is_set_recipe then
            for _, player_to_machine_map in pairs {storage.player_to_selected_machine, storage.player_to_machine_with_open_gui} do
                for player_idx, selected_machine in pairs(player_to_machine_map) do
                    if machine == selected_machine then
                        local player = game.get_player(player_idx)
                        if player and player.valid and settings.get_player_settings(player_idx)["parallel-module-show-set-recipe-messages"].value then
                            if has_parallel_modules then
                                player.print({
                                    "mod-tooltip-name.parallel-module-circuit-set-recipe-warning",
                                    {"gui-control-behavior-modes.set-recipe"},
                                }, {
                                    skip = defines.print_skip.if_visible,
                                    game_state = false,
                                })
                            elseif not has_base_parallel_but_no_connections then
                                player.print({
                                    "mod-tooltip-name.parallel-module-entity-circuit-set-recipe-warning",
                                    {"gui-control-behavior-modes.set-recipe"},
                                    {"module-category-name.parallel"},
                                }, {
                                    skip = defines.print_skip.if_visible,
                                    game_state = false,
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    local was_changed = latest_recipe ~= recipe_name or latest_parallel ~= current_machine_parallel
    -- If no change, don't update
    if was_changed or just_built then
        set_parallel_recipe(
            machine,
            get_parallel_recipe(recipe_name, utils.round_parallel(current_machine_parallel)),
            quality,
            (recipe and recipe.name) or nil
        )
        update_machine_info(machine, recipe_name, current_machine_parallel, is_set_recipe)
    elseif current_machine_parallel > 0 then
        update_machine_info(machine, recipe_name, current_machine_parallel, is_set_recipe)
    end

    script.register_on_object_destroyed(machine)
end
