local pairs = pairs
local table = table

utils = require "utils"

TOOLTIP_ID = 2453693297

local recipe_table = {}
for base_recipe, recipes in pairs(mod_data.recipe_table) do
    recipe_table[base_recipe] = {}
    for parallel, recipe in pairs(recipes) do
        recipe_table[base_recipe][tonumber(parallel)] = recipe
    end
end

-- Call the prototypes_check in advance and cache the results to stop calling prototypes every tick
local is_parallel_module = {}
local module_name_to_quality_to_parallel = {}
for module_name, module in pairs(prototypes.get_item_filtered{{filter = "type", type = "module"}}) do
    if module.category == "parallel" then
        is_parallel_module[module_name] = true
        module_name_to_quality_to_parallel[module_name] = mod_data.parallel_value_cache[tostring(module.tier)]
    end
end

for _, type in pairs(mod_data.crafting_machine_types) do
    for entity_name, entity in pairs(prototypes.get_entity_filtered{{filter = "type", type = type}}) do
        if entity.allowed_module_categories and entity.allowed_module_categories.parallel then
            mod_data.allowed_machines[entity_name] = true
        end
    end
end

local function cached_tostring(x)
    local s = storage.cached_to_string[x]
    if s == nil then
        s = tostring(x)
        storage.cached_to_string[x] = s
    end
    return s
end

local Public = {}

function Public.ensure_storage_cache_is_setup()
    storage.machines_waiting_for_parallel_module = storage.machines_waiting_for_parallel_module or {}
    storage.player_to_machine_with_open_gui = storage.player_to_machine_with_open_gui or {}
    storage.player_to_selected_machine = storage.player_to_selected_machine or {}
    storage.players_holding_cut_paste_tool = storage.players_holding_cut_paste_tool or {}
    storage.machine_to_latest_recipe_and_parallel = storage.machine_to_latest_recipe_and_parallel or {}
    if not storage.cached_to_string then storage.cached_to_string = {} end
end

function Public.update_all_entities()
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities()) do
            if not entity or not entity.valid then
                goto continue
            end

            local name = entity.name
            entity = Public.update_machine_for_parallel(entity, true)
            if entity and name ~= entity.name then
                log(string.format("Migrated entity %s from prototype %s", entity, name))
            end
            ::continue::
        end
    end
end

function Public.get_parallel_recipe(base_recipe_name, parallel)
    if not base_recipe_name or parallel == 0 then
        return base_recipe_name
    end

    local parallel_recipes = recipe_table[base_recipe_name]
    if not parallel_recipes then
        return base_recipe_name
    end

    return parallel_recipes[parallel] or base_recipe_name
end

function Public.get_crafting_machines(surface, position, area)
    local result = {}
    local filters = {
        type = mod_data.crafting_machine_types
    }
    if position ~= nil then
        filters["position"] = position
    elseif area ~= nil then
        filters["area"] = area
    end
    for _, machine in pairs(surface.find_entities_filtered(filters)) do
        table.insert(result, machine)
    end

    filters["ghost_type"] = mod_data.crafting_machine_types
    filters["type"] = nil
    for _, machine in pairs(surface.find_entities_filtered(filters)) do
        table.insert(result, machine)
    end
    return result
end

function Public.get_total_parallel_from_module_inventory(entity)
    local module_inventory
    if entity.type == "entity-ghost" then
        module_inventory = entity.item_requests
    else
        module_inventory = entity.get_module_inventory()
        if module_inventory then
            module_inventory = module_inventory.get_contents()
        end
    end

    local total_parallel = 0.0
    if not module_inventory then
        return total_parallel
    end

    for _, module in pairs(module_inventory) do
        if module == nil or not is_parallel_module[module.name] then
            goto continue
        end

        total_parallel = total_parallel + module.count * module_name_to_quality_to_parallel[module.name][module.quality]
        ::continue::
    end
    return total_parallel
end

function Public.get_total_machine_parallel_optimized(machine)
    if machine == nil or not machine.valid then
        return nil, nil
    end

    local machine_name = machine.type == "entity-ghost" and machine.ghost_name or machine.name
    local machine_base_parallel = mod_data.entity_to_base_parallel[machine_name]
    local module_parallel
    if mod_data.allowed_machines[machine_name] then
        module_parallel = Public.get_total_parallel_from_module_inventory(machine)
    elseif machine_base_parallel then
        module_parallel = 0
    else
        return nil, nil
    end

    local parallel = math.min(mod_data.max_total_parallel, module_parallel + (machine_base_parallel or 0))
    return parallel, module_parallel > 0
