"""
    produce_or_load(c, f [,path]; suffix = "jld2", kwargs...) -> file
Let `s = savename(c; kwargs...)`. If a file named `s.suffix` exists in the
given `path` (by default `""`) load it using `FileIO.load` and return it.

If the file does not exist then call `file = f(c)`, save the `file` in
`path` using `FileIO.save` and name `s.suffix`. Then return the `file`.

To play well with `FileIO` the function `f` should return a dictionary
with `String` as key type. The macro [`@dict`](@ref) can help with that.

See also [`savename`](@ref).
"""
function produce_or_load(c, f, path = ""; suffix = "jld2" kwargs...)

    s = savename(c; kwargs...)*"."*suffix
    spath = joinpath(path, s)
    if isfile(spath)
        file = FileIO.load(spath)
        return file
    else
        @info "File $s does not exist. Producing it now..."
        file = f(c)
        FileIO.save(spath, file)
        return file
    end
end

function addrun! end
