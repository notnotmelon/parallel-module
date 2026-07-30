-------------------------------------------------------------------------------
--- SETUP
-------------------------------------------------------------------------------

local utils = require("__parallel-module__.utils")
local data_utils = require("__parallel-module__.data-utils")
local spoilable_items = require("__item-request-proxy-events__.spoilable-items")

local EFFECT_NAME = "parallel"
local types_with_allowed_module_categories = { "assembling-machine", "furnace", "beacon", "lab", "mining-drill", "recipe" }
if data.raw["agricultural-tower"] then
    table.insert(types_with_allowed_module_categories, "agricultural-tower")
end
local parallel_module_mod_data = data.raw["mod-data"].parallel_module_mod_data.data

local explicitly_allowed_recycling_recipes = parallel_module_mod_data.allowed_recycling_recipes
local explicitly_disallowed_categories = parallel_module_mod_data.disallowed_crafting_categories
local explicitly_disallowed_recipes = parallel_module_mod_data.disallowed_recipes
local recipe_to_result_to_alter = parallel_module_mod_data.explicit_recipe_results
local explicit_entities = parallel_module_mod_data.explicit_entities
local entity_to_base_parallel = parallel_module_mod_data.entity_to_base_parallel
local extra_count_fraction_recipe_results = parallel_module_mod_data.extra_count_fraction_recipe_results
local additional_default_categories = parallel_module_mod_data.additional_default_categories
local crafting_machine_types = parallel_module_mod_data.crafting_machine_types
local max_total_parallel = parallel_module_mod_data.max_total_parallel / 100.0

local crafting_category_to_max_module_slots = {}
local crafting_category_to_max_parallel_without_modules = {}
local crafting_category_to_should_enable_parallel_effect = {}
local crafting_categories_in_furnaces = {}
local new_recipes = {}
local crafting_category_to_recipes = {}
local new_crafting_categories = {}
local original_to_altered_crafting_category = {}

local base_recipe_to_altered_recipes = data.raw["mod-data"].parallel_module_mod_recipe_table.data
local altered_recipe_to_base_recipe_parallel_pair = data.raw["mod-data"].parallel_module_mod_recipe_table_inverse.data
local parallel_value_cache = data.raw["mod-data"].parallel_module_mod_parallel_value_cache.data

-- TODO: use space locations
if mods["virentis"] then
    require("__parallel-module__.compat.virentis-final-fixes")
end
if mods["planetaris-tellus"] then
    require("__parallel-module__.compat.planetaris-tellus-final-fixes")
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

do
    local function to_quality_values(module)
    local result = {}
    for name, quality in pairs(data.raw.quality) do
        result[name] = { "mod-tooltip-value.parallel-module-value", tostring(module.effect.parallel * quality.level) }
    end
    return result
    end

    local parallel_module_coefficients = data.raw["mod-data"].parallel_module_mod_data.data.parallel_formula_coefficients
    for module_name, module in pairs(data.raw.module) do
        if module.category ~= "parallel" then
            goto continue
        end

        if spoilable_items.register_item_spoiled_event(module) then
            data.raw["mod-data"].spoilable_parallel_modules.data[module_name] = true
        end

        local parallel = utils.get_parallel_effect(parallel_module_coefficients, module.tier)
        parallel_module_mod_data.max_parallel_per_module = math.max(parallel_module_mod_data.max_parallel_per_module, parallel * max_quality_multipler)
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
                parallel_value_cache[tier][name] = parallel * quality.level
            end
        end
        ::continue::
    end
end

local module_value_max_per_slot = parallel_module_mod_data.max_parallel_per_module / 100.0

-------------------------------------------------------------------------------
--- RECIPE CATEGORIES
-------------------------------------------------------------------------------

-- Set max module slots per crafting category
for name, _ in pairs(data.raw["recipe-category"]) do
    crafting_category_to_max_module_slots[name] = 0
    crafting_category_to_max_parallel_without_modules[name] = 0
    crafting_category_to_should_enable_parallel_effect[name] = false
end

local valid_machines_with_base_parallel = {}

local function max_parallel_without_modules(machine)
    local base_parallel = machine and machine.type == "assembling-machine" and entity_to_base_parallel[machine.name] or 0
    if base_parallel > 0 then
        valid_machines_with_base_parallel[machine.name] = true
    end
    return base_parallel
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
        local base_machine_parallel = max_parallel_without_modules(machine)
        for _, category in pairs(categories) do
            if not data.raw["recipe-category"][category] then
                goto continue
            end
            crafting_category_to_max_module_slots[category] = math.max(crafting_category_to_max_module_slots[category], machine_module_slots)
            crafting_category_to_max_parallel_without_modules[category] = math.max(crafting_category_to_max_parallel_without_modules[category], base_machine_parallel)
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
for machine_name, parallel in pairs(entity_to_base_parallel) do
    if valid_machines_with_base_parallel[machine_name] then
        local item = data.raw.item[machine_name]
        if item then
            item.custom_tooltip_fields = item.custom_tooltip_fields or {}
            table.insert(item.custom_tooltip_fields, {
                name = { "mod-tooltip-name.parallel-module-parallel" },
                value = { "mod-tooltip-value.parallel-module-value", tostring(parallel) },
                order = 110,
                show_in_factoriopedia = true,
                show_in_tooltip = true
            })
        end
    else
        entity_to_base_parallel[machine_name] = nil
    end
end

local function is_category_valid(recipe_name, category)
    if not (category
            and crafting_category_to_max_module_slots[category]
            and crafting_category_to_max_module_slots[category] > 0) then
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

local function get_max_parallel_without_modules_for_recipe(crafting_categories)
    local parallel = 0
    for _, category in pairs(crafting_categories) do
        parallel = math.max(parallel, crafting_category_to_max_parallel_without_modules[category])
    end
    return parallel
