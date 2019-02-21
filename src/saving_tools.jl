export current_commit
export dict_list, ntuple_list

function addrun! end

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
