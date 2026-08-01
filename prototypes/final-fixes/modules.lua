local spoilable_items = require("__item-request-proxy-events__.spoilable-items")
local parallel_value_cache = data.raw["mod-data"].parallel_module_mod_parallel_value_cache.data

parallel.max_parallel_per_module = 0

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
        parallel.max_parallel_per_module = math.max(parallel.max_parallel_per_module, module.effect.parallel * max_quality_multipler)
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
