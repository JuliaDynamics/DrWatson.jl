export Metadata, Metadata!, rename!, delete!, get_metadata

import Base.==, Base.getproperty, Base.setproperty!

const metadata_folder_name = ".metadata"

metadatadir(args...) = projectdir(metadata_folder_name, args...)

mutable struct Metadata <: AbstractDict{String, Any}
    path::String
    mtime::Float64
    data::Dict{String,Any}
end

"""
    Metadata(path::String; overwrite=false) -> Metadata

Create or load the metadata file for `path`. If `overwrite = true`, existing data for `path` is removed.
`Metadata` is automatically updated on every change.
`Metadata` is a subtype of AbstractDict.

!!! warning "`Metadata` performes IO operations"
    Writing metadata in a multi threaded environment can cause race conditions.
    You have to take care of proper locking.

Metadata files are stored in a directory `.metadata` in the DrWatson project's root directory.
The filenames are obtained as follows:

1. Make the path relative to the DrWatson project's root directory [`project_rel_path`](@ref).
2. Standardize the paths by fixing the path separator to `/` [`standardize_path`](@ref).
3. Generate a hash of the standardized, relative path [`hash_path`](@ref).

This approach allows storing and retrieving metadata independet of the location of the project
folder and the used OS.

See also [`Metadata!`](@ref), [`get_metadata`](@ref).

# Examples
```julia-repl
julia> m = Metadata(datadir("sims", "1"))
[ Info: Metadata directory not found, creating a new one
Metadata()

julia> tag!(m)

julia> m["parameters"] = Dict(
    "a" => 10,
    "b" => 11,
    "function" => Base.:+)

julia> m
Metadata with 2 entries:
  "parameters" => Dict{String, Any}("function"=>(+), "b"=>11, "a"=>10)
  "gitcommit"  => "3a44b1af806f3e932f31cbeab6af5408e379c208"

julia> m["parameters"]["function"](m["parameters"]["a"], m["parameters"]["b"])
```
"""
function Metadata(path::String; overwrite=false)
    (isfile(path) || isdir(path)) || @warn "There is no file or folder at '$path'."
    assert_metadata_directory()
    rel_path = project_rel_path(path)
    # Check if there is already an entry for that file in the index
    _path = find_file_in_index(path)
    if _path !== nothing && !overwrite
        m = load_metadata(_path)
        if m.mtime != mtime(path) && isfile(path)
            @warn "The metadata entries might not be up to date. The file changed after adding the entries"
        end
    elseif _path !== nothing && overwrite
        m = Metadata(rel_path, mtime(path), Dict{String,Any}())
        save_metadata(m)
    else
        m = Metadata(rel_path, mtime(path), Dict{String,Any}())
        save_metadata(m)
    end
    return m
end

Base.length(m::Metadata) = length(m.data)
Base.iterate(m::Metadata, args...; kwargs...) = iterate(m.data, args...; kwargs...)

"""
    Metadata!(path::String) -> Metadata

Defaults to `Metadata(path, overwrite = true)`

See also [`Metadata`](@ref).
"""
Metadata!(path::String) = Metadata(path, overwrite=true)

"""
    project_rel_path(path) -> String

Turn a path inside the activated DrWatson project into a path relative to the project's root directory.
"""
project_rel_path(path) = relpath(abspath(path), projectdir())

"""
    get_stored_path(m::Metadata) -> String

Get the path `Metadata` is pointing to.

See also [`Metadata`](@ref).
"""
get_stored_path(m::Metadata) = getfield(m,:path)

"""
    hash_path(path) -> Hash

Return the unique hash representation of a path inside the DrWatson project.

See also [`Metadata`](@ref).
"""
hash_path(path) = hash(standardize_path(path))

"""
    standardize_path(path) -> String

Return a path where '/' is used as path separator.

See also [`Metadata`](@ref).
"""
standardize_path(path) = join(splitpath(project_rel_path(path)), "/")
to_file_name(x) = string(x)*".jld2"

"""
    load_metadata(path; ignore_exceptions=false) -> Metadata

Load the metadata file stored at `path`. `path` must be the path to the actual metadata file,
not the path the metadata file points to.
"""
function load_metadata(path; ignore_exceptions=false)
    try
        entry = load(path)
        Metadata([entry[string(field)] for field in fieldnames(Metadata)]...)
    catch e
        if ignore_exceptions
            return nothing
        else
            rethrow(e)
        end
    end
end

"""
    find_file_in_index(path) -> Metadata or nothing

Return the hashed path to an already stored metadata file pointing to `path`.
"""
function find_file_in_index(path)
    file = metadatadir(hash_path(path)|>to_file_name)
    isfile(file) && return file
    return nothing
