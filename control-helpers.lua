local pairs = pairs
local table = table

utils = require("__parallel-module__.utils")

TOOLTIP_ID = 2453693297

local parallel_module_mod_data = prototypes.mod_data.parallel_module_mod_data.data
local parallel_crafting_machine_types = parallel_module_mod_data.crafting_machine_types
local max_total_parallel = parallel_module_mod_data.max_total_parallel
local entity_to_base_parallel = prototypes.mod_data.parallel_module_mod_entity_to_base_parallel.data
local parallel_module_mod_recipe_table_inverse =  prototypes.mod_data.parallel_module_mod_recipe_table_inverse.data

local parallel_module_mod_recipe_table = {}
for base_recipe, recipes in pairs(prototypes.mod_data.parallel_module_mod_recipe_table.data) do
    parallel_module_mod_recipe_table[base_recipe] = {}
    for parallel, recipe in pairs(recipes) do
        parallel_module_mod_recipe_table[base_recipe][tonumber(parallel)] = recipe
    end
end

-- Call the prototypes_check in advance and cache the results to stop calling prototypes every tick
local is_parallel_module = {}
local module_name_to_quality_to_parallel = {}
for module_name, module in pairs(prototypes.get_item_filtered{{filter = "type", type = "module"}}) do
    if module.category == "parallel" then
        is_parallel_module[module_name] = true
        module_name_to_quality_to_parallel[module_name] = prototypes.mod_data.parallel_module_mod_parallel_value_cache.data[tostring(module.tier)]
    end
end

local machine_accepts_parallel_modules = {}
for _, type in pairs(parallel_crafting_machine_types) do
    for entity_name, entity in pairs(prototypes.get_entity_filtered{{filter = "type", type = type}}) do
        if entity.allowed_module_categories and entity.allowed_module_categories["parallel"] then
            machine_accepts_parallel_modules[entity_name] = true
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

    local parallel_recipes = parallel_module_mod_recipe_table[base_recipe_name]
    if not parallel_recipes then
        return base_recipe_name
    end

    return parallel_recipes[parallel] or base_recipe_name
end

function Public.get_crafting_machines_including_ghosts(surface, position, area)
    local result = {}
    local filters = {
        type = parallel_crafting_machine_types
    }
    if position ~= nil then
        filters["position"] = position
    elseif area ~= nil then
        filters["area"] = area
    end
    for _, machine in pairs(surface.find_entities_filtered(filters)) do
        table.insert(result, machine)
    end

    filters["ghost_type"] = parallel_crafting_machine_types
    filters["type"] = nil
    for _, machine in pairs(surface.find_entities_filtered(filters)) do
        table.insert(result, machine)
    end
    return result
end

-- Ignores ghost modules
function Public.get_total_parallel_from_module_inventory(module_inventory)
    local total_parallel = 0.0
    if not module_inventory then
        return total_parallel
    end

    local contents = module_inventory.get_contents()
    for _, module in pairs(contents) do
        if module == nil or not is_parallel_module[module.name] then
            goto continue
        end

        total_parallel = total_parallel + module.count * module_name_to_quality_to_parallel[module.name][module.quality]
        ::continue::
    end
    return total_parallel
end

function Public.get_total_machine_parallel_optimized(machine, is_ghost)
    if machine == nil or not machine.valid then
        return nil, nil, nil
    end

    local machine_base_parallel = entity_to_base_parallel[machine.name]
    local module_parallel
    if machine_accepts_parallel_modules[machine.name] then
        module_parallel = is_ghost and 0 or Public.get_total_parallel_from_module_inventory(machine.get_module_inventory())
    elseif machine_base_parallel then
        module_parallel = 0
    else
        return nil, nil, nil
    end

    local parallel = math.min(max_total_parallel, module_parallel + (machine_base_parallel or 0))
    return parallel, math.ceil(parallel), module_parallel > 0
end

function Public.prepare_inventory(inventory)
    if not inventory or inventory.is_empty() then
        return nil
    end

    local filled = {}
    for i = 1, #inventory do
        local item_stack = inventory[i]
        filled[i] = item_stack and item_stack.count and item_stack.count > 0 and {
            name = item_stack.name,
            count = item_stack.count or 1,
            quality = item_stack.quality and item_stack.quality.name or nil,
            -- health = item_stack.health,
            -- durability = item_stack.durability,
            -- ammo = item_stack.ammo,
            -- tags = item_stack.tags,
            spoil_percent = item_stack.spoil_percent
        } or {}
    end
    return filled
