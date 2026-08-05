_G.mod_data = prototypes.mod_data["parallel-module"].data
local parallel = require "lib.control-utils"

local function init()
    parallel.ensure_storage_cache_is_setup()
    parallel.update_all_entities()
end

script.on_init(init)
script.on_configuration_changed(init)

script.on_event(defines.events.on_tick, parallel.handle_on_tick)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
    parallel.update_machine_for_parallel(event.destination, true)
end)

local function handle_entity_built(machine)
    if not parallel.update_machine_for_parallel(machine, true) then
        return
    end

    -- TODO: not very optimized
    for _, map in pairs {storage.player_to_machine_with_open_gui, storage.player_to_selected_machine} do
        for player_idx in pairs(map) do
            local player = game.get_player(player_idx)
            if player and player.valid then
                parallel.handle_entity_gui_opened(player)
            end
        end
    end
end

for _, build_event in pairs {
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.on_space_platform_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive,
} do
    script.on_event(build_event, function(event)
        handle_entity_built(event.entity)
    end, {{filter = "crafting-machine"}})
end

script.on_event("item-request-proxy-created", function(event)
    if not event.proxy_target or not event.proxy_target.valid or not utils.table_contains_value(parallel.crafting_machine_types, event.proxy_target.type) then
        return
    end

    remote.call("item-request-proxy-events", "register_item_request_proxy_updated", event.unit_number)
end)

script.on_event({
    "item-request-proxy-updated",
    "item-request-proxy-removed",
}, function(event)
    parallel.update_machine_for_parallel(event.proxy_target, true)
end)

if next(mod_data.spoilable_modules) then
    script.on_event("item-spoiled", function(event)
        if event.entity and event.entity.valid and event.entity.unit_number then
            storage.machines_waiting_for_parallel_module[event.entity.unit_number] = event.entity
        end
    end)
end

script.on_event(defines.events.on_undo_applied, parallel.handle_undo_redo_event)
script.on_event(defines.events.on_redo_applied, parallel.handle_undo_redo_event)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    parallel.handle_player_cursor_stack_changed(event.player_index)
end)

script.on_event({
    defines.events.on_player_fast_transferred,
    defines.events.on_player_dropped_item_into_entity,
}, function(event)
    parallel.update_selected_machine_for_player(event.player_index)
end)

script.on_event("bplib-overlaps", parallel.handle_bplib_overlaps)
script.on_event("bplib-extract", parallel.handle_bplib_extract)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.gui_type == defines.gui_type.entity then
        local player = game.get_player(event.player_index)
        parallel.handle_entity_gui_opened(player, event.entity)
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.gui_type == defines.gui_type.entity then
        parallel.handle_entity_gui_closed(event.player_index, event.entity)
    end
end)

script.on_event(defines.events.on_selected_entity_changed, function(event)
    parallel.handle_player_selection_changed(game.get_player(event.player_index))
end)

script.on_event({
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
    parallel.handle_player_event(player)
end)

remote.add_interface("parallel-module", {
    get_total_machine_parallel = parallel.get_total_machine_parallel_optimized,
    is_player_holding_cut_paste_tool = parallel.is_player_holding_cut_paste_tool,
})
