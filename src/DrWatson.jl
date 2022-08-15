"The perfect sidekick to your scientific inquiries"
module DrWatson
import Pkg, LibGit2
const PATH_SEPARATOR = joinpath("_", "_")[2]

# Misc functions for kw-macros
convert_to_kw(ex::Expr) = Expr(:kw,ex.args...)
convert_to_kw(ex) = error("invalid keyword argument syntax \"$ex\"")

# Misc helpers
"""
    readenv(var, default::T) where {T}

Try to read the environment variable `var` and parse it as a `::T`.
If that fails, return `default`.
"""
readenv(var, default::T) where {T} = something(tryparse(T, get(ENV, var, "")), Some(default))

# Pure Julia implementation
include("project_setup.jl")
include("naming.jl")
include("saving_tools.jl")

using UnPack
export @pack!, @unpack

# Functionality that saves/loads
using FileIO
using JLD2
export save, load
export wsave, wload

_wsave(filename, data...; kwargs...) = FileIO.save(filename, data...; kwargs...)

"""
    wsave(filename, data...; kwargs...)

Save `data` at `filename` by first creating the appropriate paths.
Default fallback is `FileIO.save`. Extend this for your types
by extending `DrWatson._wsave(filename, data::YourType...; kwargs...)`.
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

# Update messages
using Scratch
const env_var = "DRWATSON_UPDATE_MSG"
const display_update = true
const update_version = "2.7.3"
const update_name = "update_v$update_version"

# Get scratch space for this package
function __init__()
    @require DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
        include("result_collection.jl")
    end

    _display_update = if env_var in keys(ENV)
        try 
            parse(Bool, ENV[env_var]) 
        catch
            display_update
        end
    else
        display_update
    end

    if _display_update
        versions_dir = @get_scratch!("versions")

        if !isfile(joinpath(versions_dir, update_name))

        printstyled(stdout,
        """
        \nUpdate message: DrWatson v$update_version

        * New section "Taking project input-output automation to 11" in the documentation.
          It showcases how to eliminate code duplication and streamline your simulation setup
          and run phase using `savename` and `produce_or_load`.
        * By default now `gitpatch` is NOT saved when calling `tag!` and derivative functions.
          This is due to an unknown problem that causes collecting the git patch to
          never halt, potentially not saving a user's output.

          To disable future update messages see: https://juliadynamics.github.io/DrWatson.jl/dev/#Installing-and-Updating-1
        \n
        """; color = :light_magenta)
        touch(joinpath(versions_dir, update_name))
        end
    end
end


end # Module
