local function try_warn()
    if #prototypes.recipe >= 60000 then
        game.print {"warnings.too-many-recipe-prototypes", #prototypes.recipe, 65536}
    end
end

parallel.on_event(parallel.events.on_init(), try_warn)

parallel.on_event(defines.events.on_player_joined_game, function()
    if game.tick < 10 then try_warn() end
end)
