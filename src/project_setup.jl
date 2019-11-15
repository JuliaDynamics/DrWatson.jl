##########################################################################################
# Project directory
##########################################################################################
export projectdir, datadir, srcdir, plotsdir, scriptsdir, papersdir
export projectname
export findproject, quickactivate

@deprecate scriptdir scriptsdir #TODO: remove in next release

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
        $function_name() = projectdir($dir_type)
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
    findproject(path = pwd()) -> project_path
Recursively search `path` and its parents for a valid Julia project file
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
    @warn "Could not find find a project file by recursively checking "*
    "given `path` and its parents. Returning `nothing` instead."
    return nothing
end

"""
    quickactivate(path [, name::String])
Activate the project found by [`findproject`](@ref) of the `path`, which
recursively searches the `path` and its parents for a valid Julia
project file.
Optionally check if `name` is the same as the activated project's name.
If it is not, throw an error.

This function is _first_ activating the project and _then_ checking if
it matches the `name`.
It also does nothing if the project found is already active, or if it
fails to find a project file.

!!! warning
    Note that to access `quickactivate` you need to be `using DrWatson`.
    For this to be possible `DrWatson` must be already added in the
    existing global environment. The version of `DrWatson` loaded therefore
    will be the one of the global environment, and not of the activated project.
    To avoid unexpected behavior take care so that these two versions coincide.

    **In addition please be very careful to not write:**
    ```julia
    using DrWatson
    quickactivate(@__DIR__)
    using Package1, Package2
    # do stuff
    ```
    **instead of the erroneous:**
    ```julia
    using DrWatson, Package1, Package2
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




##########################################################################################
# Project setup
##########################################################################################
export initialize_project

const DEFAULT_PATHS = [
"_research", "src", "scripts",
"plots", "notebooks",
"papers",
joinpath("data", "sims"),
joinpath("data", "exp_raw"),
joinpath("data", "exp_pro"),
]
const DEFAULT_README = """
This is an awesome new scientific project that uses `DrWatson`!\n
"""


"""
    initialize_project(path [, name]; kwargs...)
Initialize a scientific project expected by `DrWatson` inside the given `path`.
If its `name` is not given, it is assumed to be the folder's name.

The new project remains activated for you to immidiately add packages.

## Keywords
* `readme = true` : adds a README.md file.
* `authors = nothing` : if a string or container of strings, adds the authors in the
  Project.toml file.
* `force = false` : If the `path` is _not_ empty then throw an error. If however `force`
  is `true` then recursively delete everything in the path and create the project.
* `git = true` : Make the project a Git repository.
"""
function initialize_project(path, name = basename(path);
    force = false, readme = true, authors = nothing,
    git = true)

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

    if git; repo = LibGit2.init(path); end
    git && LibGit2.commit(repo, "Initial commit")
    Pkg.activate(path)
    try
        Pkg.add("DrWatson")
    catch
        @warn "Could not add DrWatson to project. Adding Pkg instead..."
        Pkg.add("Pkg")
    end
    # Default folders
    for p in DEFAULT_PATHS
        mkpath(joinpath(path, p))
    end

    git && LibGit2.add!(repo, "Project.toml")
    git && LibGit2.add!(repo, "Manifest.toml")
    git && LibGit2.add!(repo, DEFAULT_PATHS...)
    git && LibGit2.commit(repo, "Folder setup by DrWatson")

    # Default files
    # chmod is needed, as the file permissions are not set correctly when adding the package with `add`.
    cp(joinpath(@__DIR__, "defaults", "gitignore.txt"), joinpath(path, ".gitignore"))
    chmod(joinpath(path, ".gitignore"),0o644)

    cp(joinpath(@__DIR__, "defaults", "intro.jl"), joinpath(path, "scripts", "intro.jl"))
    chmod(joinpath(path, "scripts", "intro.jl"),0o644)

    files = vcat(".gitignore", joinpath("scripts", "intro.jl"), joinpath("test", "runtests.jl"))
    if readme
        write(joinpath(path, "README.md"), DEFAULT_README)
        push!(files, "README.md")
    end
    pro = read(joinpath(path, "Project.toml"), String)
    w = "name = \"$name\"\n"
    if !(authors === nothing)
            w *= "authors = "*sprint(show, vecstring(authors))*"\n"
    end
    w *= """
        [compat]
        julia = "$(VERSION.major).$(VERSION.minor).$(VERSION.patch)"
        """
    write(joinpath(path, "Project.toml"), w, pro)
    push!(files, "Project.toml")

    git && LibGit2.add!(repo, files...)
    git && LibGit2.commit(repo, "File setup by DrWatson")
    return path
end

vecstring(a::String) = [a]
vecstring(a::Vector{String}) = a
vecstring(c) = [string(a) for a in c]

function greet()
    s =
    """
    Currently active project is: $(projectname())

    Have fun with your new project!

    You can help us make improve DrWatson by opening
    issues on GitHub or submitting feature requests!
    """
    println(s)
end
