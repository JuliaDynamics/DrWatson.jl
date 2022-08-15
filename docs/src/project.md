# Project Setup

Part of the functionality of DrWatson is creating and navigating through a project setup consistently. This works even if you move your project to a different location/computer or send it to a colleague with a different Julia installation. In addition, the navigation process is identical across any project that uses DrWatson.

This can "just work" (TM) because of the following principles:

1. **Your science project is also a [Julia project](https://julialang.github.io/Pkg.jl/v1/environments/) defined by a `Project.toml` file.** This way the project tracks the used packages (and their versions) and can be shared with any other Julia user.
2. **You first activate this project environment before running any code.** This way you ensure that your project runs on the specified package installation (instead of the global one). See [Activating a Project](@ref) for ways to do this.
3. **You use the functions `projectdir`, `datadir`, etc. from DrWatson** to navigate your project (see [Navigating a Project](@ref)).

Importantly, our suggested project setup was designed to be fully reproducible, see [Reproducibility](@ref).

## Default Project Setup

DrWatson suggests a universal project structure for any scientific project, which is the following:

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
* `src` should only contain files that define functions or types but not output anything.

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
   4. using the function [`quickactivate`](@ref) or the macro [`@quickactivate`](@ref) offered by DrWatson.

We recommend the fourth approach, although it does come with a caveat (see the docstring of [`quickactivate`](@ref)).

```@docs
quickactivate
@quickactivate
findproject
```

Notice that to get the current project's name you can use:
```@docs
projectname
```

## Including Julia packages/modules in `src`
Notice that the project initialized by DrWatson does not represent a Julia package. It represents a scientific project. That being said, it is often the case that you want to develop normal Julia Modules (and perhaps later publish them as packages) inside your project, so that you can later use them in your code with `using ModuleName`. The proper way to do this is to initialize Julia packages, using the package manager, inside the `src` folder, using these steps:

1. Active your project that uses DrWatson.
2. Change directory to the project's main folder (**important!**).
3. Go into package mode and initialize a package with the name that you want: `generate src/ModuleName`
4. `dev` the local path to `ModuleName` using the package manager: `dev src/ModuleName`. Notice that this command uses a local path, see [this PR](https://github.com/JuliaLang/Pkg.jl/pull/1215) for more details.
   * If you don't care to make this module a Julia package, simply delete its `.git` folder: `src/Modulename/.git`.
   * If you do care about publishing this module as a Julia package, then it is mandatory to keep it as git-repository. In this case it is sensible to put `src/ModuleName/.git` into the main `.gitignore` file.

Now whenever you do `using ModuleName`, the local version will be used. This will still work even if you transfer your project to another computer, because the Manifest.toml file stores the local path.

## Navigating a Project
To be able to navigate the project consistently, DrWatson provides the core function
```@docs
projectdir
```

Besides the above, the following derivative functions
```julia
datadir()
srcdir()
plotsdir()
scriptsdir()
papersdir()
```
behave exactly like `projectdir` but have as root the appropriate subdirectory. These are also defined due to the frequent use of these subdirectories.

All of these functions take advantage of `joinpath`, ensuring an error-free path creation that works across different operating systems. It is heavily advised to use `projectdir` and derivatives by giving them the subpaths as arguments, instead of using multiplication between paths:
```julia
datadir("foo", "test.jld2") # preferred
datadir() * "/foo/test.jld2" # not recommended
```

### Custom directory functions

It is straightforward to make custom directory functions if there is a directory you created that you access more often. Simply define
```julia
customdir(args...) = projectdir("custom", args...)
```
to make the `customdir` version that works exactly like e.g. `datadir` but for `"custom"` instead of `"data"`.

## Reproducibility
The project setup approach that DrWatson suggests is designed to work flawlessly with Julia standards, to be easy to share and to be fully reproducible. There are three reasons that **true** reproducibility is possible:
1. The project's used packages are embedded in the project because of `Manifest.toml`.
2. The navigation around the folders of the project uses local directories.
3. The project is a Git repository, which means that it has a detailed (and re-traceable) history of all changes and additions.

If you send your entire project folder to a colleague, they only need to do:
```julia
julia> cd("path/to/project")
pkg> activate .
pkg> instantiate
```
to use your project (*assuming of course that you are both using the same Julia installation and version*).
All required packages and dependencies will be installed and then any script that was running in your computer will also be running in their computer **in the same way!**

In addition, with DrWatson you have the possibility of "tagging" each simulation created with the commit id, see the discussion around [`gitdescribe`](@ref) and [`tag!`](@ref).
This way, any data result obtained at any moment can be truly reproduced simply by resetting the Git tree to the appropriate commit and running the code.

## Transitioning an existing project to DrWatson
If you already have an existing project with scripts and data etc., then there is no reason to use the [`initialize_project`](@ref) function.
The only requirement is that everything that belongs to your project is contained within a single folder (which can have an arbitrary amount of subfolders).
If your project is already a Julia project (which means it has its own Project.toml and Manifest.toml files), then there is nothing more necessary to be done,
you can immediately start using DrWatson with it.
Although we recommend following the [Default Project Setup](@ref), you don't have to do this either, since you can create your own [Custom directory functions](@ref).

If your project is _not_ also a Julia project, the steps necessary are still quite simple. You can do:
```julia
julia> cd("path/to/project")
pkg> activate .
pkg> add Package1 Package2 ...
```
Julia will automatically make the Project.toml and Manifest.toml files for you as you add packages used by your project.
