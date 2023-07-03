export produce_or_load, @produce_or_load, tagsave, @tagsave, safesave

"""
    produce_or_load(f::Function, config, path = ""; kwargs...) -> data, file
The goal of `produce_or_load` is to avoid running some data-producing code that has
already been run with a given configuration container `config`.
If the output of some function `f(config)` exists on disk, `produce_or_load` will load
it and return it, and if not, it will produce it, save it, and then return it.

Here is how it works:

1. The output data are saved in a file named `name = filename(config)`.
   I.e., the output file's name is created from the configuration container `config`.
   By default, this is `name = `[`savename`](@ref)`(config)`,
   but can be configured differently, using e.g. `hash`, see keyword `filename` below.
   See also [`produce_or_load` with hash codes](@ref) for an example where `config`
   would be hard to put into `name` with `savename`, and `hash` is used instead.
2. Now, let `file = joinpath(path, name)`.
3. If `file` exists, load it and return
   the contained `data`, along with the global path that it is saved at (`file`).
4. If the file does not exist then call `data = f(config)`, with `f` your function
   that produces your data from the configuration container.
5. Then save the `data` as `file` and then return `data, file`.

The function `f` should return a string-keyed dictionary if the data are saved in the
default format of JLD2.jl., the macro [`@strdict`](@ref) can help with that.

You can use a [do-block]
(https://docs.julialang.org/en/v1/manual/functions/#Do-Block-Syntax-for-Function-Arguments)
instead of defining a function to pass in. For example,
```julia
produce_or_load(config, path) do config
    # code using `config` runs here
    # and then returns a dictionary to be saved
end
```

## Keywords
### Name deciding
* `filename::Union{Function, String} = savename` :
  Configures the `name` of the file to produce or load given the configuration container.
  It may be a one-argument function of `config`, [`savename`](@ref) by default, so that
  `name = filename(config)`. Useful alternative to `savename` is `hash`.
  The keyword `filename` could also be a `String` directly,
  possibly extracted from `config` before calling `produce_or_load`,
  in which case `name = filename`.
* `suffix = "jld2", prefix = default_prefix(config)` : If not empty, added to `name`
  as `name = prefix*'_'*name*'.'*suffix` (i.e., like in [`savename`](@ref)).

### Saving
* `tag::Bool = DrWatson.readenv("DRWATSON_TAG", istaggable(suffix))` : Save the file
  using [`tagsave`](@ref) if `true` (which is the default).
* `gitpath, storepatch` : Given to [`tagsave`](@ref) if `tag` is `true`.
* `force = false` : If `true` then don't check if `file` exists and produce
  it and save it anyway.
* `loadfile = true` : If `false`, this function does not actually load the
  file, but only checks if it exists. The return value in this case is always
  `nothing, file`, regardless of whether the file exists or not. If it doesn't
  exist it is still produced and saved.
* `verbose = true` : print info about the process, if the file doesn't exist.
* `wsave_kwargs = Dict()` : Keywords to pass to `wsave` (e.g. to enable
  compression).
"""
function produce_or_load(f::Function, config, path::String = "";
        suffix = "jld2", prefix = default_prefix(config),
        tag::Bool = readenv("DRWATSON_TAG", istaggable(suffix)),
        gitpath = projectdir(), loadfile = true,
        storepatch::Bool = readenv("DRWATSON_STOREPATCH", false),
        force = false, verbose = true, wsave_kwargs = Dict(),
        filename::Union{Nothing, Function, AbstractString} = nothing,
        kwargs...
    )
    # Deprecations
    # TODO: Remove this in future versions and make `filename = savename` as keyword.
    if !isempty(kwargs)
        @warn """
        Passing arbitrary keyword arguments in `produce_or_load`, with the goal of
        forwarding them to `savename` is deprecated. Instead, just create a function
        for the keyword `filename` as `filename = config -> savename(config; kwargs...)`
        """
    end
    # Prepare absolute file name
    if filename === nothing
        filename = config -> savename(prefix, config, suffix; kwargs...)
        name = filename(config)
    elseif filename isa AbstractString
        name = append_prefix_suffix(filename, prefix, suffix)
    else #if filename isa Function
        name = string(filename(config))
        name = append_prefix_suffix(name, prefix, suffix)
    end
    file = joinpath(path, name)
    # Run the remaining logic on whether to produce or load
    if !force && isfile(file)
        if loadfile
            data = wload(file)
            return data, file
        else
            return nothing, file
        end
    else
        if force
            verbose && @info "Producing file $file now..."
        else
            verbose && @info "File $file does not exist. Producing it now..."
        end
        data = f(config)
        try
            if tag
                tagsave(file, data; safe = false, gitpath = gitpath, storepatch = storepatch, wsave_kwargs...)
            else
                wsave(file, copy(data); wsave_kwargs...)
            end
            verbose && @info "File $file saved."
        catch er
            @warn "Could not save file. Error stacktrace:"
            Base.showerror(stderr, er, stacktrace(catch_backtrace()))
        end
        if loadfile
            return data, file
        else
            return nothing, file
        end
    end
