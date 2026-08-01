if not mods["planetaris-tellus"] then return end

local bioassembler_dead = data.raw["assembling-machine"]["planetaris-bioassembler-dead"]
if not bioassembler_dead or not bioassembler_dead.fixed_recipe then
    return
end

local explicit_recipes_without_results = data.raw["mod-data"].parallel_module_mod_data.data.explicit_recipes_without_results
local explicit_entities = data.raw["mod-data"].parallel_module_mod_data.data.explicit_entities

table.insert(explicit_recipes_without_results, bioassembler_dead.fixed_recipe)
table.insert(explicit_entities, "planetaris-bioassembler-dead")