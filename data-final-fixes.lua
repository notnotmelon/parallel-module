-------------------------------------------------------------------------------
--- SETUP
-------------------------------------------------------------------------------

local utils = require("__rigor-module__.utils")
local data_utils = require("__rigor-module__.data-utils")
local spoilable_items = require("__item-request-proxy-events__.spoilable-items")

local EFFECT_NAME = "rigor"
local types_with_allowed_module_categories = { "assembling-machine", "furnace", "beacon", "lab", "mining-drill", "recipe" }
if data.raw["agricultural-tower"] then
    table.insert(types_with_allowed_module_categories, "agricultural-tower")
end
local rigor_module_mod_data = data.raw["mod-data"].rigor_module_mod_data.data

local explicitly_allowed_recycling_recipes = rigor_module_mod_data.allowed_recycling_recipes
local explicitly_disallowed_categories = rigor_module_mod_data.disallowed_crafting_categories
local explicitly_disallowed_recipes = rigor_module_mod_data.disallowed_recipes
local recipe_to_result_to_alter = rigor_module_mod_data.explicit_recipe_results
local recipe_to_result_to_alter_idx = rigor_module_mod_data.explicit_recipe_result_indices
local explicit_recipes_without_results = rigor_module_mod_data.explicit_recipes_without_results
local explicit_entities = rigor_module_mod_data.explicit_entities
local entity_to_base_rigor = rigor_module_mod_data.entity_to_base_rigor
local extra_count_fraction_recipe_results = rigor_module_mod_data.extra_count_fraction_recipe_results
local additional_default_categories = rigor_module_mod_data.additional_default_categories
local crafting_machine_types = rigor_module_mod_data.crafting_machine_types
local module_value_increment = rigor_module_mod_data.round_rigor_to_nearest / 100.0
local max_total_rigor = rigor_module_mod_data.max_total_rigor / 100.0

local crafting_category_to_max_module_slots = {}
local crafting_category_to_max_rigor_without_modules = {}
local crafting_machine_to_max_module_slots = {}
local crafting_category_to_should_enable_rigor_effect = {}
local crafting_categories_in_furnaces = {}
local new_recipes = {}
local base_recipe_to_affected_result = {}
local crafting_category_to_recipes = {}
local new_crafting_categories = {}
local altered_to_original_crafting_category = {}
local original_to_altered_crafting_category = {}
local new_machines = {}

local base_recipe_to_altered_recipes = data.raw["mod-data"].rigor_module_mod_recipe_table.data
local altered_recipe_to_base_recipe_rigor_pair = data.raw["mod-data"].rigor_module_mod_recipe_table_inverse.data
local base_machine_to_altered_machine = data.raw["mod-data"].rigor_module_mod_crafting_machine_table.data
local altered_machine_to_base_machine = data.raw["mod-data"].rigor_module_mod_crafting_machine_table_inverse.data
local rigor_value_cache = data.raw["mod-data"].rigor_module_mod_rigor_value_cache.data
local crafting_machine_to_fixed_base_recipe = data.raw["mod-data"].crafting_machine_to_fixed_base_recipe.data

local compatibility_mode = settings.startup["rigor-module-compatibility-mode"].value
local compatibiltiy_mode_include_vanilla = compatibility_mode and settings.startup["rigor-module-compatibility-mode-include-vanilla"].value

local compatibility_mode_category_whitelist = rigor_module_mod_data.compatibility_mode_category_whitelist
local compatibility_mode_recipe_whitelist = rigor_module_mod_data.compatibility_mode_recipe_whitelist

-------------------------------------------------------------------------------
--- VALIDATION
-------------------------------------------------------------------------------

assert(module_value_increment > 0, "'round_rigor_to_nearest' must be positive.")
assert(max_total_rigor > module_value_increment, "'max_total_rigor' must greater than 'module_value_increment'.")
assert(max_total_rigor % module_value_increment == 0, "'max_total_rigor' must be a whole-number multipler of 'round_rigor_to_nearest'.")

-------------------------------------------------------------------------------
--- COMPATIBILITY
-------------------------------------------------------------------------------

if compatibiltiy_mode_include_vanilla then
    compatibility_mode_recipe_whitelist["uranium-processing"] = true
    if mods["space-age"] then
        compatibility_mode_recipe_whitelist["scrap-recycling"] = true
        compatibility_mode_recipe_whitelist["yumako-processing"] = true
        compatibility_mode_recipe_whitelist["jellynut-processing"] = true
        compatibility_mode_recipe_whitelist["copper-bacteria"] = true
        compatibility_mode_recipe_whitelist["iron-bacteria"] = true

        for _, recipe in pairs({
            "metallic-asteroid-crushing",
            "carbonic-asteroid-crushing",
            "oxide-asteroid-crushing"
        }) do
            compatibility_mode_recipe_whitelist[recipe] = true
            compatibility_mode_recipe_whitelist["advanced-"..recipe] = true
        end
    end
