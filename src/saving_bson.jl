"""
    produce_or_load([prefix="",] c, f; suffix="bson", kwargs...) -> file
Let `s = savename(prefix, c, suffix; kwargs...)`.
If a file named `s` exists load it using `BSON.load` and return it.

If the file does not exist then call `file = f(c)`, save a copy of `file` as
`s` using `BSON.bson`. Then return the `file`.

To play well with `BSON` the function `f` should return a dictionary
with `Symbol` as key type. The macro [`@dict`](@ref) can help with that.

Notice that this function requires you to be `using BSON`.
See also [`savename`](@ref).
"""
produce_or_load(c, f; kwarg...) = produce_or_load("", c, f; kwargs...)
function produce_or_load(prefix::String, c, f; suffix = "bson", kwargs...)
    s = savename(prefix, c, suffix; kwargs...)
    if isfile(s)
        file = BSON.load(s)
        return file
    else
        @info "File $s does not exist. Producing it now..."
        file = f(c)
        try
            mkpath(dirname(s))
            BSON.bson(s, copy(file))
        catch er
            @warn "Could not save file, got error $er. "*
            "\n Returning the file nontheless."
        end
        return file
    end
end

export produce_or_load