end

function Public.get_latest_recipe_and_parallel(unit_number)
    local latest = storage.machine_to_latest_recipe_and_parallel[unit_number]
    if not latest then
        return nil, nil, nil
    end

    return latest[1], latest[2], latest[3]
end

function Public.update_machine_for_parallel(machine, just_built)
    if not machine then return end
    if not machine.valid then return end
    if machine.prototype.hidden then return end
    local machine_type = (machine.type == "entity-ghost" and machine.ghost_type) or machine.type
    if machine_type == "furnace" then return end

    if not utils.table_contains_value(mod_data.crafting_machine_types, machine_type) then
        return
    end

    local current_machine_parallel, has_parallel_modules = Public.get_total_machine_parallel_optimized(machine)
    -- Machine does not support parallel modules
    if current_machine_parallel == nil then
        return
    end

    -- Machine has no parallel and is not dirty
    local latest_recipe, latest_parallel, latest_set_recipe = Public.get_latest_recipe_and_parallel(machine.unit_number)
    if not just_built and (not latest_parallel or latest_parallel == 0) and current_machine_parallel == 0 then
        return machine
    end

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
            for _, player_to_machine_map in pairs{storage.player_to_selected_machine, storage.player_to_machine_with_open_gui} do
                for player_idx, selected_machine in pairs(player_to_machine_map) do
                    if machine == selected_machine then
                        local player = game.get_player(player_idx)
                        if player and player.valid and settings.get_player_settings(player_idx)["parallel-module-show-set-recipe-messages"].value then
                            if has_parallel_modules then
                                player.print({
                                    "mod-tooltip-name.parallel-module-circuit-set-recipe-warning",
                                    {"gui-control-behavior-modes.set-recipe"}
                                }, {
                                    skip = defines.print_skip.if_visible,
                                    game_state = false
                                })
                            elseif not has_base_parallel_but_no_connections then
                                player.print({
                                    "mod-tooltip-name.parallel-module-entity-circuit-set-recipe-warning",
                                    {"gui-control-behavior-modes.set-recipe"},
                                    {"module-category-name.parallel"}
                                }, {
                                    skip = defines.print_skip.if_visible,
                                    game_state = false
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
        local base_recipe_name = nil
        if recipe_name then
            _, base_recipe_name = next(mod_data.recipe_table_inverse[recipe_name] or {})
        end
        
        Public.set_parallel_recipe(
            machine,
            Public.get_parallel_recipe(base_recipe_name, utils.round_parallel(current_machine_parallel)),
            quality,
            (recipe and recipe.name) or nil
        )
        Public.update_machine_info(machine, recipe_name, current_machine_parallel, is_set_recipe)
    elseif current_machine_parallel > 0 then
        Public.update_machine_info(machine, recipe_name, current_machine_parallel, is_set_recipe)
    end

    if just_built then
        script.register_on_object_destroyed(machine)
    end
    return machine
end

function Public.update_machine_info(machine, recipe_name, current_machine_parallel, is_set_recipe)
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
        machine.set_tooltip_field({
            id = TOOLTIP_ID,
            name = { "mod-tooltip-name.parallel-module-parallel" },
            value = {
                "mod-tooltip-value.parallel-module-num-parallels",
                utils.round_parallel(tooltip_machine_parallel) + 1,
                {
                    tooltip_machine_parallel == mod_data.max_total_parallel and "mod-tooltip-value.parallel-module-value-max" or "mod-tooltip-value.parallel-module-value",
                    cached_tostring(tooltip_machine_parallel * 100)
                }
            },
            order = 90
        })
    end
    
    storage.machine_to_latest_recipe_and_parallel[machine.unit_number] = { recipe_name, current_machine_parallel, is_set_recipe }

    if machine.type == "entity-ghost" then
        machine.clear_tooltip_field(TOOLTIP_ID)
    end
end

function Public.update_opened_machine_for_player(player_index)
    Public.update_machine_for_parallel(storage.player_to_machine_with_open_gui[player_index])
end

function Public.update_selected_machine_for_player(player_index)
    Public.update_machine_for_parallel(storage.player_to_selected_machine[player_index])
end

function Public.handle_on_tick()
    if next(storage.player_to_machine_with_open_gui) then
        for _, opened_machine in pairs(storage.player_to_machine_with_open_gui) do
            Public.update_machine_for_parallel(opened_machine)
        end
    end
    if next(storage.machines_waiting_for_parallel_module) then
        for _, machine in pairs(storage.machines_waiting_for_parallel_module) do
            Public.update_machine_for_parallel(machine, true)
        end
        storage.machines_waiting_for_parallel_module = {}
    end
end

function Public.handle_undo_redo_action(surface, action)
    if action.type == "upgraded-entity" or action.type == "upgraded-modules" or action.type == "copy-entity-settings" then
        for _, machine in pairs(Public.get_crafting_machines(surface, action.target.position)) do
            Public.update_machine_for_parallel(machine, true)
        end
    end
end

function Public.handle_undo_redo_event(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    for _, action in pairs(event.actions) do
        Public.handle_undo_redo_action(player.surface, action)
    end
end

function Public.handle_bplib_overlaps(event)
    if not event or not event.overlaps then
        return
    end

    for _, entity in pairs(event.overlaps) do
        storage.machines_waiting_for_parallel_module[entity.unit_number] = entity
    end
end

function Public.handle_player_cursor_stack_changed(player_index)
    local player = game.get_player(player_index)
    storage.players_holding_cut_paste_tool[player_index] = player
            and player.valid
            and player.cursor_stack
            and player.cursor_stack.valid_for_read
            and player.cursor_stack.name == "cut-paste-tool"
    Public.update_selected_machine_for_player(player_index)
end

function Public.sanitize_bp_entities(bp_entities)
    local was_modified = false
    for _, bp_entity in pairs(bp_entities) do
        local current_parallel_to_base_recipe_name = bp_entity.recipe and mod_data.recipe_table_inverse[bp_entity.recipe]

        -- Set blueprint entity's recipe to non-parallel version, if applicable
        if current_parallel_to_base_recipe_name then
            local _, base_recipe_name = next(current_parallel_to_base_recipe_name)
            if base_recipe_name and bp_entity.recipe ~= base_recipe_name then
                was_modified = true
                bp_entity.recipe = base_recipe_name
            end
        end
    end

    return was_modified
end

function Public.is_player_holding_cut_paste_tool(player)
    if not player then
        return false
    end

    local t = type(player)
    if t == "number" then
        return storage.players_holding_cut_paste_tool[player]
    end

    if t == "string" then
        player = (game and game.get_player(player)) or player
    end
    return player.index and storage.players_holding_cut_paste_tool[player.index]
end

function Public.handle_bplib_extract(event)
    -- Preserve external wire connections
    if Public.is_player_holding_cut_paste_tool(event.player_index) then
        return
    end

    if not event.blueprint then
        return
    end

    local bp_entities = event.blueprint.get_blueprint_entities()
    if not bp_entities then
        return
    end

    if Public.sanitize_bp_entities(bp_entities) then
        event.blueprint.set_blueprint_entities(bp_entities)
    end
end

function Public.handle_entity_gui_opened(player, entity)
    entity = entity or player.opened

    if not entity or entity.object_name ~= "LuaEntity" or not entity.valid or entity == storage.player_to_machine_with_open_gui[player.index] then
        return
    end

    local entity_name = entity.name == "entity-ghost" and entity.ghost_name or entity.name
    if mod_data.allowed_machines[entity_name] or mod_data.entity_to_base_parallel[entity_name] then
        storage.player_to_machine_with_open_gui[player.index] = entity
    end
end

function Public.handle_entity_gui_closed(player_index, entity)
    if entity ~= storage.player_to_machine_with_open_gui[player_index] then
        return
    end

    storage.player_to_machine_with_open_gui[player_index] = nil
end

function Public.handle_player_selection_changed(player)
    local entity = player.selected
    if not entity or entity.object_name ~= "LuaEntity" or not entity.valid or not utils.table_contains_value(mod_data.crafting_machine_types, (entity.type == "entity-ghost" and entity.ghost_type) or entity.type) then
        storage.player_to_selected_machine[player.index] = nil
    else
        storage.player_to_selected_machine[player.index] = entity
    end
end

function Public.handle_player_event(player)
    storage.player_to_machine_with_open_gui[player.index] = nil
    storage.player_to_selected_machine[player.index] = nil
    Public.handle_entity_gui_opened(player)
    Public.handle_player_selection_changed(player)
end

function Public.set_parallel_recipe(entity, recipe, quality, current_recipe)
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
            drop_full_stack = true
        }
    end
end

return Public