end
if compatibility_mode then
    log("\nCOMPATIBILITY MODE ENABLED")
    log("\nRecipe category whitelist: " .. serpent.block(compatibility_mode_category_whitelist))
    log("\nRecipe whitelist: " .. serpent.block(compatibility_mode_recipe_whitelist))
end

if mods["Flare Stack"] then
    require("compat.flare-stack-final-fixes")
end
-- TODO: use space locations
if mods["virentis"] then
    require("__rigor-module__.compat.virentis-final-fixes")
end
if mods["planetaris-tellus"] then
    require("__rigor-module__.compat.planetaris-tellus-final-fixes")
end
if data.raw["space-location"]["secretas"] then
    require("__rigor-module__.compat.secretas-final-fixes")
end

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

-- Add rigor
data:extend({
  {
    type = "module-category",
    name = "rigor"
  }
})

local function to_quality_values(quality_to_multiplier, rigor)
  local result = {}
  for quality, multiplier in pairs(quality_to_multiplier) do
    result[quality] = { "mod-tooltip-value.rigor-module-value", tostring(rigor * multiplier) }
  end
  return result
end

-- Update rigor module prototypes (do it here in case another mod added another tier)
local quality_to_multiplier = {}
local max_quality_multipler = 1
for quality_name, quality in pairs(data.raw.quality) do
    local quality_multiplier = quality.default_multiplier or (1.0 + 0.3 * quality.level)
    quality_to_multiplier[quality_name] = quality_multiplier
    max_quality_multipler = math.max(max_quality_multipler, quality_multiplier)
end

local rigor_module_coefficients = data.raw["mod-data"].rigor_module_mod_data.data.rigor_formula_coefficients
for module_name, module in pairs(data.raw.module) do
    if module.category ~= "rigor" then
        goto continue
    end

    if spoilable_items.register_item_spoiled_event(module) then
        data.raw["mod-data"].spoilable_rigor_modules.data[module_name] = true
    end

    -- Add consumption effect to rigor modules
    module.effect = { consumption = 0.125 * 2 ^ module.tier }
    local rigor = utils.get_rigor_effect(rigor_module_coefficients, module.tier)
    rigor_module_mod_data.max_rigor_per_module = math.max(rigor_module_mod_data.max_rigor_per_module, rigor * max_quality_multipler)
    module.custom_tooltip_fields = {{
        name = { "mod-tooltip-name.rigor-module-rigor" },
        value = { "mod-tooltip-value.rigor-module-value", tostring(rigor), },
        quality_values = to_quality_values(quality_to_multiplier, rigor),
        order = 80
    }}
    local tier = tostring(module.tier)
    if not rigor_value_cache[tier] then
        rigor_value_cache[tier] = {}
        for quality, multiplier in pairs(quality_to_multiplier) do
            rigor_value_cache[tier][quality] = rigor * multiplier
        end
    end
    ::continue::
end

local module_value_max_per_slot = rigor_module_mod_data.max_rigor_per_module / 100.0

-------------------------------------------------------------------------------
--- RECIPE CATEGORIES
-------------------------------------------------------------------------------

-- Set max module slots per crafting category
for name, _ in pairs(data.raw["recipe-category"]) do
    crafting_category_to_max_module_slots[name] = 0
    crafting_category_to_max_rigor_without_modules[name] = 0
    crafting_category_to_should_enable_rigor_effect[name] = false
end

local valid_machines_with_base_rigor = {}

local function max_rigor_without_modules(machine)
    local base_rigor = machine and machine.type == "assembling-machine" and entity_to_base_rigor[machine.name] or 0
    if base_rigor > 0 then
        valid_machines_with_base_rigor[machine.name] = true
    end
    return base_rigor
end

