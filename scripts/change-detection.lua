local utils = require "lib.utils"
local pairs = pairs
local next = next

local crafting_machine_types = {
    "assembling-machine",
    "rocket-silo",
}

parallel.on_event(parallel.events.on_init(), function()
    storage.player_to_machine_with_open_gui = storage.player_to_machine_with_open_gui or {}
    storage.player_to_selected_machine = storage.player_to_selected_machine or {}

    -- update all entities
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered {
            type = crafting_machine_types,
        }) do
            parallel.update_machine(entity, true)
        end
        for _, entity in pairs(surface.find_entities_filtered {
            ghost_type = crafting_machine_types,
        }) do
            parallel.update_machine(entity, true)
        end
    end
end)

parallel.on_event(defines.events.on_tick, function()
    if next(storage.player_to_machine_with_open_gui) then
        for _, opened_machine in pairs(storage.player_to_machine_with_open_gui) do
            parallel.update_machine(opened_machine)
        end
    end
end)

parallel.on_event(defines.events.on_entity_settings_pasted, function(event)
    parallel.update_machine(event.destination, true)
end)

parallel.on_event("item-request-proxy-created", function(event)
    if not event.proxy_target or not event.proxy_target.valid or not utils.table_contains_value(crafting_machine_types, event.proxy_target.type) then
        return
    end

    remote.call("item-request-proxy-events", "register_item_request_proxy_updated", event.unit_number)
end)

parallel.on_event({
    "item-request-proxy-updated",
    "item-request-proxy-removed",
}, function(event)
    parallel.update_machine(event.proxy_target, true)
end)

if next(mod_data.spoilable_modules) then
    parallel.on_event("item-spoiled", function(event)
        local entity = event.entity
        if entity and entity.valid and entity.unit_number then
            parallel.execute_later("update_machine", 1, entity, true)
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
                type = crafting_machine_types,
                position = position,
            }) do
                parallel.update_machine(machine, true)
            end

            for _, ghost in pairs(surface.find_entities_filtered {
                ghost_type = crafting_machine_types,
                position = position,
            }) do
                parallel.update_machine(ghost, true)
            end
        end
    end
end)

parallel.on_event({
    defines.events.on_player_fast_transferred,
    defines.events.on_player_dropped_item_into_entity,
    defines.events.on_player_cursor_stack_changed,
}, function(event)
    parallel.update_machine(storage.player_to_selected_machine[event.player_index])
end)

local function handle_entity_gui_opened(player)
    local entity = player.opened
    if not entity then return end
    if entity.object_name ~= "LuaEntity" then return end
    if entity == storage.player_to_machine_with_open_gui[player.index] then return end

    local entity_name = entity.name == "entity-ghost" and entity.ghost_name or entity.name
    if mod_data.allowed_machines[entity_name] then
        storage.player_to_machine_with_open_gui[player.index] = entity
    end
end

parallel.on_event(defines.events.on_gui_opened, function(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    local player = game.get_player(event.player_index)
    handle_entity_gui_opened(player)
end)

parallel.on_event(defines.events.on_gui_closed, function(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    if event.entity ~= storage.player_to_machine_with_open_gui[event.player_index] then return end
    storage.player_to_machine_with_open_gui[event.player_index] = nil
end)

parallel.on_event(parallel.events.on_built(), function(event)
    local entity = event.entity
    if not entity.valid then return end
    local entity_name = entity.type == "entity-ghost" and entity.ghost_name or entity.name
    if not mod_data.allowed_machines[entity_name] then return end

    parallel.update_machine(event.entity, true)

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
    if not entity or entity.object_name ~= "LuaEntity" or not entity.valid or not utils.table_contains_value(crafting_machine_types, (entity.type == "entity-ghost" and entity.ghost_type) or entity.type) then
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
