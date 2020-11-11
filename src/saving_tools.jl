export gitdescribe, current_commit, tag!, @tag!
export dict_list, dict_list_count

"""
    gitdescribe(gitpath = projectdir()) -> gitstr

Return a string `gitstr` with the output of `git describe` if an annotated git tag exists,
otherwise the current active commit id of the Git repository present
in `gitpath`, which by default is the currently active project. If the repository
is dirty when this function is called the string will end
with `"_dirty"`.

Return `nothing` if `gitpath` is not a Git repository, i.e. a directory within a git
repository.

The format of the `git describe` output in general is

    `"TAGNAME-[NUMBER_OF_COMMITS_AHEAD-]gLATEST_COMMIT_HASH[_dirty]"`

If the latest tag is `v1.2.3` and there are 5 additional commits while the
latest commit hash is 334a0f225d9fba86161ab4c8892d4f023688159c, the output
will be `v1.2.3-5-g334a0f`. Notice that git will shorten the hash if there
are no ambiguous commits.

More information about the `git describe` output can be found on
(https://git-scm.com/docs/git-describe)

See also [`tag!`](@ref).

## Examples
```julia
julia> gitdescribe() # a tag exists
"v1.2.3-g7364ab"

julia> gitdescribe() # a tag doesn't exist
"96df587e45b29e7a46348a3d780db1f85f41de04"

julia> gitdescribe(path_to_a_dirty_repo)
"3bf684c6a115e3dce484b7f200b66d3ced8b0832_dirty"
```
"""
function gitdescribe(gitpath = projectdir())
    # Here we test if the gitpath is a git repository.
    try
        repo = LibGit2.GitRepoExt(gitpath)
    catch er
        if isa(er,LibGit2.GitError) && er.code == LibGit2.Error.ENOTFOUND
            @warn "The directory ('$gitpath') is not a Git repository, "*
            "returning `nothing` instead of the commit ID."
        elseif isa(er,LibGit2.GitError)
            @warn "$(er.msg). Returning `nothing` instead of the commit ID."
        else
            @warn "`gitdescribe` failed with '$er', returning `nothing` instead of the commit ID."
        end
        return nothing
    end
    suffix = ""
    if LibGit2.isdirty(repo)
        suffix = "_dirty"
        @warn "The Git repository is dirty! Appending $(suffix) to the commit ID"
    end
    # then we return the output of `git describe` or the latest commit hash
    # if no annotated tags are available
    repo = LibGit2.GitRepoExt(gitpath)
    c = try
        gdr = LibGit2.GitDescribeResult(repo)
        fopt = LibGit2.DescribeFormatOptions(dirty_suffix=pointer(suffix))
        LibGit2.format(gdr, options=fopt)
    catch GitError
        string(LibGit2.head_oid(repo)) * suffix
    end
    return c
end

"""
    gitpatch(gitpath = projectdir())

Generates a patch describing the changes of a dirty repository
compared to its last commit; i.e. what `git diff HEAD` produces.
The `gitpath` needs to point to a directory within a git repository,
otherwise `nothing` is returned.

Be aware that `gitpatch` needs a working installation of Git, that 
can be found in the current PATH.
"""
function gitpatch(path = projectdir())
    try
        repo = LibGit2.GitRepoExt(path)
        gitpath = LibGit2.path(repo)
        gitdir = joinpath(gitpath,".git")
        patch = read(`git --git-dir=$gitdir --work-tree=$gitpath diff --submodule=diff HEAD`, String)
        return patch
    catch er
        if isa(er,LibGit2.GitError) && er.code == LibGit2.Error.ENOTFOUND
            @warn "The directory ('$path') is not a Git repository, "*
            "returning `nothing` instead of a patch."
        elseif isa(er,LibGit2.GitError)
            @warn "$(er.msg). Returning `nothing` instead of a patch."
        elseif Sys.which("git") == nothing
            @warn "`git` was not found in the current PATH, "*
            "returning `nothing` instead of a patch."
        else
            @warn "`gitpatch` failed with error $er, returning `nothing` instead."
        end
        return nothing
    end
    # tree = LibGit2.GitTree(repo, "HEAD^{tree}")
    # diff = LibGit2.diff_tree(repo, tree)
    # now there is no way to generate the patch with LibGit2.jl.
    # Instead use commands:
end

