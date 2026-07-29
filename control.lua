local control_helpers = require("__parallel-module__.control-helpers")
local parallel_module_mod_data = prototypes.mod_data.parallel_module_mod_data.data
local parallel_crafting_machine_types = parallel_module_mod_data.crafting_machine_types


script.on_init(function()
    control_helpers.ensure_storage_cache_is_setup()
end)

script.on_configuration_changed(function()
    control_helpers.ensure_storage_cache_is_setup()
    control_helpers.update_all_entities()
end)

script.on_event(defines.events.on_tick, control_helpers.handle_on_tick)

-- TODO: Enable if `on_tick` is disabled
-- script.on_nth_tick(15, control_helpers.handle_on_tick)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
    control_helpers.update_machine_for_parallel(event.destination, true)
end)

local function handle_entity_built(machine)
    if not control_helpers.update_machine_for_parallel(machine, true) then
        return
    end

    -- TODO: not very optimized
    for _, map in pairs{storage.player_to_machine_with_open_gui, storage.player_to_selected_machine} do
        for player_idx in pairs(map) do
            control_helpers.handle_entity_gui_opened(player_idx)
        end
    end
end

script.on_event(defines.events.on_built_entity, function(event)
    handle_entity_built(event.entity)
end, { { filter = "crafting-machine" } })

script.on_event(defines.events.on_robot_built_entity, function(event)
    handle_entity_built(event.entity)
end, { { filter = "crafting-machine" } })

script.on_event(defines.events.on_space_platform_built_entity, function(event)
    handle_entity_built(event.entity)
end, { { filter = "crafting-machine" } })

script.on_event(defines.events.script_raised_built, function(event)
    handle_entity_built(event.entity)
end, { { filter = "crafting-machine" } })

script.on_event(defines.events.script_raised_revive, function(event)
    handle_entity_built(event.entity)
end, { { filter = "crafting-machine" } })

script.on_event("item-request-proxy-created", function(event)
    if not event.proxy_target or not event.proxy_target.valid or not utils.table_contains_value(parallel_crafting_machine_types, event.proxy_target.type) then
        return
    end

    remote.call("item-request-proxy-events", "register_item_request_proxy_updated", event.unit_number)
end)

script.on_event("item-request-proxy-removed", function(event)
    control_helpers.update_machine_for_parallel(event.proxy_target, true)
end)

script.on_event("item-request-proxy-updated", function(event)
    control_helpers.update_machine_for_parallel(event.proxy_target, true)
end)

if next(prototypes.mod_data.spoilable_parallel_modules.data) then
    script.on_event("item-spoiled", function(event)
        if event.entity and event.entity.valid and event.entity.unit_number then
            storage.machines_waiting_for_parallel_module[event.entity.unit_number] = event.entity
        end
    end)
end

script.on_event(defines.events.on_undo_applied, control_helpers.handle_undo_redo_event)
script.on_event(defines.events.on_redo_applied, control_helpers.handle_undo_redo_event)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    control_helpers.handle_player_cursor_stack_changed(event.player_index)
    -- TODO: Enable if `on_tick` is disabled
    -- Public.update_opened_machine_for_player(player_index)
end)
script.on_event(defines.events.on_player_dropped_item_into_entity, function(event)
    control_helpers.update_selected_machine_for_player(event.player_index)
    -- TODO: Enable if `on_tick` is disabled
    -- Public.update_opened_machine_for_player(player_index)
end)
script.on_event(defines.events.on_player_fast_transferred, function(event)
    control_helpers.update_selected_machine_for_player(event.player_index)
    -- TODO: Enable if `on_tick` is disabled
    -- Public.update_opened_machine_for_player(player_index)
end)

script.on_event("bplib-overlaps", control_helpers.handle_bplib_overlaps)
script.on_event("bplib-extract", control_helpers.handle_bplib_extract)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.gui_type == defines.gui_type.entity then
        control_helpers.handle_entity_gui_opened(event.player_index, event.entity)
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.gui_type == defines.gui_type.entity then
        control_helpers.handle_entity_gui_closed(event.player_index, event.entity)
    end
end)

script.on_event(defines.events.on_selected_entity_changed, function(event)
    control_helpers.handle_player_selection_changed(event.player_index, event.last_entity)
end)

script.on_event(defines.events.on_player_died, function(event)
    control_helpers.handle_player_left(event.player_index)
end)

script.on_event(defines.events.on_player_left_game, function(event)
    control_helpers.handle_player_left(event.player_index)
end)

script.on_event(defines.events.on_player_removed, function(event)
    control_helpers.handle_player_left(event.player_index)
end)

script.on_event(defines.events.on_player_kicked, function(event)
    control_helpers.handle_player_left(event.player_index)
end)

script.on_event(defines.events.on_player_banned, function(event)
    control_helpers.handle_player_left(event.player_index, event.player_name)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    control_helpers.handle_player_joined(event.player_index)
end)

script.on_event(defines.events.on_player_unbanned, function(event)
    control_helpers.handle_player_joined(event.player_index, event.player_name)
end)

remote.add_interface("parallel-module", {
    get_total_machine_parallel = control_helpers.get_total_machine_parallel_optimized,
    is_player_holding_cut_paste_tool = control_helpers.is_player_holding_cut_paste_tool
})
if script.active_mods["funit"] then
    remote.add_interface("__funit__parallel-module", {
        update_all_entities = control_helpers.update_all_entities,
        sanitize_bp_entities = control_helpers.sanitize_bp_entities
    })
    local mock = require("__funit__.mock")
    mock.register()
end