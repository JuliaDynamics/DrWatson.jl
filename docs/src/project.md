# Project Setup

Part of the functionality of DrWatson is creating and navigating through a project setup consistently. This works even if you move your project to a different location/computer or send it to a colleague with a different Julia installation. In addition, the navigation process is identical across any project that uses DrWatson.

For this to work, you only need to follow these "rules":

1. **Your science project is also a Julia project defined by a `Project.toml` file.**
2. **You first activate this project environment before running any code.** See [Activating a Project](@ref) for ways to do this.
3. **You use the functions `scriptdir`, `datadir`, etc. from DrWatson** (see [Navigating a Project](@ref))

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

* If upon `include("file.jl")` there is _anything_ being produced, be it data files, plots or even output to the console, then it should be in `scripts`.
* If it is functionality used across multiple files or pipelines, it should be in `src`.
* `src` should only contain files that define functions or types but not output anything. You can also organize `src` to be a Julia package, or contain multiple Julia packages.

## Initializing a Project

To initialize a project as described in the [Default Project Setup](@ref) section, we provide the following function:
```@docs
initialize_project
```

## Activating a Project
This part of DrWatson's functionality requires you to have your scientific project (and as a consequence, the Julia project) activated.
This can be done in multiple ways:
   1. doing `Pkg.activate("path/to/project")` programmatically
   2. using the startup flag `--project path` when starting Julia
   3. by setting the [`JULIA_PROJECT`](https://docs.julialang.org/en/latest/manual/environment-variables/#JULIA_PROJECT-1) environment variable
   4. using the functions [`quickactivate`](@ref) and [`findproject`](@ref) offered by DrWatson.

We recommend the fourth approach, although it does come with a caveat (see the docstring of [`quickactivate`](@ref)).

Here is how it works: the function [`quickactivate`](@ref) activates a project given some path by recursively searching the path and its parents for a valid `Project.toml` file. Typically you put this function in your script files like so:
```julia
using DrWatson # DONT USE OTHER PACKAGES HERE!
quickactivate(@__DIR__, "Best project in the WOLLRDD")
# Now you should start using other packages
```
where the second optional argument can assert if the activated project matches the name you provided. If not the function will throw an error.

```@docs
quickactivate
findproject
```

Notice that to get the current project's name you can use:
```@docs
projectname
```

## Navigating a Project
To be able to navigate the project consistently, DrWatson provides the core function
```@docs
projectdir
```

Besides the above, the shortcut functions:
```julia
datadir()
srcdir()
plotsdir()
scriptdir()
papersdir()
```
immediately return the appropriate subdirectory. These are also defined due to the frequent use of these subdirectories.

In addition, the return value of all these functions ends with `/`. This means that you can directly chain them with a file name using just `*`. E.g. you could do
```julia
using DrWatson
file = makesimulation()
tagsave(datadir()*"sims/test.bson", file)
```

## Reproducibility
This project setup approach that DrWatson suggests has a very big side-benefit: it is fully reproducible firstly because it uses Julia's suggested project structure, secondly because the navigation only uses local directories and lastly because it is a Git repository.

If you send your entire project folder to a colleague, they only need to do:
```julia
julia> cd("path/to/project")
pkg> activate .
pkg> instantiate
```
All required packages and dependencies will be installed and then any script that was running in your computer will also be running in their computer **in the same way!**

In addition, with DrWatson you have the possibility of "tagging" each simulation created with the commit id, see the discussion around [`current_commit`](@ref) and [`tag!`](@ref).
