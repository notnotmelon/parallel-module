local function disallow(category)
    local category = data.raw["recipe-category"][category]
    if category and category.parallel_blacklist == nil then
        category.parallel_blacklist = true
    end
end

disallow("tiberium-reprocessing")
disallow("cosmic_incubator")
disallow("ammunition")
disallow("incineration")
disallow("fuel-incineration")
disallow("recycling")
