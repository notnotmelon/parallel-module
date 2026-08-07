_G.parallel = {}
_G.mod_data = prototypes.mod_data["parallel-module"].data

require "lib.events"
require "scripts.tostring"
require "scripts.warnings"
require "scripts.parallel-module"
require "scripts.change-detection"
require "scripts.blueprints"
require "scripts.rocket-silo"

remote.add_interface("parallel-module", {
    get_machine_parallel = parallel.get_machine_parallel,
})

parallel.finalize_events()
