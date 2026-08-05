parallel.on_event("bplib-overlaps", function(event)
    if not event or not event.overlaps then
        return
    end

    for _, entity in pairs(event.overlaps) do
        storage.machines_waiting_for_parallel_module[entity.unit_number] = entity
    end
end)

local function is_player_holding_cut_paste_tool(player)
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

local function sanitize_bp_entities(bp_entities)
    local was_modified = false
    for _, bp_entity in pairs(bp_entities) do
        local base_recipe_name = bp_entity.recipe and mod_data.recipe_table_inverse[bp_entity.recipe]

        -- Set blueprint entity's recipe to non-parallel version, if applicable
        if base_recipe_name and bp_entity.recipe ~= base_recipe_name then
            was_modified = true
            bp_entity.recipe = base_recipe_name
        end
    end

    return was_modified
end

parallel.on_event("bplib-extract", function(event)
    if is_player_holding_cut_paste_tool(event.player_index) then return end -- preserve external wire connections
    if not event.blueprint then return end
    local bp_entities = event.blueprint.get_blueprint_entities()
    if not bp_entities then return end

    if sanitize_bp_entities(bp_entities) then
        event.blueprint.set_blueprint_entities(bp_entities)
    end
end)
