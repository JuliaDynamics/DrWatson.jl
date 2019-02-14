# Project Setup

Part of the functionality of DrWatson is creating and navigating through a project setup consistently. This works even if you move your project to a different location/computer and in addition the navigation process is identical across any project that uses DrWatson.

For this to work, you only need to follow these rules:

1. **Your science project is also a Julia project defined by a `Project.toml` file.**
2. **You first activate this project environment before running any code.** This can be done in multiple ways:
   * by doing `Pkg.activate("path/to/project")` programmatically
   * by using the startup flag `--project path` when starting Julia
   * by setting the [`JULIA_PROJECT`](https://docs.julialang.org/en/latest/manual/environment-variables/#JULIA_PROJECT-1) environment variable
3. **You use the functions `scriptdir`, `datadir`, etc. from DrWatson** (see [Navigating the Project](@ref))

## Default Project Setup

Here is the default project setup that DrWatson suggests (and assumes, for the functionality of this page):

```@setup project
using DrWatson
struct ShowFile
    file::String
end
function Base.show(io::IO, ::MIME"text/plain", f::ShowFile)
    write(io, read(f.file))
end
```
```@example project
ShowFile(dirname(pathof(DrWatson))*"/defaults/project_structure.txt") # hide
```

### `src` vs `scripts`
Seems like `src` and `scripts` folders have pretty similar functionality. However there is a distinction between these two. You can follow these mental rules to know where to put `file.jl`:

1. If upon `include("file.jl")` there is _anything_ being produced, be it data files, plots or even output to the console, then it should be in `scripts`.
2. If it is functionality used across multiple files or pipelines, it should be in `src`.
3. `src` should only contain files the define functions or modules but not output anything. You can also organize `src` to be a Julia package, or contain multiple Julia packages.

## Initializing a Project

To initialize a project as described in the [Default Project Setup](@ref) section, we provide the following function:
```@docs
initialize_project
```

## Navigating the Project
To be able to navigate the project consistently, DrWatson provides the following functions:
```julia
datadir() = projectdir()*"data/"
srcdir() = projectdir()*"src/"
plotsdir() = projectdir()*"plots/"
scriptdir() = projectdir()*"scripts/"
```

while as you can see all of them use `projectdir`:
```@docs
projectdir
projectname
```

In addition, all these functions end with `/` by default. This means that you can directly chain them with a file name. E.g. you could do
```julia
using DrWatson, FileIO
file = makesimulation()
FileIO.save(datadir()*"simulations/test.jld2", file)
```

## Reproducibility
This project setup approach that DrWatson suggests has a very big side-benefit: it is fully reproducible firstly because it uses Julia's suggested project structure and secondly because the navigation only uses local directories.

If you send your entire project folder to a colleague, they only need to do:
```julia
julia> cd("path/to/project")
pkg> activate .
pkg> instantiate
```
All required packages and dependencies will be installed and then any script that was running in your computer will also be running in their computer **in the same way!**
