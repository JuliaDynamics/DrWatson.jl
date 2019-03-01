using DataFrames
using BSON

"""
    merge_dataframes(df, df_new)
Merge two dataframes `df` and `df_new`. If the `names` of the dataframes
are the same this is just `vcat`.

If `df_new` is missing keys that are already columns in `df`,
they will set as `missing` in `df`.
If on the other hand new keys are encountered, existing in `df_new`
but not `df`, a new column will be added and filled with `missing`
in `df`. Then `df` and `df_new` are concatenated.
"""
function merge_dataframes(df1, df2)
    if names(df1) == names(df2)
        return vcat(df1, df2)
    else
        for m ∈ setdiff(names(df1), names(df2))
            df2[m] = [missing]
        end
        for m ∈ setdiff(names(df2), names(df1))
            df1[m] = fill(missing, size(df1,1))
        end
        return vcat(df1,df2)
    end
end

is_valid_file(file, valid_filetypes) =
    any(endswith.(Ref(file),valid_filetypes))

function to_data_row(data,
        white_list = collect(keys(data)),
        black_list = [],
        special_list = [])
    cnames = setdiff!(white_list, black_list)
    df = DataFrame( (Symbol.(cnames) .=> getindex.(Ref(data),cnames))...)
    #Add special things here
    for (ename, func) in special_list
        try df_new[ename] = func(data)
        catch e
            df_new[ename] = missing
            @warn e
        end
    end
    return df
end


"""
    collect_results(; kwargs...)

Walks the data directory for new result-files and adds them
to a `DataFrame` containing all attributes relevant for evaluation.
Files already included in the resulting `DataFrame` are skipped in
subsequent calls to `collect_results`.

If a result file is missing keys that are already columns in the `DataFrame`,
they will set as `missing`. If on the other hand new keys are encountered,
a new column will be added and filled with `missing` for all previous entries.

## Keyword Arguments
 * `data_folder = joinpath(datadir(), "results")`: Folder that is scanned for
   result files.
 * `filename = joinpath(datadir(),"results_dataframe.bson")`: Path to the file
   the DataFrame should be saved to.
 * `valid_filetypes = [".bson", ".jld2", ".jld"]`: File types to be
   interpreted as result files. Other files are skipped.
 * `white_list=keys(data)`: List of keys to use from result file.
 * `black_list=[]`: List of keys not to include from result file.
 * `special_list=[]`: List of additional (derived) key-value pairs
   to put in `DataFrame` as explained below.


`special_list` is a `Vector{Pair{Symbol, Function}}` where each entry
is a derived quantity to be included in the `DataFrame`.
As an example consider that each results-file (which is a dictionary)
contains a field `:longvector` too large to be included in the `DataFrame`.
The quantity of interest is the mean and the variance of said field.
To do just this, pass: `black_list = [:longvector]` and

    special_list = [ :lv_mean => data -> mean(data[:longvector]),
                     :lv_lar  => data -> var(data[:longvector])]
In case this operation fails the values will be treated as `missing`.
"""
function collect_results(;
    data_folder = joinpath(datadir(), "results"),
    filename = joinpath(datadir(),"results_dataframe.bson"),
    valid_filetypes = [".bson", ".jld2", ".jld"],
    kwargs...)

    df = isfile(filename) ? BSON.load(filename)[:df] : DataFrame()

    for (root, dirs, files) in walkdir(data_folder)
        for file in files
            is_valid_file(file, valid_filetypes) && continue
            #already added?
            joinpath(root,file) in get(df,:path,[]) && continue

            data = load(joinpath(root,file))
            df_new = to_data_row(data, kwargs...)
            #add filename
            df_new[:path] = joinpath(root, file)

            df = merge_dataframes(df, df_new)
        end
    end
    BSON.@save filename df
end
