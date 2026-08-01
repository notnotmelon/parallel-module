require("__parallel-module__.compat.virentis-final-fixes")
require("__parallel-module__.compat.planetaris-tellus-final-fixes")

_G.EFFECT_NAME = "parallel"

local utils = require("__parallel-module__.utils")
local spoilable_items = require("__item-request-proxy-events__.spoilable-items")
local get_base_parallel = require("prototypes.final-fixes.base-parallel")

local types_with_allowed_module_categories = { "assembling-machine", "furnace", "beacon", "lab", "mining-drill", "recipe" }
if data.raw["agricultural-tower"] then
    table.insert(types_with_allowed_module_categories, "agricultural-tower")
end
local parallel_module_mod_data = data.raw["mod-data"].parallel_module_mod_data.data

local explicitly_disallowed_categories = parallel_module_mod_data.disallowed_crafting_categories
local additional_default_categories = parallel_module_mod_data.additional_default_categories
local crafting_machine_types = parallel_module_mod_data.crafting_machine_types

_G.crafting_category_to_max_module_slots = {}
_G.crafting_category_to_max_parallel_without_modules = {}
local crafting_category_to_should_enable_parallel_effect = {}
local original_to_altered_crafting_category = {}
_G.max_parallel_per_module = 0

local parallel_value_cache = data.raw["mod-data"].parallel_module_mod_parallel_value_cache.data

-------------------------------------------------------------------------------
--- MODULES
-------------------------------------------------------------------------------

-- Update default allowed module categories
local base_module_categories
ModuleCategoryDefaults = ModuleCategoryDefaults
if ModuleCategoryDefaults and ModuleCategoryDefaults.default_categories then
    base_module_categories = ModuleCategoryDefaults.default_categories
else
    base_module_categories = { "speed", "efficiency", "productivity" }
    if mods["quality"] then
        table.insert(base_module_categories, "quality")
    end
end
for _, category in pairs(additional_default_categories) do
    if data.raw["module-category"][category] then
        table.insert(base_module_categories, category)
    end
end
local base_module_category_mask = {}
for _, category in pairs(base_module_categories) do
    base_module_category_mask[category] = true
end

local module_categories_with_explicit_entity_rules = {}
local module_categories_with_explicit_recipe_rules = {}
for _, prototype_type in pairs(types_with_allowed_module_categories) do
    local is_recipe = prototype_type == "recipe"
    for _, prototype in pairs(data.raw[prototype_type]) do
        if prototype.allowed_module_categories then
            for _, category in pairs(prototype.allowed_module_categories) do
                if not base_module_category_mask[category] then
                    if is_recipe then
                        module_categories_with_explicit_recipe_rules[category] = true
                    else
                        module_categories_with_explicit_entity_rules[category] = true
                    end
                end
            end
        end
    end
end

-- Normalize prototypes' allowed_module_categories
local base_categories_recipe = table.deepcopy(base_module_categories)
local base_category_mask_recipe = table.deepcopy(base_module_category_mask)
local base_categories_entity = table.deepcopy(base_module_categories)
local base_category_mask_entity = table.deepcopy(base_module_category_mask)
for _, category in pairs(data.raw["module-category"]) do
    if not base_module_category_mask[category.name] then
        if not module_categories_with_explicit_recipe_rules[category.name] then
            table.insert(base_categories_recipe, category.name)
            base_category_mask_recipe[category.name] = true
        end
        if not module_categories_with_explicit_entity_rules[category.name] then
            table.insert(base_categories_entity, category.name)
            base_category_mask_entity[category.name] = true
        end
    end
end

for _, prototype_type in pairs(types_with_allowed_module_categories) do
    local is_recipe = prototype_type == "recipe"
    for _, prototype in pairs(data.raw[prototype_type]) do
        if not prototype.allowed_module_categories then
            prototype.allowed_module_categories = table.deepcopy(is_recipe and base_categories_recipe or base_categories_entity)
            goto continue
        end
        if table_size(prototype.allowed_module_categories) == 0 then
            goto continue
        end

        local base_category_mask_typed = is_recipe and base_category_mask_recipe or base_category_mask_entity
        for _, category in pairs(prototype.allowed_module_categories) do
            if not base_category_mask_typed[category] then
                goto continue
            end
        end

        prototype.allowed_module_categories = table.deepcopy(is_recipe and base_categories_recipe or base_categories_entity)
        ::continue::
    end
end

local function module_stregth(module, quality)
    if not module.effect or not module.effect.parallel then
        return 0
    end
    if not quality then
        return module.effect.parallel
    end
    return module.effect.parallel * (quality.level + 1)
end

