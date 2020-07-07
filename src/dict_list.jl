"""
    dict_list(c::Dict)
Expand the dictionary `c` into a vector of dictionaries.
Each entry has a unique combination from the product of the `Vector`
values of the dictionary while the non-`Vector` values are kept constant
for all possibilities. The keys of the entries are the same.

Whether the values of `c` are iterable or not is of no concern;
the function considers as "iterable" only subtypes of `Vector`.

Use the function [`dict_list_count`](@ref) to get the number of
dictionaries that `dict_list` will produce.

## Examples
```julia
julia> c = Dict(:a => [1, 2], :b => 4);

julia> dict_list(c)
3-element Array{Dict{Symbol,Int64},1}:
 Dict(:a=>1,:b=>4)
 Dict(:a=>2,:b=>4)

julia> c[:model] = "linear"; c[:run] = ["bi", "tri"];

julia> dict_list(c)
4-element Array{Dict{Symbol,Any},1}:
 Dict(:a=>1,:b=>4,:run=>"bi",:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"bi",:model=>"linear")
 Dict(:a=>1,:b=>4,:run=>"tri",:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"tri",:model=>"linear")

julia> c[:e] = [[1, 2], [3, 5]];

julia> dict_list(c)
8-element Array{Dict{Symbol,Any},1}:
 Dict(:a=>1,:b=>4,:run=>"bi",:e=>[1, 2],:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"bi",:e=>[1, 2],:model=>"linear")
 Dict(:a=>1,:b=>4,:run=>"tri",:e=>[1, 2],:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"tri",:e=>[1, 2],:model=>"linear")
 Dict(:a=>1,:b=>4,:run=>"bi",:e=>[3, 5],:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"bi",:e=>[3, 5],:model=>"linear")
 Dict(:a=>1,:b=>4,:run=>"tri",:e=>[3, 5],:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"tri",:e=>[3, 5],:model=>"linear")
```
"""
function dict_list(c::Dict)
    if any(t->t <: DependentParameter,eltype.(values(c)))
        return collect(Set(map(_dict_list(c)) do pd
                        n = length(pd)
                        for i in 1:100_000
                            foreach(collect(pd)) do (key,val)
                                if val isa DependentParameter && !val.condition(pd)
                                    delete!(pd,key)
                                end
                            end
                            length(pd) == n && break
                            n = length(pd)
                            i == 100_000 && error("There are too many parameters with a serial dependency. The limit is set to 100000")
                        end
                        Dict([k=>pd[k] isa DependentParameter ? pd[k].value : pd[k] for k in keys(pd)])
                    end))
    end
    return _dict_list(c)
end

function _dict_list(c::Dict)
    iterable_fields = filter(k -> typeof(c[k]) <: Vector, keys(c))
    non_iterables = setdiff(keys(c), iterable_fields)

    iterable_dict = Dict(iterable_fields .=> getindex.(Ref(c), iterable_fields))
    non_iterable_dict = Dict(non_iterables .=> getindex.(Ref(c), non_iterables))

    vec(
        map(Iterators.product(values(iterable_dict)...)) do vals
            dd = Dict(keys(iterable_dict) .=> vals)
            if isempty(non_iterable_dict)
                dd
            elseif isempty(iterable_dict)
                non_iterable_dict
            else
                merge(non_iterable_dict, dd)
            end
        end
    )
end

"""
    dict_list_count(c) -> N
Return the number of dictionaries that will be created by
calling `dict_list(c)`.
"""
function dict_list_count(c)
    if DependentParameter in eltype.(values(c))
        return length(dict_list(c))
    end
    iterable_fields = filter(k -> typeof(c[k]) <: Vector, keys(c))
    prod(length(c[i]) for i in iterable_fields)
end

# Taken from https://github.com/FluxML/MacroTools.jl
walk(x, inner, outer) = outer(x)
walk(x::Expr, inner, outer) = outer(Expr(x.head, map(inner, x.args)...))
postwalk(f, x) = walk(x, x -> postwalk(f, x), f)

export @onlyif

struct DependentParameter{T}
    value::T
    condition::Function
end

function toDependentParameter(value::T,condition) where T
    if T <: Vector
        return DependentParameter.(value,Ref(condition))
    end
    return DependentParameter(value,condition)
end

function lookup_candidate(d, name)
    if name in keys(d)
        if d[name] isa DependentParameter
            return d[name].value
        end
        return d[name]
    end
    return name
end

macro onlyif(ex, value)
    pd = :pd
    condition = postwalk(:(($pd)->$(ex))) do x
        if x isa QuoteNode || x isa String
            return :(DrWatson.lookup_candidate($pd, $x))
        end
        return x
    end
    :(toDependentParameter($(esc(value)),$(esc(condition))))
end
