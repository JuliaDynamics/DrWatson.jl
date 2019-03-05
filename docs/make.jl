using Documenter, DrWatson

makedocs(modules = [DrWatson],
sitename= "DrWatson",
authors = "George Datseris and contributors.",
doctest = true,
format = Documenter.HTML(
    prettyurls = get(ENV, "CI", nothing) == "true",
    ),
pages = [
    "Introduction" => "index.md",
    "Project Setup" => "project.md",
    "Naming & Saving Simulations" => "savenames.md",
    "Running & Listing Simulations" => "addrun.md",
    "Real World Examples" => "real_world.md"
    ],
assets = ["assets/logo.ico"],
)

if get(ENV, "CI", nothing) == "true"
    deploydocs(repo = "github.com/JuliaDynamics/DrWatson.jl.git",
               target = "build")
end