end

function ==(a::Metadata,b::Metadata)
    for k ∈ fieldnames(Metadata)
        if getfield(a,k) != getfield(b,k)
            return false
        end
    end
    return true
end

setproperty!(m::Metadata, sym::Symbol, val) = error("The field '$sym' is treated as immutable and cannot be updated directly.")
getproperty(m::Metadata, sym::Symbol) = getproperty(m, Val(sym))
getproperty(m::Metadata, ::Val{T}) where T = getfield(m, T)
getproperty(m::Metadata, ::Val{:path}) = projectdir(getfield(m, :path))

Base.getindex(m::Metadata, field::String) = m.data[field]
function Base.setindex!(m::Metadata, val, field::String)
    m.data[field] = val
    save_metadata(m)
    return val
end

Base.keys(m::Metadata) = keys(m.data)

"""
    rename!(m::Metadata, path)

Renames the path `m` is pointing to to `path`.
"""
function rename!(m::Metadata, path)
    rel_path = project_rel_path(path)
    assert_metadata_directory()
    if find_file_in_index(rel_path) !== nothing
        error("There is already metadata stored for '$path'.")
    end
    new_metadata_file = metadatadir(hash_path(path)|>to_file_name)
    old_metadata_file = metadatadir(hash_path(m.path)|>to_file_name)
    mv(old_metadata_file, new_metadata_file)
    setfield!(m, :path, rel_path)
    save_metadata(m)
end

"""
    delete(m::Metadata)
    delete(m::Metadata, field)

Delete a single `field` from `m` or delete the entire metadata file `m`.
"""
function Base.delete!(m::Metadata)
    assert_metadata_directory()
    file = metadatadir(to_file_name(hash_path(m.path)))
    if !isfile(file)
        error("There is no metadata storage for id $(m.path)")
    end
    rm(file)
end

function Base.delete!(m::Metadata, field)
    delete!(m.data,field)
    save_metadata(m)
    return m
end

function save_metadata(m::Metadata)
    setfield!(m,:mtime,mtime(m.path))
    save(metadatadir(to_file_name(hash_path(m.path))),Dict(string(field)=>getfield(m,field) for field in fieldnames(Metadata)))
end

function assert_metadata_directory()
    metadata_directory = metadatadir()
    if !isdir(metadata_directory)
        @info "Metadata directory not found, creating a new one"
        try
            mkdir(metadata_directory)
        catch e
            if !isa(e, Base.IOError)
                rethrow(e)
            end
        end
    end
end

function tag!(m, args...; kwargs...)
    tag!(m.data, args...; kwargs...)
    save_metadata(m)
end

"""
    get_metadata(search_path::String; include_parents=true) -> Metadata
    get_metadata(f::Function) -> [Metadata]
    get_metadata() -> [Metadata]

Find the metadata entry pointing to `search_path`. If `include_parents = true`, the search
is performed upwards the folder structure. This allows attaching metadata to a folder and associating
all files stored in this folder with a single metadata entry.
Alternatively, a filter function `f -> Bool` can be passed returning all metadata entries for which `f(m) = true`.
If no function is passed, all entries are returned.

# Examples
```julia-repl
julia> m = Metadata(plotsdir("plt1.png"))
       m["parameters"] = Dict(:a=>10, :b=>11)
       m = Metadata(plotsdir("plt2.png"))
       m["parameters"] = Dict(:a=>1, :b=>12)
       m = Metadata(plotsdir("plt3.png"))
       m["parameters"] = Dict(:a=>10, :b=>3)

julia> get_metadata() do m
           m["parameters"][:a] == 10
       end

2-element Vector{Metadata}:
 Metadata("parameters" => Dict(:a => 10, :b => 11))
 Metadata("parameters" => Dict(:a => 10, :b => 3))
```
"""
function get_metadata(search_path::String; include_parents=true)
    while search_path != ""
        id = find_file_in_index(search_path)
        if id !== nothing
            return Metadata(search_path)
        end
        include_parents || return nothing
        search_path, _ = splitdir(search_path)
    end
    return nothing
end

function get_metadata(f::Function)
    ms = Metadata[]
    for file in filter(x->endswith(x,".jld2"),readdir(metadatadir()))
        m = load_metadata(joinpath(metadatadir(),file), ignore_exceptions=true)
        m === nothing && continue
        f(m) && push!(ms, m)
    end
    return ms
end

function get_metadata()
    return get_metadata() do m
        true
    end
end