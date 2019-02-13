##########################################################################################
# Project directory and setup management
##########################################################################################
export projectdir, datadir, srcdir, plotsdir
export projectname

projectdir() = dirname(Base.active_project())*"/"
datadir() = projectdir()*"data/"
srcdir() = projectdir()*"src/"
plotsdir() = projectdir()*"plots/"
scriptdir() = projectdir()*"scripts/"

projectname() = Pkg.REPLMode.promptf()[2:end-7]

##########################################################################################
# Project directory and setup management
##########################################################################################
export initialize_project
import Pkg, LibGit2

const DEFAULT_PATHS = [
"_reserach", "src/", "scripts/",
"plots/", "videos/", "notebooks/",
]
const DEFAULT_README = """
This is an awesome new scientific project that uses `DrWatson`!\n
"""


"""
    initialize_project(path; readme = true [, authors])
Initialize a scientific project expected by `DrWatson` inside the given `path`.
Optionally include a `readme` or `authors::Vector/Vector{String}`.
"""
function initialize_project(path; readme = true, authors = nothing)

    mkpath(path)
    repo = LibGit2.init(path)
    LibGit2.commit(repo, "Initial commit")
    Pkg.activate(path)
    Pkg.add("DrWatson")

    # Default folders
    for p in DEFAULT_PATHS
        mkpath(joinpath(path, p))
    end

    LibGit2.add!(repo, "Project.toml")
    LibGit2.add!(repo, DEFAULT_PATHS...)
    LibGit2.commit(repo, "Folder setup by DrWatson")

    # Default gitignore
    cp(joinpath(@__DIR__, "defaults", "gitignore.txt"), joinpath(path, ".gitignore"))
    cp(joinpath(@__DIR__, "defaults", "intro.jl"), joinpath(path, "scripts/intro.jl"))
    files = vcat(".gitignore", "/scripts/intro.jl")
    if readme
        write("README.md", DEFAULT_README)
        push!(files, "README.md")
    end
    if !isnothing(authors)
        pro = read("Project.toml", String)
        write("Project.toml",  "authors = "*sprint(show, vecstring(authors))*"\n" * pro)
        push!(files, "Project.toml")
    end

    LibGit2.add!(repo, files...)
    LibGit2.commit(repo, "File setup by DrWatson")
    return path
end

vecstring(a::String) = [a]
vecstring(a::Vector{String}) = a
vecstring(c) = String[string(a) for a in c]
