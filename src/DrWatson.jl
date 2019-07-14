"The perfect sidekick to your scientific inquiries"
module DrWatson
import Pkg, LibGit2

const PATH_SEPARATOR = joinpath("_", "_")[2]

# Pure Julia implementation
include("project_setup.jl")
include("naming.jl")
include("saving_tools.jl")

# Functionality that saves/loads
using FileIO: save, load
export save, load
wsave = save
wload = load

include("saving_files.jl")

# Functionality that requires Dataframes and other heavy dependencies:
using Requires
function __init__()
    @require DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
        include("result_collection.jl")
    end
end

# Update messages
display_update = true
update_version = "0.6.0"
update_name = "update_v$update_version"
if display_update
if !isfile(joinpath(@__DIR__, update_name))
printstyled(stdout,
"""
\nUpdate message: DrWatson v$update_version

[BREAKING] The function `projectdir` as well
as its derivatives like `datadir` have changed their internals to use
`joinpath` and in general promote the healthier usage of `joinpath`.
This means that their return value no longer end in "\"!.
This will likely break usage of e.g. `datadir` that used `*`, like it was
suggested in the old (unhealthy) documentation. We are very sorry
for this inconvenience!

\n
"""; color = :light_magenta)
touch(joinpath(@__DIR__, update_name))
end
end

end