end
# TODO: Remove this in future version!
# Deprecations for the old way of doing `produce_or_load`.
produce_or_load(c, f::Function; kwargs...) = produce_or_load(f, c; kwargs...)
produce_or_load(path::String, c, f::Function; kwargs...) = produce_or_load(f, c, path; kwargs...)
produce_or_load(f::Function, path::String, c; kwargs...) = produce_or_load(f, c, path; kwargs...)

function append_prefix_suffix(name, prefix, suffix)
    if isempty(name)
        if isempty(suffix)
            return prefix
        else
            return prefix*'.'*suffix
        end
    end
    if prefix != ""
        name = prefix*'_'*name
    end
    if suffix != ""
        name *= '.'*suffix
    end
    return name
end

"""
    @produce_or_load(f, config, path; kwargs...)
Same as [`produce_or_load`](@ref) but one more field `:script` is added that records
the local path of the script and line number that called `@produce_or_load`,
see [`@tag!`](@ref).

Notice that `path` here is mandatory in contrast to [`produce_or_load`](@ref).
"""
macro produce_or_load(f, config, path, args...)
    args = Any[args...]
    # Keywords added after a ; are moved to the front of the expression
    # that is passed to the macro. So instead of getting the function in f
    # an Expr is passed.
    if f isa Expr && f.head == :parameters
        length(args) > 0 || return :(throw(MethodError(@produce_or_load,$(esc(f)),$(esc(path)),$(esc(config)),$(esc.(args)...))))
        extra_kw_def = f.args
        f = config
        config = path
        path = popfirst!(args)
        append!(args, extra_kw_def)
    end

    # Save the source file name and line number of the calling line.
    s = QuoteNode(__source__)
    # Wrap the function f, such that the source can be saved in the data Dict.
    return quote
        produce_or_load($(esc(config)), $(esc(path)), $(esc.(convert_to_kw.(args))...)) do k
            data = $(esc(f))(k)
            # Extract the `gitpath` kw arg if it's there
            kws = ((;kwargs...) -> Dict(kwargs...))($(esc.(convert_to_kw.(args))...))
            gitpath = get(kws, :gitpath, projectdir())
            # Include the script tag with checking for the type of dict keys, etc.
            data = scripttag!(data, $s; gitpath = gitpath)
            data
        end
    end
end


################################################################################
#                             tag saving                                       #
################################################################################
"""
    tagsave(file::String, d::AbstractDict; kwargs...)
First [`tag!`](@ref) dictionary `d` and then save `d` in `file`.

"Tagging" means that when saving the dictionary, an extra field
`:gitcommit` is added to establish reproducibility of results using
Git. If the Git repository is dirty and `storepatch=true`, one more field `:gitpatch` is
added that stores the difference string. If a dictionary already
contains a key `:gitcommit`, it is not overwritten, unless
`force=true`. For more details, see [`tag!`](@ref).

Keywords `gitpath, storepatch, force,` are propagated to [`tag!`](@ref).
Any additional keyword arguments are propagated to `wsave`, to e.g.
enable compression.

The keyword `safe = DrWatson.readenv("DRWATSON_SAFESAVE", false)` decides whether
to save the file using [`safesave`](@ref).
"""
function tagsave(file, d;
        gitpath = projectdir(),
        safe::Bool = readenv("DRWATSON_SAFESAVE", false),
        storepatch::Bool = readenv("DRWATSON_STOREPATCH", false),
        force = false, source = nothing, kwargs...
    )
    d2 = tag!(d, gitpath=gitpath, storepatch=storepatch, force=force, source=source)
    if safe
        safesave(file, copy(d2); kwargs...)
    else
        wsave(file, copy(d2); kwargs...)
    end
    return d2
