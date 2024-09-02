export collect_results, collect_results!

"""
    collect_results!([filename,] folder; kwargs...) -> df

!!! note "Requires `DataFrames`"
    The function `collect_results!` is only available if you do
    `using DataFrames` in your Julia session.

Search the `folder` (and possibly all subfolders) for new result-files and add
them to `df` which is a `DataFrame` containing all the information from
each result-file.
If a result-file is missing keys that are already columns in `df`,
they will be set as `missing`. If on the other hand new keys are encountered,
a new column will be added and filled with `missing` for all previous entries.

If no file exists in `filename`, then `df` will be saved there. If however
`filename` exists, the existing `df` will be first loaded and then reused.
The reused `df` has some results already collected: files already
included in `df` are skipped in subsequent calls to `collect_results!` while
new result-files are simply appended to the dataframe.

`filename` defaults to:
```julia
filename = joinpath(dirname(folder), "results_\$(basename(folder)).jld2")
```

See also [`collect_results`](@ref).

!!! warning "Don't use `:path` as a parameter name."
    `df` contains a column `:path` which is the path where each result-file
    is saved to. This is used to not reload and reprocess files already
    present in `df` when searching for new ones.

## Keyword Arguments
* `subfolders::Bool = false` : If `true` also scan all subfolders of `folder`
  for result-files.
* `valid_filetypes = [".bson", ".jld", ".jld2"]`: Only files that have these
  endings are interpreted as result-files. Other files are skipped.
* `rpath = nothing` : If not `nothing`, then it must be a path to a folder. The `path`
  column of the result-files is then `relpath(file, rpath)`, instead of the absolute
  path, which is used by default.
* `verbose = true` : Print (using `@info`) information about the process.
* `update = false` : Update data from modified files and remove entries for deleted
  files.
* `rinclude = [r\"\"]` : Only include files whose name matches any of these Regex expressions. Default value includes all files.
* `rexclude = [r\"^\\b\$\"]` : Exclude any files whose name matches any of these Regex expressions. Default value does not exclude any files.
* `white_list` : List of keys to use from result file. By default
  uses all keys from all loaded result-files.
* `black_list = [:gitcommit, :gitpatch, :script]`: List of keys not to include from result-file.
* `special_list = []`: List of additional (derived) key-value pairs
  to put in `df` as explained below.

`special_list` is a `Vector` where each entry
is a derived quantity to be included in `df`. There are two types of entries.
The first option is of the form `key => func` where the `key` is a symbol
to be used as column name in the DataFrame. The function entry always
takes a single argument, which is the loaded result-file (a dictionary).
The second option is to provide just one function `func`. This function
also takes the single dictionary argument but returns one or more
`key => value` pairs. This second notation may be useful when one wants
to extract values for multiple columns in a single step.
As an example consider that each result-file
contains a field `:longvector` too large to be included in the `df`.
The quantity of interest is the mean and the variance of said field.
To have these values in your results first use `black_list = [:longvector]`
and then define

    special_list = [ :lv_mean => data -> mean(data[:longvector]),
                     :lv_lar  => data -> var(data[:longvector]) ]

In case this operation fails the values will be treated as `missing`.
"""
collect_results!(folder; kwargs...) =
collect_results!(
joinpath(dirname(rstrip(folder, '/')), "results_$(rstrip(basename(folder), '/')).jld2"),
folder; kwargs...)

struct InvalidResultsCollection <: Exception
    msg::AbstractString
end
 Base.showerror(io::IO, e::InvalidResultsCollection) = print(io, e.msg)

