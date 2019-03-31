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