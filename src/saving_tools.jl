export gitdescribe, isdirty, current_commit, tag!, @tag!
export struct2dict, struct2ntuple
export istaggable

########################################################################################
# Obtaining Git information
########################################################################################
"""
    gitdescribe(gitpath = projectdir(); dirty_suffix = "-dirty") -> gitstr

Return a string `gitstr` with the output of `git describe` if an annotated git tag exists,
otherwise the current active commit id of the Git repository present
in `gitpath`, which by default is the currently active project. If the repository
is dirty when this function is called the string will end
with `dirty_suffix`.

Return `nothing` if `gitpath` is not a Git repository, i.e. a directory within a git
repository.

The format of the `git describe` output in general is

    `"TAGNAME-[NUMBER_OF_COMMITS_AHEAD-]gLATEST_COMMIT_HASH[-dirty]"`

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
"3bf684c6a115e3dce484b7f200b66d3ced8b0832-dirty"
```
"""
function gitdescribe(gitpath = projectdir(); dirty_suffix::String = "-dirty")
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
        suffix = dirty_suffix
        @warn "The Git repository ('$gitpath') is dirty! "*
        "Appending $(suffix) to the commit ID."
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
    isdirty(gitpath = projectdir()) -> Bool

Return `true` if `gitpath` is the path to a dirty Git repository, `false` otherwise.

Note that unlike [`tag!`](@ref), `isdirty` **can** error
(for example, if the path passed to it doesn't exist, or isn't a Git repository).
The purpose of `isdirty` is to be used as a check before running simulations, for users
that do not wish to tag data while having a dirty git repo.
"""
function isdirty(gitpath = projectdir())
    repo = LibGit2.GitRepoExt(gitpath)
    return LibGit2.isdirty(repo)
end

"""
    read_stdout_stderr(cmd::Cmd)

Run `cmd` synchronously and capture stdout, stdin and a possible error exception.
Return a `NamedTuple` with the fields `exception`, `out` and `err`.
"""
function read_stdout_stderr(cmd::Cmd)
    out = Pipe()
    err = Pipe()
    exception = nothing
    try
        run(pipeline(cmd,stderr=err, stdout=out), wait=true)
    catch e
        exception = e
    end
    close(out.in)
    close(err.in)
    return (exception = exception, out=read(out,String), err=read(err,String))
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
function gitpatch(path = projectdir(); try_submodule_diff=true)
    try
        repo = LibGit2.GitRepoExt(path)
        gitpath = LibGit2.path(repo)
        gitdir = joinpath(gitpath,".git")
        optional_args = String[]
        try_submodule_diff && push!(optional_args,"--submodule=diff")
        result = read_stdout_stderr(`git --git-dir=$gitdir --work-tree=$gitpath diff $(optional_args) HEAD`)
        if result.exception === nothing
            return result.out
        elseif Sys.which("git") === nothing
            @warn "`git` was not found in the current PATH, "*
            "returning `nothing` instead of a patch."
        elseif occursin("--submodule",result.err) && occursin("diff",result.err) && try_submodule_diff
            # Remove the submodule option as it is not supported by older git versions.
            return gitpatch(path; try_submodule_diff = false)
        else
            @warn "`gitpatch` failed with error $(result.err) $(result.exception). Returning `nothing` instead."
        end
    catch er
        if isa(er,LibGit2.GitError) && er.code == LibGit2.Error.ENOTFOUND
            @warn "The directory ('$path') is not a Git repository, "*
            "returning `nothing` instead of a patch."
        elseif isa(er,LibGit2.GitError)
            @warn "$(er.msg). Returning `nothing` instead of a patch."
        else
            @warn "`gitpatch` failed with error $er, returning `nothing` instead."
        end
    end
    return nothing
end


########################################################################################
# Tagging
########################################################################################
"""
    tag!(d::AbstractDict; kwargs...) -> d
