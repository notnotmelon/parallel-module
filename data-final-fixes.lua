_G.mod_data = data.raw["mod-data"]["parallel-module"].data
_G.parallel = {mod_data = mod_data}

require "compat.virentis-final-fixes"
require "compat.disallowed-recipe-categories"

--require "prototypes.final-fixes.allowed-recipes"
--require "prototypes.final-fixes.allowed-machines"
require "prototypes.final-fixes.base-parallel"
require "prototypes.final-fixes.recipe-categories"
require "prototypes.final-fixes.convert-furnaces"
require "prototypes.final-fixes.module-categories"
require "prototypes.final-fixes.modules"
require "prototypes.final-fixes.recipe-productivity-technologies"
require "prototypes.final-fixes.hidden-recipes"
require "compat.bplib"