end

-------------------------------------------------------------------------------
--- CREATE PARALLEL RECIPE_CATEGORY PROTOTYPES
-------------------------------------------------------------------------------

local function get_or_create_crafting_category_if_valid(category)
    if not category or not crafting_categories_in_furnaces[category] then
        return category
    end

    local new_category = string.format("%s__parallel_module_mod", category)
    if not new_crafting_categories[new_category] then
        original_to_altered_crafting_category[category] = new_category
        new_crafting_categories[new_category] = {
            type = "recipe-category",
            name = new_category,
            hidden = true
        }
    end
    return new_category
end

-------------------------------------------------------------------------------
--- CREATE PARALLEL RECIPE PROTOTYPES
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

for recipe_name, base_recipe in pairs(data.raw.recipe) do
    if utils.table_contains_value(explicitly_disallowed_recipes, recipe_name) then
        goto continue
    end
    local results = base_recipe.results
    if results == nil then
        goto continue
    end

    local valid_categories = {}
    if not base_recipe.categories then
        base_recipe.categories = { "crafting" }
    end
    for _, category in pairs(base_recipe.categories) do
        if is_category_valid(recipe_name, category) then
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

    -- Explicitly allow parallel modules in recipe.allowed_module_categories
    table.insert(base_recipe.allowed_module_categories, EFFECT_NAME)
    for _, category in pairs(valid_categories) do
        if not crafting_category_to_recipes[category] then
            crafting_category_to_recipes[category] = {}
        end
        crafting_category_to_recipes[category][recipe_name] = true
        crafting_category_to_should_enable_parallel_effect[category] = true
    end

    base_recipe_to_altered_recipes[recipe_name] = { [tostring(0)] = recipe_name }
    altered_recipe_to_base_recipe_parallel_pair[recipe_name] = { [tostring(0)] = recipe_name }
    local total_max_module_value = math.min(max_total_parallel, get_max_parallel_without_modules_for_recipe(valid_categories) +
        module_value_max_per_slot * get_max_module_slots_for_recipe(valid_categories))
    for scale = 1, total_max_module_value do
        local new_recipe_name = string.format("%s__parallel_module_mod__%d", recipe_name, scale * 100)
        local scale_str = tostring(scale * 100)
        base_recipe_to_altered_recipes[recipe_name][scale_str] = new_recipe_name
        altered_recipe_to_base_recipe_parallel_pair[new_recipe_name] = { [scale_str] = recipe_name }
        local new_recipe = table.deepcopy(base_recipe)
        new_recipe.name = new_recipe_name
        new_recipe.localised_name = get_recipe_localised_field(base_recipe, "name")
        new_recipe.localised_description = get_recipe_localised_field(base_recipe, "description")
        ensure_recipe_icon_or_icons(new_recipe, base_recipe)
        new_recipe.factoriopedia_alternative = base_recipe.factoriopedia_alternative or recipe_name
        new_recipe.hidden = true
        -- new_recipe.hidden_in_factoriopedia = true
        -- new_recipe.hide_from_stats = true
        new_recipe.hide_from_player_crafting = true
        new_recipe.allow_as_intermediate = false
        new_recipe.hide_from_bonus_gui = true
        new_recipe.allow_decomposition = false
        new_recipe.unlock_results = false
        new_recipe.hide_from_signal_gui = true
        new_recipe.auto_recycle = false
        new_recipe.request_paste_multiplier = math.ceil((new_recipe.request_paste_multiplier or 1) / scale)
        
        for _, products in pairs{new_recipe.ingredients or {}, new_recipe.results or {}} do
            for _, product in pairs(products) do
                if product.amount then
                    product.amount = product.amount * scale
                end
                if product.ignored_by_stats then
                    product.ignored_by_stats = product.ignored_by_stats * scale
                end
                if product.ignored_by_productivity then
                    product.ignored_by_productivity = product.ignored_by_productivity * scale
                end
                if product.amount_min then
                    product.amount_min = product.amount_min * scale
                end
                if product.amount_max then
                    product.amount_max = product.amount_max * scale
                end
                if product.extra_count_fraction and product.extra_count_fraction > 0 then
                    product.extra_count_fraction = product.extra_count_fraction * scale
                    while product.extra_count_fraction > 1 do
                        product.extra_count_fraction = product.extra_count_fraction - 1
                        if product.amount then
                            product.amount = product.amount + 1
                        end
                        if product.amount_min then
                            product.amount_min = product.amount_min + 1
                        end
                        if product.amount_max then
                            product.amount_max = product.amount_max + 1
                        end
                    end
                end
            end
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

local function enable_parallel_module_for_machines(machines)
    for name, machine in pairs(machines) do
        if machine["module_slots"] == nil then
            goto continue
        end

        local parallel_added = false
        if utils.table_contains_value(explicit_entities, machine.name) then
            table.insert(machine.allowed_module_categories, EFFECT_NAME)
            register_with_bplib(name)
            parallel_added = true
        end

        local should_add_categories = machine.type ~= "furnace"
        local new_categories = {}
        for _, category in pairs(machine.crafting_categories) do
            if crafting_category_to_should_enable_parallel_effect[category] then
                if not parallel_added then
                    table.insert(machine.allowed_module_categories, EFFECT_NAME)
                    register_with_bplib(name)
                    parallel_added = true
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
    enable_parallel_module_for_machines(data.raw[machine_type])
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

for _, new_category in pairs(new_crafting_categories) do
    data:extend({ new_category })
end
for _, new_recipe in pairs(new_recipes) do
    data:extend({ new_recipe })
end

parallel_module_mod_data.additional_default_categories = nil
