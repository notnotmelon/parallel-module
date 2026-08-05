local utils = require "lib.utils"
local pairs = pairs

parallel.on_event(parallel.events.on_init(), function()
    -- update all entities
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities()) do
            if not entity or not entity.valid then goto continue end
            parallel.update_machine_for_parallel(entity, true)
            ::continue::
        end
    end
end)

parallel.on_event(defines.events.on_tick, function()
    if next(storage.player_to_machine_with_open_gui) then
        for _, opened_machine in pairs(storage.player_to_machine_with_open_gui) do
            parallel.update_machine_for_parallel(opened_machine)
        end
    end
    if next(storage.machines_waiting_for_parallel_module) then
        for _, machine in pairs(storage.machines_waiting_for_parallel_module) do
            parallel.update_machine_for_parallel(machine, true)
        end
        storage.machines_waiting_for_parallel_module = {}
    end
end)

parallel.on_event(defines.events.on_entity_settings_pasted, function(event)
    parallel.update_machine_for_parallel(event.destination, true)
end)

parallel.on_event("item-request-proxy-created", function(event)
    if not event.proxy_target or not event.proxy_target.valid or not utils.table_contains_value(parallel.crafting_machine_types, event.proxy_target.type) then
        return
    end

    remote.call("item-request-proxy-events", "register_item_request_proxy_updated", event.unit_number)
end)

parallel.on_event({
    "item-request-proxy-updated",
    "item-request-proxy-removed",
}, function(event)
    parallel.update_machine_for_parallel(event.proxy_target, true)
end)

if next(mod_data.spoilable_modules) then
    parallel.on_event("item-spoiled", function(event)
        if event.entity and event.entity.valid and event.entity.unit_number then
            storage.machines_waiting_for_parallel_module[event.entity.unit_number] = event.entity
        end
    end)
end

parallel.on_event({defines.events.on_undo_applied, defines.events.on_redo_applied}, function(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end

    for _, action in pairs(event.actions) do
        if action.surface_index and action.target then
            local surface = game.get_surface(action.surface_index)
            local position = action.target.position

            for _, machine in pairs(surface.find_entities_filtered {
                type = parallel.crafting_machine_types,
                position = position,
            }) do
                parallel.update_machine_for_parallel(machine, true)
            end

            for _, ghost in pairs(surface.find_entities_filtered {
                ghost_type = parallel.crafting_machine_types,
                position = position,
            }) do
                parallel.update_machine_for_parallel(ghost, true)
            end
        end
    end
end)

parallel.on_event({
    defines.events.on_player_fast_transferred,
    defines.events.on_player_dropped_item_into_entity,
    defines.events.on_player_cursor_stack_changed,
}, function(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    storage.players_holding_cut_paste_tool[player_index] = player
        and player.valid
        and player.cursor_stack
        and player.cursor_stack.valid_for_read
        and player.cursor_stack.name == "cut-paste-tool"
    parallel.update_machine_for_parallel(storage.player_to_selected_machine[player_index])
end)

local function handle_entity_gui_opened(player, entity)
    entity = entity or player.opened

    if not entity or entity.object_name ~= "LuaEntity" or not entity.valid or entity == storage.player_to_machine_with_open_gui[player.index] then
        return
    end

    local entity_name = entity.name == "entity-ghost" and entity.ghost_name or entity.name
    if mod_data.allowed_machines[entity_name] or mod_data.entity_to_base_parallel[entity_name] then
        storage.player_to_machine_with_open_gui[player.index] = entity
    end
end

parallel.on_event(defines.events.on_gui_opened, function(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    local player = game.get_player(event.player_index)
    handle_entity_gui_opened(player, event.entity)
end)

parallel.on_event(defines.events.on_gui_closed, function(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    if entity ~= storage.player_to_machine_with_open_gui[event.player_index] then return end
    storage.player_to_machine_with_open_gui[event.player_index] = nil
end)

parallel.on_event(parallel.events.on_built(), function(event)
    if not parallel.update_machine_for_parallel(event.entity, true) then return end

    -- TODO: not very optimized
    for _, map in pairs {storage.player_to_machine_with_open_gui, storage.player_to_selected_machine} do
        for player_idx in pairs(map) do
            local player = game.get_player(player_idx)
            if player and player.valid then
                handle_entity_gui_opened(player)
            end
        end
    end
end)

local function handle_player_selection_changed(player)
    local entity = player.selected
    if not entity or entity.object_name ~= "LuaEntity" or not entity.valid or not utils.table_contains_value(parallel.crafting_machine_types, (entity.type == "entity-ghost" and entity.ghost_type) or entity.type) then
        storage.player_to_selected_machine[player.index] = nil
    else
        storage.player_to_selected_machine[player.index] = entity
    end
end

parallel.on_event(defines.events.on_selected_entity_changed, function(event)
    handle_player_selection_changed(game.get_player(event.player_index))
end)

parallel.on_event({
    defines.events.on_player_died,
    defines.events.on_player_left_game,
    defines.events.on_player_removed,
    defines.events.on_player_kicked,
    defines.events.on_player_banned,
    defines.events.on_player_changed_surface,
    defines.events.on_player_controller_changed,
    defines.events.on_player_joined_game,
    defines.events.on_player_unbanned,
}, function(event)
    if not event.player_index then return end
    local player = game.get_player(event.player_index)
    storage.player_to_machine_with_open_gui[player.index] = nil
    storage.player_to_selected_machine[player.index] = nil
    handle_entity_gui_opened(player)
    handle_player_selection_changed(player)
end)