end

function Public.spill_remaining_inventory(entity, filled)
    for i = 1, #filled do
        if filled[i] and table_size(filled[i]) > 0 and filled[i].count > 0 then
            entity.surface.spill_item_stack{
                position = entity.position,
                stack = filled[i],
                allow_belts = false
            }
        end
    end
end

function Public.update_inventory(entity, inventory, filled)
    if not filled then
        return
    end

    if not inventory then
        if entity.get_inventory(defines.inventory.crafter_trash) then
            for i = 1, #filled do
                filled[i].count = filled[i].count - entity.get_inventory(defines.inventory.crafter_trash).insert(filled[i])
            end
        end
        Public.spill_remaining_inventory(entity, filled)
        return
    end

    if #inventory == #filled then
        for i = 1, #filled do
            if filled[i] and table_size(filled[i]) > 0 then
                inventory[i].set_stack(filled[i])
                filled[i].count = filled[i].count - inventory[i].count
                if filled[i].count > 0 then
                    filled[i].count = filled[i].count - entity.get_inventory(defines.inventory.crafter_trash).insert(filled[i])
                end
            end
        end
    else
        for i = 1, #filled do
            if filled[i] and next(filled[i]) then
                filled[i].count = filled[i].count - inventory.insert(filled[i])
                if filled[i].count > 0 then
                    filled[i].count = filled[i].count - entity.get_inventory(defines.inventory.crafter_trash).insert(filled[i])
                end
            end
        end
    end
    Public.spill_remaining_inventory(entity, filled)
end

function Public.return_ingredients_or_get_progress(machine, recipe_prototype, quality)
    if not recipe_prototype or not machine.is_crafting() then
        return 0, 0
    end

    -- assembling machine => furnace
    local inventory = machine.get_inventory(defines.inventory.crafter_input)
    if not inventory or #inventory == 0 then
        return 0, 0
    end

    for _, ingredient in pairs(recipe_prototype.ingredients) do
        if ingredient.type == "fluid" then
            -- TODO: might break when using fluid energy source?
            machine.insert_fluid({
                name = ingredient.name,
                amount = ingredient.amount,
                temperature = ingredient.temperature or ingredient.minimum_temperature
            })
        else
            local stack = inventory.find_item_stack({
                name = ingredient.name,
                quality = quality and quality.name or "normal"
            })
            local spoil_percent = stack and stack.spoil_percent or nil
            inventory.insert({
                name = ingredient.name,
                count = ingredient.amount or 1,
                quality = quality and quality.name or "normal",
                spoil_percent = spoil_percent
            })
        end
    end
    return 0, 0
end

function Public.get_latest_recipe_and_parallel(unit_number)
    local latest = storage.machine_to_latest_recipe_and_parallel[unit_number]
    if not latest then
        return nil, nil, nil
    end

    return latest[1], latest[2], latest[3]
end

function Public.update_machine_for_parallel(machine, just_built)
    if not machine or not machine.valid then
        return
    end

    local is_ghost = machine.type == "entity-ghost"
    local type = (is_ghost and machine.ghost_type) or machine.type
    if not utils.table_contains_value(parallel_crafting_machine_types, type) then
        return
    end

    local current_machine_parallel, rounded_machine_parallel, has_parallel_modules = Public.get_total_machine_parallel_optimized(machine, is_ghost)
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
            _, base_recipe_name = next(parallel_module_mod_recipe_table_inverse[recipe_name] or {})
        end
        local was_crafting = was_changed and machine.is_crafting()
        local crafting_progress, bonus_progress = Public.return_ingredients_or_get_progress(machine, recipe, quality)

        Public.set_parallel_recipe(
            machine,
            is_ghost,
            Public.get_parallel_recipe(base_recipe_name, rounded_machine_parallel),
            quality,
            (recipe and recipe.name) or nil
        )

        if was_crafting and base_recipe_name and recipe then
            if crafting_progress > 0 then
                machine.crafting_progress = crafting_progress
            end
            if bonus_progress > 0 then
                machine.bonus_progress = bonus_progress
            end
        end
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
                tooltip_machine_parallel == max_total_parallel and "mod-tooltip-value.parallel-module-value-max" or "mod-tooltip-value.parallel-module-value",
                cached_tostring(tooltip_machine_parallel * 100)
            },
            order = 90
        })
    end
    
    storage.machine_to_latest_recipe_and_parallel[machine.unit_number] = { recipe_name, current_machine_parallel, is_set_recipe }
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
        for _, machine in pairs(Public.get_crafting_machines_including_ghosts(surface, action.target.position)) do
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
        local current_parallel_to_base_recipe_name = bp_entity.recipe and parallel_module_mod_recipe_table_inverse[bp_entity.recipe]

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

