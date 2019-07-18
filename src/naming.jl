export savename, @savename, @dict, @ntuple, @strdict, parse_savename
export ntuple2dict, dict2ntuple

"""
    savename([prefix,], c [, suffix]; kwargs...)
Create a shorthand name, commonly used for saving a file or as a figure title,
based on the
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
See [`default_prefix`](@ref) for more.

`savename` can be very conveniently combined with
[`@dict`](@ref) or [`@ntuple`](@ref).
See also [`parse_savename`](@ref).

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
* `expand::Vector{String} = default_expand` : keys that will be expanded
  to the `savename` of their contents, to allow for nested containers.
  By default is empty. Notice that the type of the container must also be
  allowed for `expand` to take effect!

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
                  connector = "_", expand::Vector{String} = default_expand(c))

    # Here take care of extra prefix besides default
    dpre = default_prefix(c)
    if dpre != "" && prefix != dpre
        prefix = joinpath(prefix, dpre)
    end

    labels = vecstring(accesses) # make it vector of strings
    p = sortperm(labels)
    first = prefix == "" || endswith(prefix, PATH_SEPARATOR)
    s = prefix
    for j ∈ p
        val = access(c, accesses[j])
        label = labels[j]
        t = typeof(val)
        if any(x -> (t <: x), allowedtypes)
            !first && (s *= connector)
            if t <: AbstractFloat
                x = round(val; digits = digits); y = round(Int, val)
                val = x == y ? y : x
            end
            if label ∈ expand
                s *= label*"="*'('*savename(val;connector=",")*')'
            else
                s *= label*"="*string(val)
            end
            first = false
        end
    end
    suffix != "" && (s *= "."*suffix)
    return s
end

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

    access(c, keys...)
When given multiple keys, `access` is called recursively, i.e.
`access(c, key1, key2) = access(access(c, key1), key2)` and so on.
For example, if `c, c.k1` are `NamedTuple`s then
`access(c, k1, k2) == c.k1.k2`.

!!! note
    Please only extend the single key method when customizing `access`
    for your own Types.
"""
access(c, keys...) = access(access(c, keys[1]), Base.tail(keys)...)
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

Notice that if `default_prefix` is defined for `c` but a prefix is also given
to [`savename`](@ref) then the two values are merged via `joinpath` for
convenience (if they are not the same of course).

E.g. defining `default_prefix(c::MyType) = "lala"` and calling
```julia
savename(datadir(), mytype)
```
will in fact return a string that looks like
```julia
"path/to/data/lala_p1=..."
```
This allows [`savename`](@ref) to nicely inderplay with
[`produce_or_load`](@ref) as well as paths-as-prefixes.
"""
default_prefix(c) = ""

"""
    default_expand(c) = String[]
Keys that should be expanded in their `savename` within [`savename`](@ref).
Must be `Vector{String}` (as all keys are first translated into strings inside
`savename`).
"""
default_expand(c) = String[]

"""
    @dict vars...
Create a dictionary out of the given variables that has as keys the variable
names and as values their values.

Notice: `@dict a b` is the correct way to call the macro. `@dict a, b`
is incorrect. If you want to use commas you have to do `@dict(a, b)`.

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
    return esc_dict_expr_from_vars(vars)
end

"""
    @savename vars...
Convenient combination of chaining a call to [`@dict`](@ref) on `vars` and [`savename`](@ref).

## Examples
```julia
julia> a = 0.153456453; b = 5.0; mode = "double"
julia> @savename a b mode
"a=0.153_b=5_mode=double"
```
"""
macro savename(vars...)
    expr = esc_dict_expr_from_vars(vars)
    return :(savename($expr))
end

"""
    esc_dict_expr_from_vars(vars)
Transform a `Tuple` of `Symbol` into a dictionary where each `Symbol` in `vars`
defines a key-value pair. The value is obtained by evaluating the `Symbol` in
the macro calling environment.

This should only be called when producing an expression intended to be returned by a macro.
"""
function esc_dict_expr_from_vars(vars)
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


