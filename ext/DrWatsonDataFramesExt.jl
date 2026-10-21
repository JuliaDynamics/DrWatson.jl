module DrWatsonDataFramesExt

using DrWatson, DataFrames
using DrWatson: FileIO, JLD2, InvalidResultsCollection
using DrWatson.FileIO: File, filename, @format_str
import DrWatson: collect_results, collect_results!
using PrecompileTools: @setup_workload, @compile_workload

collect_results!(folder; kwargs...) =
collect_results!(
joinpath(dirname(rstrip(folder, '/')), "results_$(rstrip(basename(folder), '/')).jld2"),
folder; kwargs...)

function collect_results!(filename, folder;
    valid_filetypes = [".bson", "jld", ".jld2"],
    subfolders = false,
    rpath = nothing,
    verbose = true,
    update = false,
    newfile = false, # keyword only for defining collect_results without !
    rinclude = [r""],
    rexclude = [r"^\b$"],
    load_function = wload,
    kwargs...)

    @assert all(eltype(r) <: Regex for r in (rinclude, rexclude)) "Elements of `rinclude` and `rexclude` must be Regex expressions."

    if newfile || !isfile(filename)
        !newfile && verbose && @info "Starting a new result collection..."
        df = DataFrames.DataFrame()
        mtimes = Dict{String,Float64}()
    else
        verbose && @info "Loading existing result collection..."
        data = load_function(filename)
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
    existing_files = "path" in names(df) ? Set(df[:,:path]) : Set{String}()
    new_rows = DataFrames.DataFrame[]
    replaced_files = Set{String}()
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
        df_new = to_data_row(FileIO.query(fpath); load_function=load_function, kwargs...)
        #add filename
        df_new[!, :path] .= file
        if replace_entry
            push!(replaced_files, file)
            u += 1
        else
            n += 1
        end
        push!(new_rows, df_new)
    end
    if !isempty(replaced_files)
        # Delete the rows with the old data
        df = df[(!in(replaced_files)).(df.path), :]
    end
    # Concatenate once: appending row by row is quadratic in the number of files
    df = merge_dataframes!(df, new_rows)
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
    merge_dataframes!(df, dfs) -> merged_df
Concatenate `df` and all dataframes in the vector `dfs`.

If a dataframe is missing columns that exist in another one, these entries
are set as `missing`. Columns are ordered by first appearance.
"""
function merge_dataframes!(df, dfs)
    isempty(dfs) && return df
    return reduce(vcat, [df; dfs]; cols = :union)
end

is_valid_file(file, valid_filetypes) =
    any(endswith(file, v) for v in valid_filetypes)

# Use wload per default when nothing else is available
function to_data_row(file::File; load_function=wload, kwargs...)
    fpath = filename(file)
    @debug "Opening $(filename(file)) with fallback wload."
    return to_data_row(load_function(fpath), fpath; kwargs...)
end
# Specialize for JLD2 files, can do much faster mmapped access
function to_data_row(file::File{format"JLD2"}; load_function=(filename) -> JLD2.jldopen(filename, "r"), kwargs...)
    fpath = filename(file)
    @debug "Opening $(filename(file)) with jldopen."
    data = load_function(fpath)
    return to_data_row(data, fpath; kwargs...)
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


collect_results(folder; kwargs...) =
collect_results!("", folder; newfile = true, kwargs...)

@setup_workload begin
    @compile_workload begin
        mktempdir() do dir
            folder = joinpath(dir, "results")
            for (a, c) in ((1, "x"), (2, "y"))
                data = Dict{String,Any}("a" => a, "b" => 0.5a, "c" => c,
                    "v" => rand(3), "s" => :sym)
                wsave(joinpath(folder, savename(data, "jld2"; accesses = ["a", "c"])), data)
            end
            collect_results(folder; verbose = false)
            collect_results!(folder; verbose = false)
            collect_results!(folder; verbose = false, update = true)
        end
    end
end

end