local function calculate_max_module_slots(machines)
    for _, machine in pairs(machines) do
        local machine_module_slots = machine.module_slots or 0
        local explicitly_allowed = utils.table_contains_value(explicit_entities, machine.name)
        if not explicitly_allowed and machine.fixed_recipe then
            goto continue
        end

        local categories = {}
        for _, category in pairs(machine.crafting_categories) do
            if utils.table_contains_value(explicitly_disallowed_categories, category) then
                goto continue
            end
            if category:find("recycling", 1, true) or category:find("voidcraft", 1, true) then
                local has_any = false
                for _, recipe_name in pairs(explicitly_allowed_recycling_recipes) do
                    local recipe = data.raw.recipe[recipe_name]
                    -- TODO: compatibility mode?
                    if recipe and recipe.categories and utils.table_contains_value(recipe.categories, category) then
                        has_any = true
                        break
                    end
                end
                if not has_any then
                    goto continue
                end
            end

            table.insert(categories, category)
            ::continue::
        end
        if not explicitly_allowed and table_size(categories) == 0 then
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
        crafting_machine_to_max_module_slots[machine.name] = machine_module_slots
        local base_machine_rigor = max_rigor_without_modules(machine)
        for _, category in pairs(categories) do
            if not data.raw["recipe-category"][category] then
                goto continue
            end
            crafting_category_to_max_module_slots[category] = math.max(crafting_category_to_max_module_slots[category], machine_module_slots)
            crafting_category_to_max_rigor_without_modules[category] = math.max(crafting_category_to_max_rigor_without_modules[category], base_machine_rigor)
            if machine.type == "furnace" then
                crafting_categories_in_furnaces[category] = true
            end
            ::continue::
        end
        ::continue::
    end
end

for _, machine_type in pairs(crafting_machine_types) do
    calculate_max_module_slots(data.raw[machine_type])
end
for machine_name, rigor in pairs(entity_to_base_rigor) do
    if valid_machines_with_base_rigor[machine_name] then
        local item = data.raw.item[machine_name]
        if item then
            item.custom_tooltip_fields = item.custom_tooltip_fields or {}
            table.insert(item.custom_tooltip_fields, {
                name = { "mod-tooltip-name.rigor-module-rigor" },
                value = { "mod-tooltip-value.rigor-module-value", tostring(rigor) },
                order = 110,
                show_in_factoriopedia = true,
                show_in_tooltip = true
            })
        end
    else
        entity_to_base_rigor[machine_name] = nil
    end
end

local function is_category_valid(recipe_name, category, category_requires_whitelist)
    if not (category
            and crafting_category_to_max_module_slots[category]
            and crafting_category_to_max_module_slots[category] > 0
            and (not category_requires_whitelist or compatibility_mode_category_whitelist[category])) then
        return false
    end

    if category:find("recycling", 1, true) and not utils.table_contains_value(explicitly_allowed_recycling_recipes, recipe_name) then
        return false
    end
    if category:find("voidcraft", 1, true) and not utils.table_contains_value(explicitly_allowed_recycling_recipes, recipe_name) then
        return false
    end
    return true
end

local function get_max_module_slots_for_recipe(crafting_categories)
    local slots = 0
    for _, category in pairs(crafting_categories) do
        slots = math.max(slots, crafting_category_to_max_module_slots[category])
    end
    return slots
end

local function get_max_rigor_without_modules_for_recipe(crafting_categories)
    local rigor = 0
    for _, category in pairs(crafting_categories) do
        rigor = math.max(rigor, crafting_category_to_max_rigor_without_modules[category])
    end
    return rigor
end

-------------------------------------------------------------------------------
--- CREATE RIGOR RECIPE_CATEGORY PROTOTYPES
-------------------------------------------------------------------------------

local function get_or_create_crafting_category_if_valid(category)
    if not category or not crafting_categories_in_furnaces[category] then
        return category
    end

    local new_category = string.format("%s__rigor_module_mod", category)
    if not new_crafting_categories[new_category] then
        original_to_altered_crafting_category[category] = new_category
        new_crafting_categories[new_category] = {
            type = "recipe-category",
            name = new_category,
            hidden = true
        }
        altered_to_original_crafting_category[new_category] = category
    end
    return new_category
end

-------------------------------------------------------------------------------
--- CREATE RIGOR RECIPE PROTOTYPES
-------------------------------------------------------------------------------

local function get_prototype_helper(base_type, name)
    for type_name in pairs(defines.prototypes[base_type]) do
        local prototypes = data.raw[type_name]
        if prototypes and prototypes[name] then
            return prototypes[name]
        end
    end
end

local function get_recipe_localised_field(prototype, field_type)
    local field = "localised_"..field_type
    if prototype[field] then
        return prototype[field]
    end

    local fluid = data.raw.fluid[prototype.name]
    if fluid and fluid[field] then
        return fluid[field]
    end
    
    local entity = get_prototype_helper("entity", prototype.name)
    local equipment = get_prototype_helper("equipment", prototype.name)
    local tile = data.raw.tile[prototype.name]
    local item = data.raw.item[prototype.name]
    if item then
        if item[field] then
            return item[field]
        end

        entity = entity or (item.place_result and get_prototype_helper("entity", item.place_result))
        equipment = equipment or (item.place_as_equipment_result and get_prototype_helper("equipment", item.place_as_equipment_result))
        tile = tile or (item.place_as_tile_result and data.raw.tile[item.place_as_tile_result])
    end

    if entity and entity[field] then
        return entity[field]
    end
    if equipment and equipment[field] then
        return equipment[field]
    end
    if tile and tile[field] then
        return tile[field]
    end

    local localised_field = {
        "?",
        { "recipe-"..field_type.."."..prototype.name }
    }
    if fluid then
        table.insert(localised_field, { "fluid-"..field_type.."."..fluid.name })
    end
    if item then
        table.insert(localised_field, { "item-"..field_type.."."..item.name })
    end
    if entity then
        table.insert(localised_field, { "entity-"..field_type.."."..entity.name })
    end
    if equipment then
        table.insert(localised_field, { "equipment-"..field_type.."."..equipment.name })
    end
    if tile then
        table.insert(localised_field, { "tile-"..field_type.."."..tile.name })
    end
    return localised_field
