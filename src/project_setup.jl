##########################################################################################
# Project directory
##########################################################################################
export projectdir, datadir, srcdir, plotsdir, scriptsdir, papersdir
export projectname
export findproject, quickactivate, @quickactivate

"""
    function is_standard_julia_project()

Returns true if the standard Julia project is active.
"""
function is_standard_julia_project()
    Base.active_project() == Base.load_path_expand("@v#.#")
end


"""
    projectdir()
Return the directory of the currently active project.

```julia
projectdir(args...) = joinpath(projectdir(), args...)
```
Join the path of the currently active project with `args`
(typically other subfolders).
"""
function projectdir()
    if is_standard_julia_project()
        @warn "Using the standard Julia project."
    end
    dirname(Base.active_project())
end
projectdir(args...) = joinpath(projectdir(), args...)


# Generate functions to access the path of default subdirectories.
for dir_type ∈ ("data", "src", "plots", "scripts", "papers")
    function_name = Symbol(dir_type * "dir")
    @eval begin
        $function_name(args...) = projectdir($dir_type, args...)
    end
end

"""
    projectname()
Return the name of the currently active project.
"""
projectname() = _projectname(try
                                Pkg.Types.read_project(Base.active_project())
                             catch
                                nothing
                             end)
_projectname(pkg) = pkg.name
# Pkg in julia 1.0 returns a dict
_projectname(pkg::Dict) = pkg["name"]
_projectname(::Nothing) = nothing


"""
    findproject(dir = pwd()) -> project_path
Recursively search `dir` and its parents for a valid Julia project file
(anything in `Base.project_names`).
If it is found return its path, otherwise issue a warning and return
`nothing`.

The function stops searching if it hits either the home directory or
the root directory.
"""
function findproject(dir::AbstractString = pwd())
    # look for project file in current dir and parents
    home = homedir()
    while true
        for proj in Base.project_names
            file = joinpath(dir, proj)
            Base.isfile_casesensitive(file) && return dir
        end
        # bail at home directory
        dir == home && break
        # bail at root directory
        old, dir = dir, dirname(dir)
        dir == old && break
    end
    @warn "DrWatson could not find find a project file by recursively checking "*
    "given `dir` and its parents. Returning `nothing` instead.\n(given dir: $dir)"
    return nothing
end

"""
    quickactivate(path [, name::String])
Activate the project found by recursively searching the `path`
and its parents for a valid Julia project file via the [`findproject`](@ref) function.
Optionally check if `name` is the same as the activated project's name.
If it is not, throw an error. See also [`@quickactivate`](@ref).
Do nothing if the project found is already active, or if no
project file is found.

Example:
```julia
using DrWatson
quickactivate("path/to/project", "Best project in the WOLRLDD")
```

Notice that this function is _first_ activating the project and _then_ checking if
it matches the `name`.

!!! warning
    Note that to access `quickactivate` you need to be `using DrWatson`.
    For this to be possible `DrWatson` must be already added in the
    existing global environment. If you use `quickactivate` and share your project, do
    note to your co-workers that they need to add `DrWatson` globally (the default
    README.md created by `initialize_project` says this automatically).

    **In addition, in your scripts write:**
    ```julia
    using DrWatson # YES
    quickactivate(@__DIR__)
    using Package1, Package2
    # do stuff
    ```
    **instead of the erroneous:**
    ```julia
    using DrWatson, Package1, Package2 # NO!
    quickactivate(@__DIR__)
    # do stuff
    ```
    This ensures that the packages you use will all have the versions dictated
    by your activated project (besides `DrWatson`, since this is impossible
    to do using `quickactivate`).
"""
function quickactivate(path, name = nothing)
    projectpath = findproject(path)
    if projectpath === nothing || projectpath == dirname(Base.active_project())
        return nothing
    end
    Pkg.activate(projectpath)
    if !(name === nothing) && projectname() != name
        error(
        "The activated project did not match asserted name. Current project "*
        "name is $(projectname()) while the asserted name is $name."
        )
    end
    return nothing
end

function get_dir_from_source(source_file)
    if source_file === nothing
        return nothing
    else
        _dirname = dirname(String(source_file))
        return isempty(_dirname) ? pwd() : abspath(_dirname)
    end
end