function collect_results!(filename, folder;
    valid_filetypes = [".bson", "jld", ".jld2"],
    subfolders = false,
    rpath = nothing,
    verbose = true,
    update = false,
    newfile = false, # keyword only for defining collect_results without !
    rinclude = [r""],
    rexclude = [r"^\b$"],
    kwargs...)

    @assert all(eltype(r) <: Regex for r in (rinclude, rexclude)) "Elements of `rinclude` and `rexclude` must be Regex expressions."

    if newfile || !isfile(filename)
        !newfile && verbose && @info "Starting a new result collection..."
        df = DataFrames.DataFrame()
        mtimes = Dict{String,Float64}()
    else
        verbose && @info "Loading existing result collection..."
        data = wload(filename)
        df = data["df"]
        # Check if we have pre-recorded mtimes (if not this could be because of an old results database).
        if "mtime" ∈ keys(data)
            mtimes = data["mtime"]
        else
            if update
                throw(InvalidResultsCollection("update of existing results collection requested, but no previously recorded modification time found. Likely the existing results collection was produced with an old version of DrWatson. Recomputing the collection solves this problem."))
            end
            mtimes = nothing
        end
    end
    verbose && @info "Scanning folder $folder for result files."

    if subfolders
        allfiles = String[]
        for (root, dirs, files) in walkdir(folder)
            for file in files
                push!(allfiles, joinpath(root,file))
            end
        end
    else
        allfiles = joinpath.(Ref(folder), readdir(folder))
    end

    if (rinclude == [r""] && rexclude == [r"^\b$"]) == false
        idx_filt = Int[]
        for i in eachindex(allfiles)
            file = allfiles[i]
            include_bool = any(match(rgx, file) !== nothing for rgx in rinclude)
            exclude_bool = any(match(rgx, file) !== nothing for rgx in rexclude)
            if include_bool == false || exclude_bool == true
                push!(idx_filt, i)
            end
        end
        deleteat!(allfiles, idx_filt)
    end

    n = 0 # new entries added
    u = 0 # entries updated
    existing_files = "path" in string.(names(df)) ? df[:,:path] : ()
    for file ∈ allfiles
        is_valid_file(file, valid_filetypes) || continue
        # maybe use relative path
        file = rpath === nothing ? file : relpath(file, rpath)
        mtime_file = mtime(file)
        replace_entry = false
        #already added?
        if file ∈ existing_files
            if !update
                continue
            end

            # Error if file is not in the mtimes database
            if file ∉ keys(mtimes)
                throw(InvalidResultsCollection("existing results correction is corrupt: no `mtime` entry for file $(file) found."))
            end

            # Skip if mtime is the same as the one previously recorded
            if mtimes[file] == mtime_file
                continue
            end

            replace_entry = true
        end

        # Now update the mtime of the new or modified file
        mtimes[file] = mtime_file

        fpath = rpath === nothing ? file : joinpath(rpath, file)
        df_new = to_data_row(FileIO.query(fpath); kwargs...)
        #add filename
        df_new[!, :path] .= file
        if replace_entry
            # Delete the row with the old data
            delete!(df, findfirst((x)->(x.path == file), eachrow(df)))
            u += 1
        else
            n += 1
        end
        df = merge_dataframes!(df, df_new)
    end
    if update
        # Delete entries with nonexisting files.
        idx = findall((x)->(!isfile(x.path)), eachrow(df))
        deleteat!(df, idx)
        verbose && @info "Added $n entries. Updated $u entries. Deleted $(length(idx)) entries."
    else
        verbose && @info "Added $n entries."
    end
    if !newfile
        data = Dict{String,Any}("df" => df)
        # mtimes is only `nothing` if we are working with an older collection
        # We want to keep it that way, so do not try to create mtimes entry.
        if !isnothing(mtimes)
            data["mtime"] = mtimes
        end
        wsave(filename, data)
    end
    return df
end

"""
    merge_dataframes!(df, df_new) -> merged_df
Merge two dataframes `df` and `df_new`. If the `names` of the dataframes
are the same this is just `vcat`.

If `df_new` is missing keys that are already columns in `df`,
they will set as `missing` in `df`.
If on the other hand new keys are encountered, existing in `df_new`
but not `df`, a new column will be added and filled with `missing`
in `df`. Then `df` and `df_new` are concatenated.
"""
function merge_dataframes!(df1, df2)
    if sort!(names(df1)) == sort!(names(df2))
        return vcat(df1, df2)
    else
        for m ∈ setdiff(names(df1), names(df2))
            df2[!, m] .= [missing]
        end
        for m ∈ setdiff(names(df2), names(df1))
            DataFrames.insertcols!(df1, length(names(df1))+1, m => fill(missing, size(df1,1)))
        end
        return vcat(df1,df2)
    end
end

is_valid_file(file, valid_filetypes) =
    any(endswith(file, v) for v in valid_filetypes)

# Use wload per default when nothing else is available
function to_data_row(file::File; kwargs...)
    fpath = filename(file)
    @debug "Opening $(filename(file)) with fallback wload."
    return to_data_row(wload(fpath), fpath; kwargs...)
end
# Specialize for JLD2 files, can do much faster mmapped access
function to_data_row(file::File{format"JLD2"}; kwargs...)
    fpath = filename(file)
    @debug "Opening $(filename(file)) with jldopen."
    JLD2.jldopen(filename(file), "r") do data
        return to_data_row(data, fpath; kwargs...)
    end
end
function to_data_row(data, file;
        white_list = collect(keys(data)),
        black_list = keytype(data).((:gitcommit, :gitpatch, :script)),
        special_list = [])
    cnames = setdiff!(white_list, black_list)
    entries = Pair{Symbol,Any}[]
    append!(entries,Symbol.(cnames) .=> (x->[x]).(getindex.(Ref(data),cnames)))
    #Add special things here
    for elem in special_list
        try
            if elem isa Pair
                push!(entries, first(elem) => last(elem)(data))
            elseif elem isa Function
                res = elem(data)
                if res isa Pair
                    # Use push! if a single key value pair is returned
                    push!(entries, res)
                else
                    # Use append! if a vector of pairs is returned
                    append!(entries, res)
                end
            end
        catch e
            @warn "While applying $(string(elem)) to file "*
            "$(file), got error $e."
        end
    end
    return DataFrames.DataFrame(entries...)
end


"""
    collect_results(folder; kwargs...) -> df
Do exactly the same as [`collect_results!`](@ref) but don't care to
load (or later save) an existing dataframe. Thus all found results files
are processed.
"""
collect_results(folder; kwargs...) =
collect_results!("", folder; newfile = true, kwargs...)
