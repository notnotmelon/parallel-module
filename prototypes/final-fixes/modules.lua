local utils = require "lib.utils"

local spoilable_items = require("__item-request-proxy-events__.spoilable-items")

local function quality_multiplier(module, quality)
    local module_quality_boost
    if ((module.effect or {}).parallel or 0.0) > 0.0 then
        module_quality_boost = module.parallel_quality_multiplier or 1.0
    else
        module_quality_boost = module.parallel_quality_multiplier or 0.0
    end

    if quality.module_parallel_multiplier then
        assert(quality.module_parallel_multiplier >= 0.01, "Must be >= 0.01.")
        return quality.module_parallel_multiplier * module_quality_boost
    end

    return (quality.level * module_quality_boost) + 1.0
end

local function module_strength(module, quality)
    if not module.effect or not module.effect.parallel then
        return 0.0
    end

    return module.effect.parallel * quality_multiplier(module, quality)
end

local function generate_quality_tooltip(module)
    local result = {}
    for name, quality in pairs(data.raw.quality) do
        result[name] = utils.parallel_tooltip(module_strength(module, quality))
    end
    return result
end

for module_name, module in pairs(data.raw.module) do
    if type(module.effect) ~= "table" then goto continue end
    if (module.effect.parallel or 0) == 0 then goto continue end

    if spoilable_items.register_item_spoiled_event(module) then
        mod_data.spoilable_modules[module_name] = true
    end

    module.custom_tooltip_fields = {{
        name = {"mod-tooltip-name.parallel-module-parallel"},
        value = utils.parallel_tooltip(module_strength(module, data.raw.quality.normal)),
        quality_values = generate_quality_tooltip(module),
        order = 79,
    }}

    mod_data.parallel_value_cache[module.name] = {}
    for _, quality in pairs(data.raw.quality) do
        mod_data.parallel_value_cache[module.name][quality.name] = module_strength(module, quality)
    end

    ::continue::
end