end

local function set_recipe_icon_or_icons(prototype, prototype_with_icon)
    prototype.icon = prototype_with_icon.icon
    prototype.icon_size = prototype_with_icon.icon_size
    prototype.icons = prototype_with_icon.icons -- Non-deep copy is probably better
end

local function ensure_recipe_icon_or_icons(prototype, base_prototype)
    if prototype.icon or prototype.icons then
        return
    end

    local fluid = data.raw.fluid[base_prototype.name]
    if fluid and (fluid.icon or fluid.icons) then
        set_recipe_icon_or_icons(prototype, fluid)
        return
    end

    local entity = get_prototype_helper("entity", base_prototype.name)
    local equipment = get_prototype_helper("equipment", base_prototype.name)
    local tile = data.raw.tile[base_prototype.name]
    local item = data.raw.item[base_prototype.name]
    if item then
        if item and (item.icon or item.icons) then
            set_recipe_icon_or_icons(prototype, item)
            return
        end

        entity = entity or (item.place_result and get_prototype_helper("entity", item.place_result))
        equipment = equipment or (item.place_as_equipment_result and get_prototype_helper("equipment", item.place_as_equipment_result))
        tile = tile or (item.place_as_tile_result and data.raw.tile[item.place_as_tile_result])
    end

    if entity and (entity.icon or entity.icons) then
        set_recipe_icon_or_icons(prototype, entity)
        return
    end

    if equipment and (equipment.icon or equipment.icons) then
        set_recipe_icon_or_icons(prototype, equipment)
        return
    end

    if tile and (tile.icon or tile.icons) then
        set_recipe_icon_or_icons(prototype, tile)
        return
    end
end

for _, map in pairs({recipe_to_result_to_alter, extra_count_fraction_recipe_results}) do
    for recipe_name, result_name in pairs(map) do
        local recipe = data.raw.recipe[recipe_name]
        if not recipe or not recipe.results then
            goto continue
        end

        for _, result in pairs(recipe.results) do
            if result.name == result_name then
                goto continue
            end
        end

        -- TODO: Check that this is okay
        map[recipe_name] = nil -- Expected result not in recipe results
        ::continue::
    end
end

local quality_by_tier = {}
if data.raw.quality then
    for quality_name, quality in pairs(data.raw.quality) do
        quality_by_tier[quality.level] = quality_name
    end
end

local function quality_to_tier(name)
    if not name then
        return 0
    end

    local quality = data.raw.quality[name]
    return quality and quality.level or 0
end

local function set_custom_tooltip(recipe, result_to_alter_idx)
    if not recipe.custom_tooltip_fields then
        recipe.custom_tooltip_fields = {}
    end
    local rigor_tooltip_field
    local result_to_alter = recipe.results[result_to_alter_idx]
    local quality_tier = math.max(result_to_alter.quality_change or 0, quality_to_tier(result_to_alter.quality_min))
    if quality_tier > 0 then
        if result_to_alter.quality_max then
            quality_tier = math.min(quality_tier, quality_to_tier(result_to_alter.quality_max))
        end
        rigor_tooltip_field = {
            name = {"mod-tooltip-name.rigor-module-rigor"},
            value = {"mod-tooltip-value.rigor-module-recipe-item-quality", result_to_alter.name, quality_by_tier[quality_tier] or "common"},
            order = 200,
            show_in_factoriopedia = true,
            show_in_tooltip = false
        }
    else
        rigor_tooltip_field = {
            name = {"mod-tooltip-name.rigor-module-rigor"},
            value = {"mod-tooltip-value.rigor-module-recipe-"..result_to_alter.type, result_to_alter.name},
            order = 200,
            show_in_factoriopedia = true,
            show_in_tooltip = false
        }
    end
    if recipe.rigor_sensitivity then
        recipe.rigor_sensitivity = utils.round(recipe.rigor_sensitivity, 0.01)
        if recipe.rigor_sensitivity == 1 or recipe.rigor_sensitivity < 0.01 or recipe.rigor_sensitivity > 100 then
            recipe.rigor_sensitivity = nil
        else
            rigor_tooltip_field.value = {
                "",
                rigor_tooltip_field.value,
                {"mod-tooltip-value.rigor-module-rigor-sensitivity", tostring(recipe.rigor_sensitivity)}
            }
        end
    end
    table.insert(recipe.custom_tooltip_fields, rigor_tooltip_field)
