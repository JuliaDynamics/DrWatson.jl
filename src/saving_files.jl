export produce_or_load, tagsave, safesave

"""
    produce_or_load([prefix="",] c, f; kwargs...) -> file
Let `s = savename(prefix, c, suffix)`.
If a file named `s` exists then load it and return it.

If the file does not exist then call `file = f(c)`, save `file` as
`s` and then return the `file`.
The function `f` must return a dictionary.
The macros [`@dict`](@ref) and [`@strdict`](@ref) can help with that.

## Keywords
* `tag = true` : Add the Git commit of the project in the saved file.
* `gitpath = projectdir()` : Path to search for a Git repo.
* `suffix = "bson"` : Used in `savename`.
* `force = false` : If `true` then don't check if file `s` exists and produce
  it and save it anyway.
* `kwargs...` : All other keywords are propagated to `savename`.

See also [`savename`](@ref) and [`tag!`](@ref).
"""
produce_or_load(c, f; kwargs...) = produce_or_load("", c, f; kwargs...)
function produce_or_load(prefix::String, c, f;
    tag::Bool = true, gitpath = projectdir(),
    suffix = "bson", force = false, kwargs...)

    s = savename(prefix, c, suffix; kwargs...)

    if !force && isfile(s)
        file = wload(s)
        return file
    else
        if force
            @info "Producing file $s now..."
        else
            @info "File $s does not exist. Producing it now..."
        end
        file = f(c)
        try
            mkpath(dirname(s))
            if tag
                tagsave(s, file; gitpath = gitpath)
            else
            wsave(s, copy(file))
        end
        catch er
            @warn "Could not save file, got error $er. "*
            "\nReturning the file nontheless."
        end
        return file
    end
end

"""
    tagsave(file::String, d::Dict; gitpath, safe)
First [`tag!`](@ref) dictionary `d` and then save `d` in `file`.

## Keywords
* `gitpath = projectdir()` : Path of the Git repository.
* `safe = false` : Save the file using [`safesave`](@ref).
"""
function tagsave(file, d; gitpath = projectdir(), safe = false)
    d2 = tag!(d, gitpath)
    if safe
        safesave(file, copy(d2))
    else
        wsave(file, copy(d2))
    end
    return d2
end


################################################################################
#                          Backup files before saving                          #
################################################################################

# Implementation inspired by behavior of GROMACS
"""
    safesave(filename, data)

Safely save `data` in `filename` by ensuring that no existing files
are overwritten. Do this by renaming already existing data with a backup-number
ending like `#1, #2, ...`. For example if `filename = test.bson`, the first
time you `safesave` it, the file is saved normally. The second time
the existing save is renamed to `test_#1.bson` and a new file `test.bson`
is then saved.

If a backup file already exists then its backup-number is incremented
(e.g. going from `#2` to `#3`). For example safesaving `test.bson` a third time
will rename the old `test_#1.bson` to `test_#2.bson`, rename the old
`test.bson` to `test_#1.bson` and then save a new `test.bson` with the latest
`data`.

See also [`tagsave`](@ref).
"""
function safesave(f, data)
    recursively_clear_path(f)
    wsave(f, data)
end

#take a path of a results file and increment its prefix backup number
function increment_backup_num(filepath)
    path, filename = splitdir(filepath)
    fname, suffix = splitext(filename)
    m = match(r"^(.*)_#([0-9]+)$", fname)
    if m == nothing
        return joinpath(path, "$(fname)_#1$(suffix)")
    end
    newnum = string(parse(Int, m.captures[2]) +1)
    return joinpath(path, "$(m.captures[1])_#$newnum$(suffix)")
end

#recursively move files to increased backup number
function recursively_clear_path(cur_path)
    isfile(cur_path) || return
    new_path=increment_backup_num(cur_path)
    if isfile(new_path)
        recursively_clear_path(new_path)
    end
    mv(cur_path, new_path)
end
