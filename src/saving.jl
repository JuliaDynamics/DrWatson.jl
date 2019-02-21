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
    dict_list(d)
Take the dictionary `d` and expand it into a vector of dictionaries.
Each entry has a unique combination from the product of the `Vector`
values of the dictionary while the non-`Vector` values are kept constant
for all possibilities. The keys of the entries are the same.

## Examples
julia> d = Dict(:a => [1, 2, 3], :b => 4);

julia> dict_list(d)
3-element Array{Dict{Symbol,Int64},1}:
 Dict(:a=>1,:b=>4)
 Dict(:a=>2,:b=>4)
 Dict(:a=>3,:b=>4)

julia> d[:c] = "test"; d[:d] = ["lala", "lulu"];

julia> dict_list(d)
6-element Array{Dict{Symbol,Any},1}:
 Dict(:a=>1,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>3,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>1,:b=>4,:d=>"lulu",:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lulu",:c=>"test")
 Dict(:a=>3,:b=>4,:d=>"lulu",:c=>"test")

julia> d[:e] = [[0.1, 0.2]]; # final result retains the inner vector

julia> dict_list(d)
6-element Array{Dict{Symbol,Any},1}:
 Dict(:a=>1,:b=>4,:d=>"lala",:e=>[0.1, 0.2],:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lala",:e=>[0.1, 0.2],:c=>"test")
 Dict(:a=>3,:b=>4,:d=>"lala",:e=>[0.1, 0.2],:c=>"test")
 Dict(:a=>1,:b=>4,:d=>"lulu",:e=>[0.1, 0.2],:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lulu",:e=>[0.1, 0.2],:c=>"test")
 Dict(:a=>3,:b=>4,:d=>"lulu",:e=>[0.1, 0.2],:c=>"test")
"""
function dict_list(d)
    vec(map(Iterators.product(values(d)...)) do vals
        Dict(keys(d) .=> vals)
    end)
end

# function namedtuple_list(d::NamedTuple)
#     vec(map(Iterators.product(values(d)...)) do vals
#         s = tuple(keys(d)...)
#         NamedTuple{s,typeof(vals)}(vals)
#     end)
# end


# function prepare(cs...)
#     allkeys = [allaccess(c) for c in cs]
#
#     if !allunique(Iterators.flatten(allkeys))
#         error("The keys of the given containers are not all unique.")
#     end
#
#     # Key type of the final dictionary:
#     K = promote_type([eltype(k) for k in allkeys]...)
#     total = Dict{K, Any}()
#     for (i, acc) in enumerate(allkeys)
#         c = cs[i]
#         for k in acc
#             if eltype(c[k]) <: Vector # Expand
