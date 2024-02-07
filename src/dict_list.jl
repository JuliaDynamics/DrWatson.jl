export dict_list, dict_list_count
export Derived, @onlyif

"""
    dict_list(c::AbstractDict)
Expand the dictionary `c` into a vector of dictionaries.
Each entry has a unique combination from the product of the `Vector`
values of the dictionary while the non-`Vector` values are kept constant
for all possibilities. The keys of the entries are the same.

Whether the values of `c` are iterable or not is of no concern;
the function considers as "iterable" only subtypes of `Vector`.

To restrict some values in the dictionary so that they only appear in the
resulting dictionaries, if a certain condition is met, the macro
[`@onlyif`](@ref) can be used on those values.

To compute some parameters on creation of `dict_list` as a function
of other specified parameters, use the type [`Derived`](@ref).

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

## Example using Derived
```
julia> p = Dict(:α => [1, 2],
           :solver => ["SolverA","SolverB"],
           :β => Derived(:α, x -> x^2),
           )
Dict{Symbol, Any} with 3 entries:
  :α      => [1, 2]
  :solver => ["SolverA", "SolverB"]
  :β      => Derived{Symbol}(:α, #51)

julia> dict_list(p)
4-element Vector{Dict{Symbol, Any}}:
 Dict(:α => 1, :solver => "SolverA", :β => 1)
 Dict(:α => 2, :solver => "SolverA", :β => 4)
 Dict(:α => 1, :solver => "SolverB", :β => 1)
 Dict(:α => 2, :solver => "SolverB", :β => 4)
```
"""
function dict_list(c::AbstractDict)
    if contains_partially_restricted(c)
        # The method for generating the restricted parameter set is as follows:
        # 1. Remove any nested parameter restrictions (#209)
        # 2. Create an array of trial combinations containing all possible
        # combinations of all parameters.
        # 3. For each solution, remove all parameters where the conditions
        # functions returns false
        # 4. Do (3) until the length of the obtained parameter set stops
        # changing.
        # 5. Replace all `DependentParameter` types by their respective values
        # 6. This gives a parameter dict with a valid combination
        # 7. From the resulting list of valid combinations remove the
        # duplicates.
        # 8. Remove solutions which are only a subset of others.
        parameter_sets = unique!(map(_dict_list(unexpand_restricted(c))) do trial
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
        return produce_derived_parameters(collect(filter(parameter_sets) do trial
            !is_solution_subset_of_existing(trial, parameter_sets)
        end))
    end
    return produce_derived_parameters(_dict_list(c))
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

function _dict_list(c::AbstractDict)
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
    if contains_partially_restricted(c)
        return length(dict_list(c))
    end
    iterable_fields = filter(k -> typeof(c[k]) <: Vector, keys(c))
    prod(length(c[i]) for i in iterable_fields)
end

# Basis taken from https://github.com/FluxML/MacroTools.jl.
# The functions are similar to the ones from MacroTools but support an
# additional expression to be passed. The functions are NOT exported by
# MacroTools, so there is no need to rename or import them.
walk(x, inner, outer, ex) = outer(x, ex)
walk(x::Expr, inner, outer, ex) = outer(Expr(x.head, map(y->inner(y,x), x.args)...), ex)
postwalk(f, x, ex=:()) = walk(x, (x,y) -> postwalk(f, x, y), f, ex)

struct DependentParameter{T}
    value::T
    condition::Function
end

# This adds support for nesting DependentParameters, which translates to an and condition.
# The value is propagated upwards and both conditions are merged into one.
function DependentParameter(value::DependentParameter, condition::Function)
    new_condition = (args...) -> (condition(args...) && value.condition(args...))
    DependentParameter(value.value, new_condition)
end

contains_partially_restricted(d::AbstractDict) = any(contains_partially_restricted,values(d))
contains_partially_restricted(d::Vector) = any(contains_partially_restricted,d)
contains_partially_restricted(::DependentParameter) = true
contains_partially_restricted(::Any) = false


"""
    unexpand_restricted(c)
Return a dict where nested @[`@onlyif`](@ref) vectors are removed.
This is necessary, because `@onlyif` automatically broadcasts vector arguments.
In a case like this:

```julia
   :b => [@onlyif(:a==10,[10,11]), [12,13]]
```

Broadcasting is obviously not wanted as `:b` should retain it's type of `Vector{Int}`.
"""
function unexpand_restricted(c::AbstractDict{T}) where T
    _c = Dict{T,Any}() # There are hardly any cases where this will not be any.
    for k in keys(c)
        if c[k] isa AbstractVector && any(el->eltype(el) <: DependentParameter, c[k])
            _c[k] = unexpand_restricted.(c[k])
        else
            _c[k] = c[k]
        end
    end
    return _c
end

function unexpand_restricted(d::Vector{<:DependentParameter})
    values = [_d.value for _d in d]
    conditions = [_d.condition for _d in d]
    unique!(conditions)
    @assert length(conditions) == 1 "Nested @onlyif definitions with different conditions are not allowed."
    DependentParameter(values, conditions[1])
end

unexpand_restricted(d) = d

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

"""
   Derived(parameters::Vector{Union{String,Symbol}}, function::Function)
   Derived(parameter::Union{String,Symbol}, function::Function)

Wrap the name(s) of a parameter(s) and a function. After the
possible parameter combinations are created, [`dict_list`](@ref) will replace instances of
Derived by the result of the function func, evaluated with the value of
the parameter(s).

## Examples
```
julia> p = Dict(:α => [1, 2],
           :solver => ["SolverA","SolverB"],
           :β => Derived(:α, x -> x^2),
           )
Dict{Symbol, Any} with 3 entries:
  :α      => [1, 2]
  :solver => ["SolverA", "SolverB"]
  :β      => Derived{Symbol}(:α, #51)

julia> dict_list(p)
4-element Vector{Dict{Symbol, Any}}:
 Dict(:α => 1, :solver => "SolverA", :β => 1)
 Dict(:α => 2, :solver => "SolverA", :β => 4)
 Dict(:α => 1, :solver => "SolverB", :β => 1)
 Dict(:α => 2, :solver => "SolverB", :β => 4)
```
A vector of parameter names can also be passed when the accompanying function
uses multiple arguments:
```julia
 julia> p2 = Dict(:α => [1, 2],
           :β => [10,100],
           :solver => ["SolverA","SolverB"],
           :γ => Derived([:α,:β], (x,y) -> x^2 + 2y),
           )
Dict{Symbol, Any} with 4 entries:
  :α      => [1, 2]
  :γ      => Derived{Symbol}([:α, :β], #7)
  :solver => ["SolverA", "SolverB"]
  :β      => [10, 100]

julia> dict_list(p2)
8-element Vector{Dict{Symbol, Any}}:
 Dict(:α => 1, :γ => 21, :solver => "SolverA", :β => 10)
 Dict(:α => 2, :γ => 24, :solver => "SolverA", :β => 10)
 Dict(:α => 1, :γ => 21, :solver => "SolverB", :β => 10)
 Dict(:α => 2, :γ => 24, :solver => "SolverB", :β => 10)
 Dict(:α => 1, :γ => 201, :solver => "SolverA", :β => 100)
 Dict(:α => 2, :γ => 204, :solver => "SolverA", :β => 100)
 Dict(:α => 1, :γ => 201, :solver => "SolverB", :β => 100)
 Dict(:α => 2, :γ => 204, :solver => "SolverB", :β => 100)
```
"""
struct Derived{T}
    independentParam::Vector{T}
    func::Function
end

# convenience dispatch
function Derived(independentP::Union{String,Symbol}, func::Function)
    return Derived([independentP], func)
end


"""
   produce_computed_parameter(dicts)

Receive an array of parameter dictionaries, and for each one, evaluate
the computed parameters after the possible combination of
parameters has been created.
"""
function produce_derived_parameters(dicts)
    for dict in dicts
        replace!(dict) do (k,v)
           if isa(v,Derived)
            k => v.func((dict[param] for param in v.independentParam)...)
           else
            return k => v
           end
        end
    end
    return dicts
end