function Public.handle_entity_gui_opened(player_index, entity)
    if not entity then
        local player = game.players[player_index]
        if not player or not player.valid then
            return
        end
        entity = player.opened
    end

    if not entity or entity.object_name ~= "LuaEntity" or not entity.valid or entity == storage.player_to_machine_with_open_gui[player_index] then
        return
    end

    local entity_name = entity.name == "entity-ghost" and entity.ghost_name or entity.name
    if machine_accepts_parallel_modules[entity_name] or entity_to_base_parallel[entity_name] then
        storage.player_to_machine_with_open_gui[player_index] = entity
    end
end

function Public.handle_entity_gui_closed(player_index, entity)
    if entity ~= storage.player_to_machine_with_open_gui[player_index] then
        return
    end

    storage.player_to_machine_with_open_gui[player_index] = nil
end

function Public.handle_player_selection_changed(player_index, last_entity)
    local player = game.get_player(player_index)
    local entity = player and player.valid and player.selected or nil
    if not entity or entity.object_name ~= "LuaEntity" or not entity.valid or not utils.table_contains_value(parallel_crafting_machine_types, (entity.type == "entity-ghost" and entity.ghost_type) or entity.type) then
        storage.player_to_selected_machine[player_index] = nil
    else
        storage.player_to_selected_machine[player_index] = entity
    end
end

function Public.handle_player_joined(player_index, player_name)
    Public.handle_entity_gui_opened(player_index or player_name)
    Public.handle_player_selection_changed(player_index or player_name)
end

function Public.handle_player_left(player_index, player_name)
    if not player_index then
        local player = game.get_player(player_name)
        player_index = player and player.valid and player.index
    end
    if not player_index then
        return
    end

    storage.player_to_machine_with_open_gui[player_index] = nil
    storage.player_to_selected_machine[player_index] = nil
end

local inventories_to_copy = {
    -- TODO: Add check and include these? Or check if this ever returns wrong inventory for crafting machines?
    -- defines.inventory.fuel,
    -- defines.inventory.burnt_result,
    defines.inventory.crafter_input,
    defines.inventory.crafter_output,
    defines.inventory.crafter_modules,
    defines.inventory.crafter_trash,
}

function Public.set_parallel_recipe(entity, is_ghost, recipe, quality, current_recipe)
    if recipe and recipe == current_recipe then
        return
    end

    local players_with_machine_open = {}
    local players_with_machine_selected = {}
    for player_index, open_machine in pairs(storage.player_to_machine_with_open_gui) do
        if open_machine == entity then table.insert(players_with_machine_open, player_index) end
    end
    for player_index, selected_machine in pairs(storage.player_to_selected_machine) do
        if selected_machine == entity then table.insert(players_with_machine_selected, player_index) end
    end

    -- TODO: what about to_be_upgraded()?
    local inventory_to_filled = nil
    local fluids_by_index = nil
    if not is_ghost then
        -- TODO: check interactions with all/any other code that touches inventories
        inventory_to_filled = {}
        for _, inventory in pairs(inventories_to_copy) do
            inventory_to_filled[inventory] = Public.prepare_inventory(entity.get_inventory(inventory))
        end
    end

    if recipe and entity.type == "assembling-machine" then
        entity.set_recipe(recipe, quality)
    end
    if inventory_to_filled then
        for inventory, filled in pairs(inventory_to_filled) do
            Public.update_inventory(entity, entity.get_inventory(inventory), filled)
        end
        if fluids_by_index then
            for i = 1, entity.fluids_count do
                if fluids_by_index[i] and fluids_by_index[i].amount > 0 then
                    entity.set_fluid(i, fluids_by_index[i])
                end
            end
        end
    end
end

return Public