module DrWatson
using Pkg

export projectdir, datadir, srcdir, projectname, visdir

projectdir() = dirname(Base.active_project())*"/"
datadir() = projectdir()*"data/"
srcdir() = projectdir()*"src/"
projectname() = Pkg.REPLMode.promptf()[1:end-6]
visdir() = projectdir()*"visualizations/"


##########################################################################################
# Namings
##########################################################################################
export savename, @dict

"""
    allaccess(d)
Return all the keys `d` can be accessed using [`access`](@ref).
"""
allaccess(d::AbstractDict) = sort!(collect(keys(d)))
allaccess(d::Any) = fieldnames(typeof(d))
allaccess(d::DataType) = fieldnames(d)


"""
    access(d, key)
Access `d` with given key. For `AbstractDict` this is `getindex`,
for anything else it is `getproperty`.
"""
access(d::AbstractDict, key) = getindex(d, key)
access(d, key) = getproperty(d, key)

"""
```julia
savename(d, allowedtypes = (Real, String, Symbol);
         accesses = allaccess(d), digits = 3)
```
Create a shorthand name, commonly used for saving a file, based on the parameters
in the container `d` (`Dict`, `NamedTuple` or any other Julia composite type, e.g.
created with Parameters.jl).

The function chains keys and values into a string of the form:
```julia
key1=val1_key2=val2_key3=val3....
```
while the keys are always sorted alphabetically.

## Details
Only values of type in `allowedtypes` are used in the name. You can also specify
which keys you want to use with the keyword `accesses`. By default this is all possible
keys `d` can be accessed with, see [`allaccess`](@ref).

Floating point values are rounded to `digits`. In addition if the following holds:
```julia
round(val; digits = digits) == round(Int, val)
```
then the integer value is used in the name instead.

## Examples
```jldoctest
julia> d = (a = 0.153456453, b = 5.0, mode = "double")
(a = 0.153456453, b = 5.0, mode = "double")

julia> savename(d; digits = 4)
"a=0.1535_b=5_mode=double"

julia> savename(d, (String,))
"mode=double"

julia> rick = (never = "gonna", give = "you", up = "!");

julia> savename(rick) # keys are always sorted
  "give=you_never=gonna_up=!"
```
"""
function savename(d, allowedtypes = (Real, String, Symbol);
                  accesses = allaccess(d), digits = 3)

    labels = [string(a) for a in accesses]
    p = sortperm(labels)
    s = ""
    first = true
    for j ∈ p
        val = access(d, accesses[j])
        label = labels[j]
        t = typeof(val)
        if any(x -> (t <: x), allowedtypes)
            !first && (s *= "_")
            if t <: AbstractFloat
                if round(val; digits = digits) == round(Int, val)
                    val = round(Int, val)
                else
                    val = round(val; digits = digits)
                end
            end
            s *= label*"="*string(val);
            first = false
        end
    end
    return s
end

"""
    @dict vars...
Create a dictionary out of the given variables that has as keys the variable names
(symbols) and as values their values.
"""
macro dict(vars...)
    expr = Expr(:call, :Dict)
    for i in 1:length(vars)
        push!(expr.args, :($(QuoteNode(vars[i])) => $(esc(vars[i]))))
    end
    return expr
end

end # module
