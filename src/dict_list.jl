"""
    dict_list(c::Dict)
Expand the dictionary `c` into a vector of dictionaries.
Each entry has a unique combination from the product of the `Vector`
values of the dictionary while the non-`Vector` values are kept constant
for all possibilities. The keys of the entries are the same.

Whether the values of `c` are iterable or not is of no concern;
the function considers as "iterable" only subtypes of `Vector`.

To restrict some values in the dictionary so that they only appear in the
resulting dictionaries, if a certain condition is met, the macro
[`@onlyif`](@ref) can be used on those values.

Use the function [`dict_list_count`](@ref) to get the number of
dictionaries that `dict_list` will produce.

## Examples
```julia
julia> c = Dict(:a => [1, 2], :b => 4);

julia> dict_list(c)
2-element Array{Dict{Symbol,Int64},1}:
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
    if contains_partially_restricted(c)
        # The method for generating the restricted parameter set is as follows:
        # 1. Create an array of trial combinations containing all possible
        # combinations of all parameters.
        # 2. For each solution, remove all parameters where the conditions
        # functions returns false
        # 3. Do (2) until the length of the obtained parameter set stops
        # changing.
        # 4. Replace all `DependentParameter` types by their respective values
        # 5. This gives a parameter dict with a valid combination
        # 6. From the resulting list of valid combinations remove the
        # duplicates.
        # 7. Remove solutions which are only a subset of others.
        parameter_sets = Set(map(_dict_list(c)) do trial
                                 n = length(trial)
                                 for i in 1:100_000
                                     for key in keys(trial)
                                         val = trial[key]
                                         if val isa DependentParameter && !val.condition(c,trial)
                                             delete!(trial,key)
                                         end
                                     end
                                     length(trial) == n && break
                                     n = length(trial)
                                     i == 100_000 && error("There are too many parameters with a serial dependency. The limit is set to 100000.")
                                 end
                                 Dict([k=>lookup_candidate(c,trial,k) for k in keys(trial)])
                             end)
        return collect(filter(parameter_sets) do trial
            !is_solution_subset_of_existing(trial, parameter_sets)
        end)
    end
    return _dict_list(c)
end

function is_solution_subset_of_existing(trial, trial_solutions)
    ks = Set(keys(trial))
    for _trial in trial_solutions
        trial == _trial && continue
        ks ⊆ Set(keys(_trial)) || continue
        all(trial[k] == _trial[k] for k in ks) && return true
    end
    return false
end

function _dict_list(c::Dict)
    iterable_fields = filter(k -> typeof(c[k]) <: Vector, keys(c))
    non_iterables = setdiff(keys(c), iterable_fields)

    iterable_dict = Dict(iterable_fields .=> getindex.(Ref(c), iterable_fields))
    non_iterable_dict = Dict(non_iterables .=> getindex.(Ref(c), non_iterables))

    vec(
        map(Iterators.product(values(iterable_dict)...)) do vals
            dd = [k=>convert(eltype(c[k]),v) for (k,v) in zip(keys(iterable_dict),vals)]
            if isempty(non_iterable_dict)
                Dict(dd)
            elseif isempty(iterable_dict)
                non_iterable_dict
            else
                # We can't use merge here because it promotes types.
                # The uniqueness of the dictionary keys is guaranteed.
                Dict(dd..., collect(non_iterable_dict)...)
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

# Basis taken from https://github.com/FluxML/MacroTools.jl
walk(x, inner, outer, ex) = outer(x, ex)
walk(x::Expr, inner, outer, ex) = outer(Expr(x.head, map(y->inner(y,x), x.args)...), ex)
postwalk(f, x, ex=:()) = walk(x, (x,y) -> postwalk(f, x, y), f, ex)

export @onlyif

struct DependentParameter{T}
    value::T
    condition::Function
end

contains_partially_restricted(d::Dict) = any(contains_partially_restricted,values(d))
contains_partially_restricted(d::Vector) = any(contains_partially_restricted,d)
contains_partially_restricted(::DependentParameter) = true
contains_partially_restricted(::Any) = false

function toDependentParameter(value::T,condition) where T
    if T <: Vector
        return DependentParameter.(value,Ref(condition))
    end
    return DependentParameter(value,condition)
end

struct KeyDeletedFromDictError <: Exception end

"""
    lookup_candidate(original_dict, d, name)
If `name` is a key name from `original_dict` either return it's value from `d`
or throw a `KeyDeletedFromDictError` error if it's not in `d`.
"""
function lookup_candidate(original_dict,d, name)
    if name in keys(original_dict)
        name in keys(d) || throw(KeyDeletedFromDictError())
        if d[name] isa DependentParameter
            return d[name].value
        end
        return d[name]
    end
    return name
end

"""
    @onlyif(ex, value)
Tag `value` to only appear in a dictionary created with [`dict_list`](@ref) if
the Julia expression `ex` (see below) is evaluated as true.  If `value` is a subtype of
`Vector`, `@onlyif` is applied to each entry.
Since `@onlyif` is applied to a value and not to a dictionary key, it is
possible to restrict only some of the values of a vector. This means that based
on `ex` the number of options for a particular key varies.

Within `ex` it is possible to extract values of the dictionary passed to
[`dict_list`](@ref) by a shorthand notation where only the key must be
provided.  For example `ex = :(:N == 1)` is tranformed in the call
`dict_list(d)` to an expression analogous to `:(d[:N] == 1)` by using the
function `lookup_candidate`.  This is supported for `Symbol` and `String` keys.

## Examples
```julia
julia> d = Dict(:a => [1, 2], :b => 4, :c => @onlyif(:a == 1, [10, 11]));

julia> dict_list(d) # only in case `:a` is `1` the dictionary will get key `:c`
3-element Array{Dict{Symbol,Int64},1}:
 Dict(:a => 1,:b => 4,:c => 10)
 Dict(:a => 1,:b => 4,:c => 11)
 Dict(:a => 2,:b => 4)

 julia> d = Dict(:a => [1, 2], :b => 4, :c => [10, @onlyif(:a == 1, 11)]);

 julia> dict_list(d) # only in case `:a` is `1` the dictionary will get extra value `11` for key `:c`
 3-element Array{Dict{Symbol,Int64},1}:
 Dict(:a => 1,:b => 4,:c => 10)
 Dict(:a => 1,:b => 4,:c => 11)
 Dict(:a => 2,:b => 4,:c => 10)
```
 See the [Defining parameter sets with restrictions](@ref) section for more examples.
 """
 macro onlyif(ex, value)
     pd = gensym()
     original_dict = gensym()
     anon_function = quote
         ($(original_dict),$pd)->try
             $(ex)
         catch e
             e isa DrWatson.KeyDeletedFromDictError && return false
             rethrow(e)
         end
     end
     condition = postwalk(anon_function) do x, parent
         # Check if the parent expression in the postwalk is a dot expression
         # like Foo.Bar. In this case Bar is a QuoteNode, however it should not
         # be wrapped by the lookup_candidate function, because without Foo it's
         # not valid.
         if (x isa QuoteNode && !(parent isa Expr && parent.head == :.)) || x isa String
             return :(DrWatson.lookup_candidate($(original_dict),$pd, $x))
         end
         return x
     end
     :(toDependentParameter($(esc(value)),$(esc(condition))))
 end
