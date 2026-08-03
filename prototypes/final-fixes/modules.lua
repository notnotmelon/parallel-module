local spoilable_items = require("__item-request-proxy-events__.spoilable-items")

parallel.max_parallel_per_module_slot = 0

local function quality_multiplier(module, quality_level)
    local quality_multiplier = module.parallel_quality_multiplier or 1.0
    return (quality_level * quality_multiplier) + 1.0
end

local function module_strength(module, quality)
    if not module.effect or not module.effect.parallel then
        return 0.0
    end

    if not quality then
        return module.effect.parallel
    end

    return module.effect.parallel * quality_multiplier(module, quality.level)
end

local max_quality_level = data.raw.quality.normal.level
for _, quality in pairs(data.raw.quality) do
    max_quality_level = math.max(max_quality_level, quality.level)
end

local function to_quality_values(module)
    local result = {}
    for name, quality in pairs(data.raw.quality) do
        result[name] = {"mod-tooltip-value.parallel-module-value", tostring(100 * module_strength(module, quality))}
    end
    return result
end

for module_name, module in pairs(data.raw.module) do
    if type(module.effect) ~= "table" then goto continue end
    if (module.effect.parallel or 0) == 0 then goto continue end

    if spoilable_items.register_item_spoiled_event(module) then
        mod_data.spoilable_modules[module_name] = true
    end

    parallel.max_parallel_per_module_slot = math.max(
        parallel.max_parallel_per_module_slot,
        module.effect.parallel * quality_multiplier(module, max_quality_level)
    )

    module.custom_tooltip_fields = {{
        name = {"mod-tooltip-name.parallel-module-parallel"},
        value = {"mod-tooltip-value.parallel-module-value", tostring(module.effect.parallel)},
        quality_values = to_quality_values(module),
        order = 79,
    }}

    mod_data.parallel_value_cache[module.name] = {}
    for _, quality in pairs(data.raw.quality) do
        mod_data.parallel_value_cache[module.name][quality.name] = module_strength(module, quality)
    end

    ::continue::
end