"""
    parse_savename(filename::AbstractString; kwargs...)
Try to convert a shorthand name produced with [`savename`](@ref) into a dictionary
containing the parameters and their values, a prefix and suffix string.
Return `prefix, parameters, suffix`.

Parsing the key-value parts of `filename` is performed under the assumption that the value
is delimited by `=` and the closest `connector`. This allows the user to have `connector`
(eg. `_`) in a key name (variable name) but not in the value part.

## Keywords
* `connector = "_"` : string used to connect the various entries.
* `parsetypes = (Int, Float64)` : tuple used to define the types which should
  be tried when parsing the values given in `filename`. Fallback is `String`.
"""
function parse_savename(filename::AbstractString;
                        parsetypes = (Int, Float64),
                        connector::AbstractString = "_")
    length(connector) == 1 || error(
    "Cannot parse savenames where the 'connector'"*
    " string consists of more than one character.")

    # Prefix can be anything, so it might also contain a folder which's
    # name was generated using savename. Therefore first the path is split
    # into folders and filename.
    prefix_part, savename_part = dirname(filename),basename(filename)
    # Extract the suffix. A suffix is identified by searching for the last "."
    # after the last "=".
    last_eq = findlast("=",savename_part)
    last_dot = findlast(".",savename_part)
    if last_dot == nothing || last_eq > last_dot
        # if no dot is after the last "="
        # there is no suffix
        name, suffix = savename_part,""
    else
        # Check if the last dot is part of a float number by parsing it as Int
        if tryparse(Int,savename_part[first(last_dot)+1:end]) == nothing
            # no int, so the part after the last dot is the suffix
            name, suffix = savename_part[1:first(last_dot)-1], savename_part[first(last_dot)+1:end]
        else
            # no suffix, because the dot just denotes the decimal places.
            name, suffix = savename_part, ""
        end
    end
    # Extract the prefix by searching for the first connector that comes before
    # an "=".
    first_eq = findfirst("=",name)
    first_connector = findfirst(connector,name)
    if first_connector == nothing || first(first_eq) < first(first_connector)
        prefix, _parameters = "", name
    else
        # There is a connector symbol before, so there might be a connector.
        # Of course the connector symbol could also be part of the variable name.
        prefix, _parameters = name[1:first(first_connector)-1], name[first(first_connector)+1:end]
    end
    # Add leading directory back to prefix
    prefix = joinpath(prefix_part,prefix)
    parameters = Dict{String,Any}()
    # Regex that matches smalles possible range between = and connector.
    # This way it is possible to corretly match something where the
    # connector ("_") was used as a variable name.
    # var_with_undersocore_1=foo_var=123.32_var_name_with_underscore=4.4
    # var_with_undersocore_1[=foo_]var[=123.32_]var_name_with_underscore=4.4
    name_seperator = Regex("=[^$connector]+$connector")
    c_idx = 1
    while (next_range = findnext(name_seperator,_parameters,c_idx)) != nothing
        equal_sign, end_of_value = first(next_range), last(next_range)-1
        parameters[_parameters[c_idx:equal_sign-1]] =
            parse_from_savename_value(parsetypes,_parameters[equal_sign+1:end_of_value])
        c_idx = end_of_value+2
    end
    # The last = cannot be followed by a connector, so it's not captured by the regex.
    equal_sign = findnext("=",_parameters,c_idx)
    equal_sign == nothing && error(
        "Savename cannot be parsed. There is a '$connector' after the last '='. "*
        "Values containing '$connector' are not allowed when parsing.")
    parameters[_parameters[c_idx:first(equal_sign)-1]] =
        parse_from_savename_value(parsetypes,_parameters[first(equal_sign)+1:end])
    return prefix,parameters,suffix
end

"""
    parse_from_savename_value(types,str)
Try parsing `str` with the types given in `types`. The first working parse is returned.
Fallback is `String` ie. `str` is returned.
"""
function parse_from_savename_value(types::NTuple{N,<:Type},str::AbstractString) where N
    for t in types
        res = tryparse(t,str)
        res == nothing || return res
    end
    return str
end