Tag `d` by adding an extra field `gitcommit` which will have as value
the [`gitdescribe`](@ref) of the repository at `gitpath` (by default
the project's gitpath). Do nothing if a key `gitcommit` already exists
(unless `force=true` then replace with the new value) or if the Git
repository is not found. If the git repository is dirty, i.e. there
are un-commited changes, and `storepatch` is true, then the output of `git diff HEAD` is stored
in the field `gitpatch`.  Note that patches for binary files are not
stored. You can use [`isdirty`](@ref) to check if a repo is dirty. 
If the `commit message` is set to `true`, 
then the dictionary `d` will include an additional field `"gitmessage"` and will contain the git message associated  with the commit.

Notice that the key-type of the dictionary must be `String` or `Symbol`.
If `String` is a subtype of the _value_ type of the dictionary, this operation is
in-place. Otherwise a new dictionary is created and returned.

To restore a repository to the state of a particular model-run do:
1. checkout the relevant commit with `git checkout xyz` where xyz is the value stored
2. apply the patch `git apply patch`, where the string stored in the `gitpatch` field needs to be written to the file `patch`.

## Keywords
* `gitpath = projectdir()`
* `force = false`
* `storepatch = DrWatson.readenv("DRWATSON_STOREPATCH", false)`: Whether to collect and store the
  output of [`gitpatch`](@ref) as well.

## Examples
```julia
julia> d = Dict(:x => 3, :y => 4)
Dict{Symbol,Int64} with 2 entries:
  :y => 4
  :x => 3

julia> tag!(d; commit_message=true)
Dict{Symbol,Any} with 3 entries:
  :y => 4
  :gitmessage => "File set up by DrWatson"
  :gitcommit => "96df587e45b29e7a46348a3d780db1f85f41de04"
  :x => 3
```
"""
function tag!(d::AbstractDict{K,T};
        gitpath = projectdir(), force = false, source = nothing,
        storepatch::Bool = readenv("DRWATSON_STOREPATCH", false),
        commit_message::Bool = false
    ) where {K,T}
    @assert (K <: Union{Symbol,String}) "We only know how to tag dictionaries that have keys that are strings or symbols"
    c = gitdescribe(gitpath)
    c === nothing && return d # gitpath is not a git repo

    # Get the appropriate keys
    commitname = keyname(d, :gitcommit)
    patchname = keyname(d, :gitpatch)
    message_name = keyname(d, :gitmessage)

    if haskey(d, commitname) && !force
        @warn "The dictionary already has a key named `gitcommit`. We won't "*
        "add any Git information."
    else
        d = checktagtype!(d)
        d[commitname] = c
        # Only include patch info if `storepatch` is true and if we can get the info.
        if storepatch
            patch = gitpatch(gitpath)
            if (patch !== nothing) && (patch != "")
                d[patchname] = patch
            end
        end
        if commit_message
            repo = LibGit2.GitRepoExt(gitpath)
            mssgcommit =  LibGit2.GitCommit(repo, "HEAD")
            msg = LibGit2.message(mssgcommit)
            if (msg !== nothing) && (msg != "")
                 d[message_name] = msg
            end
        end
    end

    # Include source file and line number info if given.
    if source !== nothing
        d = scripttag!(d, source; gitpath = gitpath, force = force)
    end

    return d
end



"""
    keyname(d::AbstractDict{K,T}, key) where {K<:Union{Symbol,String},T}

Check the key type of `d` and convert `key` to the appropriate type.
"""
function keyname(d::AbstractDict{K,T}, key) where {K<:Union{Symbol,String},T}
    if K == Symbol
        return Symbol(key)
    end
    return String(key)
end

"""
    checktagtype!(d::AbstractDict{K,T}) where {K<:Union{Symbol,String},T}

Check if the value type of `d` allows `String` and promote it to do so if not.
"""
function checktagtype!(d::AbstractDict{K,T}) where {K<:Union{Symbol,String},T}
    DT = get_rawtype(typeof(d)) #concrete type of dictionary
    if !(String <: T)
        d = DT{K, promote_type(T, String)}(d)
    end
    d
end

"""
    get_rawtype(D::DataType) = getproperty(parentmodule(D), nameof(D))

Return Concrete DataType from an `AbstractDict` `D`. Found online at:
https://discourse.julialang.org/t/retrieve-the-type-of-abstractdict-without-parameters-from-a-concrete-dictionary-type/67567/3
"""
get_rawtype(D::DataType) = getproperty(parentmodule(D), nameof(D))

"""
    scripttag!(d::AbstractDict{K,T}, source::LineNumberNode; gitpath = projectdir(), force = false) where {K<:Union{Symbol,String},T}

Include a `script` field in `d`, containing the source file and line number in
`source`. Do nothing if the field is already present unless `force = true`. Uses
`gitpath` to make the source file path relative.
"""
function scripttag!(d::AbstractDict{K,T}, source; gitpath = projectdir(), force = false) where {K,T}
    # We want this functionality to be separate from `tag!` to allow
    # inclusion of this information without the git tagging
    # functionality.
    # To be used in `tag!` and `@produce_or_load`.
    # We have to assert the key type here again because `scripttag!` can be called
    # from `@produce_or_load` without going through `tag!`.
    @assert (K <: Union{Symbol,String}) "We only know how to tag dictionaries that have keys that are strings or symbols"
    scriptname = keyname(d, :script)
    if haskey(d, scriptname) && !force
        @warn "The dictionary already has a key named `script`. We won't "*
            "overwrite it with the script name."
    else
        d = checktagtype!(d)
        d[scriptname] = relpath(sourcename(source), gitpath)
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

########################################################################################
# Tagging Utilities
########################################################################################
const TAGGABLE_FILE_ENDINGS = ("bson", "jld", "jld2")
"""
    istaggable(file::AbstractStrig) → bool
Return `true` if the file save format (file ending) is "taggable", i.e. allows adding
additional data fields as strings. Currently endings that can do this are:
```
$(TAGGABLE_FILE_ENDINGS)
```
"""
istaggable(file::AbstractString) = any(endswith(file, e) for e ∈ TAGGABLE_FILE_ENDINGS)

"""
    istaggable(x) = x isa AbstractDict
For non-string input the function just checks if input is dictionary.
"""
istaggable(x) = x isa AbstractDict


"""
    struct2dict([type = Dict,] s) -> d
Convert a Julia composite type `s` to a dictionary `d` with key type `Symbol`
that maps each field of `s` to its value. Simply passing `s` will return a regular dictionary.
This can be useful in e.g. saving:
```
tagsave(savename(s), struct2dict(s))
```
"""
function struct2dict(::Type{DT},s) where {DT<:AbstractDict}
        DT(x => getfield(s, x) for x in fieldnames(typeof(s)))
end
struct2dict(s) = struct2dict(Dict,s)

"""
    struct2ntuple(s) -> n
Convert a Julia composite type `s` to a NamedTuple `n`.
"""
function struct2ntuple(s)
    NamedTuple{fieldnames(typeof(s))}(( getfield(s, x) for x in fieldnames(typeof(s))))
end
