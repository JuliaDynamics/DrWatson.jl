export current_commit, tag
export dict_list, ntuple_list

function addrun! end

"""
    current_commit(path = projectdir()) -> commit
Return the current active commit id of the Git repository present
in `path`, which by default is the project path. For example:
```julia
julia> current_commit()
"96df587e45b29e7a46348a3d780db1f85f41de04"
```
"""
function current_commit(path = projectdir())
    # Here we test if the path is a git repository.
    try
        repo = LibGit2.GitRepo(path)
    catch er
        @warn "The current project directory is not a Git repository, "*
        "returning `nothing` instead of the commit id."
        return nothing
    end
    # then we return the current commit
    repo = LibGit2.GitRepo(path)
    return string(LibGit2.head_oid(repo))
end

"""
    tag(d::Dict, path = projectdir()) -> d
Tag `d` by adding an extra field `commit` which will have as value
the [`current_commit`](@ref) of the repository at `path` (by default
the project's path).

Notice that if `String` is not a subtype of the value type of `d` then
a new dictionary is created and returned. Otherwise the operation
is inplace (and the dictionary is returned again).

## Examples
```julia
julia> d = Dict(:x => 3, :y => 4)
Dict{Symbol,Int64} with 2 entries:
  :y => 4
  :x => 3

julia> tag(d)
Dict{Symbol,Any} with 3 entries:
  :y      => 4
  :commit => "96df587e45b29e7a46348a3d780db1f85f41de04"
  :x      => 3
```
"""
function tag(d::Dict{K, T}, path = projectdir()) where {K, T}
    c = current_commit(path)
    c === nothing && return d
    if haskey(d, K("commit"))
        @warn "The dictionary already has a key named `commit`. We won't "
        "overwrite it with the commit id."
    end
    if String <: T
        d[K("commit")] = c
    else
        d = Dict{K, promote_type(T, String)}(d)
        d[K("commit")] = c
    end
    return d
end


"""
    dict_list(c)
Expand the dictionary `c` into a vector of dictionaries.
Each entry has a unique combination from the product of the `Vector`
values of the dictionary while the non-`Vector` values are kept constant
for all possibilities. The keys of the entries are the same.

Whether the values of `c` are iterable or not is of no concern;
the function considers as "iterable" only subtypes of `Vector`.

See also [`ntuple_list`](@ref).

## Examples
julia> c = Dict(:a => [1, 2], :b => 4);

julia> dict_list(c)
3-element Array{Dict{Symbol,Int64},1}:
 Dict(:a=>1,:b=>4)
 Dict(:a=>2,:b=>4)

julia> c[:c] = "test"; c[:d] = ["lala", "lulu"];

julia> dict_list(c)
4-element Array{Dict{Symbol,Any},1}:
 Dict(:a=>1,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>1,:b=>4,:d=>"lulu",:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lulu",:c=>"test")

julia> c[:e] = [[1, 2], [3, 5]];

julia> dict_list(c)
8-element Array{Dict{Symbol,Any},1}:
 Dict(:a=>1,:b=>4,:d=>"lala",:e=>[1, 2],:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lala",:e=>[1, 2],:c=>"test")
 Dict(:a=>1,:b=>4,:d=>"lulu",:e=>[1, 2],:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lulu",:e=>[1, 2],:c=>"test")
 Dict(:a=>1,:b=>4,:d=>"lala",:e=>[3, 5],:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lala",:e=>[3, 5],:c=>"test")
 Dict(:a=>1,:b=>4,:d=>"lulu",:e=>[3, 5],:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lulu",:e=>[3, 5],:c=>"test")
"""
function dict_list(c)
    iterable_fields = filter(k -> typeof(c[k]) <: Vector, keys(c))
    non_iterables = setdiff(keys(c), iterable_fields)

    iterable_dict = Dict(iterable_fields .=> getindex.(Ref(c), iterable_fields))
    non_iterable_dict = Dict(non_iterables .=> getindex.(Ref(c), non_iterables))

    vec(
        map(Iterators.product(values(iterable_dict)...)) do vals
            dd = Dict(keys(iterable_dict) .=> vals)
            merge(non_iterable_dict, dd)
        end
    )
end

# function ntuple_list(c)
#     iterable_fields = filter(k -> typeof(c[k]) <: Vector, collect(keys(c)))
#     non_iterables = setdiff(keys(c), iterable_fields)
#
#     iterable_vals = Tuple(collect((typeof(c[i]) for i in iterable_fields)))
#     iterable_tuple = NamedTuple{tuple(iterable_fields), iterable_vals}
#
#     Dict(iterable_fields .=> getindex.(Ref(c), iterable_fields))
#     non_iterable_tuple = Dict(non_iterables .=> getindex.(Ref(c), non_iterables))
#
#     vec(
#         map(Iterators.product(values(iterable_dict)...)) do vals
#             dd = Dict(keys(iterable_dict) .=> vals)
#             merge(non_iterable_dict, dd)
#         end
#     )
# end
