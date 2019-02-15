export savename, @dict, @ntuple

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
    savename(d; kwargs...)
Create a shorthand name, commonly used for saving a file, based on the parameters
in the container `d` (`Dict`, `NamedTuple` or any other Julia composite type, e.g.
created with Parameters.jl).

The function chains keys and values into a string of the form:
```julia
key1=val1_key2=val2_key3=val3...
```
while the keys are always sorted alphabetically.

`savename` can be very conveniently combined with
[`@dict`](@ref) or [`@ntuple`](@ref).

## Keywords
* `allowedtypes = (Real, String, Symbol)`
Only values of type subtyping `allowedtypes` are used in the name.

* `accesses = allaccess(d)`
You can also specify which specific keys you want to use with the keyword
`accesses`. By default this is all possible
keys `d` can be accessed with, see [`allaccess`](@ref).

* `digits = 3`
Floating point values are rounded to `digits`. In addition if the following holds:
```julia
round(val; digits = digits) == round(Int, val)
```
then the integer value is used in the name instead.

* `connector = "_"` : string used to connect the various entries.

## Examples
```jldoctest; setup = :(using DrWatson)
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
function savename(d; allowedtypes = (Real, String, Symbol),
                  accesses = allaccess(d), digits = 3,
                  connector = "_")

    labels = [string(a) for a in accesses]
    p = sortperm(labels)
    s = ""
    first = true
    for j ∈ p
        val = access(d, accesses[j])
        label = labels[j]
        t = typeof(val)
        if any(x -> (t <: x), allowedtypes)
            !first && (s *= connector)
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
Create a dictionary out of the given variables that has as keys the variable
names (as strings) and as values their values.

## Examples
```jldoctest; setup = :(using DrWatson)
julia> ω = 5; χ = "test"; ζ = π/3;

julia> @dict ω χ ζ
Dict{String,Any} with 3 entries:
  "ω" => 5
  "χ" => "test"
  "ζ" => 1.0472
```
"""
macro dict(vars...)
    expr = Expr(:call, :Dict)
    for i in 1:length(vars)
        push!(expr.args, :(string($(QuoteNode(vars[i]))) => $(esc(vars[i]))))
    end
    return expr
end


"""
    @ntuple vars...
Create a `NamedTuple` out of the given variables that has as keys the variable
names and as values their values.

## Examples
```jldoctest; setup = :(using DrWatson)
julia> ω = 5; χ = "test"; ζ = 3.14;

julia> @ntuple ω χ ζ
(ω = 5, χ = "test", ζ = 3.14)
```
"""
macro ntuple(vars...)
   args = Any[]
   for i in 1:length(vars)
       push!(args, Expr(:(=), esc(vars[i]), :($(esc(vars[i])))))
   end
   expr = Expr(:tuple, args...)
   return expr
end
# Credit of `ntuple` macro goes to Sebastian Pfitzner, @pfitzseb
