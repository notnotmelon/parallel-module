assert(mods["bplib"])

for name in pairs(mod_data.allowed_machines) do
    local bplib = data.raw["mod-data"]["bplib"]
    bplib.data.extract_entity_names[name] = true
    bplib.data.overlap_entity_names[name] = true
end
