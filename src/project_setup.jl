##########################################################################################
# Project directory and setup management
##########################################################################################
export projectdir, datadir, srcdir, plotsdir
export projectname

"""
    projectdir()
Return the directory of the currently active project. Ends with `"/"`.
"""
projectdir() = dirname(Base.active_project())*"/"
datadir() = projectdir()*"data/"
srcdir() = projectdir()*"src/"
plotsdir() = projectdir()*"plots/"
scriptdir() = projectdir()*"scripts/"

"""
    projectname()
Return the name of the currently active project.
"""
projectname() = Pkg.REPLMode.promptf()[2:end-7]

##########################################################################################
# Project directory and setup management
##########################################################################################
export initialize_project
import Pkg, LibGit2

const DEFAULT_PATHS = [
"_reserach", "src/", "scripts/",
"plots/", "videos/", "notebooks/",
"data/simulations/",
"data/exp_raw/",
"data/exp_pro/",
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
* `git = true` : Make the project a GIT repository.
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
    # Pkg.add("DrWatson")#Uncomment when the package is released
    Pkg.add("Pkg")

    # Default folders
    for p in DEFAULT_PATHS
        mkpath(joinpath(path, p))
    end

    git && LibGit2.add!(repo, "Project.toml")
    git && LibGit2.add!(repo, DEFAULT_PATHS...)
    git && LibGit2.commit(repo, "Folder setup by DrWatson")

    # Default files
    cp(joinpath(@__DIR__, "defaults", "gitignore.txt"), joinpath(path, ".gitignore"))
    cp(joinpath(@__DIR__, "defaults", "intro.jl"), joinpath(path, "scripts/intro.jl"))
    files = vcat(".gitignore", "/scripts/intro.jl")
    if readme
        write(joinpath(path, "README.md"), DEFAULT_README)
        push!(files, "README.md")
    end
    pro = read(joinpath(path, "Project.toml"), String)
    w = "name = \"$name\"\n"
    if !(authors === nothing)
            w *= "authors = "*sprint(show, vecstring(authors))*"\n"
    end
    write(joinpath(path, "Project.toml"), w, pro)
    push!(files, "Project.toml")

    git && LibGit2.add!(repo, files...)
    git && LibGit2.commit(repo, "File setup by DrWatson")
    return path
end

vecstring(a::String) = [a]
vecstring(a::Vector{String}) = a
vecstring(c) = String[string(a) for a in c]
