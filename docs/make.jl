using Pkg
Pkg.activate(@__DIR__)
CI = get(ENV, "CI", nothing) == "true" || get(ENV, "GITHUB_TOKEN", nothing) !== nothing
using DrWatson
using Documenter, DataFrames, Parameters, Dates, BSON, JLD2

# %%
isdir(datadir()) && rm(datadir(); force = true, recursive = true)

makedocs(modules = [DrWatson],
sitename= "DrWatson",
authors = "George Datseris and contributors.",
doctest = false,
format = Documenter.HTML(
    prettyurls = CI,
    assets = ["assets/logo.ico"],
    ),
pages = [
    "Introduction" => "index.md",
    "Project Setup" => "project.md",
    "Naming Simulations" => "name.md",
    "Saving Tools" => "save.md",
    "Running & Listing Simulations" => "run&list.md",
    "Real World Examples" => "real_world.md"
    ],
)

if CI
    deploydocs(
        repo = "github.com/JuliaDynamics/DrWatson.jl.git",
        target = "build",
        push_preview = true
    )
end
