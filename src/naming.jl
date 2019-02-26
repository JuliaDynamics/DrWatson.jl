export savename, @dict, @ntuple, @strdict
export ntuple2dict, dict2ntuple

"""
    allaccess(c)
Return all the keys `c` can be accessed using [`access`](@ref).
For dictionaries/named tuples this is `keys(c)`,
for everything else it is `fieldnames(typeof(c))`.
"""
allaccess(c::AbstractDict) = collect(keys(c))
allaccess(c::NamedTuple) = keys(c)
allaccess(c::Any) = fieldnames(typeof(c))
allaccess(c::DataType) = fieldnames(c)
allaccess(c::String) = error("`c` must be a container, not a string!")

"""
    access(c, key)
Access `c` with given key. For `AbstractDict` this is `getindex`,
for anything else it is `getproperty`.
"""
access(c::AbstractDict, key) = getindex(c, key)
access(c, key) = getproperty(c, key)

"""
    default_allowed(c) = (Real, String, Symbol)
Return the (super-)Types that will be used as `allowedtypes`
in [`savename`](@ref) or other similar functions.
"""
default_allowed(c) = (Real, String, Symbol)

"""
    default_prefix(c) = ""
Return the `prefix` that will be used by default
in [`savename`](@ref) or other similar functions.
"""
default_prefix(c) = ""

"""
    savename([prefix,], c [, suffix]; kwargs...)
Create a shorthand name, commonly used for saving a file, based on the
parameters in the container `c` (`Dict`, `NamedTuple` or any other Julia
composite type, e.g. created with Parameters.jl). If provided use
the `prefix` and end the name with `.suffix` (i.e. you don't have to include
the `.` in your `suffix`).

The function chains keys and values into a string of the form:
```julia
key1=val1_key2=val2_key3=val3
```
while the keys are **always sorted alphabetically.** If you provide
the prefix/suffix the function will do:
```julia
prefix_key1=val1_key2=val2_key3=val3.suffix
```
assuming you chose the default `connector`, see below. Notice
that `prefix` can be any path and in addition if
it ends as a path (`/` or `\\`) then the `connector` is ommited.

`savename` can be very conveniently combined with
[`@dict`](@ref) or [`@ntuple`](@ref).

## Keywords
* `allowedtypes = default_allowed(c)` : Only values of type subtyping
  anything in `allowedtypes` are used in the name. By default
  this is `(Real, String, Symbol)`.
* `accesses = allaccess(c)` : You can also specify which specific keys you want
  to use with the keyword `accesses`. By default this is all possible
  keys `c` can be accessed with, see [`allaccess`](@ref).
* `digits = 3` : Floating point values are rounded to `digits`.
  In addition if the following holds:
  ```julia
  round(val; digits = digits) == round(Int, val)
  ```
  then the integer value is used in the name instead.
* `connector = "_"` : string used to connect the various entries.

## Examples
```julia
d = (a = 0.153456453, b = 5.0, mode = "double")
savename(d; digits = 4) == "a=0.1535_b=5_mode=double"
savename("n", d) == "n_a=0.153_b=5_mode=double"
savename("n/", d) == "n/a=0.153_b=5_mode=double"
savename(d, "n") == "a=0.153_b=5_mode=double.n"
savename("data/n", d, "n") == "data/n_a=0.153_b=5_mode=double.n"
savename("n", d, "n"; connector = "-") == "n-a=0.153-b=5-mode=double.n"
savename(d, allowedtypes = (String,)) == "mode=double"

rick = (never = "gonna", give = "you", up = "!");
savename(rick) == "give=you_never=gonna_up=!" # keys are sorted!
```
"""
savename(c; kwargs...) = savename(default_prefix(c), c, ""; kwargs...)
savename(c::Any, suffix::String; kwargs...) =
    savename(default_prefix(c), c, suffix; kwargs...)
savename(prefix::String, c::Any; kwargs...) = savename(prefix, c, ""; kwargs...)
function savename(prefix::String, c, suffix::String;
                  allowedtypes = default_allowed(c),
                  accesses = allaccess(c), digits = 3,
                  connector = "_")

    labels = vecstring(accesses) # make it vector of strings
    p = sortperm(labels)
    first = prefix == "" || prefix[end] == '\\' || prefix[end] == '/'
    s = prefix
    for j ∈ p
        val = access(c, accesses[j])
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
    suffix != "" && (s *= "."*suffix)
    return s
end

"""
    @dict vars...
Create a dictionary out of the given variables that has as keys the variable
names and as values their values.

## Examples
```jldoctest; setup = :(using DrWatson)
julia> ω = 5; χ = "test"; ζ = π/3;

julia> @dict ω χ ζ
Dict{Symbol,Any} with 3 entries:
  :ω => 5
  :χ => "test"
  :ζ => 1.0472
```
"""
macro dict(vars...)
    expr = Expr(:call, :Dict)
    for i in 1:length(vars)
        push!(expr.args, :($(QuoteNode(vars[i])) => $(esc(vars[i]))))
    end
    return expr
end

"""
    @strdict vars...
Same as [`@dict`](@ref) but the key type is `String`.
"""
macro strdict(vars...)
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

"""
    ntuple2dict(nt) -> dict
Convert a `NamedTuple` to a dictionary.
"""
ntuple2dict(nt::NamedTuple) = Dict(k => nt[k] for k in keys(nt))

"""
    dict2ntuple(dict) -> ntuple
Convert a dictionary (with `Symbol` or `String` as key type) to
a `NamedTuple`.
"""
function dict2ntuple(dict::Dict{String, T}) where T
    NamedTuple{Tuple(Symbol.(keys(dict)))}(values(dict))
end
function dict2ntuple(dict::Dict{Symbol, T}) where T
    NamedTuple{Tuple(keys(dict))}(values(dict))
end
