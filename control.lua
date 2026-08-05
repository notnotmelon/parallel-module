_G.parallel = {}
_G.mod_data = prototypes.mod_data["parallel-module"].data

require "lib.events"
require "scripts.tostring"
require "scripts.parallel-module"
require "scripts.change-detection"
require "scripts.blueprints"

remote.add_interface("parallel-module", {
    get_total_machine_parallel = parallel.get_total_machine_parallel,
})

parallel.finalize_events()