end


"""
    @tagsave(file::String, d::AbstractDict; kwargs...)
Same as [`tagsave`](@ref) but one more field `:script` is added that records
the local path of the script and line number that called `@tagsave`, see [`@tag!`](@ref).
"""
macro tagsave(file,d,args...)
    args = Any[args...]
    # Keywords added after a ; are moved to the front of the expression
    # that is passed to the macro. So instead of getting the filename in file
    # an Expr is passed.
    if file isa Expr && file.head == :parameters
        length(args) > 0 || return :(throw(MethodError(@tagsave,$(esc(file)),$(esc(d)),$(esc.(args)...))))
        extra_kw_def = file.args
        file = d
        d = popfirst!(args)
        append!(args,extra_kw_def)
    end
    s = QuoteNode(__source__)
    return :(tagsave($(esc(file)), $(esc(d)), $(esc.(convert_to_kw.(args))...),source=$s))
end

################################################################################
#                          Backup files before saving                          #
################################################################################

# Implementation inspired by behavior of GROMACS
"""
    safesave(filename, data...; kwargs...)

Safely save `data` in `filename` by ensuring that no existing files
are overwritten. Do this by renaming already existing data with a backup-number
ending like `#1, #2, ...`. For example if `filename = test.jld2`, the first
time you `safesave` it, the file is saved normally. The second time
the existing save is renamed to `test_#1.jld2` and a new file `test.jld2`
is then saved.

If a backup file already exists then its backup-number is incremented
(e.g. going from `#2` to `#3`). For example safesaving `test.jld2` a third time
will rename the old `test_#1.jld2` to `test_#2.jld2`, rename the old
`test.jld2` to `test_#1.jld2` and then save a new `test.jld2` with the latest
`data`.

Any additional keyword arguments are passed through to wsave (to e.g. enable
compression).

See also [`tagsave`](@ref).
"""
function safesave(f, data...; kwargs...)
    recursively_clear_path(f)
    wsave(f, data...; kwargs...)
end

#take a path of a results file and increment its prefix backup number
function increment_backup_num(filepath)
    path, filename = splitdir(filepath)
    fname, suffix = splitext(filename)
    m = match(r"^(.*)_#([0-9]+)$", fname)
    if m === nothing
        return joinpath(path, "$(fname)_#1$(suffix)")
    end
    newnum = string(parse(Int, m.captures[2]) +1)
    return joinpath(path, "$(m.captures[1])_#$newnum$(suffix)")
end

#recursively move files to increased backup number
function recursively_clear_path(cur_path)
    ispath(cur_path) || return
    new_path=increment_backup_num(cur_path)
    if ispath(new_path)
        recursively_clear_path(new_path)
    end
    mv(cur_path, new_path)
end

################################################################################
#                    Compliment to dict_list: tmpsave                          #
################################################################################
export tmpsave
using Random
"""
    tmpsave(dicts::Vector{Dict} [, tmp]; kwargs...) -> r
Save each entry in `dicts` into a unique temporary file in the directory `tmp`.
Then return the list of file names (relative to `tmp`) that were used
for saving each dictionary. Each dictionary can then be loaded back by calling

    wload(nth_tmpfilename, "params")

`tmp` defaults to `projectdir("_research", "tmp")`.

See also [`dict_list`](@ref).

## Keywords
* `l = 8` : number of characters in the random string.
* `prefix = ""` : prefix each temporary name will have.
* `suffix = "jld2"` : ending of the temporary names (no need for the dot).
* `kwargs...` : Any additional keywords are passed through to wsave (e.g. compression).
"""
function tmpsave(dicts, tmp = projectdir("_research", "tmp");
    l = 8, suffix = "jld2", prefix = "", kwargs...)

    mkpath(tmp)
    n = length(dicts)
    existing = readdir(tmp)
    r = String[]
    i = 0
    while i < n
        x = prefix*randstring(l)*"."*suffix
        while x ∈ r || x ∈ existing
            x = prefix*randstring(l)*"."*suffix
        end
        i += 1
        push!(r, x)
        wsave(joinpath(tmp, x), Dict("params" => copy(dicts[i])); kwargs...)
    end
    r
end