end

for recipe_name, base_recipe in pairs(data.raw.recipe) do
    if utils.table_contains_value(explicitly_disallowed_recipes, recipe_name) then
        goto continue
    end
    local results = base_recipe.results
    if results == nil then
        goto continue
    end

    local valid_categories = {}
    local category_requires_whitelist = compatibility_mode and not compatibility_mode_recipe_whitelist[recipe_name]
    if not base_recipe.categories then
        base_recipe.categories = { "crafting" }
    end
    for _, category in pairs(base_recipe.categories) do
        if is_category_valid(recipe_name, category, category_requires_whitelist) then
            table.insert(valid_categories, category)
        end
    end
    if table_size(valid_categories) == 0 then
        goto continue
    end

    local use_extra_count_fraction = false
    local result_to_alter = recipe_to_result_to_alter[recipe_name]
    if not result_to_alter then
        result_to_alter = extra_count_fraction_recipe_results[recipe_name]
        use_extra_count_fraction = result_to_alter ~= nil
    end
    local result_to_alter_idx = recipe_to_result_to_alter_idx[recipe_name]
    if result_to_alter_idx and result_to_alter_idx > table_size(results) then
        result_to_alter_idx = nil
    end
    if not result_to_alter and not result_to_alter_idx then
        result_to_alter_idx = data_utils.lowest_probability_ingredient_idx(base_recipe)
        -- if still no result to alter, then this is not a probabilistic recipe
        if not result_to_alter_idx then
            if utils.table_contains_value(explicit_recipes_without_results, recipe_name) then
                table.insert(base_recipe.allowed_module_categories, EFFECT_NAME)
                for _, category in pairs(valid_categories) do
                    crafting_category_to_should_enable_rigor_effect[category] = true
                end
                base_recipe_to_affected_result[recipe_name] = "nil (explicit_recipes_without_results)"
            end
            goto continue
        end
    end

    -- Explicitly allow rigor modules in recipe.allowed_module_categories
    table.insert(base_recipe.allowed_module_categories, EFFECT_NAME)
    for _, category in pairs(valid_categories) do
        if not crafting_category_to_recipes[category] then
            crafting_category_to_recipes[category] = {}
        end
        crafting_category_to_recipes[category][recipe_name] = true
        crafting_category_to_should_enable_rigor_effect[category] = true
    end

    if not result_to_alter_idx then
        for i, output in pairs(base_recipe.results) do
            if output.name == result_to_alter then
                -- TODO: This is a mess and doesn't really work
                if use_extra_count_fraction and output.extra_count_fraction or output.independent_probability or output.shared_probability then
                    result_to_alter_idx = i
                    break
                end
            end
        end
        assert(result_to_alter_idx, "Could not find valid explicitly requested result "..result_to_alter.." for recipe "..recipe_name)
    end
    set_custom_tooltip(base_recipe, result_to_alter_idx)
    base_recipe_to_affected_result[recipe_name] = base_recipe.results[result_to_alter_idx].name

    base_recipe_to_altered_recipes[recipe_name] = { [tostring(0)] = recipe_name }
    altered_recipe_to_base_recipe_rigor_pair[recipe_name] = { [tostring(0)] = recipe_name }
    local total_max_module_value = math.min(max_total_rigor, get_max_rigor_without_modules_for_recipe(valid_categories) +
        module_value_max_per_slot * get_max_module_slots_for_recipe(valid_categories))
    local sensitivity = base_recipe.rigor_sensitivity or 1
    base_recipe.rigor_sensitivity = nil
    for scale = module_value_increment, total_max_module_value, module_value_increment do
        local new_recipe_name = string.format("%s__rigor_module_mod__%d", recipe_name, scale * 100)
        local scale_str = tostring(scale * 100)
        base_recipe_to_altered_recipes[recipe_name][scale_str] = new_recipe_name
        altered_recipe_to_base_recipe_rigor_pair[new_recipe_name] = { [scale_str] = recipe_name }
        local new_recipe = table.deepcopy(base_recipe)
        new_recipe.name = new_recipe_name
        new_recipe.localised_name = get_recipe_localised_field(base_recipe, "name")
        new_recipe.localised_description = get_recipe_localised_field(base_recipe, "description")
        local effective_scale = scale * sensitivity -- Recipes with rigor sensitivity have their effective rigor multiplied by their sensitivity value.
        ensure_recipe_icon_or_icons(new_recipe, base_recipe)
        new_recipe.factoriopedia_alternative = base_recipe.factoriopedia_alternative or recipe_name
        new_recipe.hidden = true
        -- new_recipe.hidden_in_factoriopedia = true
        -- new_recipe.hide_from_stats = true
        -- new_recipe.hide_from_player_crafting = true
        new_recipe.hide_from_bonus_gui = true
        local output = new_recipe.results[result_to_alter_idx]
        if use_extra_count_fraction then
            output.extra_count_fraction = utils.scale_probability_as_odds(output.extra_count_fraction, 1.0 + effective_scale)
        elseif base_recipe.results[result_to_alter_idx].independent_probability and base_recipe.results[result_to_alter_idx].independent_probability < data_utils.maximum_probability_valid_for_rigor then
            output.independent_probability = utils.scale_probability_as_odds(output.independent_probability, 1.0 + effective_scale)
        else
            data_utils.Strategy.simple_zero_sum_scale(new_recipe, result_to_alter_idx, 1.0 + effective_scale)
        end
        for i, category in pairs(new_recipe.categories) do
            new_recipe.categories[i] = get_or_create_crafting_category_if_valid(category)
        end
        new_recipes[new_recipe_name] = new_recipe
    end
    ::continue::
