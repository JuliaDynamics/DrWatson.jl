export produce_or_load, tagsave

"""
    produce_or_load([prefix="",] c, f; kwargs...) -> file
Let `s = savename(prefix, c, suffix)`.
If a file named `s` exists then load it and return it.

If the file does not exist then call `file = f(c)`, save `file` as
`s` and then return the `file`.

To play well with `BSON` the function `f` should return a dictionary
with `Symbol` as key type. The macro [`@dict`](@ref) can help with that.

## Keywords
* `tag = false` : Add the Git commit of the project in the saved file.
* `projectpath = projectdir()` : Path to search for a Git repo.
* `suffix = "bson"` : Used in `savename`.
* `kwargs...` : All other keywords are propagated to `savename`.

See also [`savename`](@ref) and [`tag!`](@ref).
"""
produce_or_load(c, f; kwargs...) = produce_or_load("", c, f; kwargs...)
function produce_or_load(prefix::String, c, f;
    tag::Bool = false, projectpath = projectdir(),
    suffix = "bson", kwargs...)
    s = savename(prefix, c, suffix; kwargs...)
    if isfile(s)
        file = wload(s)
        return file
    else
        @info "File $s does not exist. Producing it now..."
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
            isfile(s) && rm(s)
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
