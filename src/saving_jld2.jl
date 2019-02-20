"""
    produce_or_load([prefix="",] c, f; suffix="jld2", kwargs...) -> file
Let `s = savename(prefix, c, suffix; kwargs...)`.
If a file named `s` exists load it using `FileIO.load` and return it.

If the file does not exist then call `file = f(c)`, save a copy of `file` as
`s` using `FileIO.save`. Then return the `file`.

To play well with `FileIO` the function `f` should return a dictionary
with `Symbol` as key type. The macro [`@strdict`](@ref) can help with that.

Notice that this function requires you to be `using FileIO`.
See also [`savename`](@ref).
"""
produce_or_load(c, f; kwargs...) = produce_or_load("", c, f; kwargs...)
function produce_or_load(prefix::String, c, f; suffix = "jld2", kwargs...)
    s = savename(prefix, c, suffix; kwargs...)
    if isfile(s)
        file = FileIO.load(s)
        return file
    else
        @info "File $s does not exist. Producing it now..."
        file = f(c)
        try
            mkpath(dirname(s))
            FileIO.save(s, copy(file))
        catch er
            @warn "Could not save file, got error $er. "*
            "\nReturning the file nontheless."
            isfile(s) && rm(s)
        end
        return file
    end
end

export produce_or_load
