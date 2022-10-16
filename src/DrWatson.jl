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
const update_version = "2.11.0"
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

        - Now the default project with `initialize_project` will include a documentation
          and a test folder, as well as scripts to trigger them.
        - It will also set up CI for both automatically, if a GitHub repo is given.
        - This new template is showcased in the Good Scientific Code Workshop,
          see https://youtu.be/x3swaMSCcYk
        - `@produce_or_load` was broken but because CI was disabled this was
          silently ignored. `produce_or_load` now has call signature
          `produce_or_load(f::Function, config, path::String = "")` and
          same signature for the macro with `path` mandatory.

        To disable future update messages see:
        https://juliadynamics.github.io/DrWatson.jl/dev/#Installing-and-Updating-1
        \n
        """; color = :light_magenta)
        touch(joinpath(versions_dir, update_name))
        end
    end
end


end # Module
