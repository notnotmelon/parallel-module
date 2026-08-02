if not mods["Krastorio2"] then return end

if not mods["Krastorio2-spaced-out"] then
    local data_util = require("__Krastorio2__.data-util")
    data_util.add_prerequisite("parallel-module-2", "chemical-science-pack")
    data_util.add_prerequisite("parallel-module-3", "processing-unit")
    data_util.add_prerequisite("parallel-module-3", "production-science-pack")

    data_util.remove_prerequisite("parallel-module-2", "processing-unit")
end