"""
    @quickactivate
Equivalent with `quickactivate(@__DIR__)`.

    @quickactivate name::String
Equivalent with `quickactivate(@__DIR__, name)`.

Notice that since `@quickactivate` is a macro, standard caveats apply
when using `Distributed` computing. Specifically, you need to import
`DrWatson` and use `@quickactivate` in different `begin` blocks as follows:
```julia
using Distributed
addprocs(8)
@everywhere using DrWatson

@everywhere begin
    @quickactivate "TestEnv"
    using Distributions, ...
    # remaining imports
end
```

!!! warning "Usage in Pluto.jl"
    Pluto.jl understands the `@quickactivate` macro and will switch to
    using the standard Julia package manager once it encounters it (or `quickactivate`).
    But, because `@quickactivate` is a macro
    it needs to be executed in a new cell, after `using DrWatson`. I.e., you need to split
    ```julia
    begin
        using DrWatson
        @quickactivate "Whatever"
    end
    ```
    to two different cells:
    ```julia
    using DrWatson
    ```
    ```julia
    @quickcativate "Whatever"
    ```
"""
macro quickactivate(name = nothing)
    dir = get_dir_from_source(__source__.file)
    :(quickactivate($dir,$name))
end

"""
    @quickactivate ProjectName::Symbol
If given a `Symbol` then first `quickactivate(@__DIR__, string(ProjectName))`,
and then do `using ProjectName`, as if the symbol was representing a module name.

This ties with [Making your project a usable module](@ref) functionality,
see the docs for an example.
"""
macro quickactivate(name::QuoteNode)
    dir = get_dir_from_source(__source__.file)
    quote
        quickactivate($dir, string($name))
        using $(name.value)
    end
end

##########################################################################################
# Project setup
##########################################################################################
export initialize_project

"""
    initialize_project(path [, name]; kwargs...)
Initialize a scientific project expected by `DrWatson` in `path` (directory representing
an empty folder).
If `name` is not given, it is assumed to be the folder's name.

The new project remains activated for you to immidiately add packages.

## Keywords
* `readme = true` : adds a README.md file.
* `authors = nothing` : if a string or container of strings, adds the authors in the
  Project.toml file and README.md.
* `force = false` : If the `path` is _not_ empty then throw an error. If however `force`
  is `true` then recursively delete everything in the path and create the project.
* `git = true` : Make the project a Git repository.
* `template = DrWatson.DEFAULT_TEMPLATE` : A template containing the folder structure
  of the project. It should be a vector containing strings (folders) or pairs of `String
  => Vector{String}`, containg a folder and subfolders (this can be nested further). Example:
  ```
  DEFAULT_TEMPLATE = [
    "_research", 
    "src", 
    "scripts",
    "plots", 
    "notebooks",
    "papers",
    "data" => ["sims", "exp_raw", "exp_pro"],
  ]
  ```
  Obviously, the default derivative functions of [`projectdir`](@ref), such as `datadir`,
  have been written with the default template in mind.
* `placeholder = false` : Add hidden place holder files in each default folder to ensure 
  that project folder structure is maintained when the directory is cloned.
  Only used when `git = true`.
"""
function initialize_project(path, name = default_name_from_path(path);
        force = false, readme = true, authors = nothing,
        git = true, placeholder = false, template = DEFAULT_TEMPLATE
    )

    if git == false; placeholder = false; end
    mkpath(path)
    rd = readdir(path)
    if length(rd) != 0
        if force
            for d in rd
                rm(joinpath(path, d), recursive = true, force = true)
            end
        else
            error("Project path is not empty!")
        end
    end

    if git
        repo = LibGit2.init(path)
        sig = LibGit2.Signature("DrWatson", "no@mail", round(Int, time()), 0)
        LibGit2.commit(repo, "Initial commit"; author=sig, committer=sig)
    end

    Pkg.activate(path)
    try
        Pkg.add("DrWatson")
    catch
        @warn "Could not add DrWatson to project. Adding Pkg instead..."
        Pkg.add("Pkg")
    end

    # Instantiate template
    folders, ph_files = insert_folders(path, template, placeholder)

    if git
        LibGit2.add!(repo, "Project.toml")
        LibGit2.add!(repo, "Manifest.toml")
        LibGit2.add!(repo, folders...)
        placeholder && LibGit2.add!(repo, ph_files...)
        sig = LibGit2.Signature("DrWatson", "no@mail", round(Int, time()), 0)
        LibGit2.commit(repo, "Folder setup by DrWatson"; author=sig, committer=sig)
    end

    # Default files
    # chmod is needed, as the file permissions are not set correctly when adding the package with `add`.
    cp(joinpath(@__DIR__, "defaults", "gitignore.txt"), joinpath(path, ".gitignore"))
    chmod(joinpath(path, ".gitignore"), 0o644)
    cp(joinpath(@__DIR__, "defaults", "gitattributes.txt"), joinpath(path, ".gitattributes"))
    chmod(joinpath(path, ".gitattributes"), 0o644)
    write(joinpath(path, "intro.jl"), makeintro(name))

    files = [".gitignore", ".gitattributes", "intro.jl"]
    if readme
        write(joinpath(path, "README.md"), DEFAULT_README(name, authors))
        push!(files, "README.md")
    end
    pro = read(joinpath(path, "Project.toml"), String)
    w = "name = \"$name\"\n"
    if !(authors === nothing)
        w *= "authors = "*sprint(show, vecstring(authors))*"\n"
    end
    w *= compat_entry()
    write(joinpath(path, "Project.toml"), w, pro)
    push!(files, "Project.toml")
    if git
        LibGit2.add!(repo, files...)
        sig = LibGit2.Signature("DrWatson", "no@mail", round(Int, time()), 0)
        LibGit2.commit(repo, "File setup by DrWatson"; author=sig, committer=sig)
    end
    return path
