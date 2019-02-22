using Documenter, DrWatson

makedocs(modules = [DrWatson],
sitename= "DrWatson",
authors = "George Datseris and contributors.",
doctest = true,
format = Documenter.HTML(
    prettyurls = get(ENV, "CI", nothing) == "true"
    ),
pages = [
    "Introduction" => "index.md",
    "Project Setup" => "project.md",
    "Handling Simulations" => "savenames.md",
    "Real World Examples" => "real_world.md"
    ]
)

if !Sys.iswindows()
    deploydocs(repo = "github.com/JuliaDynamics/DrWatson.jl.git",
               target = "build")
end