do
    local max_quality_multipler = 1
    for _, quality in pairs(data.raw.quality) do
        max_quality_multipler = math.max(max_quality_multipler, quality.level + 1)
    end


    local function to_quality_values(module)
        local result = {}
        for name, quality in pairs(data.raw.quality) do
            result[name] = { "mod-tooltip-value.parallel-module-value", tostring(100 * module_stregth(module, quality)) }
        end
        return result
    end

    for module_name, module in pairs(data.raw.module) do
        if module.category ~= "parallel" then
            goto continue
        end

        if spoilable_items.register_item_spoiled_event(module) then
            data.raw["mod-data"].spoilable_parallel_modules.data[module_name] = true
        end

        module.effect.parallel = module.effect.parallel or 0
        max_parallel_per_module = math.max(max_parallel_per_module, module.effect.parallel * max_quality_multipler)
        module.custom_tooltip_fields = {{
            name = { "mod-tooltip-name.parallel-module-parallel" },
            value = { "mod-tooltip-value.parallel-module-value", tostring(module.effect.parallel), },
            quality_values = to_quality_values(module),
            order = 79
        }}
        local tier = tostring(module.tier)
        if not parallel_value_cache[tier] then
            parallel_value_cache[tier] = {}
            for name, quality in pairs(data.raw.quality) do
                parallel_value_cache[tier][name] = module_stregth(module, quality)
            end
        end
        ::continue::
    end
end

-------------------------------------------------------------------------------
--- RECIPE CATEGORIES
-------------------------------------------------------------------------------

-- Set max module slots per crafting category
for name, _ in pairs(data.raw["recipe-category"]) do
    crafting_category_to_max_module_slots[name] = 0
    crafting_category_to_max_parallel_without_modules[name] = 0
    crafting_category_to_should_enable_parallel_effect[name] = false
end

local function calculate_max_module_slots(machines)
    for _, machine in pairs(machines) do
        local machine_module_slots = machine.module_slots or 0
        
        local categories = {}
        for _, category in pairs(machine.crafting_categories) do
            if utils.table_contains_value(explicitly_disallowed_categories, category) then
                goto continue
            end

            table.insert(categories, category)
            ::continue::
        end
        if table_size(categories) == 0 then
            goto continue
        end

        if machine.quality_affects_module_slots then
            local max_extra_module_slots = 0
            for _, quality in pairs(data.raw.quality) do
                if machine.module_slots_quality_bonus and machine.module_slots_quality_bonus[quality.name] then
                    max_extra_module_slots = math.max(max_extra_module_slots, machine.module_slots_quality_bonus[quality.name])
                else
                    max_extra_module_slots = math.max(max_extra_module_slots, quality.crafting_machine_module_slots_bonus or quality.level)
                end
            end
            machine_module_slots = machine_module_slots + max_extra_module_slots
        end
        local base_machine_parallel = get_base_parallel(machine)
        for _, category in pairs(categories) do
            if not data.raw["recipe-category"][category] then
                goto continue
            end
            crafting_category_to_max_module_slots[category] = math.max(crafting_category_to_max_module_slots[category], machine_module_slots)
            crafting_category_to_max_parallel_without_modules[category] = math.max(crafting_category_to_max_parallel_without_modules[category], base_machine_parallel)
            ::continue::
        end
        ::continue::
    end
end

for _, machine_type in pairs(crafting_machine_types) do
    calculate_max_module_slots(data.raw[machine_type])
end

require "prototypes.final-fixes.recipe-productivity-technologies"

-------------------------------------------------------------------------------
--- ENTITIES
-------------------------------------------------------------------------------

-- Register entities with bplib
local extract_entity_names = data.raw["mod-data"]["bplib"].data.extract_entity_names
local overlap_entity_names = data.raw["mod-data"]["bplib"].data.overlap_entity_names

local function register_with_bplib(name)
    overlap_entity_names[name] = true
    extract_entity_names[name] = true
end

local function enable_parallel_module_for_machines(machines)
    for name, machine in pairs(machines) do
        if machine["module_slots"] == nil or machine.type == "furnace" then
            goto continue
        end

        local new_categories = {}
        for _, category in pairs(machine.crafting_categories) do
            if crafting_category_to_should_enable_parallel_effect[category] then
                table.insert(machine.allowed_module_categories, EFFECT_NAME)
                register_with_bplib(name)
                table.insert(new_categories, original_to_altered_crafting_category[category])
            end
        end
        for _, new_category in pairs(new_categories) do
            table.insert(machine.crafting_categories, new_category)
        end
        ::continue::
    end
end

for _, machine_type in pairs(crafting_machine_types) do
    enable_parallel_module_for_machines(data.raw[machine_type])
end

require "prototypes.final-fixes.hidden-recipes"

parallel_module_mod_data.additional_default_categories = nil
