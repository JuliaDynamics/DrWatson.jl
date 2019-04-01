export produce_or_load, tagsave, safesave

"""
    produce_or_load([prefix="",] c, f; kwargs...) -> file
Let `s = savename(prefix, c, suffix)`.
If a file named `s` exists then load it and return it.

If the file does not exist then call `file = f(c)`, save `file` as
`s` and then return the `file`.
The function `f` must return a dictionary.
The macros [`@dict`](@ref) and [`strdict`](@ref) can help with that.

## Keywords
* `tag = false` : Add the Git commit of the project in the saved file.
* `projectpath = projectdir()` : Path to search for a Git repo.
* `suffix = "bson"` : Used in `savename`.
* `force = false` : If `true` then don't check if file `s` exists and produce
  it and save it anyway.
* `kwargs...` : All other keywords are propagated to `savename`.

See also [`savename`](@ref) and [`tag!`](@ref).
"""
produce_or_load(c, f; kwargs...) = produce_or_load("", c, f; kwargs...)
function produce_or_load(prefix::String, c, f;
    tag::Bool = false, projectpath = projectdir(),
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
                tagsave(s, file, projectpath)
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
    tagsave(file::String, d::Dict [, path = projectdir()])
First [`tag!`](@ref) dictionary `d` using the project in `path`,
and then save `d` in `file`.
"""
function tagsave(file, d, path = projectdir())
    d2 = tag!(d, path)
    wsave(copy(d2))
    return d2
end


################################################################################
#                          Backup files before saving                          #
################################################################################

# Implementation inspired by behavior of GROMACS
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

"""
    safesave(filename, data)

A wrapper around FileIO.save that ensures no existing files are overwritten.
If a file with name `filename` such as `test.bson` already exists
it will be renamed to `test_#1.bson` before the new data is written
to `test.bson`.
It recursively makes sure that no existing backups are overwritten
by increasing the backup-number:
`test.bson → test_#1.bson → test_#2.bson → ...`
"""
function safesave(f, data)
    recursively_clear_path(f)
    FileIO.save(f,data)
end
