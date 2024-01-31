##########################################################################################
# Project directory
##########################################################################################
export projectdir, datadir, srcdir, plotsdir, scriptsdir, papersdir
export projectname
export findproject, quickactivate, @quickactivate

"""
    is_standard_julia_project()

Return `true` if the standard Julia project is active.
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
    findproject(dir = pwd()) -> project_path
Recursively search `dir` and its parents for a valid Julia project file
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
    @warn "DrWatson could not find find a project file by recursively checking "*
    "given `dir` and its parents. Returning `nothing` instead.\n(given dir: $dir)"
    return nothing
end

"""
    quickactivate(path [, name::String])
Activate the project found by recursively searching the `path`
and its parents for a valid Julia project file via the [`findproject`](@ref) function.
Optionally check if `name` is the same as the activated project's name.
If it is not, throw an error. See also [`@quickactivate`](@ref).
Do nothing if the project found is already active, or if no
project file is found.

Example:
```julia
using DrWatson
quickactivate("path/to/project", "Best project in the WOLRLD")
```

Notice that this function is _first_ activating the project and _then_ checking if
it matches the `name`.

!!! warning
    Note that to access `quickactivate` you need to be `using DrWatson`.
    For this to be possible `DrWatson` must be already added in the
    existing global environment. If you use `quickactivate` and share your project, do
    note to your co-workers that they need to add `DrWatson` globally (the default
    README.md created by `initialize_project` says this automatically).

    **In addition, in your scripts write:**
    ```julia
    using DrWatson # YES
    quickactivate(@__DIR__)
    using Package1, Package2
    # do stuff
    ```
    **instead of the erroneous:**
    ```julia
    using DrWatson, Package1, Package2 # NO!
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

function get_dir_from_source(source_file)
    if source_file === nothing
        return nothing
    else
        _dirname = dirname(String(source_file))
        return isempty(_dirname) ? pwd() : abspath(_dirname)
    end
end

"""
    @quickactivate
Equivalent with `quickactivate(@__DIR__)`.

    @quickactivate name::String
Equivalent with `quickactivate(@__DIR__, name)`.

Notice that since `@quickactivate` is a macro, standard caveats apply
when using `Distributed` computing. Specifically, you need to import
`DrWatson` and use `@quickactivate` in different `begin` blocks as follows:
```julia
using Distributed
addprocs(8)
@everywhere using DrWatson

@everywhere begin
    @quickactivate "TestEnv"
    using Distributions, ...
    # remaining imports