end

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

local function enable_rigor_module_for_machines(machines)
    for name, machine in pairs(machines) do
        if machine["module_slots"] == nil then
            goto continue
        end

        local rigor_added = false
        if utils.table_contains_value(explicit_entities, machine.name) then
            table.insert(machine.allowed_module_categories, EFFECT_NAME)
            register_with_bplib(name)
            rigor_added = true
        end

        local should_add_categories = machine.type ~= "furnace"
        local new_categories = {}
        for _, category in pairs(machine.crafting_categories) do
            if crafting_category_to_should_enable_rigor_effect[category] then
                if not rigor_added then
                    table.insert(machine.allowed_module_categories, EFFECT_NAME)
                    register_with_bplib(name)
                    rigor_added = true
                end
                if should_add_categories then
                    table.insert(new_categories, original_to_altered_crafting_category[category])
                end
            end
        end
        for _, new_category in pairs(new_categories) do
            table.insert(machine.crafting_categories, new_category)
        end
        ::continue::
    end
end

for _, machine_type in pairs(crafting_machine_types) do
    enable_rigor_module_for_machines(data.raw[machine_type])
end

-------------------------------------------------------------------------------
--- TECHNOLOGIES
-------------------------------------------------------------------------------

for _, technology in pairs(data.raw.technology) do
    if not technology.effects then
        goto continue
    end

    local base_unlock_recipes = {}
    local base_productivity_recipes = {}
    for _, effect in pairs(technology.effects) do
        if effect.type == "unlock-recipe" then
            table.insert(base_unlock_recipes, effect.recipe)
        elseif effect.type == "change-recipe-productivity" then
            base_productivity_recipes[effect.recipe] = effect.change
        end
    end

    for _, base_recipe in pairs(base_unlock_recipes) do
        local altered_recipes = base_recipe_to_altered_recipes[base_recipe]
        if altered_recipes == nil then
            goto continue
        end

        for _, altered_recipe in pairs(altered_recipes) do
            if altered_recipe ~= base_recipe then
                table.insert(technology.effects, {
                    type   = "unlock-recipe",
                    recipe = altered_recipe,
                    hidden = true
                })
            end
        end
        ::continue::
    end

    for base_recipe, change in pairs(base_productivity_recipes) do
        local altered_recipes = base_recipe_to_altered_recipes[base_recipe]
        if altered_recipes == nil then
            goto continue
        end

        for _, altered_recipe in pairs(altered_recipes) do
            if altered_recipe ~= base_recipe then
                table.insert(technology.effects, {
                    type   = "change-recipe-productivity",
                    recipe = altered_recipe,
                    change = change,
                    hidden = true
                })
            end
        end
        ::continue::
    end
    ::continue::
end

-------------------------------------------------------------------------------
--- CREATE RIGOR ENTITY PROTOTYPES
-------------------------------------------------------------------------------

local function get_entity_localised_field(prototype, field_type)
    local field = "localised_"..field_type
    if prototype[field] then
        return prototype[field]
    end

    local item = data.raw.item[prototype.name]
    if item and item[field] then
        return item[field]
    end

    local localised_field = {
        "?",
        { "entity-"..field_type.."."..prototype.name }
    }
    if item then
        table.insert(localised_field, { "item-"..field_type.."."..item.name })
    end
    return localised_field
end