end

function insert_folders(path, template, placeholder)
    # Default folders
    folders = String[]
    ph_files = String[]
    for p in template
        _recursive_folder_insertion!(path, p, placeholder, folders, ph_files)
    end
    return folders, ph_files
end
function _recursive_folder_insertion!(path, p::String, placeholder, folders, ph_files)
    folder = joinpath(path, p)
    mkpath(folder)
    push!(folders, folder)
    if placeholder #Create a placeholder file in each path
        write(joinpath(folder, ".placeholder"), PLACEHOLDER_TEXT)
        push!(ph_files, joinpath(folder, ".placeholder"))
    end
end
function _recursive_folder_insertion!(path, p::Pair{String, <:Any}, placeholder, folders, ph_files)
    path = joinpath(path, p[1])
    for z in p[2]
        _recursive_folder_insertion!(path, z, placeholder, folders, ph_files)
    end
end
function _recursive_folder_insertion!(path, p::Pair{String, String}, placeholder, folders, ph_files)
    path = joinpath(path, p[1])
    _recursive_folder_insertion!(path, p[2], placeholder, folders, ph_files)
end

function compat_entry()
    DrWatson_VERSION = let
        project = joinpath(dirname(dirname(pathof(DrWatson))), "Project.toml")
        versionline = readlines(project)[4]
        VersionNumber(versionline[12:end-1])
    end
    """
    [compat]
    julia = "$(VERSION.major).$(VERSION.minor).$(VERSION.patch)"
    DrWatson = "$(DrWatson_VERSION)"
    """
end

vecstring(a::String) = [a]
vecstring(a::Vector{String}) = a
vecstring(c) = [string(a) for a in c]


function default_name_from_path(path)
    ap = abspath(path)
    path, dir = splitdir(ap)
    if length(dir) == 0
        _, dir = splitdir(path)
    end
    return dir
end


const PLACEHOLDER_TEXT = """
This file acts as a placeholder to ensure the project structure is copied whenever you clone the project.
This doesn't commit any files within the folder.
"""

function DEFAULT_README(name, authors = nothing)
    s = """
    # $name

    This code base is using the Julia Language and [DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/)
    to make a reproducible scientific project named
    > $name

    """
    if !(authors === nothing)
        s *= "It is authored by "*join(vecstring(authors), ", ")*".\n\n"
    end

    s *= """
    To (locally) reproduce this project, do the following:

    0. Download this code base. Notice that raw data are typically not included in the
       git-history and may need to be downloaded independently.
    1. Open a Julia console and do:
       ```
       julia> using Pkg
       julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`
       julia> Pkg.activate("path/to/this/project")
       julia> Pkg.instantiate()
       ```

    This will install all necessary packages for you to be able to run the scripts and
    everything should work out of the box, including correctly finding local paths.
    """
    return s
end

##########################################################################################
# Project templates
##########################################################################################
const DEFAULT_TEMPLATE = [
    "_research", 
    "src", 
    "scripts",
    "plots", 
    "notebooks",
    "papers",
    "data" => ["sims", "exp_raw", "exp_pro"],
]

const DOCUMENTS_TEMPLATE = [
    "src", 
    "scripts",
    "plots", 
    "notebooks",
    "documents",
    "papers",
    "data" => ["sims", "obs", "ana"], # simulations, observations, analysis
]


##########################################################################################
# Introductory file
##########################################################################################
function makeintro(name)
    """
    using DrWatson
    @quickactivate "$name"
    
    println(
    \"\"\"
    Currently active project is: \$(projectname())

    Path of active project: \$(projectdir())

    Have fun with your new project!

    You can help us improve DrWatson by opening
    issues on GitHub, submitting feature requests,
    or even opening your own Pull Requests!
    \"\"\"
    )
    """
end
