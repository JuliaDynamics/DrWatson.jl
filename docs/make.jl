using Documenter, DrWatson
using BSON, DataFrames, Parameters, Dates

makedocs(modules = [DrWatson],
sitename= "DrWatson",
authors = "George Datseris and contributors.",
doctest = false,
format = Documenter.HTML(
    prettyurls = get(ENV, "CI", nothing) == "true",
    ),
pages = [
    "Introduction" => "index.md",
    "Project Setup" => "project.md",
    "Naming & Saving Simulations" => "name&save.md",
    "Running & Listing Simulations" => "run&list.md",
    "Real World Examples" => "real_world.md"
    ],
assets = ["assets/logo.ico"],
)

if get(ENV, "CI", nothing) == "true"
    deploydocs(repo = "github.com/JuliaDynamics/DrWatson.jl.git",
               target = "build")
end