local function ensure_entity_icon_or_icons(prototype, base_prototype)
    if prototype.icon or prototype.icons then
        return
    end

    local item = data.raw.item[base_prototype.name]
    if item then
        prototype.icon = item.icon
        prototype.icon_size = item.icon_size
        prototype.icons = item.icons -- Non-deep copy is probably better
    end
end

local function prepare_machine_for_copying(machine_name, machine)
    if machine.type ~= "furnace"  or not machine.module_slots or not machine.allowed_module_categories or not utils.table_contains_value(machine.allowed_module_categories, "rigor") then
        return false
    end

    if not crafting_machine_to_max_module_slots[machine_name] or crafting_machine_to_max_module_slots[machine_name] <= 0 then
        return false
    end

    local total_max_module_value = math.min(max_total_rigor, module_value_max_per_slot * crafting_machine_to_max_module_slots[machine_name])
    if total_max_module_value <= 0 then
        return false
    end

    if not machine.fast_replaceable_group then
        machine.fast_replaceable_group = machine_name
    end
    return true
end

local base_machines_to_copy = {}
for _, machine_type in pairs(crafting_machine_types) do
    for machine_name, machine in pairs(data.raw[machine_type]) do
        if prepare_machine_for_copying(machine_name, machine) then
            table.insert(base_machines_to_copy, machine_name)
        end
    end
end

-- Convert furnaces to crafting machines
for _, base_machine_name in pairs(base_machines_to_copy) do
    local base_machine = data.raw.furnace[base_machine_name]
    if not base_machine then
        goto continue_machines
    end

    local categories = {}
    local recipes = {}
    for _, category in pairs(base_machine.crafting_categories) do
        if not crafting_category_to_recipes[category] then
            goto continue_categories
        end

        categories[category] = true
        for recipe_name, _ in pairs(crafting_category_to_recipes[category]) do
            recipes[recipe_name] = true
        end
        ::continue_categories::
    end

    if table_size(recipes) == 0 then
        goto continue_machines
    end

    if table_size(recipes) == 1 then
        local recipe_name, _ = next(recipes)
        crafting_machine_to_fixed_base_recipe[base_machine_name] = recipe_name
    end
    local new_machine_name = string.format("%s__rigor-module", base_machine_name)
    local max_inventory_size = math.max(base_machine.result_inventory_size, base_machine.source_inventory_size)
    base_machine.trash_inventory_size = math.max(base_machine.trash_inventory_size or 1, max_inventory_size)
    local new_machine = table.deepcopy(base_machine)
    new_machine.name = new_machine_name
    new_machine.type = "assembling-machine"
    new_machine.localised_name = get_entity_localised_field(base_machine, "name")
    new_machine.localised_description = get_entity_localised_field(base_machine, "description")
    ensure_entity_icon_or_icons(new_machine, base_machine)
    if new_machine.icon then
        new_machine.icons = {
            {
                icon = new_machine.icon,
                icon_size = new_machine.icon_size,
            },
            {
                icon = "__rigor-module__/graphics/icons/rigor-module-3.png",
                icon_size = 64,
                scale = 0.3,
                shift = { -6, 6 },
                draw_background = true
            }
        }
        new_machine.icon = nil
    elseif new_machine.icons then
        table.insert(new_machine.icons, {
            icon = "__rigor-module__/graphics/icons/rigor-module-3.png",
            icon_size = 64,
            scale = 0.3,
            shift = { -6, 6 },
            draw_background = true
        })
    end
    if not new_machine.flags then
        new_machine.flags = {}
    end
    if not utils.table_contains_value(new_machine.flags, "not-in-made-in") then
        table.insert(new_machine.flags, "not-in-made-in")
    end
    if not utils.table_contains_value(new_machine.flags, "not-in-bonus-gui") then
        table.insert(new_machine.flags, "not-in-bonus-gui")
    end
    if base_machine.placeable_by then
        new_machine.placeable_by = base_machine.placeable_by
    elseif data.raw.item[base_machine.name] then
        new_machine.placeable_by = {
            item = base_machine.name,
            count = 1
        }
    end
    new_machine.deconstruction_alternative = base_machine.deconstruction_alternative or base_machine.name
    new_machine.factoriopedia_alternative = base_machine.factoriopedia_alternative or base_machine.name
    new_machine.crafting_categories = {}
    for category, _ in pairs(categories) do
        table.insert(new_machine.crafting_categories, category)
        table.insert(new_machine.crafting_categories, original_to_altered_crafting_category[category])
    end
    table.insert(new_machines, new_machine)
    register_with_bplib(new_machine_name)
    base_machine_to_altered_machine[base_machine_name] = new_machine_name
    altered_machine_to_base_machine[new_machine_name] = base_machine_name
    ::continue_machines::
end

for _, new_category in pairs(new_crafting_categories) do
    data:extend({ new_category })