end
```

!!! warning "Usage in Pluto.jl"
    Pluto.jl understands the `@quickactivate` macro and will switch to
    using the standard Julia package manager once it encounters it (or `quickactivate`).
    But, because `@quickactivate` is a macro
    it needs to be executed in a new cell, after `using DrWatson`. I.e., you need to split
    ```julia
    begin
        using DrWatson
        @quickactivate "Whatever"
    end
    ```
    to two different cells:
    ```julia
    using DrWatson
    ```
    ```julia
    @quickcativate "Whatever"
    ```
"""
macro quickactivate(name = nothing)
    dir = get_dir_from_source(__source__.file)
    :(quickactivate($dir,$name))
end

"""
    @quickactivate ProjectName::Symbol
If given a `Symbol` then first `quickactivate(@__DIR__, string(ProjectName))`,
and then do `using ProjectName`, as if the symbol was representing a module name.

This ties with [Making your project a usable module](@ref) functionality,
see the docs for an example.
"""
macro quickactivate(name::QuoteNode)
    dir = get_dir_from_source(__source__.file)
    quote
        quickactivate($dir, string($name))
        using $(name.value)
    end
end

##########################################################################################
# Project setup
##########################################################################################
export initialize_project

"""
    initialize_project(path [, name]; kwargs...)
Initialize a scientific project expected by `DrWatson` in `path` (directory representing
an empty folder).
If `name` is not given, it is assumed to be the folder's name.

The new project remains activated for you to immediately add packages.

## Keywords
* `readme = true` : adds a README.md file.
* `authors = nothing` : if a string or container of strings, adds the authors in the
  Project.toml file and README.md.
* `force = false` : If the `path` is _not_ empty then throw an error. If however `force`
  is `true` then recursively delete everything in the path and create the project.
* `git = true` : Make the project a Git repository.
* `add_test = true` : Add some additional files for testing the project.
  This is done automatically during continuous integration (if hosted on GitHub),
  or manually by running the contents of the `test/runtests.jl` file.
* `add_docs = false` : Add some additional files for generating documentation
  for the project, which can be generated locally by running `docs/make.jl` but
  is also generated and hosted during continuous integration using Documenter.jl
  (if hosted on GitHub). If this option is enabled, `Documenter` also becomes a
  dependency of the project.

  To host the docs online, set the keyword `github_name` with the name of the GitHub account
  you plan to upload at, and then manually enable the `gh-pages` deployment by going to
  settings/pages of the GitHub repo, and choosing as "Source" the `gh-pages` branch.

  Typically, a full documentation is not necessary for most projects, because README.md can
  serve as the documentation, hence this feature is `false` by default.
* `template = DrWatson.DEFAULT_TEMPLATE` : A template containing the folder structure
  of the project. It should be a vector containing strings (folders) or pairs of `String
  => Vector{String}`, containg a folder and subfolders (this can be nested further). Example:
  ```julia
  DEFAULT_TEMPLATE = [
    "_research",
    "src",
    "scripts",
    "data",
    "plots",
    "notebooks",
    "papers",
    "data" => ["sims", "exp_raw", "exp_pro"],
  ]
  ```
  Obviously, the default derivative functions of [`projectdir`](@ref), such as `datadir`,
  have been written with the default template in mind.
* `placeholder = false` : Add "hidden" placeholder files in each default folder to ensure
  that project folder structure is maintained when the directory is cloned (because
  empty folders are not pushed to a remote). Only used when `git = true`.
* `folders_to_gitignore = ["data", "videos","plots","notebooks","_research"]` : Folders to include in the created .gitignore
  """
function initialize_project(path, name=default_name_from_path(path);
    force=false, readme=true, authors=nothing,
    git=true, placeholder=false, template=DEFAULT_TEMPLATE,
    add_test=true, add_docs=false,
    github_name="PutYourGitHubNameHere",
    folders_to_gitignore=["data", "videos", "plots", "notebooks", "_research"]
)
    if git == false
        placeholder = false
    end
    if add_docs == true
        add_test = true
    end
    if add_docs == true && github_name == "PutYourGitHubNameHere"
        @warn "Docs will be generated but `github_name` is not set. " *
              "You'd need to manually change paths to GitHub in `make.jl`."
    end
    # Set up and potentially clean path
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
    # Instantiate git repository
    if git
        repo = LibGit2.init(path)
        sig = LibGit2.Signature("DrWatson", "no@mail", round(Int, time()), 0)
        LibGit2.commit(repo, "Initial commit"; author=sig, committer=sig)
        # Attempt to rename branch to `main`
        try
            default = LibGit2.branch(repo)
            branch = "main"
            if branch != default
                LibGit2.branch!(repo, branch)
                LibGit2.delete_branch(LibGit2.GitReference(repo, "refs/heads/$default"))
            end
        catch err
            @warn "We couldn't rename default branch to `main`, please do it manually. "*
            "We got error: \n$(sprint(showerror, err))"
        end
    end
    # Add packages
    Pkg.activate(path)
    try
        Pkg.add("DrWatson")
        if add_docs
            Pkg.add("Documenter")
        end
    catch
        @warn "Could not add DrWatson to project. Adding Pkg instead..."
        Pkg.add("Pkg")
    end
    # Instantiate template
    add_test && push!(template, "test", ".github/workflows")
    add_docs && push!(template, "docs", "docs/src")
    folders = insert_folders(path, template, placeholder)
    # Add standard files to git
    if git
        LibGit2.add!(repo, "Project.toml")
        LibGit2.add!(repo, "Manifest.toml")
        LibGit2.add!(repo, folders...)
        sig = LibGit2.Signature("DrWatson", "no@mail", round(Int, time()), 0)
        LibGit2.commit(repo, "Folder setup by DrWatson"; author=sig, committer=sig)
    end
    # Define some default pathing functions
    defaultdir(args...) = joinpath(@__DIR__, "defaults", args...)
    pathdir(args...) = joinpath(path, args...)
    function rename(file)
        s = read(file, String)
        replace(s, "<NAME-PLACEHOLDER>" => name)
    end
    # Create and add files
    # chmod is needed, as the file permissions are not
    # set correctly when adding the package with `add`.
    # First, add all default files

    function create_gitignore(gitignore_path, folders_to_ignore, template_path)

        output_lines = []
        line_index = 1
        in_section = false

        input_lines = readlines(template_path)

        start_line = 1
        end_line = n_lines = length(input_lines)
        for line in input_lines

            if startswith(line, "# Folders to ignore")
                in_section = true

                start_line = line_index
            end

            if (in_section && length(line) == 0)
                end_line = line_index
                break
            end

            line_index += 1
        end

        append!(output_lines, input_lines[1:start_line])

        for p in folders_to_ignore
            push!(output_lines, "/" * p)
        end

        append!(output_lines, input_lines[end_line:n_lines])

        open(gitignore_path, "w") do f
            for l in output_lines
                write(f, l * "\n")
            end
        end
        chmod(gitignore_path, 0o644)
    end

    create_gitignore(pathdir(".gitignore"),
        folders_to_gitignore, defaultdir("gitignore.txt"))

    cp(defaultdir("gitattributes.txt"), pathdir(".gitattributes"))
    chmod(pathdir(".gitattributes"), 0o644)

    if "scripts" ∈ template
        write(pathdir("scripts", "intro.jl"), rename(defaultdir("intro.jl")))
    end
    if "src" ∈ template
        write(pathdir("src", "dummy_src_file.jl"), rename(defaultdir("dummy_src_file.jl")))
    end
    if readme
        write(pathdir("README.md"), DEFAULT_README(name, authors; add_docs, github_name))
    end
    # Update Project.toml with name, version, and authors
    pro = read(pathdir("Project.toml"), String)
    w = "name = \"$name\"\n"
    if !(authors === nothing)
        w *= "authors = "*sprint(show, vecstring(authors))*"\n"
    end
    w *= compat_entry()
    write(pathdir("Project.toml"), w, pro)
    # Then, add optional files for tests and/or docs
    if add_test
        write(pathdir("test", "runtests.jl"), rename(defaultdir("runtests.jl")))
        ci_file = rename(defaultdir("ci.yml"))
        if add_docs
            docs_file = rename(defaultdir("ci_docs.yml"))
            ci_file = ci_file*'\n'*docs_file
            write(pathdir("docs", "make.jl"),
                replace(rename(defaultdir("make.jl")), "PutYourGitHubNameHere"=>github_name)
            )
            write(pathdir("docs", "src", "index.md"), rename(defaultdir("index.md")))
        end
        write(pathdir(".github", "workflows", "CI.yml"), ci_file)
    end
    # Lastly, commit everything via git
    if git
        LibGit2.add!(repo, ".")
        sig = LibGit2.Signature("DrWatson", "no@mail", round(Int, time()), 0)
        LibGit2.commit(repo, "File setup by DrWatson"; author=sig, committer=sig)
    end
    return path
end

function insert_folders(path, template, placeholder)
    # Default folders
    folders = String[]
    for p in template
        _recursive_folder_insertion!(path, p, placeholder, folders)
    end
    return folders
end
function _recursive_folder_insertion!(
        path, p::String, placeholder, folders
    )
    folder = joinpath(path, p)
    mkpath(folder)
    push!(folders, folder)
    if placeholder #Create a placeholder file in each path
        write(joinpath(folder, ".placeholder"), PLACEHOLDER_TEXT)
    end
end
function _recursive_folder_insertion!(
        path, p::Pair{String, <:Any}, placeholder, folders
    )
    path = joinpath(path, p[1])
    for z in p[2]
        _recursive_folder_insertion!(path, z, placeholder, folders)
    end
end
function _recursive_folder_insertion!(
        path, p::Pair{String, String}, placeholder, folders
    )
    path = joinpath(path, p[1])
    _recursive_folder_insertion!(path, p[2], placeholder, folders)
end

function compat_entry()
    DrWatson_VERSION = let
        project = joinpath(dirname(dirname(pathof(DrWatson))), "Project.toml")
        versionline = readlines(project)[4]
        VersionNumber(versionline[12:end-1])
    end
    """
    [compat]
    julia = "$(VERSION.major).$(VERSION.minor).$(VERSION.patch)"
    DrWatson = "$(DrWatson_VERSION)"
    """
end

vecstring(a::String) = [a]
vecstring(a::Vector{String}) = a
vecstring(c) = [string(a) for a in c]


function default_name_from_path(path)
    ap = abspath(path)
    path, dir = splitdir(ap)
    if length(dir) == 0
        _, dir = splitdir(path)
    end
    return dir
end


const PLACEHOLDER_TEXT = """
This file acts as a placeholder.
It ensures the project structure is copied whenever you clone the project.
This doesn't commit any files within the folder.
"""

function DEFAULT_README(name, authors = nothing;
        add_docs = false, github_name = "PutYourGitHubNameHere"
    )
    s = """
    # $name

    This code base is using the [Julia Language](https://julialang.org/) and
    [DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/)
    to make a reproducible scientific project named
    > $name

    """
    if !(authors === nothing)
        s *= "It is authored by "*join(vecstring(authors), ", ")*".\n\n"
    end

    s *= """
    To (locally) reproduce this project, do the following:

    0. Download this code base. Notice that raw data are typically not included in the
       git-history and may need to be downloaded independently.
    1. Open a Julia console and do:
       ```
       julia> using Pkg
       julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`
       julia> Pkg.activate("path/to/this/project")
       julia> Pkg.instantiate()
       ```

    This will install all necessary packages for you to be able to run the scripts and
    everything should work out of the box, including correctly finding local paths.

    You may notice that most scripts start with the commands:
    ```julia
    using DrWatson
    @quickactivate "$name"
    ```
    which auto-activate the project and enable local path handling from DrWatson.
    """
    if add_docs
        s *= """
        \n\n
        Some documentation has been set up for this project. It can be viewed by
        running the file `docs/make.jl`, and then launching the generated file
        `docs/build/index.html`.
        Alternatively, the documentation may be already hosted online.
        If this is the case it should be at:

        https://$(github_name).github.io/$(name)/dev/
        """
    end
    return s
end

##########################################################################################
# Project templates
##########################################################################################
const DEFAULT_TEMPLATE = [
    "_research",
    "src",
    "scripts",
    "plots",
    "notebooks",
    "papers",
    "data" => ["sims", "exp_raw", "exp_pro"],
]

const DOCUMENTS_TEMPLATE = [
    "src",
    "scripts",
    "plots",
    "notebooks",
    "documents",
    "papers",
    "data" => ["simulations", "observations", "analysis"],
]
