local item_sounds = require("__base__.prototypes.item_sounds")

-- Add module effect in data-final-fixes to prevent other mods from incorrectly classifying rigor modules as efficiency modules
data:extend({
  -- {
  --   type = "module-category",
  --   name = "rigor"
  -- },
  {
    type = "module",
    name = "rigor-module",
    icon = "__rigor-module__/graphics/icons/rigor-module.png",
    icon_size = 64,
    subgroup = "module",
    category = "rigor",
    tier = 1,
    order = "d[rigor]-a[rigor-module-1]",
    inventory_move_sound = item_sounds.module_inventory_move,
    pick_sound = item_sounds.module_inventory_pickup,
    drop_sound = item_sounds.module_inventory_move,
    stack_size = 50,
    weight = 20 * kg,
    effect = {},
  },
  {
    type = "module",
    name = "rigor-module-2",
    icon = "__rigor-module__/graphics/icons/rigor-module-2.png",
    icon_size = 64,
    subgroup = "module",
    category = "rigor",
    tier = 2,
    order = "d[rigor]-b[rigor-module-2]",
    inventory_move_sound = item_sounds.module_inventory_move,
    pick_sound = item_sounds.module_inventory_pickup,
    drop_sound = item_sounds.module_inventory_move,
    stack_size = 50,
    weight = 20 * kg,
    effect = {},
  },
  {
    type = "module",
    name = "rigor-module-3",
    icon = "__rigor-module__/graphics/icons/rigor-module-3.png",
    icon_size = 64,
    subgroup = "module",
    category = "rigor",
    tier = 3,
    order = "d[rigor]-c[rigor-module-3]",
    inventory_move_sound = item_sounds.module_inventory_move,
    pick_sound = item_sounds.module_inventory_pickup,
    drop_sound = item_sounds.module_inventory_move,
    stack_size = 50,
    weight = 20 * kg,
    effect = {},
  },
  {
    type = "tips-and-tricks-item-category",
    name = "rigor-module-mod",
    order = "jj-[rigor]"
  },
  {
    type = "tips-and-tricks-item",
    name = "rigor-module-mod-tip-1",
    category = "rigor-module-mod",
    order = "a",
    is_title = true,
    trigger = { type = "research", technology = "rigor-module" }
  },
  {
    type = "tips-and-tricks-item",
    name = "rigor-module-mod-tip-2",
    category = "rigor-module-mod",
    order = "b",
    dependencies = { "rigor-module-mod-tip-1" },
    indent = 1,
    tag = "[item=rigor-module][item=rigor-module-3]",
    trigger = { type = "dependencies-met" },
    skip_trigger = {
      type = "sequence",
      triggers = {
        {
          type = "dependencies-met",
        },
        {
          type = "time-elapsed",
          ticks = 180 * minute
        }
      }
    },
    simulation = {
      init = [[
        local utils = require("__rigor-module__.utils")

        player = game.simulation.create_test_player{name = "Rigor Manager"}
        player.teleport({-7.5, 0})
        game.simulation.camera_player = player
        game.simulation.camera_position = {0, 0.5}
        game.simulation.camera_alt_info = true
        game.simulation.camera_player_cursor_position = player.position
        game.simulation.hide_cursor = true
        player.character.direction = defines.direction.south

        game.surfaces[1].create_entities_from_blueprint_string{
          string = "0eNp9UNtqwzAM/Rc9O2Vtk3Txr4xQnERkYrFcbKcsBP97lZrSvWQgDPK56EgrdNOMN08cQa9AveMA+muFQCObaftjYxE0mBDQdhPxWFjTfxNjcYakgHjAX9DH1CpAjhQJs8OzWa482w69ENS/TgpuLojY8TZTDIv61BwqBYtIL/Wh2kZFtNmbhj/JPI3OF9YN8/TKlInC4yvxXZI4v2ThuysVhGj6H9AfSe0gx13ktIucU5uk2hxD8r0vrOCOPjx3rGS9smmqz7K+yJPSA5uSgzc=",
          position = {-8, 2}
        }


        show_probabilities = function()

          local intitial_probabilities = { 0.001, 0.01, 0.05, 0.1, 0.25 }
          local rigor_levels = { 0, 0.5, 1, 2, 5, 10, 20 }

          local frame = game.players[1].gui.screen.add{
            type = "frame",
            caption = {"tips-and-tricks-simulation.rigor-module-mod-tip-2"},
            direction = "vertical"
          }
          frame.auto_center = true
          local inner = frame.add{
            type = "frame",
            style = "inside_shallow_frame_with_padding",
            direction = "vertical"
          }
          local rigor_table = inner.add{
            type = "table",
            column_count = table_size(rigor_levels),
            style = "bordered_table"
          }
          rigor_table.add{
            type = "label",
            caption = {"tips-and-tricks-simulation.initial-probability"},
            style = "bold_label"
          }

          for _, rigor in pairs (rigor_levels) do
            if rigor ~= 0 then
              rigor_table.add{
                type = "label",
                caption = {"tips-and-tricks-simulation.with-rigor", rigor * 100},
                style = "bold_label"
              }
            end
          end

          for _, probability in pairs (intitial_probabilities) do
            -- rigor_table.add{
            --   type = "label",
            --   caption = {"tips-and-tricks-simulation.rigor-probability", string.format("%.2f", probability * 100)}
            -- }
            for _, rigor in pairs(rigor_levels) do
            rigor_table.add{
              type = "label",
              caption = {"tips-and-tricks-simulation.rigor-probability", string.format("%.2f", utils.scale_probability_as_odds(probability, 1 + rigor) * 100)}
            }
            end
          end
        end

        show_probabilities()
      ]]
    }
  }
})