end
for _, new_recipe in pairs(new_recipes) do
    data:extend({ new_recipe })
end
if next(new_machines) then
    data:extend(new_machines)
end

-- Update tips-and-tricks
if mods["space-age"] and (not compatibility_mode or compatibiltiy_mode_include_vanilla) then
    data.raw["tips-and-tricks-item"]["rigor-module-mod-tip-1"].simulation = {
        init = [[
            game.forces[1].enable_all_prototypes()
            game.forces[1].enable_all_recipes()

            game.surfaces[1].create_entities_from_blueprint_string{
                string = "0eNq9WdtuozAQ/Rc/wyrGXCPtl6wqRIiTWgWbNaZqtuLf1ySbW+NpDCNtVbVNHJ8zPp4r/SSbZuCdFtKQ9ScRtZI9Wf/6JL3Yy6qZ3pNVy8ma8I9O874Pja5k3yltwg1vDBkDIuSWf5A1HV8CwqURRvATxvHFoZRDu+HafiA4YwmtZFi/8t6QgHSqt1uUnLgsTJiw4kcSkANZR5n9axyDB6TIF4k+Q2LB1/M1qtralW/tyqk9tjl0RwtkN0wyPEDHV+iG10aLOuSS6/0htGJzvatq7mTJbjg2w27HddmLPxaHri5fDrrkQtcPm95UR1AXfnyD/3uoGgtiNzV8z+W20gfXUdI5KtFZKmXBEwf7/iIi97XmOFTmRi2WoNJnttIVDhYwllKcBjEAG+FgEwCW4USArI1xsJC1CU6EFIBNcbAZAJvhRICszXGwkLUFToQcKBkrHCxUiShOBMjaCAcLWctQIhQrADbGwVIANkGJAFqb4mAha3GVrACqQ4QrZQVQHaJrlGleH+oGKOb52TpbyrfCfvS0bN9uhdbKIhk9cO9Ggl2jcDM0b7YT6rk2AHd6p80df+zCpjOwYxibRi7wa0D2hvPmm54zeXaljD1oX5Za7JUOW7UdGndbyMCbcGkfTNDi2Hr1ta668MQk5P4fVXmimn6VZb5aXXaUVzipdGtnANvhG96eWnqxvRkJbm0OGYG84Lzd7palkO9WDmUXjnDXVzaH2K61fiPrY3frXKHgSgSusPFltN+Oa8D1BuDtIrMWELAM1xsUQIPEkFkLaJDYoqyV38F6BOVjq9B31gHNk2QWf0W3CzvRTNuuzv2qmlYMbag0v/PsS1DUqu0qXZkpCZKfk5+rwdgpp7TTtNLnMNi5Z8NF3UgG6+NKiPGi3iSFSXIXyaJOJZ5JwuZdNPvvF21T4av7phdlGTYzEuJFSSea6U/IxglIQTFuPIFSULwkBcWrC2zq5ZgFjiTz0T3BjS6PJ3G6UEJxKduTBff4wFMwhjuKH0mMS+GeeiW4HO7JkuLO4idYhjtK5hOQSY4rR6nXSQociddJ0hUupXudJKW46uRHEuFIMi8fThlOL0+WRVE/s6qkyBHC71aQ1dxTrwynlycL8iFJ7sdS4MqKH0uGHA08WZCzgScLcjjIfRw5Qwa+HwmyjfcjQca9g+Tl9PRleiZ2+T9vQN657o8fSFLblhdFksdpZn+M41/zCNyA",
                position = {0, -5}
            }
            
            game.simulation.camera_position = {0, 0.5}
            game.simulation.camera_alt_info = true
            game.forces[1].bulk_inserter_capacity_bonus = 12

            local steel_chest = game.surfaces[1].find_entities_filtered{name = "steel-chest"}[1]
            steel_chest.insert({name = "scrap", count = 1000})
        ]]
    }
end

rigor_module_mod_data.additional_default_categories = nil

local category_to_recipe_count = {}
local category_to_recipe_to_result = {}
for name, result in pairs(base_recipe_to_affected_result) do
    local recipe = data.raw.recipe[name]
    local original_category = altered_to_original_crafting_category[recipe.categories[1]] or recipe.categories[1]
    category_to_recipe_count[original_category] = (category_to_recipe_count[original_category] or 0) + table_size(base_recipe_to_altered_recipes[name] or {})
    if not category_to_recipe_to_result[original_category] then
        category_to_recipe_to_result[original_category] = {}
    end
    category_to_recipe_to_result[original_category][name] = result
end
log("Number of rigor-affected recipes by crafting category:\n" .. serpent.block(category_to_recipe_count))
log("Rigor-affected result of recipes by crafting category:\n" .. serpent.block(category_to_recipe_to_result))