"""
    tag!(d::Dict; gitpath = projectdir(), storepatch = true, force = false) -> d
Tag `d` by adding an extra field `gitcommit` which will have as value
the [`gitdescribe`](@ref) of the repository at `gitpath` (by default
the project's gitpath). Do nothing if a key `gitcommit` already exists
(unless `force=true` then replace with the new value) or if the Git
repository is not found. If the git repository is dirty, i.e. there
are un-commited changes, then the output of `git diff HEAD` is stored
in the field `gitpatch`.  Note that patches for binary files are not
stored.

Notice that the key-type of the dictionary must be `String` or `Symbol`.
If `String` is a subtype of the _value_ type of the dictionary, this operation is
in-place. Otherwise a new dictionary is created and returned.

To restore a repository to the state of a particular model-run do:
1. checkout the relevant commit with `git checkout xyz` where xyz is the value stored
2. apply the patch `git apply patch`, where the string stored in the `gitpatch` field needs to be written to the file `patch`.

## Examples
```julia
julia> d = Dict(:x => 3, :y => 4)
Dict{Symbol,Int64} with 2 entries:
  :y => 4
  :x => 3

julia> tag!(d)
Dict{Symbol,Any} with 3 entries:
  :y => 4
  :gitcommit => "96df587e45b29e7a46348a3d780db1f85f41de04"
  :x => 3
```
"""
function tag!(d::Dict{K,T}; gitpath = projectdir(), storepatch = true, force = false, source = nothing) where {K,T}
    c = gitdescribe(gitpath)
    patch = gitpatch(gitpath)
    @assert (Symbol <: K) || (String <: K)
    if K == Symbol
        commitname, patchname, scriptname = :gitcommit, :gitpatch, :script
    else
        commitname, patchname, scriptname = "gitcommit", "gitpatch", "script"
    end

    c === nothing && return d # gitpath is not a git repo
    if haskey(d, commitname) && !force
        @warn "The dictionary already has a key named `gitcommit`. We won't "*
        "add any Git information."
        return d
    end
    if String <: T
        d[commitname] = c
        if storepatch && (patch != nothing)
            d[patchname] = patch
        end
    else
        d = Dict{K, promote_type(T, String)}(d)
        d[commitname] = c
        if patch!=""
            d[patchname] = patch
        end
    end
    if source != nothing && !force
        if haskey(d, scriptname)
            @warn "The dictionary already has a key named `script`. We won't "*
            "overwrite it with the script name."
        else
            d[scriptname] = relpath(sourcename(source), gitpath)
        end
    end
    return d
end

sourcename(s) = string(s)
sourcename(s::LineNumberNode) = string(s.file)*"#"*string(s.line)

"""
    @tag!(d, gitpath = projectdir(), storepatch = true, force = false) -> d
Do the same as [`tag!`](@ref) but also add another field `script` that has
the path of the script that called `@tag!`, relative with respect to `gitpath`.
The saved string ends with `#line_number`, which indicates the line number
within the script that `@tag!` was called at.

## Examples
```julia
julia> d = Dict(:x => 3)Dict{Symbol,Int64} with 1 entry:
  :x => 3

julia> @tag!(d) # running from a script or inline evaluation of Juno
Dict{Symbol,Any} with 3 entries:
  :gitcommit => "618b72bc0936404ab6a4dd8d15385868b8299d68"
  :script => "test\\stools_tests.jl#10"
  :x      => 3
```
"""
macro tag!(d,args...)
    args = Any[args...]
    # Keywords added after a ; are moved to the front of the expression
    # that is passed to the macro. So instead of getting the dict in d
    # an Expr is passed.
    if d isa Expr && d.head == :parameters
        length(args) > 0 || return :(throw(MethodError(@tag!,$(esc(d)),$(esc.(args)...))))
        extra_kw_def = d.args
        d = popfirst!(args)
        append!(args,extra_kw_def)
    end
    s = QuoteNode(__source__)
    return :(tag!($(esc(d)),$(esc.(convert_to_kw.(args))...),source=$s))
end

export struct2dict

"""
    struct2dict(s) -> d
Convert a Julia composite type `s` to a dictionary `d` with key type `Symbol`
that maps each field of `s` to its value. This can be useful in e.g. saving:
```
tagsave(savename(s), struct2dict(s))
```
"""
function struct2dict(s)
    Dict(x => getfield(s, x) for x in fieldnames(typeof(s)))
end

export struct2ntuple

"""
    struct2ntuple(s) -> n
Convert a Julia composite type `s` to a NamedTuple `n`.
"""
function struct2ntuple(s)
    NamedTuple{fieldnames(typeof(s))}(( getfield(s, x) for x in fieldnames(typeof(s))))
end
