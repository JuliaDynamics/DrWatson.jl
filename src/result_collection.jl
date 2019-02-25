using DataFrames
using BSON

function merge_df(df1, df2)
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
is_valid_file(file, valid_filetypes) = any(endswith.(Ref(file),valid_filetypes)

function to_data_row(
        data,
        white_list = collect(keys(data),
        black_list = [],
        special = [])
    cnames = setdiff!(white_list, black_list)
    df = DataFrame( (Symbol.(cnames) .=> getindex.(Ref(data),cnames))...)
    #Add special things here
    for (ename, func) in special
        try df_new[ename] = func(data)
        catch e
            df_new[ename] = missing
            @warn e
        end
    end
    return df
end

function collect_results(
    data_folder = joinpath(datadir(), "results");
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

            df = merge_df(df, df_new)
        end
    end
    BSON.@save filename df
end
