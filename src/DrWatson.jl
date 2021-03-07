"The perfect sidekick to your scientific inquiries"
module DrWatson
import Pkg, LibGit2

const PATH_SEPARATOR = joinpath("_", "_")[2]

# Misc functions for kw-macros
convert_to_kw(ex::Expr) = Expr(:kw,ex.args...)
convert_to_kw(ex) = error("invalid keyword argument syntax \"$ex\"")

# Pure Julia implementation
include("project_setup.jl")
include("naming.jl")
include("saving_tools.jl")

using UnPack
export @pack!, @unpack

# Functionality that saves/loads
using FileIO
export save, load
export wsave, wload

_wsave(filename, data...; kwargs...) = FileIO.save(filename, data...; kwargs...)

"""
    wsave(filename, data...; kwargs...)

Save `data` at `filename` by first creating the appropriate paths.
Default fallback is `FileIO.save`. Extend `wsave` for your type
by extending `DrWatson._wsave(filename, data...; kwargs...)`.
"""
function wsave(filename, data...; kwargs...)
    mkpath(dirname(filename))
    return _wsave(filename, data...; kwargs...)
end

"Currently equivalent with `FileIO.load`."
wload(data...; kwargs...) = FileIO.load(data...; kwargs...)

include("saving_files.jl")
include("dict_list.jl")

# Functionality that requires Dataframes and other heavy dependencies:
using Requires
function __init__()
    @require DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
        include("result_collection.jl")
    end
end

# Update messages
const display_update = true
const update_version = "2.0.0"
const update_name = "update_v$update_version"
if display_update
if !isfile(joinpath(@__DIR__, update_name))
printstyled(stdout,
"""
\nUpdate message: DrWatson v$update_version

`savename` no longer replaces `AbstractFloat` values with integer values
if they two values coincide. I.e. no longer is `1.0` output as `1` in `savename`.
In this new major release, the following breaking changes have occured:
1. DrWatson now uses, and suggests using, JLD2.jl instead of BSON.jl
   for saving files.
2. The `savename` stuff.
\n
"""; color = :light_magenta)
touch(joinpath(@__DIR__, update_name))
end
end

end
