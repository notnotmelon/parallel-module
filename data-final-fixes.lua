ModuleCategoryDefaults.process_entity_prototypes()
ModuleCategoryDefaults.process_recipe_prototypes()

_G.mod_data = data.raw["mod-data"]["parallel-module"].data
_G.parallel = {mod_data = mod_data}

if mods.pypostprocessing then require "prototypes.item-recipe-technology" end

require "compat.virentis-final-fixes"
require "compat.disallowed-recipe-categories"

require "prototypes.final-fixes.allowed-recipes-and-machines"
require "prototypes.final-fixes.convert-furnaces"
require "prototypes.final-fixes.base-parallel"
require "prototypes.final-fixes.modules"
require "prototypes.final-fixes.module-categories"
require "prototypes.final-fixes.hidden-recipes"
require "prototypes.final-fixes.recipe-productivity-technologies"
require "prototypes.final-fixes.rocket-part-recipes"
require "compat.bplib"
