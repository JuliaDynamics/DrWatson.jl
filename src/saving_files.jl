export produce_or_load, tagsave

"""
    produce_or_load([prefix="",] c, f; suffix="bson", kwargs...) -> file
Let `s = savename(prefix, c, suffix; kwargs...)`.
If a file named `s` exists load it and return it.

If the file does not exist then call `file = f(c)`, save `file` as
`s` and then return the `file`.

To play well with `BSON` the function `f` should return a dictionary
with `Symbol` as key type. The macro [`@dict`](@ref) can help with that.

See also [`savename`](@ref).
"""
produce_or_load(c, f; kwargs...) = produce_or_load("", c, f; kwargs...)
function produce_or_load(prefix::String, c, f; suffix = "bson", kwargs...)
    s = savename(prefix, c, suffix; kwargs...)
    if isfile(s)
        file = wload(s)
        return file
    else
        @info "File $s does not exist. Producing it now..."
        file = f(c)
        try
            mkpath(dirname(s))
            wsave(s, copy(file))
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
